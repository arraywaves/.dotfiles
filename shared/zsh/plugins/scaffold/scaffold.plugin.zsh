#!/usr/bin/env zsh
# Usage: scaffold <projectname> [--next|--ts|--react|--go|--cpp|--wagtail|--wagtail-pg] [-p <port>]

_SCAFFOLD_DIR="${0:A:h}"
source "$_SCAFFOLD_DIR/_scaffold_postgres.zsh"
source "$_SCAFFOLD_DIR/_scaffold_viteplus.zsh"
source "$_SCAFFOLD_DIR/_scaffold_ts.zsh"
source "$_SCAFFOLD_DIR/_scaffold_react.zsh"
source "$_SCAFFOLD_DIR/_scaffold_next.zsh"
source "$_SCAFFOLD_DIR/_scaffold_go.zsh"
source "$_SCAFFOLD_DIR/_scaffold_cpp.zsh"
source "$_SCAFFOLD_DIR/_scaffold_dockerfiles.zsh"
source "$_SCAFFOLD_DIR/_scaffold_wagtail.zsh"
source "$_SCAFFOLD_DIR/_scaffold_wagtail_pg.zsh"
source "$_SCAFFOLD_DIR/_scaffold_infisical.zsh"

scaffold() {
  # ── Paths ────────────────────────────────────────────────────────────────────
  local PROJECTS_DIR="$HOME/Projects"
  local DOTFILES_CLANG="$HOME/.dotfiles/shared/clang-format"
  local CADDYFILE="$HOME/.dotfiles/personal/caddy/Caddyfile"

  # ── Defaults ─────────────────────────────────────────────────────────────────
  local project_name=""
  local project_type=""
  local port=""

  # ── Default ports per type ───────────────────────────────────────────────────
  local default_port_ts=5173
  local default_port_react=3000
  local default_port_next=3000
  local default_port_wagtail=8000
  local default_port_go=8080

  # ── Arg parsing ──────────────────────────────────────────────────────────────
  if [[ $# -eq 0 ]]; then
    echo "Usage: scaffold <projectname> [--next|--ts|--react|--go|--cpp|--wagtail|--wagtail-pg] [-p <port>]"
    return 1
  fi

  project_name="$1"
  shift

  while [[ $# -gt 0 ]]; do
    case "$1" in

      --ts)             project_type="ts"               ;;
      --react)          project_type="react"			;;
      --next)           project_type="next"				;;
      --go)				project_type="go"				;;
      --cpp)			project_type="cpp"				;;
      --wagtail)        project_type="wagtail"			;;
      --wagtail-pg)     project_type="wagtail-pg"		;;
      -p)				shift; port="$1"				;;
      *)
        echo "Unknown option: $1"
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "$project_type" ]]; then
    echo "Error: no project type specified. Use --next, --ts, --react, --go, --cpp, --wagtail, or --wagtail-pg"
    return 1
  fi

  # ── Resolve port ─────────────────────────────────────────────────────────────
  if [[ -z "$port" ]]; then
    case "$project_type" in
      ts)				port=$default_port_ts			;;
      react)			port=$default_port_react    	;;
      next)				port=$default_port_next			;;
      wagtail)			port=$default_port_wagtail		;;
      wagtail-pg)		port=$default_port_wagtail		;;
      go)				port=$default_port_go			;;
      cpp)				port=""                    		;;
    esac
  fi

  # ── Create project dir ───────────────────────────────────────────────────────
  local project_dir="$PROJECTS_DIR/$project_name"

  if [[ -d "$project_dir" ]]; then
    echo "Error: $project_dir already exists"
    return 1
  fi

  mkdir -p "$project_dir"
  cd "$project_dir" || return 1

  echo "🏗  Scaffolding $project_type project: $project_name"

  _scaffold_readme "$project_name" "$project_type"

  case "$project_type" in
    ts)         _scaffold_ts       "$project_name" ;;
    react)      _scaffold_react      "$project_name" ;;
    next)       _scaffold_next       "$project_name" ;;
    go)         _scaffold_go         "$project_name" ;;
    cpp)        _scaffold_cpp        "$project_name" ;;
    wagtail)    _scaffold_wagtail    "$project_name" ;;
    wagtail-pg) _scaffold_wagtail_pg "$project_name" ;;
  esac

  # ── Copy vite+ config (TS projects) ──────────────────────────────────────────
  if [[ "$project_type" == "ts" || "$project_type" == "react" ]]; then
    _scaffold_viteplus_config
  fi

  # ── Infisical secret + Caddy regen (projects with a dev server) ──────────────
  if [[ -n "$port" ]]; then
    _scaffold_infisical_store "$project_name" "$project_type" "$port"
    _scaffold_caddy_regen
  fi

  echo "Initialising git"
  git init

  echo "Done! Now \`cd $project_dir\`"
  [[ -n "$port" ]] && echo "   → Dev server at: ${project_name}.localhost:$port"
}

