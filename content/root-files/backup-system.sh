#!/bin/bash
set -e
TOKEN=$(cat /root/.git-token 2>/dev/null || echo "")
if [ -z "$TOKEN" ]; then
  echo "Error: /root/.git-token not found" >&2
  exit 1
fi
REPO_URL="https://${TOKEN}@github.com/laow79616-ai/cui.git"
BACKUP_DIR="/root/system-backup"
cd "$BACKUP_DIR"

git config user.email "backup@laowang.local"
git config user.name "Server Backup"
git remote set-url origin "$REPO_URL"

BACKUP_CONTENT="$BACKUP_DIR/content"
mkdir -p "$BACKUP_CONTENT"

echo "=== Backup started at $(date) ===" > "$BACKUP_CONTENT/backup.log"

# 系统信息
{
  echo "=== System Info ==="
  date
  uname -a
  df -h
  free -h
  echo ""
  echo "=== Running services ==="
  systemctl list-units --type=service --state=running 2>/dev/null | head -30 || true
  echo ""
  echo "=== Listening ports ==="
  ss -tulpn 2>/dev/null | head -20 || true
} > "$BACKUP_CONTENT/system-info.txt"

# 配置文件
mkdir -p "$BACKUP_CONTENT/etc" "$BACKUP_CONTENT/root-config"
cp -a /etc/hostname /etc/hosts /etc/fstab "$BACKUP_CONTENT/etc/" 2>/dev/null || true
cp -a /etc/nginx/sites-enabled/panel "$BACKUP_CONTENT/etc/nginx-panel.conf" 2>/dev/null || true
crontab -l > "$BACKUP_CONTENT/crontab.txt" 2>/dev/null || true

# 网页和文案库
mkdir -p "$BACKUP_CONTENT/www"
cp -a /var/www/html/wenan.html /var/www/html/copy.html /var/www/html/ku.html "$BACKUP_CONTENT/www/" 2>/dev/null || true
cp -a /var/www/html/lib/library.json "$BACKUP_CONTENT/www/" 2>/dev/null || true
cp -a /var/www/threads-generator/data/library.json "$BACKUP_CONTENT/www/library-src.json" 2>/dev/null || true

# /root 脚本
mkdir -p "$BACKUP_CONTENT/root-files"
find /root -maxdepth 2 -type f \( -name "*.sh" -o -name "*.py" -o -name "*.conf" -o -name "*.json" \)   -size -10M ! -name ".git-token" 2>/dev/null | while read f; do
  rel="${f#/root/}"
  mkdir -p "$BACKUP_CONTENT/root-files/$(dirname "$rel")"
  cp -a "$f" "$BACKUP_CONTENT/root-files/$rel" 2>/dev/null || true
done

echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$BACKUP_CONTENT/last-backup.txt"

cd "$BACKUP_DIR"
git add -A
if git diff --cached --quiet; then
  echo "No changes"
else
  git commit -m "Auto backup $(date '+%Y-%m-%d %H:%M:%S')"
  git push origin HEAD || git push -u origin main
fi
echo "Backup completed at $(date)" >> "$BACKUP_CONTENT/backup.log"
