---
name: agent-creator
description: >
  Create new Claude Code agent definition files. Use when asked to create an agent,
  define a new specialised agent, or add an agent to the dotfiles system. Generates
  a correctly structured .md file with YAML frontmatter and body following established
  conventions. Triggers on: "create an agent", "new agent for X", "make an agent that".
---

# Agent Creator

Guides you through an interview-driven workflow to produce a well-formed agent `.md`
file at `~/.dotfiles/shared/claude-code/agents/<name>.md`.

## Agent Anatomy

Each agent is a single Markdown file with YAML frontmatter + a short body.

**Frontmatter — required fields:**

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | kebab-case; matches filename without `.md` |
| `description` | block string | Multi-line `>` block. Must state purpose AND delegation triggers clearly — this is what causes tasks to route here |
| `tools` | string | Comma-separated subset of: `Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch` |
| `skills` | list | YAML list of skill names the agent can invoke |
| `memory` | string | `project` — task-scoped; `user` — persistent across sessions |
| `effort` | string | `low` / `medium` / `high` |
| `color` | string | CSS colour name — pick one not used by existing agents |

**Frontmatter — optional fields:**

| Field | Notes |
|-------|-------|
| `model` | Override only when non-default is needed (e.g. `haiku` for lightweight tasks) |

**Existing agent colours (avoid duplicating):** blue, orange, cyan, purple, green

**Body conventions:**
- First line: one-sentence role definition — `You are a …`
- `## Conventions` — optional; style, toolchain, or language preferences
- `## Skill Routing` — required even for single-skill agents; one bullet per skill:
  `- **skill-name** — when to invoke it`
- Closing philosophy note — optional; one or two sentences on approach/aesthetic

## Workflow

### Step 1 — Clarify purpose

Ask the user:
1. What is the agent's name? (suggest a kebab-case form if unclear)
2. What tasks should route to this agent? Give concrete examples.
3. What should it *not* handle? (helps sharpen the description)

Derive the `description` block from answers — it must read as a delegation trigger,
not just a label. Include task examples inline.

### Step 2 — Select tools

Choose the **minimum** tool set the agent needs:

- Read-only research → `Read, Glob, Grep`
- File generation → add `Write, Edit`
- Shell commands / builds → add `Bash`
- Web lookups → add `WebFetch` or `WebSearch`

Avoid adding tools the agent will never realistically use.

### Step 3 — Assign skills

List skills from `~/.dotfiles/shared/claude-code/skills/`. Read the skills directory
if you need to verify available skill names:

```
ls ~/.dotfiles/shared/claude-code/skills/
```

Only assign skills that directly serve the agent's domain. One skill per agent is
fine; more than six is a smell — consider splitting.

### Step 4 — Set metadata

- **memory**: `project` if the agent works on a specific codebase or task context;
  `user` if it needs to recall personal preferences or style choices across sessions
- **effort**: `low` for simple, fast tasks (single tool, single skill);
  `high` for multi-step, multi-skill orchestration; `medium` otherwise
- **color**: pick a visually distinct colour not already used (see anatomy table)
- **model**: only set to `haiku` for purely mechanical, low-reasoning tasks

### Step 5 — Draft the body

Write:
1. Role sentence
2. `## Conventions` (if the agent has strong style/toolchain opinions)
3. `## Skill Routing` — one bullet per assigned skill with a clear trigger description
4. Closing note (optional)

Keep the body under 40 lines. Agents are orchestrators, not encyclopaedias.

### Step 6 — Write the file

Output the complete agent file to:

```
~/.dotfiles/shared/claude-code/agents/<name>.md
```

Show the full file content before writing so the user can review it.

### Step 7 — Register in routing table

If the project's `CLAUDE.md` or `AGENTS.md` contains an agent routing table (like the
one in `~/.claude/CLAUDE.md`), add a row for the new agent:

```
| Intent description | `agent-name` | Examples |
```

Ask the user if they want this done before writing.
