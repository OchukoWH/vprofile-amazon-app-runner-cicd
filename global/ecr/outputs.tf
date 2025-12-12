output "ecr_repository_db_url" {
  description = "URL of the ECR repository for database image"
  value       = module.ecr_db.repository_url
}

output "ecr_repository_app_url" {
  description = "URL of the ECR repository for application image"
  value       = module.ecr_app.repository_url
}

output "ecr_repository_web_url" {
  description = "URL of the ECR repository for web/nginx image"
  value       = module.ecr_web.repository_url
}

output "ecr_repository_db_arn" {
  description = "ARN of the ECR repository for database image"
  value       = module.ecr_db.repository_arn
}

output "ecr_repository_app_arn" {
  description = "ARN of the ECR repository for application image"
  value       = module.ecr_app.repository_arn
}

output "ecr_repository_web_arn" {
  description = "ARN of the ECR repository for web/nginx image"
  value       = module.ecr_web.repository_arn
}

output "ecr_repository_arns" {
  description = "List of all ECR repository ARNs"
  value = [
    module.ecr_db.repository_arn,
    module.ecr_app.repository_arn,
    module.ecr_web.repository_arn
  ]
}

