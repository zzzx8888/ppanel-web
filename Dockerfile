# Stage 1: Install dependencies
FROM oven/bun:latest AS deps
WORKDIR /app

# Copy root workspace files
COPY package.json bun.lock ./
COPY packages ./packages
COPY apps/admin/package.json ./apps/admin/

# Install dependencies
RUN bun install

# Stage 2: Build the application
FROM deps AS builder
WORKDIR /app
COPY . .
# Build the admin app
RUN bun run build --filter=admin-web

# Stage 3: Production server
FROM oven/bun:latest AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy only the necessary files from builder
COPY --from=builder /app/apps/admin/.next/standalone ./
COPY --from=builder /app/apps/admin/.next/static ./apps/admin/.next/static
COPY --from=builder /app/apps/admin/public ./apps/admin/public

EXPOSE 3000

CMD ["bun", "apps/admin/server.js"]