# ── README ────────────────────────────────────────────────────────────────────
_scaffold_readme() {
  local name="$1"
  local type="$2"

  local scripts_section=""
  case "$type" in
    ts|react)
      scripts_section="## Scripts

| Command | Description |
|---|---|
| \`vp dev\` | Start dev server |
| \`vp build\` | Production build |
| \`vp preview\` | Preview production build |
| \`vp check\` | Format, lint & type-check |
| \`vp fmt\` | Format |
| \`vp lint\` | Lint |
| \`vp test\` | Run unit tests (Vitest) |
| \`vp run test:e2e\` | Run e2e tests (Playwright) |
| \`vp run check:todos\` | Check for TODO comments |

## Packages

"
      ;;
    next)
      scripts_section="## Scripts

| Command | Description |
|---|---|
| \`vp run dev\` | Start dev server |
| \`vp run build\` | Production build |
| \`vp run start\` | Preview production build |
| \`vp lint\` | Lint |
| \`vp test\` | Run unit tests (Vitest) |
| \`vp run test:e2e\` | Run e2e tests (Playwright) |
| \`vp run check:todos\` | Check for TODO comments |
| \`vp check\` | Lint, format and type-check |

## Packages

"
      ;;
    go)
      scripts_section="## Scripts

| Command | Description |
|---|---|
| \`go run ./cmd/$name\` | Run the app |
| \`go mod tidy\` | Install dependencies |
| \`go build ./...\` | Build |
| \`go test ./...\` | Run tests |

## Packages

"
      ;;
    wagtail)
      scripts_section="## Scripts

| Command | Description |
|---|---|
| \`uv run python manage.py makemigrations\` | Make migrations (after changes to models) |
| \`uv run python manage.py migrate\` | Run migrations |
| \`uv run python manage.py runserver\` | Start dev server |
| \`uv run ruff check .\` | Lint |
| \`uv run ruff format .\` | Format |

## Packages

"
      ;;
    wagtail-pg)
      scripts_section="## Database

Postgres runs via Docker Compose. The container is started automatically during scaffold,
but if you need to start it manually:

\`\`\`bash
docker compose up -d        # start Postgres
docker compose down         # stop (data persisted in volume)
docker compose down -v      # stop and delete volume
\`\`\`

Copy \`.env.example\` to \`.env\` (already done during scaffold) and adjust values if needed.

## Scripts

| Command | Description |
|---|---|
| \`uv run python manage.py makemigrations\` | Make migrations (after changes to models) |
| \`uv run python manage.py migrate\` | Run migrations |
| \`uv run python manage.py runserver\` | Start dev server |
| \`uv run ruff check .\` | Lint |
| \`uv run ruff format .\` | Format |
| \`sh scripts/db-backup.sh\` | Backup the database |

## Packages

"
      ;;
    cpp)
      scripts_section="## Scripts

| Command | Description |
|---|---|
| \`cmake -B build\` | Configure |
| \`cmake --build build\` | Build |
| \`./build/$name\` | Run |

## Packages

"
      ;;
  esac

  cat > README.md <<EOF
# $name

## Overview

## Getting Started

\`\`\`bash
# clone and install
\`\`\`

$scripts_section
## Notes

EOF
}

