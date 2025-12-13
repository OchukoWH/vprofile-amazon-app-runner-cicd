variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repo_db" {
  description = "ECR repository name for database image"
  type        = string
  default     = "vprofiledb"
}

variable "ecr_repo_app" {
  description = "ECR repository name for application image"
  type        = string
  default     = "vprofileapp"
}

variable "ecr_repo_web" {
  description = "ECR repository name for web/nginx image"
  type        = string
  default     = "vprofileweb"
}

