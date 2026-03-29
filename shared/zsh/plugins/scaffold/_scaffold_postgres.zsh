# ── Postgres (Docker) ─────────────────────────────────────────────────────────
# Writes a standard docker-compose.yml with a single Postgres service named `db`.
#
# Usage: _scaffold_write_docker_compose_pg <db_name>
#   db_name  Value for POSTGRES_DB (typically the project name)
_scaffold_write_docker_compose_pg() {
  local db_name="$1"

  cat > docker-compose.yml <<EOF
services:
  db:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_DB: $db_name
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  postgres_data:
EOF

  echo "   → Created docker-compose.yml"
}


# Handles port conflict detection, container start, readiness wait, and an
# optional post-start command (e.g. migrations). Requires a docker-compose.yml
# with a service named `db` already present in the current directory.
#
# Usage: _scaffold_postgres_start [post_start_cmd]
#   post_start_cmd  Command to run once Postgres is ready (optional)
_scaffold_postgres_start() {
  local post_start_cmd="${1:-}"

  if ! command -v docker &>/dev/null; then
    echo "   Warning: docker not found — start Postgres manually"
    [[ -n "$post_start_cmd" ]] && echo "   Then run: $post_start_cmd"
    return
  fi

  local blocking_container
  blocking_container=$(docker ps --format "{{.Names}}" --filter "publish=5432" | head -1)
  if [[ -n "$blocking_container" ]]; then
    echo "   ⚠ Port 5432 is in use by container: $blocking_container"
    echo -n "   Stop it and continue? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "   → Stopping $blocking_container..."
      docker stop "$blocking_container"
      sleep 2
    else
      echo "   Skipping Postgres start — stop the container manually then run:"
      echo "     docker compose up -d"
      [[ -n "$post_start_cmd" ]] && echo "     $post_start_cmd"
      return
    fi
  fi

  echo "   → Starting Postgres container..."
  docker compose up -d
  if ! docker compose ps | grep -q "0.0.0.0:5432"; then
    echo "   Warning: port 5432 may not be published — check with: docker compose ps"
  fi

  echo "   → Waiting for Postgres to be ready..."
  local retries=15
  until docker compose exec db pg_isready -U postgres -q 2>/dev/null || [[ $retries -eq 0 ]]; do
    sleep 1
    (( retries-- ))
  done

  if [[ $retries -eq 0 ]]; then
    echo "   Warning: Postgres did not become ready in time"
    [[ -n "$post_start_cmd" ]] && echo "   Run manually: $post_start_cmd"
  elif [[ -n "$post_start_cmd" ]]; then
    echo "   → Running: $post_start_cmd"
    eval "$post_start_cmd"
  fi
}
