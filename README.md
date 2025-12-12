# VProfile - Docker Containerized Application with AWS CI/CD Pipeline

A comprehensive demonstration of Docker containerization expertise, featuring a multi-tier Java web application with microservices architecture. This project includes a complete CI/CD pipeline that builds Docker images, pushes them to Amazon ECR, and deploys containers using Amazon App Runner.

## 🐳 Docker Expertise Showcase

This project demonstrates advanced Docker concepts including:
- **Multi-container orchestration** with Docker Compose
- **Multi-stage builds** for optimized images
- **Custom Dockerfile optimizations** for production readiness
- **Service discovery** and inter-container communication
- **Persistent data management** with Docker volumes
- **Load balancing** with Nginx reverse proxy
- **Database containerization** with initialization scripts

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx Proxy   │    │   Tomcat App    │    │   MySQL DB      │
│   (Port 80)     │◄──►│   (Port 8080)   │◄──►│   (Port 3306)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Memcached     │    │   RabbitMQ      │
                       │   (Port 11211)  │    │   (Port 5672)   │
                       └─────────────────┘    └─────────────────┘
```

## 🎯 Why Multiple Technology Stack?

This project demonstrates a **production-ready microservices architecture** using specialized tools for specific purposes:

### **🔐 Nginx (Reverse Proxy)**
- **Purpose**: Load balancing, SSL termination, static file serving
- **Benefits**: High performance, low resource usage, security layer
- **Why not just Tomcat**: Nginx handles concurrent connections better, provides caching, and acts as a security buffer

### **🗄️ MySQL Database**
- **Purpose**: Primary data persistence, ACID transactions
- **Benefits**: Reliable, mature, excellent for structured data
- **Why MySQL**: Proven reliability, excellent performance for relational data, strong community support

### **⚡ Memcached (Caching Layer)**
- **Purpose**: Session storage, query result caching, performance optimization
- **Benefits**: Reduces database load, faster response times, horizontal scaling
- **Why not just database**: In-memory caching is 100x faster than disk-based queries, reduces database bottlenecks

### **📨 RabbitMQ (Message Queue)**
- **Purpose**: Asynchronous processing, service decoupling, reliable message delivery
- **Benefits**: Handles traffic spikes, enables microservices communication, fault tolerance
- **Why not synchronous calls**: Prevents system overload, enables background processing, improves user experience

### **🏗️ Architecture Benefits:**
- **Scalability**: Each component can scale independently
- **Reliability**: Failure in one service doesn't bring down the entire system
- **Performance**: Each tool optimized for its specific use case
- **Maintainability**: Clear separation of concerns
- **Flexibility**: Easy to replace or upgrade individual components

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

### Running the Application

1. **Clone the repository**
   ```bash
   git clone https://github.com/CK-codemax/vprofile-docker.git
   cd vprofile-docker
   ```

2. **Build and start all services**
   ```bash
   docker-compose up --build
   ```

3. **Access the application**
   - **Web Application**: http://localhost:80 or http://0.0.0.0:80 (default port: **80**)
   - **Tomcat Direct**: http://localhost:8080 (default port: **8080**)
   - **Database**: localhost:3306
   - **Memcached**: localhost:11211
   - **RabbitMQ**: localhost:5672

4. **Login to the application**
   - **Username**: `admin_vp`
   - **Password**: `admin_vp`
   - **(Webapp default login)**

## 🚀 CI/CD Pipeline Quick Start

To set up the CI/CD pipeline for AWS ECR and App Runner:

1. **Create S3 Bucket for Terraform State** (MUST BE DONE FIRST)
   ```bash
   export AWS_REGION="us-east-1"
   export BUCKET_NAME="your-terraform-state-bucket-name"
   
   aws s3api create-bucket \
     --bucket $BUCKET_NAME \
     --region $AWS_REGION \
     --create-bucket-configuration LocationConstraint=$AWS_REGION
   
   aws s3api put-bucket-versioning \
     --bucket $BUCKET_NAME \
     --versioning-configuration Status=Enabled
   
   aws s3api put-bucket-encryption \
     --bucket $BUCKET_NAME \
     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
   ```

2. **Configure AWS Credentials**
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key-id"
   export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
   export AWS_REGION="us-east-1"  # or your preferred region
   ```

