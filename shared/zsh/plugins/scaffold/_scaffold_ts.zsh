# ── Vanilla TS ────────────────────────────────────────────────────────────────
_scaffold_ts() {
  echo "   Setting up Vanilla TS + Vite..."
  mkdir -p src scripts tests/unit tests/e2e

  local DEV_SCRIPTS="$HOME/.dotfiles/shared/dev-scripts"
  if [[ -f "$DEV_SCRIPTS/check-todos.js" ]]; then
    cp "$DEV_SCRIPTS/check-todos.js" scripts/check-todos.js
  else
    echo "   Warning: check-todos.js not found at $DEV_SCRIPTS"
  fi

  cat > package.json <<EOF
{
  "name": "$1",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test:e2e": "playwright test",
    "check:todos": "node scripts/check-todos.js"
  },
  "devDependencies": {
    "typescript": "^5",
    "vite": "^5",
    "vitest": "^1",
    "@playwright/test": "^1",
    "oxlint": "latest"
  }
}
EOF

  cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src", "tests"]
}
EOF

  cat > vite.config.ts <<EOF
import { defineConfig } from 'vite'

export default defineConfig({
  test: {
    environment: 'happy-dom',
  },
})
EOF

  cat > playwright.config.ts <<EOF
import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  use: {
    baseURL: 'http://localhost:4173',
  },
})
EOF

  cat > src/index.ts <<EOF
const main = (): void => {
  console.log('$1')
}

main()
EOF

  cat > .env.example <<EOF
LOG_LEVEL=silly
APP_ENV=development
EOF

  cat > .gitignore <<EOF
node_modules/
dist/
.env
.env.local
*.log
/test-results/
/playwright-report/
/playwright/.cache/

# LLMs
.claude/
EOF

  vp install
}
