const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

app.use(express.json());

const orders = [
  { id: 1, cliente: 'Ana Souza', total: 250.0, status: 'pago' },
  { id: 2, cliente: 'Bruno Lima', total: 99.9, status: 'pendente' },
  { id: 3, cliente: 'Carla Dias', total: 1540.5, status: 'enviado' }
];

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: process.env.npm_package_version || '1.2.3',
    region: AWS_REGION,
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.status(200).json({
    servico: 'TechNova API - Aula 09 (ECR + AI Review)',
    aluno: 'FERNANDA TAVARES',
    ra: '4025109',
    endpoints: ['/health', '/api/orders', '/api/orders/:id']
  });
});

app.get('/api/orders', (req, res) => {
  res.status(200).json(orders);
});

app.get('/api/orders/:id', (req, res) => {
  const id = Number(req.params.id);
  const order = orders.find((o) => o.id === id);
  if (!order) {
    return res.status(404).json({ erro: 'Pedido não encontrado' });
  }
  return res.status(200).json(order);
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`TechNova API (aula-09) rodando na porta ${PORT}`);
  });
}

module.exports = app;
