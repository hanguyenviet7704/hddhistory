module.exports = {
  apps: [
    {
      name: 'hddhistory-api',
      script: './dist/main.js',
      instances: 1, // Chạy tối đa số core CPU (Cluster Mode)
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      out_file: '/app/logs/hddhistory-api-out.log',
      error_file: '/app/logs/hddhistory-api-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true
    },
  ],
};