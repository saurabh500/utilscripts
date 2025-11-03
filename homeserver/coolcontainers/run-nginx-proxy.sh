#!/bin/bash

# Script to run nginx reverse proxy in Docker
# Proxies traffic from /dp to Dumbpad at 10.0.0.131:3000

set -e

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker daemon is not running"
    echo "Please start Docker service: sudo systemctl start docker"
    exit 1
fi

echo "✅ Docker is installed and running"

# Create nginx config directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONFIG_DIR="$SCRIPT_DIR/nginx-config"
mkdir -p "$NGINX_CONFIG_DIR"

# Create nginx configuration
cat > "$NGINX_CONFIG_DIR/default.conf" << 'EOF'
server {
    listen 80;
    server_name 10.0.0.85;

    # Dumbpad reverse proxy - proxy everything under /dp/
    location /dp/ {
        proxy_pass http://10.0.0.131:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Handle redirects properly
        proxy_redirect http://10.0.0.131:3000/ /dp/;
        proxy_redirect http://$host/ /dp/;
        
        # Add a header to help with debugging
        add_header X-Proxy-Path /dp/ always;
    }

    # Root location
    location / {
        return 200 'nginx reverse proxy is running\n';
        add_header Content-Type text/plain;
    }
}
EOF

echo "📝 Created nginx configuration"

# Check if nginx container exists and is running
if docker ps -a --format '{{.Names}}' | grep -q '^nginx-proxy$'; then
    echo "🛑 Stopping existing nginx-proxy container..."
    docker stop nginx-proxy 2>/dev/null || true
    echo "🗑️  Removing existing nginx-proxy container..."
    docker rm nginx-proxy 2>/dev/null || true
fi

# Pull the latest nginx image
echo "📥 Pulling latest nginx image..."
docker pull nginx:alpine

echo "🚀 Starting nginx reverse proxy container..."

# Run nginx container
docker run -d \
  --name nginx-proxy \
  --restart unless-stopped \
  -p 80:80 \
  -v "$NGINX_CONFIG_DIR/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:alpine

echo ""
echo "✅ nginx reverse proxy started successfully"
echo "📍 Access Dumbpad at: http://10.0.0.85/dp/"
echo "📍 Test nginx at: http://10.0.0.85/"
echo ""
echo "Useful commands:"
echo "  - View logs: docker logs -f nginx-proxy"
echo "  - Stop container: docker stop nginx-proxy"
echo "  - Remove container: docker rm nginx-proxy"
echo "  - Reload config: docker exec nginx-proxy nginx -s reload"
echo ""
echo "Configuration file: $NGINX_CONFIG_DIR/default.conf"
