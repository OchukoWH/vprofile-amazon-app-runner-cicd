# VProfile - AWS CI/CD Pipeline

A complete CI/CD pipeline using GitHub Actions, Terraform, and AWS services. This repository automates infrastructure provisioning, Docker image builds, and application deployment to EC2 instances.

## 🎯 What This Repository Does

This CI/CD pipeline automates the following workflow:

1. **Infrastructure Provisioning** - Uses Terraform to create AWS resources (S3, ECR, IAM, EC2)
2. **Docker Image Builds** - Builds Docker images using self-hosted GitHub Actions runners
3. **Image Publishing** - Pushes images to Docker Hub
4. **Application Deployment** - Deploys containers to EC2 instances using Docker Compose

## 🏗️ Architecture Overview

```
GitHub Actions Workflows
    │
    ├─── Infrastructure (Terraform)
    │    ├─── S3 Bucket (Terraform State)
    │    ├─── ECR Repositories (Container Registry)
    │    ├─── IAM Roles (Permissions for github to push to ecr repos)
    │    └─── EC2 Instance (Application Host)
    │
    ├─── CI/CD Pipeline
    │    ├─── Self-Hosted Runner (Docker Builds)
    │    ├─── Docker Image Builds
    │    └─── Docker Hub Push
    │
    └─── Application Deployment
         └─── EC2 Instance runs Docker Compose
```

## 📋 Setup Instructions

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured locally
- GitHub repository
- EC2 instance for self-hosted runner (optional but recommended)

---

### Step 1: Create S3 Bucket for Terraform State

**Purpose:** Store Terraform state files remotely for team collaboration and state management.

```bash
# Set your AWS region and bucket name
export AWS_REGION="us-east-1"
export BUCKET_NAME="your-terraform-state-bucket-name"

# Create S3 bucket using Makefile
make init-s3 && make deploy-s3 && make migrate-s3-backend
```

**What happens:** Creates an S3 bucket with versioning and encryption enabled. This bucket stores Terraform state files for all infrastructure components.

---

### Step 2: Create ECR Repositories

**Purpose:** Amazon ECR repositories store Docker container images.

**How it works:** The GitHub Actions workflow `create-ecr.yml` automatically creates three ECR repositories:
- `vprofiledb` - Database container image
- `vprofileapp` - Application container image  
- `vprofileweb` - Web/NGINX container image

**Trigger:** Push to `state` or `main` branch, or manually trigger the workflow.

**What happens:** Terraform provisions ECR repositories with lifecycle policies (keeps last 30 images, expires untagged images after 1 day).

---

### Step 3: Create IAM Roles and Policies

**Purpose:** Grant GitHub Actions permission to push/pull images from ECR and manage AWS resources.

**How it works:** The GitHub Actions workflow `create-iam.yml` creates:
- IAM role for GitHub Actions
- OIDC provider for secure authentication (no long-lived credentials)
- Policies granting ECR read/write permissions

**Trigger:** Runs after ECR repositories are created, or push to `state`/`main` branch.

**What happens:** GitHub Actions can authenticate to AWS using OIDC and perform ECR operations without storing AWS access keys.

---

### Step 4: Launch EC2 Instance

**Purpose:** Provision EC2 instance that will run the application containers.

**How it works:** The GitHub Actions workflow `deploy-ec2.yml` uses Terraform to:
- Create EC2 instance (Ubuntu 22.04, t2.medium)
- Configure security group (ports 80, 22)
- Attach IAM role for ECR access
- Run user-data script to install Docker and start containers

**Trigger:** Runs after Docker images are built, or push to `state`/`main` branch.

**What happens:** EC2 instance is provisioned, Docker and Docker Compose are installed, images are pulled from Docker Hub, and containers are started automatically.

---

### Step 5: Self-Hosted Runner Setup

**Purpose:** Use your own EC2 instance to build Docker images instead of GitHub-hosted runners.

**Why Self-Hosted Runners:**
- More control over build environment
- No GitHub Actions minutes usage
- Custom hardware/software configurations
- Better for large Docker builds

**Setup Steps:**

1. **Provision EC2 Instance for Runner**
   - Launch an EC2 instance (Ubuntu recommended)
   - Ensure sufficient resources (CPU, RAM, disk space)

2. **Install Docker on Runner**
   ```bash
   # For Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y docker.io
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker $USER
   ```

3. **Install GitHub Actions Runner**
   - Go to your repository → **Settings** → **Actions** → **Runners**
   - Click **New self-hosted runner**
   - Follow the instructions to download and configure
   - Name the runner (e.g., `ochuko`)
   - Start the runner: `./run.sh` (or install as service)

4. **Configure Runner Labels**
   - The runner should have the label `self-hosted`
   - Additional labels can be added (e.g., `Linux`, `ochuko`)

**How It Works:**
- The `docker-image.yaml` workflow specifies `runs-on: self-hosted`
- When triggered, GitHub Actions dispatches the job to your runner
- The runner executes the workflow steps (checkout, build, push)
- Docker images are built on your runner and pushed to Docker Hub

**Workflow Flow:**
```
Push to main branch
    ↓
GitHub Actions triggers docker-image.yaml
    ↓
Job dispatched to self-hosted runner
    ↓
Runner checks out code
    ↓
Docker Buildx builds images
    ↓
Images pushed to Docker Hub
    ↓
EC2 deployment workflow triggered
```

