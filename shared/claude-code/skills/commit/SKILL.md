---
name: commit
description: Writes Git commit messages and commits staged/unstaged changes. Use when the user wants to commit — triggers on /commit, "commit my changes", "write a commit message", "stage and commit", or similar requests. Inspects git status and diff, drafts a well-formed commit message, asks the user to confirm or edit before committing. Never pushes. Overrides the global restriction on git add/git commit.
allowed-tools: Bash, AskUserQuestion
---

# Commit

## Workflow

### 1. Inspect changes

Run these in parallel:

```bash
git status
git diff HEAD
git log --oneline -5
```

`git diff HEAD` covers both staged and unstaged changes. `git log` reveals the repo's existing commit style (Conventional Commits, plain imperative, etc.).

### 2. Draft the commit message

Match the existing log style. If no clear pattern, use plain imperative.

**Rules:**
- Subject: imperative mood, ≤72 chars, no trailing period
- Body: only for non-trivial changes — explain *why*, not *what*
- Always append the trailer:
  ```
  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```

**Conventional Commits** (use if the log shows this pattern):
```
<type>(<scope>): <subject>

<optional body>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```
Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`

### 3. Confirm with the user

Use `AskUserQuestion` to present the proposed message and offer:
- **Approve** — commit as written
- **Edit** — prompt the user for a revised message, then commit with that
- **Cancel** — stop, make no changes

### 4. Commit

If approved or edited:

1. Stage specific files by name — never `git add -A` or `git add .`
   - Use `git status` output to identify which files to stage
   - If the user specified files, stage only those
2. Commit using a HEREDOC to preserve formatting:
   ```bash
   git commit -m "$(cat <<'EOF'
   <subject>

   <body if any>

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

**Never run `git push`.**
