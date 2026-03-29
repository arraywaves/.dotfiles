# ── Next.js ───────────────────────────────────────────────────────────────────
_scaffold_next() {
  echo "   Running create-next-app..."
  local tmp_name="${1}_tmp_scaffold"
  cd ..

  vp create https://github.com/$GIT_USER/template-next --directory "$tmp_name"
  mv "$tmp_name"/* "$1"/ 2>/dev/null
  mv "$tmp_name"/.[!.]* "$1"/ 2>/dev/null
  rmdir "$tmp_name" || echo "   Warning: could not remove $tmp_name"
  cd "$1"

  vp install

  local DEV_SCRIPTS="$HOME/.dotfiles/shared/dev-scripts"
  if [[ -f "$DEV_SCRIPTS/check-todos.js" ]]; then
    cp "$DEV_SCRIPTS/check-todos.js" scripts/check-todos.js
  fi

  if ! command -v claude &> /dev/null; then
    echo "claude CLI not found, skipping auto-fix"
    vp lint
  else
    MAX=3
    i=0
    while [ $i -lt $MAX ]; do
      vp lint 2>&1
      [ $? -eq 0 ] && break
      vp lint 2>&1 | claude -p "fix all lint errors and warnings" --allowedTools Read,Edit
      i=$((i + 1))
      done
  fi
}
