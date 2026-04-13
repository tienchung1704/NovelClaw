#!/bin/bash

# Script deploy NovelClaw sang server mới
# Server: netviet@192.168.1.20
# Target: /data/subtitle/NovelClaw/

set -e

SERVER="netviet@192.168.1.20"
TARGET_DIR="/data/subtitle/NovelClaw"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "NovelClaw Deployment"
echo "Server: $SERVER"
echo "Target: $TARGET_DIR"
echo "=========================================="

# Bước 1: Tạo thư mục trên server
echo ""
echo "[1/4] Creating directory on server..."
echo "Please run this command on the server first if directory doesn't exist:"
echo "  ssh $SERVER"
echo "  sudo mkdir -p $TARGET_DIR && sudo chown -R netviet:netviet $TARGET_DIR"
echo ""
read -p "Press Enter when ready to continue..."
ssh $SERVER "mkdir -p $TARGET_DIR"

# Bước 2: Sync project
echo ""
echo "[2/4] Syncing NovelClaw..."
rsync -avz --progress \
  --exclude '.git/' \
  --exclude '__pycache__/' \
  --exclude '*.pyc' \
  --exclude '.env' \
  --exclude 'node_modules/' \
  --exclude '.venv/' \
  --exclude '.venv-shared/' \
  --exclude 'venv/' \
  --exclude '.local-dev-secrets/' \
  --exclude '*.log' \
  "$SCRIPT_DIR/" \
  "$SERVER:$TARGET_DIR/"

# Bước 3: Copy file .env examples
echo ""
echo "[3/4] Copying environment templates..."
if [ -f "$SCRIPT_DIR/apps/auth-portal/local_web_portal/.env.example" ]; then
    scp "$SCRIPT_DIR/apps/auth-portal/local_web_portal/.env.example" \
        "$SERVER:$TARGET_DIR/apps/auth-portal/local_web_portal/"
fi
if [ -f "$SCRIPT_DIR/apps/novelclaw/local_web_portal/.env.example" ]; then
    scp "$SCRIPT_DIR/apps/novelclaw/local_web_portal/.env.example" \
        "$SERVER:$TARGET_DIR/apps/novelclaw/local_web_portal/"
fi

# Bước 4: Kiểm tra kết quả
echo ""
echo "[4/4] Verifying deployment..."
ssh $SERVER "ls -lh $TARGET_DIR/ | head -20"

echo ""
echo "=========================================="
echo "✓ NovelClaw deployed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. SSH to server: ssh $SERVER"
echo "2. Go to project: cd $TARGET_DIR"
echo ""
echo "3. Setup secrets:"
echo "   mkdir -p .local-dev-secrets"
echo "   chmod 700 .local-dev-secrets"
echo "   python3 -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\" > .local-dev-secrets/fernet.key"
echo "   openssl rand -hex 32 > .local-dev-secrets/session.secret"
echo ""
echo "4. Create .env files:"
echo "   # Auth Portal"
echo "   cd apps/auth-portal/local_web_portal"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "   # Main App"
echo "   cd ../../novelclaw/local_web_portal"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "5. Setup virtual environment:"
echo "   cd $TARGET_DIR"
echo "   python3 -m venv .venv-shared"
echo "   source .venv-shared/bin/activate"
echo "   pip install -r requirements.txt"
echo ""
echo "6. Start with PM2:"
echo "   pm2 start ecosystem.config.js"
echo "   pm2 save"
echo ""
echo "7. Setup Nginx (if needed):"
echo "   sudo cp infra/nginx/novelclaw.current.conf /etc/nginx/sites-available/novelclaw"
echo "   # Edit paths in the config"
echo "   sudo ln -s /etc/nginx/sites-available/novelclaw /etc/nginx/sites-enabled/"
echo "   sudo nginx -t"
echo "   sudo systemctl reload nginx"
echo "=========================================="
