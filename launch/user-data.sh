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
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Create application directory
APP_DIR="/opt/vprofile"
mkdir -p "${APP_DIR}"
cd "$APP_DIR"

# Create docker-compose.yml file for ECR images
cat > docker-compose.yml <<EOF
services:
  vprodb:
    image: "$ECR_REGISTRY/$ECR_REPO_DB:latest"
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
    image: "$ECR_REGISTRY/$ECR_REPO_APP:latest"
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
    image: "$ECR_REGISTRY/$ECR_REPO_WEB:latest"
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
docker pull "$ECR_REGISTRY/$ECR_REPO_DB:latest" || echo "Warning: Failed to pull $ECR_REPO_DB"
docker pull "$ECR_REGISTRY/$ECR_REPO_APP:latest" || echo "Warning: Failed to pull $ECR_REPO_APP"
docker pull "$ECR_REGISTRY/$ECR_REPO_WEB:latest" || echo "Warning: Failed to pull $ECR_REPO_WEB"

# Pull public images
docker pull memcached:latest
docker pull rabbitmq:latest

# Start containers with Docker Compose
echo "Starting containers with Docker Compose..."
docker-compose up -d

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

