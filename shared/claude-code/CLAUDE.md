# Global Claude Code Configuration

## Language

Always use British English in all responses, comments, and documentation. This includes spelling (e.g. "colour", "optimise", "behaviour", "serialise") and vocabulary. The exception is where coding syntax requires American English (e.g. `.normalize()`, `color:` in CSS, API field names, library identifiers). Keep responses concise where possible to prevent excess token usage.

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

## Git
- Never run git commands. Stage nothing, commit nothing, push nothing.
- The developer handles all version control manually.

## Project Memory

- Never create or write to `CLAUDE.md` in any project directory.
- When you need to persist project-specific memory, notes, or configuration, always use `AGENTS.md` instead. Read from `AGENTS.md` at the start of tasks the same way you would normally read `CLAUDE.md`.
- If the user asks you to "update memory", "save this", or "remember this for the project", write it to `AGENTS.md`.