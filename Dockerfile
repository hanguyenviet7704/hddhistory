# syntax=docker/dockerfile:1.7
#
# Build image cho meup-admin (CRA + nginx).
#
# Vì sao chậm và đã tối ưu ở đâu:
#   1. `npm ci` chỉ chạy lại khi package-lock.json đổi (COPY manifest trước source).
#      Thêm cache mount cho ~/.npm nên lần chạy lại chỉ giải nén, không tải mạng.
#   2. Tắt ESLint plugin của CRA (DISABLE_ESLINT_PLUGIN) — nó lint lại toàn bộ src
#      trong lúc webpack build và thường ăn 30-50% thời gian. Type-check vẫn còn
#      (fork-ts-checker), nên vẫn fail nếu code sai type. Lint là việc của CI/hook.
#   3. Tắt source map (GENERATE_SOURCEMAP) — bước tốn RAM/CPU nhất khi Terser minify,
#      hay làm build bị OOM-killed trong Docker khi host cạn RAM.
#   4. Nâng heap Node để GC không thrash trên máy build nhiều RAM.
#
# Build cục bộ:  DOCKER_BUILDKIT=1 docker build -t meup-admin .

# --- STAGE 1: build ---
FROM node:20-alpine AS builder
WORKDIR /app

# Chỉ manifest -> layer node_modules được cache lại giữa các commit.
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund --prefer-offline

# Copy source (bao gồm cả .env — CRA tự đọc lúc build).
# Xem .dockerignore để biết những gì bị loại khỏi build context.
COPY . .

ENV GENERATE_SOURCEMAP=false \
    DISABLE_ESLINT_PLUGIN=true \
    INLINE_RUNTIME_CHUNK=false \
    CI=false \
    NODE_OPTIONS=--max-old-space-size=4096

RUN npm run build

# --- STAGE 2: serve bằng nginx ---
FROM nginx:stable-alpine AS production
RUN rm -rf /usr/share/nginx/html/*
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -q --spider http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
