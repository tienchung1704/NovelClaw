#!/bin/bash

# Script setup production cho NovelClaw trên server mới
# Chạy script này trên server: /home/netviet/projects/NovelClaw

set -e

PROJECT_DIR="/home/netviet/projects/NovelClaw"
cd "$PROJECT_DIR"

echo "=========================================="
echo "NovelClaw Production Setup"
echo "=========================================="

# Bước 1: Cập nhật ecosystem.config.js
echo ""
echo "[1/5] Updating ecosystem.config.js..."
if [ -f "ecosystem.config.new.js" ]; then
    cp ecosystem.config.js ecosystem.config.js.backup
    cp ecosystem.config.new.js ecosystem.config.js
    echo "✓ ecosystem.config.js updated (backup saved)"
else
    echo "✗ ecosystem.config.new.js not found. Please deploy it first."
    exit 1
fi

# Bước 2: Nhập domain name
echo ""
echo "[2/5] Nginx configuration..."
read -p "Enter domain name (or IP like 192.168.1.20): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME="192.168.1.20"
    echo "Using default: $DOMAIN_NAME"
fi

# Tạo nginx config
NGINX_CONF="/tmp/novelclaw_nginx.conf"
cat > "$NGINX_CONF" << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    client_max_body_size 50m;

    location = /multiagent {
        return 301 /multiagent/;
    }

    location /multiagent/ {
        proxy_pass http://127.0.0.1:8011/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }

    location = /claw {
        return 301 /claw/;
    }

    location /claw/ {
        proxy_pass http://127.0.0.1:8012/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }

    location / {
        proxy_pass http://127.0.0.1:8010;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }
}
EOF

echo "✓ Nginx config created at $NGINX_CONF"

# Copy nginx config
echo ""
echo "Installing nginx config (requires sudo)..."
sudo cp "$NGINX_CONF" /etc/nginx/sites-available/novelclaw
sudo ln -sf /etc/nginx/sites-available/novelclaw /etc/nginx/sites-enabled/novelclaw

# Test nginx
echo ""
echo "Testing nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✓ Nginx config is valid"
    sudo systemctl reload nginx
    echo "✓ Nginx reloaded"
else
    echo "✗ Nginx config has errors"
    exit 1
fi

# Bước 3: Kiểm tra .env files
echo ""
echo "[3/5] Checking .env files..."
MISSING_ENV=0

if [ ! -f "apps/auth-portal/local_web_portal/.env" ]; then
    echo "✗ Missing: apps/auth-portal/local_web_portal/.env"
    MISSING_ENV=1
fi

if [ ! -f "apps/novelclaw/local_web_portal/.env" ]; then
    echo "✗ Missing: apps/novelclaw/local_web_portal/.env"
    MISSING_ENV=1
fi

if [ $MISSING_ENV -eq 1 ]; then
    echo ""
    echo "Please create .env files before starting services:"
    echo "  cd apps/auth-portal/local_web_portal && cp .env.example .env && nano .env"
    echo "  cd apps/novelclaw/local_web_portal && cp .env.example .env && nano .env"
    read -p "Press Enter after creating .env files..."
fi

# Bước 4: Start PM2
echo ""
echo "[4/5] Starting services with PM2..."
pm2 delete all 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
echo "✓ Services started"

# Bước 5: Setup PM2 startup
echo ""
echo "[5/5] Setting up PM2 startup..."
pm2 startup | grep "sudo" | bash || true
echo "✓ PM2 startup configured"

echo ""
echo "=========================================="
echo "✓ Production setup completed!"
echo "=========================================="
echo ""
echo "Services:"
echo "  Auth Portal  : http://$DOMAIN_NAME/"
echo "  MultiAgent   : http://$DOMAIN_NAME/multiagent/"
echo "  NovelClaw    : http://$DOMAIN_NAME/claw/"
echo ""
echo "Check status:"
echo "  pm2 status"
echo "  pm2 logs"
echo ""
echo "Nginx status:"
echo "  sudo systemctl status nginx"
echo "=========================================="
