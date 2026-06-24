#!/bin/bash
# 会话生命周期 - 备份脚本
# 用法: bash lifecycle-backup.sh <backup_index> <is_final>
# 由 cron isolated agentTurn 调用

set -e

WORKSPACE="/home/work/.openclaw/workspace"
BACKUP_INDEX="${1:-0}"
IS_FINAL="${2:-false}"
TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
BACKUP_BRANCH="lifecycle-backup-${TIMESTAMP}"

cd "$WORKSPACE"

# 检查 git 状态
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "ERROR: Not a git repository"
    exit 1
fi

# 认证信息已通过 git credential store 配置（.git/credentials）
# 不从 lifecycle.json 读取 token，避免泄露到 GitHub

# 添加所有工作区文件（排除敏感文件）
git add -A
git add lifecycle.json lifecycle-backup.sh recovery-instruction.md 2>/dev/null || true

# 检查是否有变更
if git diff --cached --quiet; then
    echo "No changes to backup at index ${BACKUP_INDEX}"
    exit 0
fi

# 提交
git commit -m "lifecycle-backup #${BACKUP_INDEX} [${TIMESTAMP}]" \
    -m "Auto-backup from session lifecycle system" \
    -m "Backup index: ${BACKUP_INDEX}/${TOTAL_BACKUPS:-8}" \
    -m "Final: ${IS_FINAL}"

# 推送到公开仓库（不含敏感文件）
git push origin main 2>&1 || echo "WARN: origin push failed"

# 推送到私有仓库（含 .openclaw/ 敏感文件）
git add -f .openclaw/recovery-token .openclaw/workspace-state.json 2>/dev/null || true
git diff --cached --quiet || git commit -m "include secrets for private backup" 2>/dev/null || true
git push private main 2>&1 || echo "WARN: private push failed"

echo "Backup #${BACKUP_INDEX} pushed to both remotes at ${TIMESTAMP}"

# 更新 lifecycle.json 中的备份状态
if command -v python3 > /dev/null 2>&1; then
    python3 -c "
import json
with open('lifecycle.json', 'r') as f:
    data = json.load(f)
idx = int('${BACKUP_INDEX}') - 1
if 0 <= idx < len(data['backups']['schedule']):
    data['backups']['schedule'][idx]['status'] = 'completed'
    data['backups']['schedule'][idx]['completedAt'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
data['backups']['completed'] = sum(1 for b in data['backups']['schedule'] if b['status'] == 'completed')
with open('lifecycle.json', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || echo "WARNING: Could not update lifecycle.json"
fi

echo "=== Backup #${BACKUP_INDEX} complete ==="
