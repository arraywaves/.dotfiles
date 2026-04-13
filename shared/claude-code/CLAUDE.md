## Memory

- Never create or write to `CLAUDE.md` in any project directory
- When you need to persist project-specific memory, notes, or configuration, always use `AGENTS.md` instead
- Read from `AGENTS.md` at the start of tasks the same way you would normally read `CLAUDE.md`
- If the prompt asks you to "update memory" or "save this", write context to `AGENTS.md`
- Only write sidecar documentation when prompted or when an agent deems it necessary, create and append new information to `AGENTS.md` and/or `README.md` if critical changes have been made

## Language

- Always use British English (e.g. "colour", "optimise", "behaviour") except where code syntax requires US English (e.g. `normalize`, `color`)
- Keep responses concise
- Prefer TypeScript to JavaScript
- Prefer tabs to spaces (4-spaces wide)

## Permissions

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
- Agents (`~/.claude/agents/`) may override any of the permissions listed above from the tools listed in the agent's `tools` property.

## Agentic Orchestration

Sub-agents at `~/.claude/agents/` handle specialised work. Delegate when a task clearly falls into a single domain; work directly for cross-cutting or simple tasks.

| Intent                                                    | Agent              | Examples                                                     |
| --------------------------------------------------------- | ------------------ | ------------------------------------------------------------ |
| Creating skills, agents, or MCP servers                   | `toolsmith`        | Build a new skill, create an agent, scaffold an MCP server   |
| TSDoc, godoc, or Python docstrings                        | `technical-writer` | Document a TypeScript module, add godoc, write docstrings    |
| System design, architecture decisions                     | `architect`        | Design a data model, choose a framework, plan a migration    |
| Application code, bug fixes, refactoring, commits         | `code-impl`        | Implement a feature, fix a bug, refactor a module            |
| Design tokens, component libraries, Figma plugins, a11y   | `design-engineer`  | Configure Style Dictionary, build Lit components, audit a11y |
| Write new Playwright / Vitest tests                       | `test-writer`      | Write E2E tests, add unit tests, debug a failing test        |
| Run existing test suites                                  | `test-runner`      | Run tests, report results, check coverage                    |
| Pre-deployment validation (build, lint, type-check, a11y) | `pre-deploy`       | Check types, run lint, validate build, run a11y scan         |
| Deploy to Railway, manage env/variables                   | `deploy`           | Deploy a service, set env vars, check logs                   |
| Image optimisation, media processing                      | `media-ops`        | Batch-compress images for web                                |
| Frontend UI, visual design, generative art, presentations | `ai-creative`      | Build a landing page, create a slide deck                    |
