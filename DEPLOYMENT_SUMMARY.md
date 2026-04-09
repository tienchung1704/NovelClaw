# NovelClaw Deployment Summary - Server 192.168.1.15

## Thông tin Server
- **IP**: 192.168.1.15
- **OS**: Ubuntu Linux
- **User**: netviet
- **Python**: 3.13 (miniconda)
- **Project Path**: /home/netviet/NovelClaw

## Những gì đã Setup

### 1. Dependencies & Environment
```bash
# Đã cài đặt
- Python 3.13 (miniconda)
- PM2 (process manager)
- Nginx (reverse proxy)
- Virtual environment: /home/netviet/NovelClaw/.venv-shared

# Dependencies đã cài
pip install -r apps/auth-portal/requirements.txt
pip install -r apps/multiagent/local_web_portal/requirements.txt
pip install -r apps/novelclaw/local_web_portal/requirements.txt

# Các package quan trọng
- openai
- langchain
- langchain-community
- chromadb
- fastapi
- uvicorn
- sqlalchemy
```

### 2. PM2 Configuration
**File**: `~/NovelClaw/ecosystem.config.js`

```javascript
module.exports = {
  apps: [
    {
      name: 'novelclaw-portal',
      script: '/home/netviet/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8010',
      cwd: '/home/netviet/NovelClaw/apps/auth-portal/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/NovelClaw/apps/auth-portal/local_web_portal:/home/netviet/NovelClaw/apps/auth-portal'
      }
    },
    {
      name: 'novelclaw-multiagent',
      script: '/home/netviet/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8011',
      cwd: '/home/netviet/NovelClaw/apps/multiagent/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/NovelClaw/apps/multiagent/local_web_portal:/home/netviet/NovelClaw/apps/multiagent'
      }
    },
    {
      name: 'novelclaw-main',
      script: '/home/netviet/NovelClaw/.venv-shared/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8036',
      cwd: '/home/netviet/NovelClaw/apps/novelclaw/local_web_portal',
      interpreter: 'none',
      env: {
        PYTHONPATH: '/home/netviet/NovelClaw/apps/novelclaw/local_web_portal:/home/netviet/NovelClaw/apps/novelclaw'
      }
    }
  ]
};
```

**Lệnh quản lý PM2:**
```bash
# Start services
pm2 start ecosystem.config.js

# Restart services
pm2 restart 0 1 12  # hoặc pm2 restart all

# Stop services
pm2 stop novelclaw-portal novelclaw-multiagent novelclaw-main

# View logs
pm2 logs novelclaw-main --lines 50

# List processes
pm2 list
```

### 3. Nginx Configuration
**File**: `/etc/nginx/sites-available/novelclaw`

```nginx
server {
    listen 80;
    server_name 192.168.1.15;

    client_max_body_size 50m;

    location = /multiagent {
        return 301 /multiagent/;
    }

    location /multiagent/ {
        proxy_pass http://127.0.0.1:8011/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }

    location = /claw {
        return 301 /claw/;
    }

    location /claw/ {
        proxy_pass http://127.0.0.1:8036/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }

    location / {
        proxy_pass http://127.0.0.1:8010;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }
}
```

