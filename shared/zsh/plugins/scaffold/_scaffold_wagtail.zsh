# ── Wagtail ───────────────────────────────────────────────────────────────────
_scaffold_wagtail() {
  echo "   Setting up uv + ruff + Wagtail..."

  uv init --no-readme .
  uv python pin 3.14
  uv add wagtail ruff

  cat > pyproject.toml <<EOF
[project]
name = "$1"
version = "0.1.0"
description = ""
readme = "README.md"
requires-python = ">=3.14"
dependencies = [
    "django>=6,<6.1",
    "wagtail>=6",
    "gunicorn>=20",
]

[tool.ruff]
line-length = 79
indent-width = 4
target-version = "py314"
exclude = [
    "dist", "build", "public", "migrations",
    "*.md", "*.env",
]

[tool.ruff.lint]
select = [
    "E",
    "W",
    "F",
    "I",
    "UP",
    "B",
    "ANN",
    "RUF",
]
ignore = []

[tool.ruff.lint.isort]
known-first-party = ["$1"]
force-sort-within-sections = true

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "lf"
EOF

  uv run wagtail start app . || exit 1
  rm -f requirements.txt main.py Dockerfile
  _create_dockerfile_wagtail

  cat > .dockerignore <<'EOF'
.env
.env.local
.venv/
__pycache__/
*.pyc
db.sqlite3
*.log
.git/
EOF

  cat > .env.example <<EOF
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
EOF

  cat > .gitignore <<EOF
__pycache__/
*.pyc
*.pyo
.env
.env.local
db.sqlite3
media/
staticfiles/
.venv/
*.log

# LLMs
.claude/
EOF
}
