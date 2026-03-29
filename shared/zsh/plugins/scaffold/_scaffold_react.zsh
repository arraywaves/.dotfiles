# ── Vite/React ────────────────────────────────────────────────────────────────
_scaffold_react() {
  echo "   Running create react-ts..."
  local tmp_name="${1}_tmp_scaffold"
  cd ..
  vp create vite "$tmp_name" --template react-ts
  mv "$tmp_name"/* "$1"/ 2>/dev/null
  mv "$tmp_name"/.[!.]* "$1"/ 2>/dev/null
  rmdir "$tmp_name" || echo "   Warning: could not remove $tmp_name"
  cd "$1"
  vp install
  vp add -D vitest @playwright/test happy-dom

  mkdir -p scripts tests/unit tests/e2e

  local DEV_SCRIPTS="$HOME/.dotfiles/shared/dev-scripts"
  if [[ -f "$DEV_SCRIPTS/check-todos.js" ]]; then
    cp "$DEV_SCRIPTS/check-todos.js" scripts/check-todos.js
  fi

  # Patch vite.config.ts to include vitest
  cat > vite.config.ts <<EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
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

  # Patch package.json scripts
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    pkg.scripts['test:e2e'] = 'playwright test';
    pkg.scripts['check:todos'] = 'node scripts/check-todos.js';
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
  "

  cat > .env.example <<EOF
VITE_APP_URL=http://localhost:5173
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
}