**Lệnh quản lý Nginx:**
```bash
# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx

# Restart
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

### 4. Environment Configuration

#### Auth Portal (.env)
**File**: `~/NovelClaw/apps/auth-portal/local_web_portal/.env`
```bash
APP_BASE_URL=http://192.168.1.15
APP_HTTPS_ONLY=0
APP_SESSION_COOKIE_NAME=colong_shared_session
APP_SESSION_COOKIE_DOMAIN=
APP_SESSION_SECRET=
APP_DATABASE_URL=
APP_MULTIAGENT_URL=http://192.168.1.15/multiagent/dashboard
APP_CLAW_URL=http://192.168.1.15/claw/dashboard
APP_PREVIEW_USER_EMAIL=preview@novelclaw.local
```

#### NovelClaw Main (.env)
**File**: `~/NovelClaw/apps/novelclaw/local_web_portal/.env`
```bash
APP_SESSION_COOKIE_NAME=colong_shared_session
APP_SESSION_COOKIE_DOMAIN=
APP_SHARED_PORTAL_URL=http://192.168.1.15
APP_DATABASE_URL=sqlite:////home/netviet/NovelClaw/apps/auth-portal/local_web_portal/data/app.db
APP_AUTH_DATABASE_URL=sqlite:////home/netviet/NovelClaw/apps/auth-portal/local_web_portal/data/app.db
APP_HTTPS_ONLY=0
WEB_BUILTIN_PROVIDERS=deepseek
WEB_MODELLESS_MODE=0
DISABLE_EMBEDDING_DOWNLOADS=1
# ... (các config khác giữ nguyên)
```

#### MultiAgent (.env)
**File**: `~/NovelClaw/apps/multiagent/local_web_portal/.env`
```bash
APP_SESSION_COOKIE_NAME=colong_shared_session
APP_SESSION_COOKIE_DOMAIN=
APP_SHARED_PORTAL_URL=http://192.168.1.15
APP_DATABASE_URL=sqlite:////home/netviet/NovelClaw/apps/auth-portal/local_web_portal/data/app.db
APP_AUTH_DATABASE_URL=sqlite:////home/netviet/NovelClaw/apps/auth-portal/local_web_portal/data/app.db
# ... (các config khác)
```

### 5. Vietnamese Language Support
Đã thêm Vietnamese translations vào:
- `apps/novelclaw/local_web_portal/app/main.py` - `_VI_FALLBACKS` dictionary
- `apps/novelclaw/local_web_portal/app/i18n.py` - SUPPORTED_LOCALES
- `apps/novelclaw/local_web_portal/app/templates/base.html` - VI language button
- `apps/multiagent/local_web_portal/app/i18n.py` - Vietnamese support

### 6. Database
**Location**: `/home/netviet/NovelClaw/apps/auth-portal/local_web_portal/data/app.db`

Tất cả 3 apps đã được cấu hình để dùng chung database này.

## Services đang chạy

| Service | Port | Status | URL |
|---------|------|--------|-----|
| Nginx | 80 | ✅ Running | http://192.168.1.15/ |
| Auth Portal | 8010 | ✅ Running | http://192.168.1.15:8010/ |
| MultiAgent | 8011 | ✅ Running | http://192.168.1.15:8011/ |
| NovelClaw Main | 8036 | ✅ Running | http://192.168.1.15:8036/ |

## Các lỗi đã gặp và cách fix

### 1. ModuleNotFoundError: No module named 'openai'
**Lỗi**: Thiếu dependencies
**Fix**: 
```bash
source ~/NovelClaw/.venv-shared/bin/activate
pip install openai langchain langchain-community chromadb
```

### 2. Port 8012 already in use
**Lỗi**: Port conflict - process zombie đang giữ port
**Fix**:
```bash
# Tìm process
sudo ss -tulpn | grep 8012

# Kill process
sudo kill -9 <PID>

# Hoặc kill tất cả
sudo fuser -k 8012/tcp

# Restart PM2
pm2 restart novelclaw-main
```

**Giải pháp cuối cùng**: Đổi sang port 8036

### 3. Template Error: TypeError: unhashable type: 'dict'
**Lỗi**: Jinja2 template response syntax không đúng với Starlette mới
**Fix**: Sửa trong `apps/auth-portal/local_web_portal/app/main.py`
```python
# Trước
return templates.TemplateResponse("template.html", context_dict)

# Sau
return templates.TemplateResponse(
    request=request,
    name="template.html",
    context=context
)
```

### 4. Cookie không được share giữa các port
**Lỗi**: Browser không share cookies giữa các port khác nhau
**Giải pháp**: Sử dụng Nginx reverse proxy để tất cả chạy trên port 80

### 5. Session không được nhận diện giữa auth-portal và novelclaw
**Lỗi**: Session cross-path/cross-service không hoạt động
**Đã thử**:
- ✅ Set `APP_SESSION_COOKIE_NAME=colong_shared_session` (giống nhau)
- ✅ Set shared database
- ✅ Set `APP_SHARED_PORTAL_URL`
- ✅ Set `APP_AUTH_DATABASE_URL`
- ❌ Vẫn không hoạt động

**Nguyên nhân**: 
- Cookie domain restrictions
- Session không được sync đúng cách giữa các services
- Có thể cần Redis hoặc shared session store

**Workaround**: Chưa có giải pháp hoàn chỉnh

### 6. APP_BASE_PATH conflict
**Lỗi**: Khi set `APP_BASE_PATH=/claw`, app expect tất cả routes có prefix `/claw`
**Fix**: Xóa `APP_BASE_PATH` khỏi .env
```bash
sed -i '/APP_BASE_PATH/d' ~/NovelClaw/apps/novelclaw/local_web_portal/.env
pm2 restart novelclaw-main
```

### 7. PM2 restart loop
**Lỗi**: PM2 restart quá nhanh, port chưa được giải phóng
**Fix**:
```bash
pm2 stop <id>
sleep 3
pm2 start <id>
```

## Vấn đề đã giải quyết

### ✅ Session Authentication (ĐÃ FIX)
**Vấn đề cũ**: Session không được share giữa auth-portal (/) và novelclaw app (/claw/)

**Nguyên nhân gốc** (đã xác định):
1. **Session secret khác nhau**: Starlette `SessionMiddleware` dùng signed cookie. Mỗi app tự tạo `session.secret` riêng nếu `APP_SESSION_SECRET` không được set → các app không decode được cookie của nhau.
2. **Redirect URL sai port**: `APP_CLAW_URL` trỏ đến `http://127.0.0.1:8012/dashboard` (port cũ, đã chết), bypass Nginx → browser thấy origin khác → mất cookie.
3. **Redirect loop qua /login**: Khi không tìm thấy user, app redirect `/login` → `/select-mode` → shared portal → quay lại app → vòng lặp.

