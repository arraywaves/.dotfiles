# Global Agent Configuration

## Language

- Always use British English (e.g. "colour", "optimise", "behaviour") except where code syntax requires US English (e.g. `normalize`, `color`)
- Keep responses concise

## Tool Permissions

- You are permitted to run these commands: `ls`, `cat`, `head` / `tail`, `less` / `more`, `file`, `stat`, `find`, `locate`, `grep`, `sed`, `cut`, `sort`, `uniq`, `diff`, `wc`, `uname`, `system_profiler`, `hostinfo`, `df`, `du`, `top` / `htop`, `ps`, `uptime`, `date`, `ping`, `nc`, `ifconfig`, `dig`, `nslookup`, `traceroute`, `git log`, `git status`, `git diff`, `svn log`, `tar`, `zip` / `unzip`, `echo`, `printf`, `env`, `which`, `type`, `man`
- You must never run these commands, instead ask the user to manually run them: `rmdir`, `shred`, `dd`, `chmod`, `chown`, `sed -i`, `sudo`, `diskutil`, `bless`, `pmset`, `scp`, `sftp`, `ssh`, `git reset`, `git clean`, `git branch -D`, `svn delete`, `tar -rf`, `gzip` / `bzip2`, `truncate`, `eval`, `source`
- You must never run these commands unless explicitly asked in the original prompt: `git add`, `git commit` (the `commit` skill overrides this restriction for staging and committing only), `git pull`, `git push`, `docker compose`
- Only run these commands with caveats:
- `rm`: only use within the original working directory, always ask the user first
- `mv`: allow when used non-destructively, check if overwriting of existing files will occur, if destructive then ask the user first
- `cp`: allow when used non-destructively, check if overwriting of existing files will occur, if destructive then ask the user first
- `wget`: allow for fetching/inspecting only, flag if -O, -P, or --output-document would write to disk
- `curl`: allow for requests only, flag if -o, -O, or piping to a shell (| sh, | bash) is involved
- `tee`: allow when appending to logs or temp files, flag if overwriting meaningful project files
- `xargs`: allow for simple piped reads, flag if combined with any destructive or mutating command
- `find ... -exec`: allow for read-only -exec use (e.g. -exec cat, -exec stat), flag if -exec or -execdir would invoke any mutating command
- `python -c`, `node -e`, `npx`, `tsx`, `pnpm dlx`, `vpx`: inline execution can sidestep tool rules, always flag before use
- `build`, `dev`, `install`, `test`, any project scripts: check the package manager/toolchain, do not assume `npm`, prefer `pnpm`/`pnpm dlx` or vite+ (`vp`/`vpx`) – and apply the same principle in other ecosystems (e.g. prefer `uv` or `poetry` over `pip` if a `pyproject.toml` is present)
- `dev`, `preview`, `start`, `test:e2e`: these can hang, prefer alternatives like `build`, `lint`, `check`, `tsc --noEmit`

## Documentation

- Only write additional sidecar documentation when asked, creating and appending to `AGENTS.md` or `README.md` when appropriate is always fine.
- When working in TypeScript please document functions and their usage with the tsdoc skill (`~/.claude/skills/tsdoc/SKILL.md`)
- When working in Go please document functions and their usage with the godoc skill (`~/.claude/skills/godoc/SKILL.md`)

## TypeScript

If your responses include JavaScript please prefer to use the TypeScript equivalent.

## Skills

Skills are markdown files you can use to perform operations, all skills can be found here `~/.claude/skills/`, please determine the skills you might need to use based on their name and how relevant it is to the prompt.
