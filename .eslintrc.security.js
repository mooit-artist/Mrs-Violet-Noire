module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true
  },
  extends: [
    'eslint:recommended',
    'plugin:security/recommended'
  ],
  plugins: [
    'security'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    // Security-focused rules
    'security/detect-object-injection': 'error',
    'security/detect-non-literal-fs-filename': 'error',
    'security/detect-eval-with-expression': 'error',
    'security/detect-no-csrf-before-method-override': 'error',
    'security/detect-buffer-noassert': 'error',
    'security/detect-child-process': 'error',
    'security/detect-disable-mustache-escape': 'error',
    'security/detect-new-buffer': 'error',
    'security/detect-unsafe-regex': 'error',

    // General security practices
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-script-url': 'error',
    'no-new-func': 'error',

    // XSS Prevention
    'no-innerHTML': 'off', // Custom rule handled elsewhere

    // Input validation
    'prefer-regex-literals': 'error',

    // Error handling
    'no-empty-catch': 'error',
    'no-throw-literal': 'error'
  },
  overrides: [
    {
      files: ['*.html'],
      rules: {
        // HTML-specific security rules can be added here
      }
    },
    {
      files: ['scripts/*.sh'],
      rules: {
        // Shell script rules would go here if using a shell linter
      }
    }
  ]
};
