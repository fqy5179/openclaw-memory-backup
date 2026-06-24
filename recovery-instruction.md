# 🔑 会话恢复指令

## 令牌验证

**令牌哈希**: `ff26402d8f93d189a1655ad44f12324a12f13d8ab976b93ba716e1589beb8ea9`

用户提供令牌 → SHA-256 → 与 lifecycle.json 的 tokenHash 比对

## 恢复流程

### Step 0: 令牌验证
```bash
echo -n "<用户令牌>" | sha256sum | awk '{print $1}'
```

### Step 1: 从私有仓库恢复
**仓库**: `https://github.com/fqy5179/openclaw-private-backup`（私有）

```
https://api.github.com/repos/fqy5179/openclaw-private-backup/contents/
https://raw.githubusercontent.com/fqy5179/openclaw-private-backup/main/<path>
```

文件清单：
- MEMORY.md, AGENTS.md, SOUL.md, IDENTITY.md, USER.md, TOOLS.md
- active-task.json, lifecycle.json, lifecycle-backup.sh
- memory/heartbeat-state.json, memory/restore-pitfalls.md
- 最近 7 天 memory/YYYY-MM-DD.md
- .openclaw/recovery-token

### Step 2: 写入工作区
使用 write 工具写入对应路径。

### Step 3: 恢复 Git 认证
```bash
cd /home/work/.openclaw/workspace
git remote set-url origin https://fqy5179:<PAT>@github.com/fqy5179/openclaw-memory-backup.git
git remote set-url private https://fqy5179:<PAT>@github.com/fqy5179/openclaw-private-backup.git
echo "https://fqy5179:<PAT>@github.com" > .git/credentials
git config credential.helper store
```
（PAT 由用户提供，不存储在公开仓库）

### Step 4: 热重启
gateway action=restart

### Step 5: 验证
检查关键文件是否完整恢复。

## 安全说明
- 公开仓库仅存令牌哈希，不含明文
- 私有仓库含完整令牌明文和敏感文件
- 恢复时需要用户提供 GitHub PAT 以访问私有仓库
