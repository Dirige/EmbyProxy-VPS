#!/usr/bin/env bash
# ============================================================
# Emby 反代管理面板 - 本地启动脚本（适合无外网/纯内网环境）
#
# 用法：
#   ./start-local.sh              # 前台启动（Ctrl+C 停止）
#   ./start-local.sh -d           # 后台运行（日志输出到 emby-proxy.log）
#   ./start-local.sh stop         # 停止后台进程
#   ./start-local.sh restart      # 重启后台进程
#
# 代理配置（反代外网 Emby 源站时需要）：
#   编辑下方 PROXY 变量，或在运行前设置环境变量：
#     export HTTPS_PROXY=http://127.0.0.1:7890
#     export HTTP_PROXY=http://127.0.0.1:7890
#   脚本会自动让 Node.js 的 fetch 走代理（Node 22.13+ 支持 NODE_USE_ENV_PROXY）
# ============================================================
set -e

# ============ 可改配置 ============
PORT="${PORT:-3333}"                       # 面板端口
# 代理地址（留空则不走代理；反代外网源站时填上你的本地代理，如 http://127.0.0.1:7890）
PROXY="${PROXY:-}"
# 内网地址白名单（不走代理），多个用逗号分隔
NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12}"
# =================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

PID_FILE="$SCRIPT_DIR/emby-proxy.pid"
LOG_FILE="$SCRIPT_DIR/emby-proxy.log"

# 检查 Node.js
if ! command -v node >/dev/null 2>&1; then
  echo "[错误] 未安装 Node.js，请先安装 Node.js 22+"
  exit 1
fi

# 设置代理环境变量（如果配置了 PROXY）
if [ -n "$PROXY" ]; then
  export HTTP_PROXY="$PROXY"
  export HTTPS_PROXY="$PROXY"
  export http_proxy="$PROXY"
  export https_proxy="$PROXY"
  export NO_PROXY="$NO_PROXY"
  export no_proxy="$NO_PROXY"
  # Node.js 22.13+：让全局 fetch 读取代理环境变量
  export NODE_USE_ENV_PROXY=1
  echo "[代理] 已启用代理：$PROXY"
  echo "[代理] 内网不走代理：$NO_PROXY"
fi

# 停止后台进程
stop() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      echo "[停止] 已停止进程 $PID"
    else
      echo "[停止] 进程 $PID 不存在"
    fi
    rm -f "$PID_FILE"
  else
    echo "[停止] 未找到 pid 文件，无进程可停"
  fi
}

case "${1:-}" in
  stop)
    stop
    exit 0
    ;;
  restart)
    stop
    sleep 1
    ;&  # fall through
  -d|daemon)
    echo "[启动] 后台运行，端口：$PORT"
    nohup node server.js > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 1
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "[启动] 成功！PID: $(cat "$PID_FILE")"
      echo "[启动] 面板地址：http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 127.0.0.1):$PORT/"
      echo "[启动] 日志文件：$LOG_FILE"
      echo "[启动] 管理密钥：查看 data/config.json 的 adminToken 字段"
    else
      echo "[错误] 启动失败，请查看日志：$LOG_FILE"
      rm -f "$PID_FILE"
      exit 1
    fi
    ;;
  *)
    echo "[启动] 前台运行，端口：$PORT（Ctrl+C 停止）"
    echo "[启动] 面板地址：http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 127.0.0.1):$PORT/"
    exec node server.js
    ;;
esac
