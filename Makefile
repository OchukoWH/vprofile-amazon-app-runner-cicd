# ==============================================================================
# VProfile AWS Infrastructure Makefile
# ==============================================================================

.PHONY: help init-s3 create-s3 deploy-s3 update-state-configs migrate-s3-backend deploy-ecr deploy-iam \
	deploy-infrastructure deploy-all destroy-ecr destroy-iam destroy-all \
	plan-ecr plan-iam plan-all validate-ecr validate-iam validate-all \
	check-aws check-config info clean

# Variables
TFVARS := global.tfvars
STATE_CONFIG := state.config
S3_DIR := global/s3
ECR_DIR := global/ecr
IAM_DIR := global/iam

# Parse state.config file
REGION := $(shell grep '^region' $(STATE_CONFIG) | cut -d'"' -f2)
BUCKET := $(shell grep '^bucket' $(STATE_CONFIG) | cut -d'"' -f2)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# ==============================================================================
# Help Target
# ==============================================================================
help:
	@echo "$(GREEN)VProfile AWS Infrastructure Deployment$(NC)"
	@echo ""
	@echo "$(YELLOW)Infrastructure Targets:$(NC)"
	@echo "  make init-s3             - Initialize S3 backend (first time only)"
	@echo "  make deploy-s3           - Deploy S3 backend"
	@echo "  make update-state-configs - Update state.tf files with bucket/region"
	@echo "  make migrate-s3-backend  - Migrate S3 backend state to S3 (after updating state.tf)"
	@echo "  make deploy-ecr          - Deploy ECR repositories"
	@echo "  make deploy-iam         - Deploy IAM roles and policies"
	@echo "  make deploy-infrastructure - Deploy ECR and IAM sequentially"
	@echo "  make deploy-all          - Deploy all infrastructure"
	@echo ""
	@echo "$(YELLOW)Planning Targets:$(NC)"
	@echo "  make plan-ecr            - Plan ECR deployment"
	@echo "  make plan-iam            - Plan IAM deployment"
	@echo "  make plan-all            - Plan all deployments"
	@echo ""
	@echo "$(YELLOW)Validation Targets:$(NC)"
	@echo "  make validate-ecr       - Validate ECR Terraform files"
	@echo "  make validate-iam       - Validate IAM Terraform files"
	@echo "  make validate-all       - Validate all Terraform files"
	@echo ""
	@echo "$(YELLOW)Destruction Targets:$(NC)"
	@echo "  make destroy-ecr        - Destroy ECR repositories"
	@echo "  make destroy-iam        - Destroy IAM resources"
	@echo "  make destroy-all        - Destroy all infrastructure"
	@echo ""
	@echo "$(YELLOW)Utility Targets:$(NC)"
	@echo "  make check-aws          - Check AWS CLI configuration"
	@echo "  make check-config       - Check configuration files"
	@echo "  make info               - Show current configuration"
	@echo "  make clean              - Clean Terraform plan files"

# ==============================================================================
# S3 Bucket Creation (Manual - Must be done first)
# ==============================================================================
create-s3:
	@echo "$(GREEN)Creating S3 bucket for Terraform state...$(NC)"
	@if [ -z "$(BUCKET)" ]; then \
		echo "$(RED)Error: bucket variable not set in $(STATE_CONFIG)$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(REGION)" ]; then \
		echo "$(RED)Error: region variable not set in $(STATE_CONFIG)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Checking if bucket exists...$(NC)"
	@if aws s3api head-bucket --bucket $(BUCKET) 2>/dev/null; then \
		echo "$(GREEN)✓ Bucket $(BUCKET) already exists, skipping creation$(NC)"; \
		exit 0; \
	fi
	@echo "$(YELLOW)Creating bucket: $(BUCKET) in region: $(REGION)$(NC)"
	@if [ "$(REGION)" = "us-east-1" ]; then \
		aws s3api create-bucket --bucket $(BUCKET) --region $(REGION); \
	else \
		aws s3api create-bucket --bucket $(BUCKET) --region $(REGION) --create-bucket-configuration LocationConstraint=$(REGION); \
	fi
	@echo "$(GREEN)Enabling versioning...$(NC)"
	@aws s3api put-bucket-versioning --bucket $(BUCKET) --versioning-configuration Status=Enabled
	@echo "$(GREEN)Enabling encryption...$(NC)"
	@aws s3api put-bucket-encryption --bucket $(BUCKET) --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
	@echo "$(GREEN)Blocking public access...$(NC)"
	@aws s3api put-public-access-block --bucket $(BUCKET) --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
	@echo "$(GREEN)✓ S3 bucket created successfully!$(NC)"
	@echo "$(YELLOW)Bucket: $(BUCKET)$(NC)"
	@echo "$(YELLOW)Region: $(REGION)$(NC)"

init-s3:
	@echo "$(GREEN)Initializing S3 backend...$(NC)"
	@cd $(S3_DIR) && terraform init

deploy-s3:
	@echo "$(GREEN)Deploying S3 backend...$(NC)"
	@cd $(S3_DIR) && \
		terraform init && \
		terraform plan -compact-warnings -var-file=../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ S3 backend deployed$(NC)"
	@echo "$(BLUE)2. Then run:$(NC)"
	@echo "   make migrate-s3-backend"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

update-state-configs:
	@echo "$(GREEN)Updating state.tf files with bucket and region...$(NC)"
	@if [ -z "$(BUCKET)" ]; then \
		echo "$(RED)Error: bucket variable not set in $(STATE_CONFIG)$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(REGION)" ]; then \
		echo "$(RED)Error: region variable not set in $(STATE_CONFIG)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Updating $(S3_DIR)/state.tf...$(NC)"
	@printf 'terraform {\n  backend "s3" {\n    region = "%s"\n    bucket = "%s"\n    key    = "global/s3/terraform.tfstate"\n    encrypt = true\n  }\n}\n' "$(REGION)" "$(BUCKET)" > $(S3_DIR)/state.tf
	@echo "$(YELLOW)You can now run: make migrate-s3-backend$(NC)"

