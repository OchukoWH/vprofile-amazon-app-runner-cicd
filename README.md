# VProfile - AWS CI/CD Pipeline with Docker

A complete CI/CD pipeline that builds Docker images, pushes them to Amazon ECR, and deploys containers to EC2 instances.

## 🚀 Quick Setup

### Step 1: Create S3 Bucket for Terraform State

**⚠️ MUST BE DONE FIRST**

```bash
# Set your AWS region and bucket name
export AWS_REGION="us-east-1"
export BUCKET_NAME="your-terraform-state-bucket-name"

# Create S3 bucket using Makefile
make init-s3 && make deploy-s3 && make migrate-s3-backend
```
---

### Step 2: Generate SSH Key Pair

```bash
./scripts/generate-keys.sh
```

Copy the public key content (`vprofile-key.pub`) - you'll need it for GitHub Secrets.

---

### Step 3: Configure GitHub Secrets

Go to **Settings** → **Secrets and variables** → **Actions** → **Secrets**

| Secret Name | Description |
|------------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_ACCESS_KEY_SECRET` | Your AWS Secret Access Key |
| `EC2_PUBLIC_KEY` | Content of `vprofile-key.pub` file |

Run 
```sh
./scripts/generate-keys.sh 
```

---

### Step 4: Configure GitHub Variables

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

### Step 5: Run Workflows

Workflows run automatically on push to `state` or `main` branch, or trigger manually:

1. **Create EC2 Key Pair** - Creates EC2 key pair in AWS
2. **Create ECR Repositories** - Creates 3 ECR repositories
3. **Create IAM Roles** - Creates IAM role for GitHub Actions
4. **Docker Image CI/CD** - Builds and pushes Docker images to ECR
5. **Deploy EC2 Instance** - Provisions EC2 and deploys application

**Workflow Order:** Key Pair → ECR → IAM → Docker Images → EC2 Deployment

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

### ECR Login Failed
- Check IAM role permissions on EC2 instance
- Verify ECR repositories exist
- Check logs: `sudo cat /var/log/user-data.log` (on EC2)

### Images Not Found
- Verify images were pushed: `aws ecr describe-images --repository-name vprofiledb --region us-east-1`
- Check image tags match (`staging-latest` or `prod-latest`)

### Containers Not Starting
- SSH into EC2: `ssh -i vprofile-key.pem ubuntu@<ec2-ip>`
- Check containers: `docker ps`
- Check logs: `cd /opt/vprofile && docker-compose logs`

### Workflow Failures
- Verify all GitHub Secrets and Variables are set
- Check AWS credentials have necessary permissions
- Review workflow logs for specific errors

---

## 📋 Setup Checklist

- [ ] S3 bucket created (`make create-s3`)
- [ ] SSH key pair generated (`./scripts/generate-keys.sh`)
- [ ] GitHub Secrets added (AWS credentials + EC2 public key)
- [ ] GitHub Variables added (region, bucket, ECR repos)
- [ ] Workflows triggered (push to `state`/`main` branch)
- [ ] Application accessible via EC2 URL

---

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Nginx     │───►│   Tomcat    │───►│   MySQL     │
│   (Port 80) │    │  (Port 8080)│    │ (Port 3306) │
└─────────────┘    └─────────────┘    └─────────────┘
                            │
                            ▼
                   ┌─────────────┐    ┌─────────────┐
                   │  Memcached  │    │  RabbitMQ   │
                   │ (Port 11211)│    │ (Port 5672) │
                   └─────────────┘    └─────────────┘
```

---

## 🔐 Security Notes

- Never commit AWS credentials or private keys
- Use GitHub Secrets for sensitive data
- Rotate access keys regularly
- Enable ECR image scanning

---

**Tech Stack:** Docker, Docker Compose, AWS ECR, AWS EC2, Terraform, GitHub Actions
