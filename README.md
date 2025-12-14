# VProfile - AWS CI/CD Pipeline with Docker

A complete CI/CD pipeline that builds Docker images, pushes them to Amazon ECR, and deploys containers to EC2 instances. The pipeline uses GitHub Actions with a self-hosted runner for Docker image builds.

## 🚀 Quick Setup

### Step 1: Create S3 Bucket for Terraform State

**⚠️ MUST BE DONE FIRST**

```bash
# Set your AWS region and bucket name
export AWS_REGION="us-east-1"
export BUCKET_NAME="your-terraform-state-bucket-name"

# Create S3 bucket using Makefile
make init-s3 &&  make deploy-s3 && make migrate-s3-backend
```

### Step 2: Set Up Self-Hosted Runner

**Required for Docker Image CI/CD workflow**

The Docker image build workflow runs on a self-hosted EC2 runner. You need to:

1. **Provision an EC2 instance** (or use an existing one) for the runner
2. **Install Docker** on the runner:
   ```bash
   # For Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y docker.io
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -aG docker $USER
   ```

3. **Install GitHub Actions Runner**:
   - Go to your GitHub repository → **Settings** → **Actions** → **Runners**
   - Click **New self-hosted runner**
   - Follow the instructions to download and configure the runner
   - Name the runner (e.g., `ochuko`)

   ```

**Note:** The runner must have Docker installed and running. The workflow uses `docker/build-push-action` which requires Docker to be available.

---

### Step 3: Generate SSH Key Pair

```bash
./scripts/generate-keys.sh
```

Copy the public key content (`vprofile-key.pub`) - you'll need it for GitHub Secrets.

---

### Step 4: Configure GitHub Secrets

Go to **Settings** → **Secrets and variables** → **Actions** → **Secrets**

| Secret Name | Description |
|------------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_ACCESS_KEY_SECRET` | Your AWS Secret Access Key |
| `EC2_PUBLIC_KEY` | Content of `vprofile-key.pub` file |
| `DOCKERHUB_USERNAME` | Docker Hub username (for pushing images) |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

---

### Step 5: Configure GitHub Variables

Go to **Settings** → **Secrets and variables** → **Actions** → **Variables**

| Variable Name | Description | Example |
|--------------|-------------|---------|
| `TF_VAR_REGION` | AWS region | `us-east-1` |
| `TF_VAR_BUCKET` | S3 bucket name (from Step 1) | `your-terraform-state-bucket-name` |
| `TF_VAR_ECR_REPO_DB` | ECR repo for database | `vprofiledb` |
| `TF_VAR_ECR_REPO_APP` | ECR repo for application | `vprofileapp` |
| `TF_VAR_ECR_REPO_WEB` | ECR repo for web/nginx | `vprofileweb` |
| `TF_VAR_GITHUB_REPO` | GitHub repo (format: owner/repo) | `your-username/vprofile-amazon-app-runner-cicd` |

---

### Step 6: Run Workflows

Workflows run automatically on push to `state` or `main` branch, or trigger manually:

1. **Create EC2 Key Pair** - Creates EC2 key pair in AWS
2. **Create ECR Repositories** - Creates 3 ECR repositories
3. **Create IAM Roles** - Creates IAM role for GitHub Actions
4. **Docker Image CI/CD** - Builds and pushes Docker images to Docker Hub (runs on self-hosted runner)
5. **Deploy EC2 Instance** - Provisions EC2 and deploys application

**Workflow Order:** Key Pair → ECR → IAM → Docker Images → EC2 Deployment

**Self-Hosted Runner:** The Docker Image CI/CD workflow runs on your self-hosted runner (`ochuko`). Ensure the runner is online and Docker is installed before triggering the workflow.

---

## 📝 Access Your Application

After the **Deploy EC2 Instance** workflow completes:

1. Check the workflow summary for the EC2 instance URL
2. Visit the URL shown in the action summary
3. Login credentials:
   - **Username:** `admin_vp`
   - **Password:** `admin_vp`

---

## 🛠️ Local Development

### Using Makefile

```bash
# View available commands
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
- Verify runner is online: Check **Settings** → **Actions** → **Runners**
- Ensure runner has correct labels: `self-hosted`
- Check runner logs for errors

**Docker not found on runner:**
- Verify Docker is installed: `docker --version`
- Check Docker service is running: `sudo systemctl status docker`
- Ensure runner user has Docker permissions: `sudo usermod -aG docker $USER`
- Restart runner after Docker installation

**Build failures on runner:**
- Check runner has sufficient disk space: `df -h`
- Verify Docker daemon is accessible: `docker ps`
- Check runner logs: `./run.sh` (if running manually)

### ECR Login Failed
- Check IAM role permissions on EC2 instance
- Verify ECR repositories exist
- Check logs: `sudo cat /var/log/user-data.log` (on EC2)

### Containers Not Starting
- SSH into EC2: `ssh -i vprofile-key.pem ubuntu@<ec2-ip>`
- Check containers: `docker ps`
- Check logs: `cd /opt/vprofile && docker-compose logs`

### Workflow Failures
- Verify all GitHub Secrets and Variables are set
- Check AWS credentials have necessary permissions
- Review workflow logs for specific errors
- Ensure self-hosted runner is online and Docker is installed

---

**CI/CD Pipeline:**
- GitHub Actions workflows orchestrate infrastructure provisioning
- Self-hosted EC2 runner builds Docker images
- Images pushed to Docker Hub
- EC2 instance pulls images and runs containers

---

**Tech Stack:** Docker, Docker Compose, AWS ECR, AWS EC2, Terraform, GitHub Actions, Self-Hosted Runners
