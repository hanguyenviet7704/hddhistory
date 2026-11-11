import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  experimental: {
    // Tạo bài học từ PDF gửi tệp (tối đa 20MB, như app) qua server action.
    // Mặc định server action chỉ nhận 1MB và proxy chỉ đệm 10MB — PDF lớn hơn
    // sẽ hỏng giữa chừng. Thêm 1MB cho phần đầu/biên của multipart.
    serverActions: { bodySizeLimit: '21mb' },
    proxyClientMaxBodySize: '21mb',
  },
};

export default nextConfig;
