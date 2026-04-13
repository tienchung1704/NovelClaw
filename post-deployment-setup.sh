#!/bin/bash

# Script chạy trên server MỚI sau khi deploy NovelClaw
# Chạy trên: netviet@192.168.1.20
# Location: /data/subtitle/NovelClaw/

set -e

PROJECT_DIR="/data/subtitle/NovelClaw"

echo "=========================================="
echo "NovelClaw Post-Deployment Setup"
echo "=========================================="

cd "$PROJECT_DIR"

# Kiểm tra Python
echo ""
echo "[1/8] Checking Python..."
python3 --version
pip3 --version

# Kiểm tra Node.js
echo ""
echo "[2/8] Checking Node.js..."
node --version || echo "WARNING: Node.js not installed"
npm --version || echo "WARNING: npm not installed"

# Tạo shared virtual environment
echo ""
echo "[3/8] Creating shared virtual environment..."
if [ ! -d ".venv-shared" ]; then
    python3 -m venv .venv-shared
    echo "✓ Shared virtual environment created"
else
    echo "✓ Shared virtual environment already exists"
fi

# Cài dependencies
echo ""
echo "[4/8] Installing Python dependencies..."
source .venv-shared/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
echo "✓ Python dependencies installed"

# Setup secrets directory
echo ""
echo "[5/8] Setting up secrets..."
mkdir -p .local-dev-secrets
chmod 700 .local-dev-secrets

# Tạo Fernet key
if [ ! -f ".local-dev-secrets/fernet.key" ]; then
    python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" > .local-dev-secrets/fernet.key
    echo "✓ Generated Fernet key"
else
    echo "✓ Fernet key already exists"
fi

# Tạo session secret
if [ ! -f ".local-dev-secrets/session.secret" ]; then
    openssl rand -hex 32 > .local-dev-secrets/session.secret
    echo "✓ Generated session secret"
else
    echo "✓ Session secret already exists"
fi

chmod 600 .local-dev-secrets/*
echo "✓ Secrets configured"

# Kiểm tra PM2
echo ""
echo "[6/8] Checking PM2..."
if ! command -v pm2 &> /dev/null; then
    echo "PM2 not found. Installing..."
    sudo npm install -g pm2
else
    echo "✓ PM2 is installed: $(pm2 --version)"
fi

# Kiểm tra Nginx
echo ""
echo "[7/8] Checking Nginx..."
if command -v nginx &> /dev/null; then
    echo "✓ Nginx is installed: $(nginx -v 2>&1)"
    # Backup current config if exists
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup.$(date +%Y%m%d) 2>/dev/null || true
    fi
else
    echo "WARNING: Nginx not installed"
    echo "Install with: sudo apt install nginx"
fi

# Set permissions
echo ""
echo "[8/8] Setting permissions..."
chmod +x infra/scripts/*.sh 2>/dev/null || true
echo "✓ Permissions set"

echo ""
echo "=========================================="
echo "✓ Setup completed!"
echo "=========================================="
echo ""
echo "IMPORTANT: Create .env files:"
echo ""
echo "1. Auth Portal:"
echo "   cd $PROJECT_DIR/apps/auth-portal/local_web_portal"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "   Required variables:"
echo "   - DATABASE_URL"
echo "   - FERNET_KEY=\$(cat $PROJECT_DIR/.local-dev-secrets/fernet.key)"
echo "   - SESSION_SECRET=\$(cat $PROJECT_DIR/.local-dev-secrets/session.secret)"
echo ""
echo "2. Main App:"
echo "   cd $PROJECT_DIR/apps/novelclaw/local_web_portal"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "   Required variables:"
echo "   - DATABASE_URL"
echo "   - AUTH_SERVICE_URL"
echo "   - Other API keys"
echo ""
echo "3. Setup Nginx:"
echo "   sudo nano /etc/nginx/sites-available/novelclaw"
echo "   # Copy from infra/nginx/novelclaw.current.conf"
echo "   # Update paths to $PROJECT_DIR"
echo "   sudo ln -s /etc/nginx/sites-available/novelclaw /etc/nginx/sites-enabled/"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo ""
echo "4. Start services:"
echo "   cd $PROJECT_DIR"
echo "   pm2 start ecosystem.config.js"
echo "   pm2 save"
echo "   pm2 startup  # Run the command it shows"
echo ""
echo "5. Check status:"
echo "   pm2 status"
echo "   pm2 logs"
echo "=========================================="
