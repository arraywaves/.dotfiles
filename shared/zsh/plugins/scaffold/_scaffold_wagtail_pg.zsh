# ── Wagtail + PostgreSQL ───────────────────────────────────────────────────────
_scaffold_wagtail_pg() {
  echo "   Setting up uv + ruff + Wagtail + PostgreSQL (Docker)..."

  uv init --no-readme .
  uv python pin 3.14
  uv add wagtail ruff 'psycopg[binary]' dj-database-url python-dotenv

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
    "psycopg[binary]>=3",
    "dj-database-url>=2",
    "python-dotenv>=1",
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
  _create_dockerfile_wagtail_pg

  cat > .dockerignore <<'EOF'
.env
.env.local
.venv/
__pycache__/
*.pyc
*.log
.git/
EOF

  # Patch settings/base.py to use dj-database-url
  uv run python3 - <<'PYEOF'
import re, sys

path = "app/settings/base.py"
content = open(path).read()

if "import dj_database_url" not in content:
    patched = re.sub(r'^import os$', 'import os\nimport dj_database_url', content, count=1, flags=re.MULTILINE)
    content = patched if patched != content else "import dj_database_url\n" + content

db_new = (
    "DATABASES = {\n"
    '    "default": dj_database_url.config(\n'
    '        env="DATABASE_URL",\n'
    '        conn_max_age=600,\n'
    "    )\n"
    "}"
)
content = re.sub(
    r"DATABASES\s*=\s*\{[^{}]*\{[^{}]*\}[^{}]*\}",
    db_new,
    content,
    flags=re.DOTALL,
)
if '"django.contrib.postgres"' not in content:
    content = content.replace(
        '"django.contrib.staticfiles",',
        '"django.contrib.staticfiles",\n    "django.contrib.postgres",'
    )

open(path, "w").write(content)
print("   → Patched app/settings/base.py")
PYEOF

  uv run python3 - <<'PYEOF'
path = "manage.py"
content = open(path).read()
if "load_dotenv" not in content:
    content = content.replace(
        "import os\nimport sys",
        "import os\nimport sys\nfrom dotenv import load_dotenv\nload_dotenv()"
    )
    open(path, "w").write(content)
    print("   → Patched manage.py to load .env")
PYEOF

  _scaffold_write_docker_compose_pg "$1"

  cat > .env.example <<EOF
DEBUG=True
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=postgres://postgres:postgres@localhost:5432/$1
EOF

  local secret_key
  secret_key=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")

  cat > .env <<EOF
DEBUG=True
SECRET_KEY=$secret_key
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=postgres://postgres:postgres@localhost:5432/$1
EOF

  cat > .gitignore <<EOF
__pycache__/
*.pyc
*.pyo
.env
.env.local
media/
staticfiles/
.venv/
*.log
.backups/

# LLMs
.claude/
EOF

  mkdir -p scripts
  cat > scripts/db-backup.sh <<EOF
#!/bin/sh

CONTAINER="$1-db-1"
DB_USER="postgres"
DB_NAME="$1"
BACKUP_DIR="\$(cd "\$(dirname "\$0")/.." && pwd)/.backups"
[ -z "\$BACKUP_DIR" ] && { echo "Error: could not resolve BACKUP_DIR" >&2; exit 1; }
TIMESTAMP=\$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="\$BACKUP_DIR/\${DB_NAME}_\${TIMESTAMP}.sql"

mkdir -p "\$BACKUP_DIR" || exit 1

if ! docker ps --format "{{.Names}}" | grep -q "^\${CONTAINER}\$"; then
  echo "Error: container '\${CONTAINER}' is not running" >&2
  exit 1
fi

docker exec "\$CONTAINER" pg_dump -U "\$DB_USER" "\$DB_NAME" > "\$BACKUP_FILE" \
  || { rm -f "\$BACKUP_FILE"; exit 1; }

echo "Backup saved to \$BACKUP_FILE"

# Keep only the 10 most recent backups
ls -t "\$BACKUP_DIR"/*.sql 2>/dev/null | tail -n +11 | xargs rm -f
EOF
  chmod +x scripts/db-backup.sh
  echo "   → Created scripts/db-backup.sh"

  _scaffold_postgres_start "uv run python manage.py migrate"
}
