# --- STAGE 1: build ---
FROM node:18-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./ 
RUN npm ci --silent

# Copy toàn bộ source (bao gồm cả .env)
COPY . .

# Tắt source map: bước tốn RAM nhất khi Terser minify, hay làm build bị
# OOM-killed trong Docker khi host cạn RAM.
ENV GENERATE_SOURCEMAP=false

# Build - CRA sẽ TỰ ĐỘNG đọc file .env
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