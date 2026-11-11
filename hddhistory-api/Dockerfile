# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE=node:18.20.8-alpine

# ---------------------------------------------------------------------------
# Stage 1: full dependencies (dev + prod) -> chỉ dùng để build TypeScript
# ---------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --no-audit --no-fund

# ---------------------------------------------------------------------------
# Stage 2: production dependencies (chạy song song với stage build)
# ---------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS prod-deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --omit=dev --no-audit --no-fund

# ---------------------------------------------------------------------------
# Stage 3: build
# ---------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json tsconfig*.json nest-cli.json ./
COPY src ./src
# Node 18 mặc định trần old-space ~2GB, mà biên dịch cây này chạm 2,19GB ở đỉnh
# (đo 2026-09-17) — build chết bằng "Ineffective mark-compacts near heap limit",
# exit 134, và bước push tag sau đó báo "No such image" chỉ là hệ quả.
#
# Chỉ đặt ở stage build: stage runtime chạy dist/ đã biên dịch, không cần gì thêm.
ENV NODE_OPTIONS=--max-old-space-size=4096
RUN npm run build \
    && cp -r src/base/i18n dist/base/i18n

# ---------------------------------------------------------------------------
# Stage 4: runtime
# ---------------------------------------------------------------------------
FROM ${NODE_IMAGE} AS production

# Layer hệ thống: đặt trước mọi COPY để luôn hit cache
RUN apk add --no-cache ffmpeg \
    && addgroup -S appgroup && adduser -S appuser -G appgroup \
    && npm install -g pm2 --no-audit --no-fund \
    && npm cache clean --force

WORKDIR /app
RUN mkdir -p /app/logs /app/public && chown -R appuser:appgroup /app

# node_modules production-only (không còn devDependencies)
COPY --chown=appuser:appgroup --from=prod-deps /app/node_modules ./node_modules

# Chỉ những file thực sự cần lúc runtime
COPY --chown=appuser:appgroup package.json ecosystem.config.js ./
COPY --chown=appuser:appgroup scripts ./scripts
COPY --chown=appuser:appgroup import-templates ./import-templates
COPY --chown=appuser:appgroup --from=build /app/dist ./dist

ENV NODE_ENV=production
USER appuser

CMD ["pm2-runtime", "ecosystem.config.js"]
