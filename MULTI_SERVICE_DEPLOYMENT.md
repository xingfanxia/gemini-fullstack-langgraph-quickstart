# Multi-Docker Compose Deployment with Single Caddy Reverse Proxy

This document explains how to deploy multiple independent Docker Compose stacks behind a single Caddy reverse proxy, enabling subdomain-based routing to different services on the same server.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Network Strategy](#network-strategy)
- [Service Configuration](#service-configuration)
- [Caddy Configuration](#caddy-configuration)
- [DNS Setup](#dns-setup)
- [Deployment Process](#deployment-process)
- [Management & Operations](#management--operations)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🏗️ Architecture Overview

### High-Level Architecture

```
Internet
    ↓
[Cloudflare DNS]
    ↓
[Server: 35.193.136.64]
    ↓
[Caddy Reverse Proxy] (:80, :443)
    ├── demos.computelabs.ai → Landing Page
    ├── gs.demos.computelabs.ai → LangGraph Service
    ├── oui.demos.computelabs.ai → Open WebUI + Ollama
    ├── dify.demos.computelabs.ai → Dify Web Interface
    └── api.dify.demos.computelabs.ai → Dify API
```

### Service Stack Distribution

| Service Stack | Location | Docker Compose | Network |
|---------------|----------|----------------|---------|
| **LangGraph + Caddy** | `/home/xingfanxia/gemini-fullstack-langgraph-quickstart/` | `docker-compose.yml` | `default` |
| **Dify Platform** | `/home/xingfanxia/dify/docker/` | `docker-compose.yaml` | `docker_default` |
| **Open WebUI + Ollama** | Integrated with LangGraph stack | `docker-compose.yml` | `default` |

## 🌐 Network Strategy

### Network Architecture

The deployment uses Docker's networking capabilities to enable communication between services across different Docker Compose stacks:

```yaml
# LangGraph Stack (docker-compose.yml)
networks:
  default:
    driver: bridge
  docker_default:
    external: true  # References Dify's network

# Dify Stack (docker-compose.yaml) 
networks:
  default:
    name: docker_default
```

### Key Network Concepts

1. **Default Networks**: Each Docker Compose stack creates its own default network
2. **External Networks**: The LangGraph stack connects to Dify's network via `external: true`
3. **Service Discovery**: Services can communicate using container names within their networks
4. **Cross-Network Communication**: Caddy connects to both networks to route traffic

### Network Connectivity Matrix

| From | To | Method |
|------|----|----|
| Caddy | LangGraph API | `langgraph-api:8000` (same network) |
| Caddy | Open WebUI | `open-webui:8080` (same network) |
| Caddy | Dify Web | `docker-web-1:3000` (external network) |
| Caddy | Dify API | `docker-api-1:5001` (external network) |

## ⚙️ Service Configuration

### 1. LangGraph Stack Configuration

**File**: `/home/xingfanxia/gemini-fullstack-langgraph-quickstart/docker-compose.yml`

```yaml
services:
  # Caddy Reverse Proxy
  caddy:
    image: caddy:2-alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3 support
    volumes:
      - $PWD/Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - default          # LangGraph network
      - docker_default   # Dify network
    external_links:
      - docker-web-1     # Link to Dify web service
      - docker-api-1     # Link to Dify API service

  # LangGraph Services
  langgraph-api:
    image: gemini-fullstack-langgraph
    container_name: langgraph-api
    # ... other configuration

  # Open WebUI with Bundled Ollama
  open-webui:
    image: ghcr.io/open-webui/open-webui:ollama
    container_name: open-webui
    restart: unless-stopped
    environment:
      WEBUI_AUTH: "True"
      WEBUI_NAME: "Open WebUI"
      OPENAI_API_KEY: ${OPENAI_API_KEY}
    volumes:
      - ollama_data:/root/.ollama
      - open_webui_data:/app/backend/data

networks:
  default:
    driver: bridge
  docker_default:
    external: true  # Connect to Dify's network
```

### 2. Dify Stack Configuration

**File**: `/home/xingfanxia/dify/docker/docker-compose.yaml`

The Dify stack runs independently with its own network and services:

```yaml
# Dify services (simplified)
services:
  web:
    image: langgenius/dify-web:latest
    container_name: docker-web-1
    ports:
      - "3000"  # Internal port only
    # ... other configuration

  api:
    image: langgenius/dify-api:latest
    container_name: docker-api-1
    ports:
      - "5001"  # Internal port only
    # ... other configuration

networks:
  default:
    name: docker_default  # Named network for external access
```

## 🔧 Caddy Configuration

### Caddyfile Structure

**File**: `/home/xingfanxia/gemini-fullstack-langgraph-quickstart/Caddyfile`

```caddy
# Main landing page with service directory
demos.computelabs.ai {
    handle {
        header Content-Type "text/html"
        respond "<!DOCTYPE html>..." 200
    }
}

# LangGraph service (same network)
gs.demos.computelabs.ai {
    reverse_proxy langgraph-api:8000 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}

# Open WebUI service (same network)
oui.demos.computelabs.ai {
    reverse_proxy open-webui:8080 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}

# Dify Web Interface (external network)
dify.demos.computelabs.ai {
    reverse_proxy docker-web-1:3000 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}

# Dify API (external network)
api.dify.demos.computelabs.ai {
    reverse_proxy docker-api-1:5001 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

### Key Caddy Features

1. **Automatic HTTPS**: Let's Encrypt certificates for all domains
2. **HTTP/3 Support**: Modern protocol support with UDP port 443
3. **Header Forwarding**: Proper proxy headers for backend services
4. **Service Discovery**: Uses Docker container names for routing
5. **Cross-Network Routing**: Routes to services on different Docker networks

## 🌍 DNS Setup

### Cloudflare DNS Configuration

All subdomains point to the same server IP:

| Record Type | Name | Content | TTL |
|-------------|------|---------|-----|
| A | demos.computelabs.ai | 35.193.136.64 | Auto |
| A | gs.demos.computelabs.ai | 35.193.136.64 | Auto |
| A | oui.demos.computelabs.ai | 35.193.136.64 | Auto |
| A | dify.demos.computelabs.ai | 35.193.136.64 | Auto |
| A | api.dify.demos.computelabs.ai | 35.193.136.64 | Auto |

### DNS Resolution Flow

1. **Client Request**: `https://dify.demos.computelabs.ai`
2. **DNS Resolution**: Cloudflare returns `35.193.136.64`
3. **HTTP Request**: Client connects to server on port 443
4. **Caddy Routing**: Caddy examines `Host` header and routes to `docker-web-1:3000`
5. **Service Response**: Dify web service responds through Caddy proxy

## 🚀 Deployment Process

### Step 1: Prepare Directory Structure

```bash
/home/xingfanxia/
├── gemini-fullstack-langgraph-quickstart/
│   ├── docker-compose.yml
│   ├── Caddyfile
│   ├── deploy.sh
│   └── ...
└── dify/
    └── docker/
        ├── docker-compose.yaml
        ├── .env
        └── ...
```

### Step 2: Start Dify Stack First

```bash
# Start Dify services to create the docker_default network
cd /home/xingfanxia/dify/docker
sudo docker compose up -d
```

### Step 3: Start LangGraph Stack with Caddy

```bash
# Start LangGraph services and Caddy
cd /home/xingfanxia/gemini-fullstack-langgraph-quickstart
sudo docker compose up -d
```

### Step 4: Verify Network Connectivity

```bash
# Check that Caddy can reach both networks
sudo docker exec caddy nslookup langgraph-api      # Same network
sudo docker exec caddy nslookup docker-web-1       # External network
```

## 🛠️ Management & Operations

### Deployment Script

**File**: `deploy.sh`

```bash
#!/bin/bash

# Comprehensive management script for multi-stack deployment
case $1 in
    "start")
        # Start all services or specific service
        ;;
    "stop") 
        # Stop all services or specific service
        ;;
    "restart")
        # Restart services with proper dependency handling
        ;;
    "status")
        # Show status of all stacks
        ;;
    "logs")
        # Show logs for specific services
        ;;
esac
```

### Common Operations

```bash
# Start all services
sudo ./deploy.sh start

# Start only LangGraph stack
sudo ./deploy.sh start langgraph

# Start only Dify stack  
sudo ./deploy.sh start dify

# Check status of all services
sudo ./deploy.sh status

# View Caddy logs
sudo ./deploy.sh logs caddy

# Restart specific service
sudo ./deploy.sh restart open-webui
```

### Service Health Monitoring

```bash
# Check service health
sudo docker compose ps
cd /home/xingfanxia/dify/docker && sudo docker compose ps

# Test endpoint connectivity
curl -s -o /dev/null -w "%{http_code}" https://gs.demos.computelabs.ai/health
curl -s -o /dev/null -w "%{http_code}" https://dify.demos.computelabs.ai
curl -s -o /dev/null -w "%{http_code}" https://oui.demos.computelabs.ai
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. Network Connectivity Issues

**Problem**: Caddy cannot reach services on external networks

**Solution**:
```bash
# Ensure external network exists
sudo docker network ls | grep docker_default

# Verify Caddy is connected to both networks
sudo docker inspect caddy | grep NetworkMode

# Test connectivity from Caddy container
sudo docker exec caddy ping docker-web-1
```

#### 2. SSL Certificate Issues

**Problem**: Let's Encrypt certificate generation fails

**Solution**:
```bash
# Check Caddy logs
sudo docker logs caddy

# Verify DNS resolution
nslookup dify.demos.computelabs.ai

# Restart Caddy to retry certificate generation
sudo docker compose restart caddy
```

#### 3. Service Discovery Issues

**Problem**: Services cannot find each other

**Solution**:
```bash
# Check container names
sudo docker ps --format "table {{.Names}}\t{{.Status}}"

# Verify network connectivity
sudo docker exec caddy nslookup langgraph-api
sudo docker exec caddy nslookup docker-web-1
```

#### 4. Port Conflicts

**Problem**: Port already in use errors

**Solution**:
```bash
# Check port usage
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Stop conflicting services
sudo systemctl stop nginx  # If nginx is running
sudo systemctl stop apache2  # If apache is running
```

### Debugging Commands

```bash
# Network inspection
sudo docker network ls
sudo docker network inspect docker_default
sudo docker network inspect gemini-fullstack-langgraph-quickstart_default

# Container connectivity testing
sudo docker exec caddy wget -qO- http://langgraph-api:8000/health
sudo docker exec caddy wget -qO- http://docker-web-1:3000

# Log monitoring
sudo docker logs -f caddy
sudo docker logs -f langgraph-api
sudo docker logs -f open-webui
```

## 📚 Best Practices

### 1. Network Design

- **Use external networks** for cross-stack communication
- **Name networks explicitly** to avoid conflicts
- **Document network dependencies** clearly
- **Test connectivity** between services

### 2. Service Configuration

- **Use container names** for service discovery
- **Implement health checks** for all services
- **Configure proper restart policies**
- **Use environment variables** for configuration

### 3. Reverse Proxy Setup

- **Forward proper headers** (Host, X-Forwarded-*)
- **Configure timeouts** appropriately
- **Enable HTTP/3** for performance
- **Use meaningful subdomain names**

### 4. Security Considerations

- **Enable authentication** where appropriate
- **Use HTTPS everywhere** with automatic certificates
- **Limit exposed ports** to necessary services only
- **Regular security updates** for all container images

### 5. Monitoring & Maintenance

- **Implement comprehensive logging**
- **Monitor service health** regularly
- **Automate deployment processes**
- **Document all configurations**
- **Regular backup of persistent data**

### 6. Scalability Planning

- **Design for horizontal scaling**
- **Use load balancing** when needed
- **Plan for service discovery** at scale
- **Consider container orchestration** for larger deployments

## 🎯 Key Advantages

1. **Service Isolation**: Each stack can be managed independently
2. **Technology Diversity**: Different stacks can use different technologies
3. **Simplified Routing**: Single entry point with subdomain-based routing
4. **SSL Automation**: Automatic HTTPS for all services
5. **Scalability**: Easy to add new services or scale existing ones
6. **Maintenance**: Independent updates and maintenance cycles

## 📖 References

- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker External Networks](https://docs.docker.com/compose/networking/#use-a-pre-existing-network)
- [Let's Encrypt with Caddy](https://caddyserver.com/docs/automatic-https)

---

**Created**: 2025-06-24  
**Last Updated**: 2025-06-24  
**Version**: 1.0 