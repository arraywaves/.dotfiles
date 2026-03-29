# Infisical secret storage + Caddyfile regen for the scaffold plugin

_SCAFFOLD_INFISICAL_DOMAIN="$INFISICAL_API_URL"
_SCAFFOLD_INFISICAL_PROJECT_ID="$INFISICAL_PROJECT_ID"
_SCAFFOLD_INFISICAL_ENV="$INFISICAL_ENV"

# Usage: _scaffold_infisical_store <name> <type> <port>
_scaffold_infisical_store() {
  local name="$1" type="$2" port="$3"

  if ! command -v infisical &>/dev/null; then
    echo "Warning: infisical not found — skipping secret storage"
    return
  fi

  # wagtail-pg → WAGTAIL_PG
  local type_key="${${(U)type}//-/_}"
  local rand_id=$(( RANDOM % 9000000 + 1000000 ))
  local secret_key="${type_key}_${rand_id}"
  local secret_value="${name}:${port}"

  if infisical secrets set "${secret_key}=${secret_value}" \
    --domain="$_SCAFFOLD_INFISICAL_DOMAIN" \
    --projectId="$_SCAFFOLD_INFISICAL_PROJECT_ID" \
    --env="$_SCAFFOLD_INFISICAL_ENV" \
    --path=/caddy \
    2>/dev/null; then
    echo "   → Stored project secret: $secret_key"
  else
    echo "Warning: failed to store secret in Infisical (Caddyfile regen may be incomplete)"
  fi
}

# Rewrite Caddyfile from all stored scaffold project secrets
_scaffold_caddy_regen() {
  local caddyfile="${CADDYFILE:-$HOME/.dotfiles/personal/caddy/Caddyfile}"

  if ! command -v infisical &>/dev/null; then
    echo "Warning: infisical not found — skipping Caddyfile regen"
    return
  fi

  local secrets
  secrets=$(infisical export \
    --domain="$_SCAFFOLD_INFISICAL_DOMAIN" \
    --projectId="$_SCAFFOLD_INFISICAL_PROJECT_ID" \
    --env="$_SCAFFOLD_INFISICAL_ENV" \
    --path=/caddy \
    --format=dotenv \
    2>/dev/null)

  if [[ -z "$secrets" ]]; then
    echo "Warning: could not fetch secrets from Infisical"
    return
  fi

  local caddy_content="" entry_count=0

  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    local raw_value="${line#*=}"
    local value="${raw_value//\"/}"
    value="${value//\'/}"
    local proj_name="${value%%:*}"
    local proj_port="${value##*:}"
    if [[ -n "$proj_name" && "$proj_port" =~ ^[0-9]+$ ]]; then
      caddy_content+="${proj_name}.localhost {\n  reverse_proxy localhost:${proj_port}\n}\n"
      (( entry_count++ ))
    fi
  done <<< "$secrets"

  if [[ entry_count -eq 0 ]]; then
    echo "   → No project secrets found — Caddyfile not updated"
    return
  fi

  mkdir -p "$(dirname "$caddyfile")"
  printf "%b" "$caddy_content" > "$caddyfile" \
    || { echo "   Error: failed to write Caddyfile" >&2; return 1; }
  echo "   → Caddyfile rewritten ($entry_count entries)"

  if pgrep -x caddy > /dev/null; then
    if caddy reload --config "$caddyfile" 2>&1; then
      echo "   → Caddy reloaded"
    else
      echo "   Warning: Caddy reload failed — config written but not active"
    fi
  fi
}
