# =============================================================================
# EC2 — Instância na sub-rede pública com cliente PostgreSQL instalado
# =============================================================================

# AMI mais recente do Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# User Data — instala psql, cria script de teste e arquivo .pgpass
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Atualizar sistema
    yum update -y

    # Instalar cliente PostgreSQL 15
    yum install -y postgresql15

    # Criar script de teste de conexão
    cat > /home/ec2-user/test-db.sh << 'SCRIPT'
    #!/bin/bash
    echo "=== Testando conexão EC2 → RDS ==="
    PGPASSWORD="${var.db_password}" psql \
      -h ${aws_db_instance.main.address} \
      -U ${var.db_username} \
      -d ${var.db_name} \
      -c "SELECT version();" 2>&1 | tee /home/ec2-user/connection-test.log

    echo "=== Criando tabela e inserindo dados de exemplo ==="
    PGPASSWORD="${var.db_password}" psql \
      -h ${aws_db_instance.main.address} \
      -U ${var.db_username} \
      -d ${var.db_name} << 'SQL'
    CREATE TABLE IF NOT EXISTS orders (
        id         SERIAL PRIMARY KEY,
        product    VARCHAR(100) NOT NULL,
        quantity   INT          NOT NULL,
        created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO orders (product, quantity) VALUES
        ('Laptop',  5),
        ('Mouse',  20),
        ('Teclado', 15)
    ON CONFLICT DO NOTHING;
    SELECT * FROM orders;
    SQL
    echo "=== Teste concluído! Ver /home/ec2-user/connection-test.log ==="
    SCRIPT

    chmod +x /home/ec2-user/test-db.sh
    chown ec2-user:ec2-user /home/ec2-user/test-db.sh

    # Arquivo .pgpass para evitar prompt de senha interativo
    echo "${aws_db_instance.main.address}:5432:${var.db_name}:${var.db_username}:${var.db_password}" \
      > /home/ec2-user/.pgpass
    chmod 600 /home/ec2-user/.pgpass
    chown ec2-user:ec2-user /home/ec2-user/.pgpass

    echo "Setup concluído em $(date)" > /home/ec2-user/setup.log
  EOF
}

# Instância EC2
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.ec2_key_name

  user_data                   = local.user_data
  user_data_replace_on_change = false

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-app-server"
  }

  # Aguardar o RDS estar disponível antes de configurar o EC2
  depends_on = [aws_db_instance.main]
}
