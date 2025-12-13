# ==============================================================================
# VProfile AWS Infrastructure Makefile
# ==============================================================================

.PHONY: help init-s3 create-s3 deploy-s3 update-state-configs migrate-s3-backend deploy-ecr deploy-iam deploy-launch \
	deploy-infrastructure deploy-all destroy-ecr destroy-iam destroy-all \
	plan-ecr plan-iam plan-launch plan-all validate-ecr validate-iam validate-all \
	check-aws check-config info clean

# Variables
TFVARS := global.tfvars
STATE_CONFIG := state.config
S3_DIR := global/s3
ECR_DIR := global/ecr
IAM_DIR := global/iam
LAUNCH_DIR := launch

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
	@echo "  make migrate-s3-backend  - Migrate S3 backend state to S3 (after updating state.tf)"
	@echo "  make deploy-ecr          - Deploy ECR repositories"
	@echo "  make deploy-iam         - Deploy IAM roles and policies"
	@echo "  make launch              - Deploy EC2 instance with Docker Compose"


# ==============================================================================
# S3 Bucket Creation (Manual - Must be done first)
# ==============================================================================
init-s3:
	@echo "$(GREEN)Initializing S3 backend...$(NC)"
	@cd $(S3_DIR) && \
		terraform init \
			-input=false \
			-no-color

deploy-s3:
	@echo "$(GREEN)Deploying S3 backend...$(NC)"
	@cd $(S3_DIR) && \
		terraform init \
			-input=false \
			-no-color && \
		terraform plan \
			-input=false \
			-no-color \
			-compact-warnings \
			-var-file=../../$(TFVARS) \
			-out=tfplan && \
		terraform apply \
			-input=false \
			-auto-approve \
			tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ S3 backend deployed$(NC)"

migrate-s3-backend:
	@echo "$(GREEN)Migrating S3 backend state...$(NC)"
	@cd $(S3_DIR) && \
		echo "yes" | terraform init \
			-backend-config=../../$(STATE_CONFIG) \
			-migrate-state \
			-no-color
	@echo "$(GREEN)✓ S3 backend state migrated$(NC)"


# ==============================================================================
# Infrastructure Deployment
# ==============================================================================
deploy-ecr:
	@echo "$(GREEN)Deploying ECR repositories...$(NC)"
	@if [ -z "$$TF_VAR_bucket" ]; then \
		echo "$(RED)Error: TF_VAR_bucket not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_region" ]; then \
		echo "$(RED)Error: TF_VAR_region not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_ecr_repo_db" ]; then \
		echo "$(RED)Error: TF_VAR_ecr_repo_db not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_ecr_repo_app" ]; then \
		echo "$(RED)Error: TF_VAR_ecr_repo_app not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_ecr_repo_web" ]; then \
		echo "$(RED)Error: TF_VAR_ecr_repo_web not set$(NC)"; exit 1; fi
	@cd $(ECR_DIR) && \
		terraform init \
			-backend-config="bucket=$$TF_VAR_bucket" \
			-backend-config="region=$$TF_VAR_region" \
			-input=false \
			-no-color && \
		terraform plan \
			-input=false \
			-no-color \
			-compact-warnings \
			-out=tfplan && \
		terraform apply \
			-input=false \
			-auto-approve \
			tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ ECR repositories deployed successfully$(NC)"
	@echo "$(YELLOW)ECR Repositories created:$(NC)"
	@cd $(ECR_DIR) && terraform output -json | jq -r 'to_entries[] | "  - \(.key): \(.value.value)"' 2>/dev/null || echo "  Run 'cd $(ECR_DIR) && terraform output' to see repository URLs"

deploy-iam:
	@echo "$(GREEN)Deploying IAM roles and policies...$(NC)"
	@if [ -z "$$TF_VAR_bucket" ]; then \
		echo "$(RED)Error: TF_VAR_bucket not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_region" ]; then \
		echo "$(RED)Error: TF_VAR_region not set$(NC)"; exit 1; fi
	@cd $(IAM_DIR) && \
		terraform init \
			-backend-config="bucket=$$TF_VAR_bucket" \
			-backend-config="region=$$TF_VAR_region" \
			-input=false \
			-no-color && \
		terraform plan \
			-input=false \
			-no-color \
			-compact-warnings \
			-out=tfplan && \
		terraform apply \
			-input=false \
			-auto-approve \
			tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ IAM resources deployed successfully$(NC)"
	@echo "$(YELLOW)IAM Role ARN:$(NC)"
	@cd $(IAM_DIR) && terraform output -json | jq -r '.iam_role_arn.value' 2>/dev/null || echo "  Run 'cd $(IAM_DIR) && terraform output' to see role ARN"

# ==============================================================================
# Launch Module (EC2 Instance)
# ==============================================================================
init-launch:
	@echo "$(GREEN)Initializing launch module...$(NC)"
	@if [ -z "$$TF_VAR_bucket" ]; then \
		echo "$(RED)Error: TF_VAR_bucket not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_region" ]; then \
		echo "$(RED)Error: TF_VAR_region not set$(NC)"; exit 1; fi
	@cd $(LAUNCH_DIR) && \
		terraform init \
			-backend-config="bucket=$$TF_VAR_bucket" \
			-backend-config="region=$$TF_VAR_region" \
			-input=false \
			-no-color

deploy-launch:
	@echo "$(GREEN)Deploying EC2 instance...$(NC)"
	@if [ -z "$$TF_VAR_aws_region" ]; then \
		echo "$(RED)Error: TF_VAR_aws_region not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_bucket" ]; then \
		echo "$(RED)Error: TF_VAR_bucket not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_region" ]; then \
		echo "$(RED)Error: TF_VAR_region not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_ecr_repo_db" ]; then \
		echo "$(RED)Error: TF_VAR_ecr_repo_db not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_ecr_repo_app" ]; then \
		echo "$(RED)Error: TF_VAR_ecr_repo_app not set$(NC)"; exit 1; fi
	@if [ -z "$$TF_VAR_ecr_repo_web" ]; then \
		echo "$(RED)Error: TF_VAR_ecr_repo_web not set$(NC)"; exit 1; fi
	@cd $(LAUNCH_DIR) && \
		terraform init \
			-backend-config="bucket=$$TF_VAR_bucket" \
			-backend-config="region=$$TF_VAR_region" \
			-input=false \
			-no-color && \
		terraform plan \
			-input=false \
			-no-color \
			-compact-warnings \
			-var="aws_region=$$TF_VAR_aws_region" \
			-var="ecr_repo_db=$$TF_VAR_ecr_repo_db" \
			-var="ecr_repo_app=$$TF_VAR_ecr_repo_app" \
			-var="ecr_repo_web=$$TF_VAR_ecr_repo_web" \
			-out=tfplan && \
		terraform apply \
			-input=false \
			-auto-approve \
			tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ EC2 instance deployed successfully$(NC)"
	@echo "$(YELLOW)EC2 Instance Details:$(NC)"
	@cd $(LAUNCH_DIR) && terraform output -json | jq -r 'to_entries[] | "  - \(.key): \(.value.value)"' 2>/dev/null || echo "  Run 'cd $(LAUNCH_DIR) && terraform output' to see instance details"

launch: deploy-launch
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)EC2 instance deployment completed!$(NC)"
	@echo "$(GREEN)========================================$(NC)"

# ==============================================================================
# Default Target
# ==============================================================================
.DEFAULT_GOAL := help