migrate-s3-backend:
	@echo "$(GREEN)Migrating S3 backend state...$(NC)"
	@cd $(S3_DIR) && \
		echo "yes" | terraform init -migrate-state -backend-config=../../$(STATE_CONFIG)
	@echo "$(GREEN)✓ S3 backend state migrated$(NC)"


# ==============================================================================
# Infrastructure Deployment
# ==============================================================================
deploy-ecr:
	@echo "$(GREEN)Deploying ECR repositories...$(NC)"
	@cd $(ECR_DIR) && \
		terraform init -backend-config=../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ ECR repositories deployed successfully$(NC)"
	@echo "$(YELLOW)ECR Repositories created:$(NC)"
	@cd $(ECR_DIR) && terraform output -json | jq -r 'to_entries[] | "  - \(.key): \(.value.value)"' 2>/dev/null || echo "  Run 'cd $(ECR_DIR) && terraform output' to see repository URLs"

deploy-iam:
	@echo "$(GREEN)Deploying IAM roles and policies...$(NC)"
	@cd $(IAM_DIR) && \
		terraform init -backend-config=../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../$(TFVARS) -out=tfplan && \
		terraform apply -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ IAM resources deployed successfully$(NC)"
	@echo "$(YELLOW)IAM Role ARN:$(NC)"
	@cd $(IAM_DIR) && terraform output -json | jq -r '.iam_role_arn.value' 2>/dev/null || echo "  Run 'cd $(IAM_DIR) && terraform output' to see role ARN"

deploy-infrastructure: deploy-ecr deploy-iam
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Infrastructure deployment completed!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

deploy-all: create-s3 deploy-s3 migrate-s3-backend deploy-infrastructure
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Complete deployment finished!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Note: Make sure to uncomment state.tf files before running migrate-s3-backend$(NC)"

# ==============================================================================
# Planning Targets
# ==============================================================================
plan-ecr:
	@cd $(ECR_DIR) && \
		terraform init -backend-config=../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../$(TFVARS)

plan-iam:
	@cd $(IAM_DIR) && \
		terraform init -backend-config=../../$(STATE_CONFIG) && \
		terraform plan -compact-warnings -var-file=../../$(TFVARS)

plan-all: plan-ecr plan-iam
	@echo "$(GREEN)Planning completed$(NC)"

# ==============================================================================
# Validation Targets
# ==============================================================================
validate-ecr:
	@echo "$(GREEN)Validating ECR Terraform files...$(NC)"
	@cd $(ECR_DIR) && terraform validate

validate-iam:
	@echo "$(GREEN)Validating IAM Terraform files...$(NC)"
	@cd $(IAM_DIR) && terraform validate

validate-all: validate-ecr validate-iam
	@echo "$(GREEN)✓ All Terraform files validated$(NC)"

# ==============================================================================
# Destruction Targets
# ==============================================================================
destroy-ecr:
	@echo "$(RED)Destroying ECR repositories...$(NC)"
	@cd $(ECR_DIR) && \
		terraform init -backend-config=../../$(STATE_CONFIG) && \
		terraform destroy -compact-warnings -var-file=../../$(TFVARS) -auto-approve
	@echo "$(GREEN)✓ ECR repositories destroyed$(NC)"

destroy-iam:
	@echo "$(RED)Destroying IAM resources...$(NC)"
	@cd $(IAM_DIR) && \
		terraform init -backend-config=../../$(STATE_CONFIG) && \
		terraform destroy -compact-warnings -var-file=../../$(TFVARS) -auto-approve
	@echo "$(GREEN)✓ IAM resources destroyed$(NC)"

destroy-all: destroy-iam destroy-ecr
	@echo "$(GREEN)All infrastructure destroyed$(NC)"
	@echo "$(YELLOW)Note: S3 bucket must be destroyed manually if needed$(NC)"

# ==============================================================================
# Utility Targets
# ==============================================================================
check-aws:
	@echo "$(GREEN)Checking AWS CLI configuration...$(NC)"
	@aws sts get-caller-identity || (echo "$(RED)Error: AWS CLI not configured or credentials invalid$(NC)" && exit 1)
	@echo "$(GREEN)✓ AWS CLI configured correctly$(NC)"

check-config:
	@echo "$(GREEN)Checking configuration files...$(NC)"
	@if [ ! -f "$(TFVARS)" ]; then \
		echo "$(RED)Error: $(TFVARS) not found$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(STATE_CONFIG)" ]; then \
		echo "$(RED)Error: $(STATE_CONFIG) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Configuration files found$(NC)"

info:
	@echo "$(GREEN)Current Configuration:$(NC)"
	@echo "$(YELLOW)Region:$(NC) $(REGION)"
	@echo "$(YELLOW)Bucket:$(NC) $(BUCKET)"
	@echo "$(YELLOW)Terraform Variables:$(NC) $(TFVARS)"
	@echo "$(YELLOW)State Config:$(NC) $(STATE_CONFIG)"
	@echo ""
	@echo "$(GREEN)AWS Account Info:$(NC)"
	@aws sts get-caller-identity 2>/dev/null || echo "$(RED)AWS CLI not configured$(NC)"

clean:
	@echo "$(YELLOW)Cleaning Terraform plan files...$(NC)"
	@find . -name "tfplan" -type f -delete
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -type f -delete
	@echo "$(GREEN)✓ Cleaned$(NC)"

# ==============================================================================
# Default Target
# ==============================================================================
.DEFAULT_GOAL := help
