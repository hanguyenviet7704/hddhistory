// Chỉ đăng ký 2 alias thật dùng trong seed-dev-user.ts (@base, src), KHÔNG lấy
// ánh xạ bắt-tất "*" trong tsconfig.json — ánh xạ đó ép mọi module trần (vd
// "mongodb") về node_modules/<tên> ở gốc bằng đường dẫn tường minh, khiến
// resolver load nhầm mã nguồn .ts nội bộ của gói mongodb (node_modules/mongodb/
// src/*.ts, không phải bản build sẵn ở lib/) rồi vỡ ở `BSON.onDemand` — tsconfig-
// paths/register bình thường (không tham số) đọc thẳng "paths" từ tsconfig.json
// nên dính lỗi này. Gọi register() tường minh ở đây để bỏ qua "*".
require('tsconfig-paths').register({
  baseUrl: require('path').join(__dirname, '..'),
  paths: {
    '@base/*': ['src/base/*'],
    '@utils/*': ['src/utils/*'],
    'src/*': ['src/*'],
  },
});
