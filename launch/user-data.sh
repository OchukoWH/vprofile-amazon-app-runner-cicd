#!/bin/bash
set -euo pipefail

# Variables from Terraform
AWS_REGION="${aws_region}"
AWS_ACCOUNT_ID="${aws_account_id}"
ECR_REPO_DB="${ecr_repo_db}"
ECR_REPO_APP="${ecr_repo_app}"
ECR_REPO_WEB="${ecr_repo_web}"


# ECR Registry URL (using template variables directly)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user-data script at $(date)"

# Update system
apt-get update -y
apt-get upgrade -y
apt-get install -y awscli

# Install prerequisites
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Install Docker
echo "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installations
docker --version
docker-compose --version

# Login to ECR
echo "Logging in to ECR..."
echo "ECR Registry: $ECR_REGISTRY"
echo "AWS Region: $AWS_REGION"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY" || {
  echo "❌ Failed to login to ECR. Checking IAM permissions..."
  aws sts get-caller-identity
  exit 1
}
echo "✅ Successfully logged in to ECR"

# Create application directory
APP_DIR="/opt/vprofile"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Create docker-compose.yml file for ECR images
# Note: Using staging-latest tag as that's what the Docker workflow pushes
cat > docker-compose.yml <<EOF
services:
  vprodb:
    image: "$ECR_REGISTRY/$ECR_REPO_DB:staging-latest"
    container_name: vprodb
    ports:
      - "3306:3306"
    volumes:
      - vprodbdata:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=vprodbpass
    restart: unless-stopped

  vprocache01:
    image: memcached:latest
    container_name: vprocache01
    ports:
      - "11211:11211"
    restart: unless-stopped

  vpromq01:
    image: rabbitmq:latest
    container_name: vpromq01
    ports:
      - "5672:5672"
    environment:
      - RABBITMQ_DEFAULT_USER=guest
      - RABBITMQ_DEFAULT_PASS=guest
    restart: unless-stopped

  vproapp:
    image: "$ECR_REGISTRY/$ECR_REPO_APP:staging-latest"
    container_name: vproapp
    ports:
      - "8080:8080"
    volumes:
      - vproappdata:/usr/local/tomcat/webapps
    depends_on:
      - vprodb
      - vprocache01
      - vpromq01
    restart: unless-stopped
    
  vproweb:
    image: "$ECR_REGISTRY/$ECR_REPO_WEB:staging-latest"
    container_name: vproweb
    ports:
      - "80:80"
    depends_on:
      - vproapp
    restart: unless-stopped

volumes:
   vprodbdata: {}
   vproappdata: {}
EOF

# Pull Docker images from ECR
echo "Pulling Docker images from ECR..."
echo "Available images in ECR repositories:"
aws ecr describe-images --repository-name "$ECR_REPO_DB" --region "$AWS_REGION" --query 'imageDetails[*].imageTags' --output table || echo "No images found in $ECR_REPO_DB"
aws ecr describe-images --repository-name "$ECR_REPO_APP" --region "$AWS_REGION" --query 'imageDetails[*].imageTags' --output table || echo "No images found in $ECR_REPO_APP"
aws ecr describe-images --repository-name "$ECR_REPO_WEB" --region "$AWS_REGION" --query 'imageDetails[*].imageTags' --output table || echo "No images found in $ECR_REPO_WEB"

echo "Pulling $ECR_REGISTRY/$ECR_REPO_DB:staging-latest"
docker pull "$ECR_REGISTRY/$ECR_REPO_DB:staging-latest" || {
  echo "❌ Failed to pull $ECR_REPO_DB:staging-latest"
  echo "Trying :latest tag..."
  docker pull "$ECR_REGISTRY/$ECR_REPO_DB:latest" || {
    echo "❌ Also failed to pull :latest tag"
    exit 1
  }
}
echo "Pulling $ECR_REGISTRY/$ECR_REPO_APP:staging-latest"
docker pull "$ECR_REGISTRY/$ECR_REPO_APP:staging-latest" || {
  echo "❌ Failed to pull $ECR_REPO_APP:staging-latest"
  echo "Trying :latest tag..."
  docker pull "$ECR_REGISTRY/$ECR_REPO_APP:latest" || {
    echo "❌ Also failed to pull :latest tag"
    exit 1
  }
}
echo "Pulling $ECR_REGISTRY/$ECR_REPO_WEB:staging-latest"
docker pull "$ECR_REGISTRY/$ECR_REPO_WEB:staging-latest" || {
  echo "❌ Failed to pull $ECR_REPO_WEB:staging-latest"
  echo "Trying :latest tag..."
  docker pull "$ECR_REGISTRY/$ECR_REPO_WEB:latest" || {
    echo "❌ Also failed to pull :latest tag"
    exit 1
  }
}
echo "✅ All ECR images pulled successfully"

# Pull public images
docker pull memcached:latest
docker pull rabbitmq:latest

# Start containers with Docker Compose
echo "Starting containers with Docker Compose..."
echo "Current directory: $(pwd)"
echo "Docker Compose file exists: $([ -f docker-compose.yml ] && echo 'yes' || echo 'no')"
cat docker-compose.yml
docker-compose up -d || {
  echo "❌ Failed to start containers with docker-compose"
  docker-compose ps
  docker-compose logs
  exit 1
}

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check container status
echo "Container status:"
docker-compose ps

# Display logs
echo "Recent logs:"
docker-compose logs --tail=50

echo "User-data script completed at $(date)"
echo "Application should be available at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

