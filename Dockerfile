# Stage 1: Install dependencies
FROM oven/bun:latest AS deps
WORKDIR /app

# 1. 拷贝 Monorepo 根目录配置
COPY package.json bun.lock ./
COPY turbo.json ./

# 2. 拷贝依赖定义（递归拷贝所有 package.json）
COPY packages ./packages
COPY apps/admin/package.json ./apps/admin/
COPY apps/user/package.json ./apps/user/

# 3. 拷贝脚本目录（解决 ./scripts/prepare.sh 找不到的问题）
COPY scripts ./scripts
RUN chmod +x scripts/*.sh

# 4. 安装依赖（跳过 prepare 脚本以防在容器内报错）
RUN bun install --ignore-scripts

# Stage 2: Build the application
FROM deps AS builder
WORKDIR /app
COPY . .
# 执行构建
RUN bun run build --filter=admin-web

# Stage 3: Production server
FROM oven/bun:latest AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# 拷贝构建产物
COPY --from=builder /app/apps/admin/.next/standalone ./
COPY --from=builder /app/apps/admin/.next/static ./apps/admin/.next/static
COPY --from=builder /app/apps/admin/public ./apps/admin/public

EXPOSE 3000

CMD ["bun", "apps/admin/server.js"]
