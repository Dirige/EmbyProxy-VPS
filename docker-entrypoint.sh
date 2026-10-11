#!/bin/sh
# ============================================================
# 容器入口脚本
# - 首次启动（无 config.json）时，可用环境变量 ADMIN_TOKEN 注入管理员密钥
# - 未设置 ADMIN_TOKEN 时，由 server.js 自动生成默认密钥（changeme_please）
# - 配置和节点数据持久化在 /app/data 卷
# ============================================================
set -e

DATA_DIR="/app/data"
CONFIG_FILE="$DATA_DIR/config.json"

# 确保数据目录存在
mkdir -p "$DATA_DIR"

# 首次启动：用环境变量 ADMIN_TOKEN 生成初始配置
if [ ! -f "$CONFIG_FILE" ] && [ -n "$ADMIN_TOKEN" ]; then
  echo "[entrypoint] 首次启动，使用环境变量 ADMIN_TOKEN 初始化配置"
  cat > "$CONFIG_FILE" <<EOF
{
  "adminToken": "$ADMIN_TOKEN",
  "adminPass": null,
  "subscribers": [],
  "frontendDomain": "",
  "backendDomain": ""
}
EOF
  echo '[]' > "$DATA_DIR/routes.json"
  echo "[entrypoint] 初始配置已生成：$CONFIG_FILE"
fi

# 打印当前监听端口
echo "[entrypoint] Emby 反代管理面板启动中，端口：${PORT:-3333}"

# 执行主进程
exec "$@"
