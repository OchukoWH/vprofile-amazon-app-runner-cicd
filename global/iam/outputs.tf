output "iam_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = module.iam_role.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role for GitHub Actions"
  value       = module.iam_role.iam_role_name
}

output "iam_policy_arn" {
  description = "ARN of the IAM policy for ECR access"
  value       = module.iam_policy.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for GitHub Actions"
  value       = module.iam_oidc_provider.arn
}