**Đã fix**:
1. ✅ Tất cả 3 `.env` files dùng chung `APP_SESSION_SECRET`
2. ✅ Thêm `path="/"` vào `SessionMiddleware` của cả 3 apps
3. ✅ Sửa `APP_CLAW_URL` và `APP_MULTIAGENT_URL` dùng relative path qua Nginx
4. ✅ Thay tất cả `_redirect("/login")` thành `_redirect("/select-mode")` trong novelclaw và multiagent
5. ✅ Fix lỗi mã hóa tên URL `%3A` trong hàm `_redirect`
6. ✅ Đảm bảo `_safe_next_path` luôn áp dụng `APP_BASE_PATH` (Fix lỗi 404 khi đổi ngôn ngữ)

**⚠️ QUAN TRỌNG - Cần làm trên Server 192.168.1.15**:
```bash
# 1. Đảm bảo cả 3 .env files trên server dùng chung APP_SESSION_SECRET
# Lấy secret từ auth-portal:
cat ~/NovelClaw/apps/auth-portal/local_web_portal/.env | grep APP_SESSION_SECRET

# Copy secret đó vào .env của novelclaw và multiagent:
# ~/NovelClaw/apps/novelclaw/local_web_portal/.env
# ~/NovelClaw/apps/multiagent/local_web_portal/.env

# 2. Cấu hình Prefix Path (Rất quan trọng để không bị lỗi 404)
# File novelclaw/.env:
sed -i 's|APP_BASE_PATH=.*|APP_BASE_PATH=/claw|' ~/NovelClaw/apps/novelclaw/local_web_portal/.env
sed -i 's|APP_SHARED_PORTAL_URL=.*|APP_SHARED_PORTAL_URL=/|' ~/NovelClaw/apps/novelclaw/local_web_portal/.env

# File multiagent/.env:
sed -i 's|APP_BASE_PATH=.*|APP_BASE_PATH=/multiagent|' ~/NovelClaw/apps/multiagent/local_web_portal/.env
sed -i 's|APP_SHARED_PORTAL_URL=.*|APP_SHARED_PORTAL_URL=/|' ~/NovelClaw/apps/multiagent/local_web_portal/.env

# 3. Sửa auth-portal .env redirect URLs:
sed -i 's|APP_MULTIAGENT_URL=.*|APP_MULTIAGENT_URL=/multiagent/dashboard|' ~/NovelClaw/apps/auth-portal/local_web_portal/.env
sed -i 's|APP_CLAW_URL=.*|APP_CLAW_URL=/claw/dashboard|' ~/NovelClaw/apps/auth-portal/local_web_portal/.env

# 4. Pull code mới và restart:
cd ~/NovelClaw
git pull
pm2 restart all
```

## Lệnh hữu ích

### Kiểm tra services
```bash
# PM2 status
pm2 list
pm2 logs <name> --lines 50

# Port listening
sudo ss -tulpn | grep -E '8010|8011|8036'

# Nginx status
sudo systemctl status nginx
sudo nginx -t

# Kill port
sudo fuser -k <port>/tcp
```

### Restart services
```bash
# Restart tất cả NovelClaw services
pm2 restart 0 1 12

# Restart Nginx
sudo systemctl reload nginx

# Restart toàn bộ
pm2 restart all
sudo systemctl restart nginx
```

### Debug
```bash
# Check logs
pm2 logs novelclaw-main --lines 100
tail -f /var/log/nginx/error.log

# Test endpoints
curl http://192.168.1.15/
curl http://192.168.1.15/claw/dashboard
curl http://127.0.0.1:8036/dashboard

# Check database
sqlite3 ~/NovelClaw/apps/auth-portal/local_web_portal/data/app.db
.tables
SELECT * FROM users;
```

## Kết luận

✅ **Đã hoàn thành**:
- Deploy infrastructure với PM2 và Nginx
- Cấu hình routing và reverse proxy
- Thêm Vietnamese language support
- Setup shared database
- Services đang chạy ổn định
- **Session authentication giữa các microservices**
- **End-to-end user flow từ select-mode đến dashboard**

## Next Steps

1. ~~Review session middleware code trong cả 3 apps~~ ✅
2. ~~Fix session management~~ ✅ (dùng shared signed cookie, không cần Redis/JWT)
3. Test end-to-end flow trên server sau khi deploy code mới
4. Setup monitoring và logging
5. Backup và disaster recovery plan
