output "bucket_name" {
  description = "Nome do bucket S3 criado"
  value       = aws_s3_bucket.technova_lab.bucket
}

output "bucket_arn" {
  description = "ARN (identificador único AWS) do bucket"
  value       = aws_s3_bucket.technova_lab.arn
}

output "bucket_region" {
  description = "Região onde o bucket foi criado"
  value       = aws_s3_bucket.technova_lab.region
}