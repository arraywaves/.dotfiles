---
name: readme
description: >
  Generate or update a README.md in the current working directory using a structured interview workflow.
  Supports creating from scratch or converting/improving an existing README. Handles badge generation
  from a GitHub repo slug, licence selection, package manager detection, and conditional sections
  (Contributing, Screenshots, Deployment, Tests). Use when the user asks to: create a readme, generate
  a readme, update/fix/improve the readme, add docs to a project, or when setting up a new project
  with missing documentation.
---

# README Skill

Read `references/template.md` for the canonical section structure and format.
Read `references/badges.md` when generating or explaining badges.
Read `references/licences.md` when discussing licence options.

## Workflow

### 1. Assess the situation

Check whether a `README.md` exists in the current working directory.

- **Exists** → Read it. Extract all usable information. Note gaps. Tell the user what you found and what's missing before asking questions.
- **Doesn't exist** → Start fresh. Announce you'll interview them section by section.

### 2. Detect the package manager

Check for lockfiles and config in this order — stop at the first match:

| File                | Package manager | Install cmd    | Dev cmd       |
| ------------------- | --------------- | -------------- | ------------- |
| `pnpm-lock.yaml`    | vite+ (vp)      | `vp install`   | `vp run dev`  |
| `pnpm-lock.yaml`    | pnpm            | `pnpm install` | `pnpm dev`    |
| `bun.lockb`         | bun             | `bun install`  | `bun dev`     |
| `yarn.lock`         | yarn            | `yarn`         | `yarn dev`    |
| `package-lock.json` | npm             | `npm install`  | `npm run dev` |

If no lockfile is found but `package.json` exists, ask the user. Present options in preference order: **vite+ (vp) → pnpm → bun → npm**. Never default to npm if another lockfile is present.

If a `vite.config.*` is present and no explicit dev script override exists, the dev command may be `vp dev` (Vite+). Check `package.json` scripts for `"dev"` to confirm the exact command.

### 3. Interview section by section

Work through these topics in order. Group related questions together — ask 2–3 at a time where they're naturally related. Tell the user they can skip any section if the info isn't ready yet.

**Core (always ask if not clear from code):**

- Project name and one-line description
- GitHub repo slug (`username/repo`) — can be a planned slug, not yet created
- Is this open-source? Are contributions welcome?
- Licence preference — if unspecified, offer the four options from `references/licences.md` with one-line summaries

**Tech stack:** Scan `package.json`, config files, and directory structure first. Present what you found and ask the user to confirm or correct, rather than asking from scratch.

**Overview:** Ask about what the project does, the technical decisions behind it, and any known challenges or future plans. A few sentences each is fine.

**Getting Started:** Confirm env vars by checking for `.env.example` or `.env.local`. Ask about Node.js version requirement if not in `package.json` `engines` field.

**Optional sections (ask once, skip gracefully if not ready):**

- Screenshots / demo URL
- Deployment platform and any gotchas
- Test commands (check `package.json` scripts for `test`, `test:e2e`, etc.)
- Credits / acknowledgements

### 4. Generate the README

Use the template from `references/template.md`. Apply these rules:

- **Omit sections entirely** when the user skips them or they don't apply — don't leave placeholder comments in the final output
- **Omit Contributing** if the project is not open to contributions
- **Omit Screenshots** if no screenshots or demo URL are provided
- **Omit Deployment** if no deployment info is given
- **Omit Running Tests** if no test setup exists
- Use the detected package manager commands throughout (install, dev, test)
- Replace all `USERNAME/REPO` placeholders with the actual slug
- Populate the Table of Contents to match only the included sections
- Use British English in prose — preserve exact package names, commands, and API identifiers as-is

### 5. Update mode

When improving an existing README:

- Preserve all existing content that fits the template
- Tell the user upfront which sections are present, which are thin, and which are missing — then ask targeted fill-in questions rather than re-interviewing everything from scratch
- Rewrite to the template format whilst keeping the user's original wording where possible
