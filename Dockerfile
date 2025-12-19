# --- STAGE 1: build ---
FROM node:18-alpine AS builder

WORKDIR /app

# Cài dependencies nhanh hơn bằng cách copy package files trước
COPY package.json package-lock.json* ./ 
# Nếu dùng yarn thì copy yarn.lock thay
# COPY package.json yarn.lock ./

RUN npm ci --silent

# Copy toàn bộ source
COPY . .

# Nếu muốn truyền biến REACT_APP_* tại thời điểm build (CRA cần build-time)
# khai báo ARG trước khi chạy build và export thành ENV để npm build thấy
ARG REACT_APP_BACKEND_AI_TUTOR
ENV REACT_APP_BACKEND_AI_TUTOR=${REACT_APP_BACKEND_AI_TUTOR}
ARG NODE_ENV
ENV NODE_ENV=${NODE_ENV}

# Build ứng dụng (sẽ tạo thư mục build/ hoặc dist/ tùy script)
RUN echo "DEBUG ENV => $REACT_APP_BACKEND_AI_TUTOR"
RUN npm run build

# --- STAGE 2: serve bằng nginx ---
FROM nginx:stable-alpine AS production

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy config nginx (nếu cần override)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build output (CRA: build/, Vite: dist/)
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port (nginx listen mặc định là 80)
EXPOSE 80

# Healthcheck (tuỳ chọn)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -q --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]