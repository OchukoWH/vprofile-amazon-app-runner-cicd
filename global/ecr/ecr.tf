# ECR Repository for Database Image
module "ecr_db" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.1.0"

  repository_name = var.ecr_repo_db

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus       = "tagged",
          tagPatternList  = ["v*", "latest"],
          countType       = "imageCountMoreThan", 
          countNumber     = 30
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged images older than 1 day",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_image_tag_mutability = "MUTABLE"

  tags = {
    Name        = var.ecr_repo_db
    Service     = "database"
  }
}

# ECR Repository for Application Image
module "ecr_app" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.1.0"

  repository_name = var.ecr_repo_app

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus       = "tagged",
          tagPatternList  = ["v*", "latest"],
          countType       = "imageCountMoreThan",
          countNumber     = 30
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged images older than 1 day",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_image_tag_mutability = "MUTABLE"

  tags = {
    Name        = var.ecr_repo_app
    Service     = "application"
  }
}

# ECR Repository for Web/NGINX Image
module "ecr_web" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.1.0"

  repository_name = var.ecr_repo_web

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus       = "tagged",
          tagPatternList  = ["v*", "latest"],
          countType       = "imageCountMoreThan",
          countNumber     = 30
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Expire untagged images older than 1 day",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_image_tag_mutability = "MUTABLE"

  tags = {
    Name        = var.ecr_repo_web
    Service     = "web"
  }
}
