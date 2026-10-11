# ============================================================
# Emby 反代管理面板 - Dockerfile
# 零依赖 Node.js 服务，仅需 Node 运行时
# ============================================================
FROM node:20-alpine

# 工作目录
WORKDIR /app

# 时区（方便日志时间正确）
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

# 复制程序文件（零依赖，无需 npm install）
COPY server.js panel.html ./

# 复制 entrypoint 脚本
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 数据目录（挂载到宿主机持久化）
VOLUME ["/app/data"]

# 默认端口（可通过环境变量 PORT 覆盖）
ENV PORT=3333

EXPOSE 3333

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server.js"]
