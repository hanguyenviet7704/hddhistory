module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint', 'import'],
  extends: [
    'plugin:@typescript-eslint/recommended',
    'prettier', // nếu có dùng prettier
  ],
  rules: {
    // Import: thư viện trước, file trong project sau
    'import/order': [
      'error',
      {
        groups: [
          'builtin',   // Node.js "fs", "path"
          'external',  // Thư viện từ node_modules
          'internal',  // Module nội bộ (alias từ tsconfig)
          ['parent', 'sibling', 'index'], // ../, ./, index
          'object',
          'type',
        ],
        'newlines-between': 'always',
        alphabetize: { order: 'asc', caseInsensitive: true },
      },
    ],

    // Cảnh báo import thừa
    'no-duplicate-imports': 'error',

    // Cảnh báo biến không dùng (cho TypeScript)
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': [
      'warn',
      {
        argsIgnorePattern: '^_', // cho phép dùng _ để bỏ qua
        varsIgnorePattern: '^_',
      },
    ],
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/no-require-imports': 'off',

    'no-empty': 'error',

  },
  settings: {
    'import/internal-regex': '^@base/|^@utils/|^src/',
    'import/resolver': {
      typescript: {
        alwaysTryTypes: true,
        project: './tsconfig.json',
      },
    },
  },
};
