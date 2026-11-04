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

# 配置 git
git config user.email "backup@laowang.local"
git config user.name "Server Backup"
git remote set-url origin "$REPO_URL"

# 备份目录
BACKUP_CONTENT="$BACKUP_DIR/content"
mkdir -p "$BACKUP_CONTENT"

# 备份关键系统信息
echo "=== Backup started at $(date) ===" > "$BACKUP_CONTENT/backup.log"

# 系统信息
{
  echo "=== System Info ==="
  date
  uname -a
  df -h
  free -h
  echo ""
  echo "=== Installed packages ==="
  dpkg -l | head -200
  echo ""
  echo "=== Running services ==="
  systemctl list-units --type=service --state=running 2>/dev/null | head -50 || true
  echo ""
  echo "=== Listening ports ==="
  ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null || true
} > "$BACKUP_CONTENT/system-info.txt"

# 备份配置文件
mkdir -p "$BACKUP_CONTENT/etc" "$BACKUP_CONTENT/root-config"
cp -a /etc/hostname /etc/hosts /etc/fstab "$BACKUP_CONTENT/etc/" 2>/dev/null || true
cp -a /root/.bashrc /root/.profile "$BACKUP_CONTENT/root-config/" 2>/dev/null || true
crontab -l > "$BACKUP_CONTENT/crontab.txt" 2>/dev/null || echo "no crontab" > "$BACKUP_CONTENT/crontab.txt"

# 备份 /root 下的脚本和配置（排除大文件、缓存、以及 token 文件）
mkdir -p "$BACKUP_CONTENT/root-files"
find /root -maxdepth 2 -type f \( -name "*.sh" -o -name "*.py" -o -name "*.conf" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.log" \) \
  -size -10M ! -name ".git-token" 2>/dev/null | while read f; do
  rel="${f#/root/}"
  mkdir -p "$BACKUP_CONTENT/root-files/$(dirname "$rel")"
  cp -a "$f" "$BACKUP_CONTENT/root-files/$rel" 2>/dev/null || true
done

# 记录最新备份时间
echo "$(date '+%Y-%m-%d %H:%M:%S')" > "$BACKUP_CONTENT/last-backup.txt"

# Git 提交并推送
cd "$BACKUP_DIR"
git add -A
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Auto backup $(date '+%Y-%m-%d %H:%M:%S')"
  git push origin HEAD || git push -u origin main
fi

echo "Backup completed at $(date)" >> "$BACKUP_CONTENT/backup.log"
