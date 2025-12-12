variable "region" {
  type        = string
  description = "AWS region to provision infrastructure."
}

variable "bucket" {
  type        = string
  description = "S3 bucket for terraform state."
}

variable "ecr_repo_db" {
  type        = string
  description = "ECR repository name for database image."
  default     = "vprofiledb"
}

variable "ecr_repo_app" {
  type        = string
  description = "ECR repository name for application image."
  default     = "vprofileapp"
}

variable "ecr_repo_web" {
  type        = string
  description = "ECR repository name for web/nginx image."
  default     = "vprofileweb"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)."
  default     = "prod"
}