---

## 🔧 Configuration

### GitHub Secrets

Add these in **Settings** → **Secrets and variables** → **Actions** → **Secrets**:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID |
| `AWS_ACCESS_KEY_SECRET` | AWS Secret Access Key |
| `EC2_PUBLIC_KEY` | SSH public key for EC2 access |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

### GitHub Variables

Add these in **Settings** → **Secrets and variables** → **Actions** → **Variables**:

| Variable | Description | Example |
|----------|-------------|---------|
| `TF_VAR_REGION` | AWS region | `us-east-1` |
| `TF_VAR_BUCKET` | S3 bucket name | `your-terraform-state-bucket-name` |
| `TF_VAR_ECR_REPO_DB` | ECR repo name for DB | `vprofiledb` |
| `TF_VAR_ECR_REPO_APP` | ECR repo name for app | `vprofileapp` |
| `TF_VAR_ECR_REPO_WEB` | ECR repo name for web | `vprofileweb` |
| `TF_VAR_GITHUB_REPO` | GitHub repo (owner/repo) | `username/repo-name` |

### Generate SSH Key Pair

```bash
./scripts/generate-keys.sh
```

Copy the public key (`vprofile-key.pub`) content to GitHub Secret `EC2_PUBLIC_KEY`.

---

## 🚀 Workflow Execution Order

The workflows run in this sequence:

1. **Create EC2 Key Pair** (`create-ec2-keypair.yml`)
   - Creates EC2 key pair in AWS
   - Trigger: Manual or push to `state`/`main`

2. **Create ECR Repositories** (`create-ecr.yml`)
   - Provisions ECR repositories with Terraform
   - Trigger: Push to `state`/`main` (when ECR files change)

3. **Create IAM Roles** (`create-iam.yml`)
   - Creates IAM role and OIDC provider
   - Trigger: After ECR creation or push to `state`/`main`

4. **Docker Image CI/CD** (`docker-image.yaml`)
   - Builds Docker images on self-hosted runner
   - Pushes images to Docker Hub
   - Trigger: Push to `main` branch

5. **Deploy EC2 Instance** (`deploy-ec2.yml`)
   - Provisions EC2 instance with Terraform
   - Installs Docker and starts containers
   - Trigger: After Docker images are built

---

## 📝 Accessing the Application

After the **Deploy EC2 Instance** workflow completes:

1. Check the workflow summary for the EC2 instance public IP
2. Visit `http://<ec2-public-ip>` in your browser
3. Login credentials:
   - **Username:** `admin_vp`
   - **Password:** `admin_vp`

---

## 🛠️ Local Development

### Using Makefile

```bash
# View all commands
make help

# Deploy infrastructure
make deploy-ecr    # Creates ECR repositories
make deploy-iam    # Creates IAM roles
make launch        # Deploys EC2 instance
```

**Required Environment Variables:**
```bash
export TF_VAR_region="us-east-1"
export TF_VAR_bucket="your-terraform-state-bucket-name"
export TF_VAR_ecr_repo_db="vprofiledb"
export TF_VAR_ecr_repo_app="vprofileapp"
export TF_VAR_ecr_repo_web="vprofileweb"
```

---

## 🔧 Troubleshooting

### Self-Hosted Runner Issues

**Runner not picking up jobs:**
- Verify runner is online: **Settings** → **Actions** → **Runners**
- Check runner has `self-hosted` label
- Review runner logs for errors

**Docker not found:**
- Verify Docker is installed: `docker --version`
- Check Docker service: `sudo systemctl status docker`
- Ensure user has Docker permissions: `sudo usermod -aG docker $USER`
- Restart runner after Docker installation

**Build failures:**
- Check disk space: `df -h`
- Verify Docker daemon: `docker ps`
- Check runner logs

### Infrastructure Issues

**ECR Login Failed:**
- Verify IAM role permissions on EC2 instance
- Check ECR repositories exist
- Review logs: `sudo cat /var/log/user-data.log` (on EC2)

**Containers Not Starting:**
- SSH into EC2: `ssh -i vprofile-key.pem ubuntu@<ec2-ip>`
- Check containers: `docker ps`
- View logs: `cd /opt/vprofile && docker-compose logs`

**Workflow Failures:**
- Verify all GitHub Secrets and Variables are set
- Check AWS credentials have necessary permissions
- Review workflow logs for specific errors
- Ensure self-hosted runner is online

---

## 📋 Quick Setup Checklist

- [ ] S3 bucket created (`make init-s3 && make deploy-s3`)
- [ ] Self-hosted runner provisioned and configured
- [ ] Docker installed on self-hosted runner
- [ ] GitHub Actions runner installed and running
- [ ] SSH key pair generated (`./scripts/generate-keys.sh`)
- [ ] GitHub Secrets configured (AWS + Docker Hub + EC2 key)
- [ ] GitHub Variables configured (region, bucket, ECR repos)
- [ ] Workflows triggered (push to `main` branch)
- [ ] Application accessible via EC2 public IP

---
**Tech Stack:** Docker, Docker Compose, AWS (EC2, ECR, S3, IAM), Terraform, GitHub Actions, Self-Hosted Runners

