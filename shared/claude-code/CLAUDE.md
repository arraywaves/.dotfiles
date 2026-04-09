# Global Claude Code Configuration

## Language

Always use British English in all responses, comments, and documentation. This includes spelling (e.g. "colour", "optimise", "behaviour", "serialise") and vocabulary. The exception is where coding syntax requires American English (e.g. `.normalize()`, `color:` in CSS, API field names, library identifiers). Keep responses concise where possible to prevent excess token usage.

## Using Tools

Of the following tools: 
- You are always permitted to use the "Allowed Tools" without asking, these are generally non-destructive.
- You must always ask and perform a dry-run before using any "Destructive Tools", always double-check their use and perform a backup of any critical data. If the total data at risk (such as a directory being removed) exceeds 20MB then do not use the tool and inform the user they must perform it manually before continuing. 
- You must never use the "No Access Tools" unless explicitly asked by the user in the original prompt.

### Allowed Tools:
`ls`, `cat`, `head` / `tail`, `less` / `more`, `file`, `stat`, `find`, `locate`, `grep`, `sed`, `cut`, `sort`, `uniq`, `diff`, `wc`, `uname`, `system_profiler`, `hostinfo`, `df`, `du`, `top` / `htop`, `ps`, `uptime`, `date`, `ping`, `nc`, `ifconfig`, `dig`, `nslookup`, `traceroute`, `git log`, `git status`, `git diff`, `svn log`, `tar`, `zip` / `unzip`, `echo`, `printf`, `env`, `which`, `type`, `man`

### Destructive Tools:
`rmdir`, `shred`, `dd`, `chmod`, `chown`, `sed -i`, `sudo`, `diskutil`, `bless`, `pmset`, `scp`, `sftp`, `ssh`, `git reset`, `git clean`, `git branch -D`, `svn delete`, `tar -rf`, `gzip` / `bzip2`, `truncate`, `eval`, `source`

### Use with Caveats (the pattern is `tool`: "caveat"):
- `rm`: "only use within the original cwd, and always ask the user first"
- `mv`: "allow when used non-destructively, check if overwriting of existing files will occur, if destructive then ask the user first"
- `cp`: "allow when used non-destructively, check if overwriting of existing files will occur, if destructive then ask the user first"
- `wget`: "allow for fetching/inspecting only, flag if -O, -P, or --output-document would write to disk"
- `curl`: "allow for requests only, flag if -o, -O, or piping to a shell (| sh, | bash) is involved"
- `tee`: "allow when appending to logs or temp files, flag if overwriting meaningful project files"
- `xargs`: "allow for simple piped reads, flag if combined with any destructive or mutating command"
- `find ... -exec`: "allow for read-only -exec use (e.g. -exec cat, -exec stat), flag if -exec or -execdir would invoke any mutating command"
- `python -c`, `node -e`, `npx`, `tsx`, `pnpm dlx`, `vpx`: "inline execution can sidestep tool rules, always flag before use"

### No Access Tools:
- Never run `git add`, `git commit`, `git pull`, or `git push`. Stage nothing, commit nothing, push nothing.
- The developer handles all version control manually.

## Package Manager

- Before running any scripts (`build`, `dev`, `install`, `test`, etc.), check the scripts in `package.json` or the relevant dependencies file and check which package manager or toolchain the project uses rather than defaulting to a standard. 
- In TypeScript projects look for lock-files: `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb` or `package-lock.json`.  Vite+ (`vp run`) is one I prefer to used in my projects, the other is pnpm. 
- Apply the same principle in other ecosystems (e.g. prefer `uv` or `poetry` over `pip` if a `pyproject.toml` is present).

## Local Development Server

Avoid running scripts that could hang on success like `dev`, `preview`, `start` etc. prefer to use tools like `build`, `lint`, `check`, `vpx tsc --noEmit`, `type-check` if it exists in `./package.json`, etc. If dev is required then please prompt the user and await their response.

## Documentation

Only write additional sidecar documentation when asked, creating and appending to `AGENTS.md` or `README.md` when appropriate is always fine. 

### Documenting Functions in TypeScript

When working in TypeScript please document functions and their usage with the jsdoc-ts skill (`~/.dotfiles/shared/claude-code/skills/jsdoc-ts/SKILL.md`)

### Documenting Functions in Go

When working in Go please document functions and their usage with the godoc skill (`~/.dotfiles/shared/claude-code/skills/godoc/SKILL.md`)

## About the User

You are assisting a UK-based Creative Developer with an interest in Design Engineering, Computer Science and building Full-Stack Apps. 

## TypeScript

If your responses include JavaScript please prefer to use the TypeScript equivalent.

## Project Memory

- Never create or write to `CLAUDE.md` in any project directory.
- When you need to persist project-specific memory, notes, or configuration, always use `AGENTS.md` instead. Read from `AGENTS.md` at the start of tasks the same way you would normally read `CLAUDE.md`.
- If the user asks you to "update memory", "save this", or "remember this for the project", write it to `AGENTS.md`.