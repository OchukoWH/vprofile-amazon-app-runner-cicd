# VProfile - Docker Containerized Application

A comprehensive demonstration of Docker containerization expertise, featuring a multi-tier Java web application with microservices architecture.

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

## 🔄 CI/CD with GitHub Actions

This project includes a GitHub Actions workflow that automatically builds and pushes Docker images to Docker Hub when code is pushed to the `docker-hub` branch.

### Setup Instructions

1. **Create Docker Hub Access Token**
   - Log in to [Docker Hub](https://hub.docker.com/)
   - Go to Account Settings → Security → New Access Token
   - Create a token with read/write permissions
   - Copy the token (you won't see it again)

2. **Configure GitHub Secrets**
   - Go to your GitHub repository
   - Navigate to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Add the following secrets:
     - `DOCKERHUB_USERNAME`: Your Docker Hub username
     - `DOCKERHUB_TOKEN`: Your Docker Hub access token

### Workflow Details

The workflow (`/.github/workflows/docker-image.yaml`) performs the following steps:

1. **Triggers** on push to the `docker-hub` branch
2. **Sets up Docker Buildx** for enhanced Docker capabilities
3. **Authenticates** with Docker Hub using the configured secrets
4. **Builds and pushes** all three Docker images:
   - `{your-username}/vprofiledb2:latest` (Database image)
   - `{your-username}/vprofileapp2:latest` (Application image)
   - `{your-username}/vprofileweb2:latest` (Web/NGINX image)

### Using the Published Images

After the workflow completes, you can pull and use the images:

```bash
# Pull the images
docker pull {your-username}/vprofiledb2:latest
docker pull {your-username}/vprofileapp2:latest
docker pull {your-username}/vprofileweb2:latest

# Or update docker-compose.yml to use your Docker Hub images
services:
  vprodb:
    image: {your-username}/vprofiledb2:latest
  vproapp:
    image: {your-username}/vprofileapp2:latest
  vproweb:
    image: {your-username}/vprofileweb2:latest
```

### Workflow Features

- ✅ Automated builds on code push
- ✅ Multi-stage build optimization
- ✅ Parallel image builds for faster CI/CD
- ✅ Secure credential management with GitHub Secrets
- ✅ Latest tag for easy deployment

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


