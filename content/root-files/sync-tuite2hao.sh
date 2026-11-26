#!/bin/bash
set -e
REPO="/root/tuite2hao"
TOKEN=$(cat /root/.git-token)
cd "$REPO"

git config user.email "backup@laowang.local"
git config user.name "tuite2hao-sync"

# Clean previous content (except .git)
find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

mkdir -p app config data docs

# 1. Application design (tuitegl panel)
echo "Copying application..."
rsync -a --exclude='node_modules' --exclude='.git' /opt/tuitegl/app/ app/ 2>/dev/null || cp -a /opt/tuitegl/app/. app/

# 2. Runtime note
mkdir -p config
echo "Node runtime: /opt/tuitegl-runtime/node-v22.21.0-linux-x64" > config/runtime.txt
ls -la /opt/tuitegl-runtime/ >> config/runtime.txt 2>/dev/null || true

# 3. Nginx configs
cp -a /etc/nginx/sites-available/tuitegl config/nginx-tuitegl.conf 2>/dev/null || true
cp -a /etc/nginx/sites-available/tuitegl-domain config/nginx-tuitegl-domain.conf 2>/dev/null || true
cp -a /etc/nginx/sites-available/tuitegl-443-default config/nginx-tuitegl-443-default.conf 2>/dev/null || true
cp -a /etc/nginx/sites-enabled/panel config/nginx-panel.conf 2>/dev/null || true

# 4. Systemd service
cp -a /etc/systemd/system/tuitegl.service config/tuitegl.service 2>/dev/null || true

# 5. Environment (mask sensitive if needed, but keep structure)
mkdir -p config/env
cp -a /etc/tuitegl/panel.env config/env/panel.env 2>/dev/null || true
# Note: contains credentials - for private repo only

# 6. Data layout (structure + current empty state)
mkdir -p data
cp -a /var/lib/tuitegl/desk.json data/desk.json 2>/dev/null || echo '{"accounts":[],"spares":[]}' > data/desk.json
ls -la /var/lib/tuitegl/ > data/data-dir-listing.txt 2>/dev/null || true

# 7. Design documentation
cat > docs/SERVER-DESIGN.md << 'EOF'
# 50.114.5.99 服务器设计与资源布局

## 主机信息
- IP: 50.114.5.99
- 主机名: laowang-mdds-01.evoxt.com
- 系统: Ubuntu 26.04 LTS
- 核心服务: tuitegl clone panel (independent)

## 资源布局
```
/opt/tuitegl/app/          # 面板应用 (Nitro/Node)
/opt/tuitegl-runtime/      # Node.js v22.21.0 runtime
/var/lib/tuitegl/          # 数据目录 (desk.json 等)
/etc/tuitegl/              # 环境配置 (panel.env)
/etc/nginx/sites-available/tuitegl*  # Nginx 站点
```

## 访问方式
- IP: https://50.114.5.99:8443 (自签名证书)
- 域名: https://tg99999.pw (Let's Encrypt)
- 内部端口: 127.0.0.1:3100

## 服务管理
- systemd: tuitegl.service (enabled, Restart=always)
- WorkingDirectory: /opt/tuitegl/app
- EnvironmentFile: /etc/tuitegl/panel.env

## 当前状态
- 账号数: 0 (desk.json 为空)
- 面板已就绪，可直接部署对接

## 原有备份
原 1 小时/定时备份系统（backup-system.sh → cui.git）保持不变，未做任何修改。
EOF

# 8. Last sync info
echo "Synced at $(date '+%Y-%m-%d %H:%M:%S %Z')" > docs/last-sync.txt
date > docs/last-sync.txt

# Git commit and push
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Sync server design and resource layout $(date '+%Y-%m-%d %H:%M')"
  git push -u origin main
fi

echo "=== Sync completed at $(date) ==="
