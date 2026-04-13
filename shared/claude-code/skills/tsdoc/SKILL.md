---
name: tsdoc
description: Write TSDoc comments for TypeScript functions, classes, and modules. Use when adding, editing, or reviewing TSDoc comments, or when asked to document TypeScript code.
---

# TSDoc Comments

Write TSDoc comments for TypeScript functions, classes, and modules.

## Style

- British English in prose (behaviour, initialise, colour) — but never alter spellings
  inside code identifiers, env var names, or string literals (match the source)
- Concise but complete — capture everything needed to understand the code, cut everything that doesn't add to that
- Write like a human technical author: no padding, no restating the obvious, no formulaic filler
- En dashes (–) for inline asides and separators, not hyphens

## Formatting

- Opening line: one sentence summarising what the function does, no period unless it's
  multiple sentences
- Blank line between the summary and any body sections
- Omit `@description` tag – the opening block is the description
- No trailing period on `@tag` lines

## Tags

### `@param`

- Include when the parameter's purpose, constraints, or valid values aren't obvious from the type
- Omit for self-evident params (e.g. `id: string` on a `getUser` function) and parameterless functions
- Format: `@param name description`
- For destructured params, document the object shape, not individual destructured keys

### `@returns`

- Use once per distinct return shape; inline with backtick-wrapped type or value, not prose
- For `Promise<T>`, document the resolved value: `@returns \`Promise<User>\` — the matched user record`
- For union returns (success/error), use one tag per shape

### `@throws`

- Include when the function throws a specific named error type, or when the throw condition is non-obvious
- Format: `@throws \`ErrorType\` – when/why it throws`

### `@deprecated`

- Always name the replacement where possible: `@deprecated Use \`newFunction\` instead`

### `@example`

- Include only when usage is genuinely non-obvious
- One short, runnable snippet — no explanatory prose around it
- Wrap code examples in back ticks for single line examples and three backticks + language for multi-line examples

### `@see`

- Include only when linking to a third-party library is relevant, e.g.
- For linking to references (URLs or other symbols)

### `@remarks`

- Include only when some kind of disclaimer or usage warning is necessary
- For caveats/notes, things a developer needs to be aware of

### `@module`

- Include at the top of files that are part of a generated docs output
- Format: `@module folder/module`, path relative to `src`, no extension
- Omit in files where the folder structure already makes the grouping obvious, or if you're not generating docs

## What to document

- What the function does and any non-obvious behaviour
- Security or design decisions worth explaining (e.g. why certain params are rejected)
- Env vars the function reads – list with backtick names, `(required)` / `(optional, default "x")` inline,
  en-dash separator, indented continuation lines for longer descriptions
- Return shapes, especially when there are multiple (success vs. error)
- Omit anything already obvious from the type signature or function name
