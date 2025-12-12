variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "vprofile"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type (use t2.medium or larger for Docker Compose)"
  type        = string
  default     = "t2.medium"
  
  validation {
    condition = can(regex("^(t2|t3|t3a)\\.(medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Instance type must be t2.medium or larger (t2.medium, t2.large, t3.medium, t3.large, etc.)"
  }
}

variable "ami_id" {
  description = "Custom AMI ID (leave empty to use latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
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