3. **Provision Infrastructure with Terraform**
   ```bash
   cd global/ecr
   terraform init
   terraform apply -var-file=../../global.tfvars
   ```

4. **Configure CI/CD Environment**
   - For GitHub Actions: Add AWS credentials as repository secrets
   - See the [CI/CD Pipeline](#-cicd-pipeline-with-aws-ecr-and-app-runner) section for detailed instructions

For complete setup instructions, see the [CI/CD Pipeline](#-cicd-pipeline-with-aws-ecr-and-app-runner) section below.

## 🐳 Docker Implementation Details

### Container Architecture

#### 1. **Web Tier (Nginx)**
- **Image**: `nginx:latest`
- **Purpose**: Reverse proxy and load balancer
- **Configuration**: Custom nginx config for service discovery
- **Port**: 80 (HTTP)

#### 2. **Application Tier (Tomcat)**
- **Base Image**: `tomcat:10-jdk21`
- **Java Version**: JDK 21
- **Application**: Spring MVC web application
- **Port**: 8080
- **Volume**: Persistent webapps directory

#### 3. **Database Tier (MySQL)**
- **Image**: `mysql:8.0.33`
- **Database**: accounts
- **Initialization**: Automatic schema import
- **Port**: 3306
- **Volume**: Persistent data storage

#### 4. **Caching Tier (Memcached)**
- **Image**: `memcached:latest`
- **Purpose**: Session caching and performance optimization
- **Port**: 11211

#### 5. **Message Queue (RabbitMQ)**
- **Image**: `rabbitmq:latest`
- **Purpose**: Asynchronous message processing
- **Port**: 5672

### Dockerfile Optimizations

#### Application Container
```dockerfile
FROM tomcat:10-jdk21
LABEL "Project"="Vprofile"
LABEL "Author"="Imran"

# Clean default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy application artifact
COPY target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

# Expose port and set working directory
EXPOSE 8080
WORKDIR /usr/local/tomcat/
VOLUME /usr/local/tomcat/webapps

# Start Tomcat
CMD ["catalina.sh", "run"]
```

#### Multi-Stage Build Option
```dockerfile
# Build stage
FROM maven:3.9.9-eclipse-temurin-21-jammy AS BUILD_IMAGE
RUN git clone https://github.com/hkhcoder/vprofile-project.git
RUN cd vprofile-project && git checkout docker && mvn install

# Runtime stage
FROM tomcat:10-jdk21
COPY --from=BUILD_IMAGE vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
```

### Docker Compose Features

- **Service Discovery**: Containers communicate via service names
- **Volume Management**: Persistent data for database and application
- **Environment Variables**: Secure configuration management
- **Network Isolation**: Automatic bridge network creation
- **Health Checks**: Built-in container health monitoring

## 🛠️ Development Workflow

### Building Individual Services
```bash
# Build application container
docker build -f Docker-files/app/Dockerfile -t vprofile-app .

# Build database container
docker build -f Docker-files/db/Dockerfile -t vprofile-db ./Docker-files/db

# Build web proxy
docker build -f Docker-files/web/Dockerfile -t vprofile-web ./Docker-files/web
```

### Development Commands
```bash
# Start services in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild specific service
docker-compose up --build vproapp

# Access container shell
docker exec -it vproapp /bin/bash
```

## 📊 Application Stack

### Backend Technologies
- **Java 17** with Spring Framework 6.0.11
- **Spring Security** 6.1.2 for authentication
- **Spring Data JPA** 3.1.2 for data persistence
- **Hibernate** 7.0.0 for ORM
- **MySQL 8.0.33** for database
- **Memcached** for caching
- **RabbitMQ** for message queuing

### Frontend Technologies
- **JSP** for server-side rendering
- **Bootstrap** for responsive UI
- **jQuery** for client-side interactions
- **Font Awesome** for icons

### Infrastructure
- **Tomcat 10** as application server
- **Nginx** as reverse proxy
- **Docker** for containerization
- **Docker Compose** for orchestration

## 🔧 Configuration

### Environment Variables
```yaml
# Database
MYSQL_ROOT_PASSWORD: vprodbpass
MYSQL_DATABASE: accounts

# RabbitMQ
RABBITMQ_DEFAULT_USER: guest
RABBITMQ_DEFAULT_PASS: guest
```

### Application Properties
- Database connection: `jdbc:mysql://vprodb:3306/accounts`
- Memcached: `vprocache01:11211`
- RabbitMQ: `vpromq01:5672`

## 📈 Performance Optimizations

1. **Multi-stage builds** reduce final image size
2. **Layer caching** for faster builds
3. **Volume mounting** for persistent data
4. **Service discovery** for container communication
5. **Load balancing** with Nginx
6. **Caching layer** with Memcached

## 🧪 Testing

### Container Health Checks
```bash
# Check all containers are running
docker-compose ps

# Test application connectivity
curl http://localhost

# Test database connection
docker exec vprodb mysql -u root -pvprodbpass -e "SHOW DATABASES;"
```

### Application Testing
```bash
# Test login functionality
curl -X POST http://localhost/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin_vp&password=admin_vp"

# Access application with credentials
# Webapp login username: admin_vp
# Webapp login password: admin_vp
```

## 🚀 Production Deployment

### Scaling
```bash
# Scale application instances
docker-compose up --scale vproapp=3

# Scale with load balancer
docker-compose up --scale vproapp=3 --scale vproweb=2
```

### Monitoring
```bash
# Resource usage
docker stats

# Container logs
docker-compose logs -f vproapp
```

## 🔄 CI/CD Pipeline with AWS ECR and App Runner

This project implements a complete CI/CD pipeline that automatically builds Docker images, pushes them to Amazon Elastic Container Registry (ECR), and deploys containers using Amazon App Runner.

### Pipeline Overview

The CI/CD pipeline performs the following steps:

1. **Create S3 Bucket** - Create S3 bucket for Terraform state storage (must be done first)
2. **Provision Infrastructure** - Use Terraform to create ECR repositories and IAM roles
3. **Build Docker Images** - Builds all three container images (Database, Application, Web)
4. **Push to ECR** - Pushes images to Amazon ECR repositories
5. **Deploy to App Runner** - Automatically deploys and runs containers using Amazon App Runner

### Prerequisites

Before setting up the CI/CD pipeline, ensure you have:

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform installed (version >= 1.0)
- Docker installed locally (for testing)
- GitHub repository (if using GitHub Actions)

### Step 1: Create S3 Bucket for Terraform State

**⚠️ IMPORTANT: This must be done FIRST before running any Terraform commands.**

The S3 bucket is required to store Terraform state files. You can create it manually or use the Makefile.

#### Option A: Using Makefile (Recommended)

```bash
# Create S3 bucket with all security settings
make create-s3
```

#### Option B: Manual AWS CLI Commands

Create it manually from the command line:

```bash
# Set your AWS region
export AWS_REGION="us-east-1"  # Change to your preferred region

# Set your bucket name (must be globally unique)
export BUCKET_NAME="your-terraform-state-bucket-name"

# Create the S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Enable versioning (recommended for state files)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access (security best practice)
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Verify bucket creation
aws s3 ls | grep $BUCKET_NAME
```

**Note for us-east-1 region:**
If you're using `us-east-1`, omit the `--create-bucket-configuration` parameter:

```bash
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region us-east-1
```

**Update Terraform Backend Configuration:**

After creating the bucket, update the `state.tf` files in each module (`global/s3/state.tf`, `global/ecr/state.tf`, `global/iam/state.tf`) with your bucket name:

```hcl
terraform {
  backend "s3" {
    region       = "us-east-1"  # Your AWS region
    bucket       = "your-terraform-state-bucket-name"  # Your bucket name
    key          = "global/ecr/terraform.tfstate"  # Path for this module
    use_lockfile = true
    encrypt      = true
  }
}
```

**Optional: Create DynamoDB Table for State Locking**

For production environments, create a DynamoDB table for state locking:

```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

# Verify table creation
aws dynamodb describe-table --table-name terraform-state-lock --region $AWS_REGION
```

Then add the DynamoDB table to your Terraform backend configuration:

```hcl
terraform {
  backend "s3" {
    region         = "us-east-1"
    bucket         = "your-terraform-state-bucket-name"
    key            = "global/ecr/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"  # Add this line
    use_lockfile   = true
    encrypt        = true
  }
}
```

### Step 2: Environment Configuration

#### 1. AWS Credentials Setup

You need to configure your AWS credentials to authenticate with AWS services. You can do this in several ways:

##### Option A: AWS CLI Configuration (Recommended for Local Development)

```bash
# Configure AWS CLI
aws configure

# You'll be prompted to enter:
# - AWS Access Key ID: Your AWS access key
# - AWS Secret Access Key: Your AWS secret access key
# - Default region name: e.g., us-east-1, us-west-2, eu-west-1
# - Default output format: json (recommended)
```

##### Option B: Environment Variables

Set the following environment variables in your system or CI/CD environment:

```bash
# AWS Credentials
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"  # or your preferred region
```

##### Option C: GitHub Secrets (For GitHub Actions)

If using GitHub Actions, configure the following secrets in your repository:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID
   - `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key
   - `AWS_REGION`: Your AWS region (e.g., `us-east-1`, `us-west-2`, `eu-west-1`)

#### 2. Required Environment Variables

Configure the following environment variables for the CI/CD pipeline:

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region for ECR and App Runner | `us-east-1` |
| `AWS_ACCOUNT_ID` | Your AWS Account ID (optional, can be auto-detected) | `123456789012` |
| `ECR_REPOSITORY_PREFIX` | Prefix for ECR repository names (optional) | `vprofile` |

#### 3. AWS Region Configuration

Choose an AWS region that supports both ECR and App Runner. Common regions include:

- `us-east-1` (N. Virginia)
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-southeast-1` (Singapore)

Set your region using one of these methods:

```bash
# Using AWS CLI
aws configure set region us-east-1

# Using environment variable
export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1
```

### Step 3: Provision Infrastructure with Terraform

After creating the S3 bucket, use Terraform to provision ECR repositories and IAM roles.

#### Option A: Using Makefile (Recommended)

The project includes a Makefile that automates the deployment process:

```bash
# View all available commands
make help

# Deploy all infrastructure in order (S3 -> ECR -> IAM)
make deploy-all

# Or deploy individually:
make deploy-ecr    # Deploy ECR repositories
make deploy-iam    # Deploy IAM roles and policies
```

**Makefile Features:**
- Automatically reads configuration from `state.config` and `global.tfvars`
- Handles Terraform initialization with correct backend configuration
- Provides colored output for better visibility
- Includes validation, planning, and destruction targets

#### Option B: Manual Terraform Commands

If you prefer to run Terraform manually:

```bash
# Navigate to the global directory
cd global

# Deploy ECR repositories
cd ecr
terraform init -backend-config="bucket=your-bucket-name" -backend-config="region=us-east-1"
terraform plan -var-file=../../global.tfvars
terraform apply -var-file=../../global.tfvars

# Deploy IAM resources
cd ../iam
terraform init -backend-config="bucket=your-bucket-name" -backend-config="region=us-east-1"
terraform plan -var-file=../../global.tfvars
terraform apply -var-file=../../global.tfvars
```

This will create:
- **3 ECR Repositories**: `vprofiledb`, `vprofileapp`, `vprofileweb`
- **IAM Role**: For GitHub Actions to push/pull images
- **OIDC Provider**: For secure GitHub Actions authentication

### Step 4: ECR Repository Setup (Alternative Manual Method)

If you prefer to create ECR repositories manually instead of using Terraform:

```bash
# Set your AWS region
export AWS_REGION=us-east-1

# Create ECR repositories
aws ecr create-repository --repository-name vprofiledb --region $AWS_REGION
aws ecr create-repository --repository-name vprofileapp --region $AWS_REGION
aws ecr create-repository --repository-name vprofileweb --region $AWS_REGION
```

Or create them via AWS Console:
1. Navigate to **Amazon ECR** in AWS Console
2. Click **Create repository**
3. Create repositories: `vprofiledb`, `vprofileapp`, `vprofileweb`
4. Note the repository URIs (format: `{account-id}.dkr.ecr.{region}.amazonaws.com/{repo-name}`)

### App Runner Configuration

Configure Amazon App Runner to deploy your containers:

1. **Create App Runner Service** via AWS Console or CLI
2. **Source Configuration**: Point to your ECR repositories
3. **Build Configuration**: Use the Dockerfile from this repository
4. **Service Configuration**: Configure port mappings, environment variables, and scaling

Example App Runner service configuration:
- **Port**: `80` (for web service) or `8080` (for app service)
- **Auto-deploy**: Enable automatic deployments on image push
- **Health check**: Configure health check endpoints

### CI/CD Workflow

The pipeline workflow typically includes:

1. **Checkout Code** - Pulls the latest code from repository
2. **Configure AWS Credentials** - Authenticates with AWS using provided credentials
3. **Login to ECR** - Authenticates Docker with Amazon ECR
4. **Build Docker Images** - Builds all three images:
   - `vprofiledb` (Database image)
   - `vprofileapp` (Application image)
   - `vprofileweb` (Web/NGINX image)
5. **Tag Images** - Tags images with ECR repository URIs
6. **Push to ECR** - Pushes images to respective ECR repositories
7. **Deploy to App Runner** - Triggers App Runner deployment (if configured)

### Manual Deployment Steps

If you want to manually build and push images:

```bash
# Set your variables
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push database image
docker build -f Docker-files/db/Dockerfile -t $ECR_REGISTRY/vprofiledb:latest ./Docker-files/db
docker push $ECR_REGISTRY/vprofiledb:latest

# Build and push application image
docker build -f Docker-files/app/multistage/Dockerfile -t $ECR_REGISTRY/vprofileapp:latest .
docker push $ECR_REGISTRY/vprofileapp:latest

# Build and push web image
docker build -f Docker-files/web/Dockerfile -t $ECR_REGISTRY/vprofileweb:latest ./Docker-files/web
docker push $ECR_REGISTRY/vprofileweb:latest
```

### Security Best Practices

- ✅ **Never commit AWS credentials** to version control
- ✅ Use **IAM roles** with least privilege principle
- ✅ **Rotate access keys** regularly
- ✅ Use **GitHub Secrets** or similar secure storage for CI/CD
- ✅ Enable **ECR image scanning** for security vulnerabilities
- ✅ Use **private ECR repositories** for production

### Troubleshooting

**Issue: Authentication failed**
- Verify AWS credentials are correct
- Check IAM permissions for ECR and App Runner
- Ensure region matches your ECR repositories

**Issue: ECR repository not found**
- Verify repository names match exactly
- Check repository exists in the specified region
- Ensure you have permissions to access the repository

**Issue: App Runner deployment fails**
- Verify ECR image URIs are correct
- Check App Runner service configuration
- Review App Runner logs in CloudWatch

---

**Docker Expertise Demonstrated:**
- ✅ Multi-container orchestration
- ✅ Custom Dockerfile optimization
- ✅ Multi-stage builds
- ✅ Service discovery
- ✅ Volume management
- ✅ Environment configuration
- ✅ Production-ready setup
- ✅ Load balancing
- ✅ Database containerization
- ✅ Microservices architecture


