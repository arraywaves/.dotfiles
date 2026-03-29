# ── Go ────────────────────────────────────────────────────────────────────────
_scaffold_go() {
  echo "   Setting up Go module..."
  go mod init "github.com/$GIT_USER/$1"
  mkdir -p cmd/"$1" internal

  cat > cmd/"$1"/main.go <<EOF
package main

import "fmt"

func main() {
	fmt.Println("$1")
}
EOF

  cat > .env.example <<EOF
APP_ENV=development
PORT=8080
LOG_LEVEL=silly
EOF

  cat > .gitignore <<EOF
# Binaries
$1
*.exe

# Build
dist/

# Env
.env
.env.local

# Go workspace
go.work

# LLMs
.claude/
EOF
}
