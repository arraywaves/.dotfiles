---
name: r3f-perf-audit
description: Audit and optimize react-three-fiber (R3F) performance. Use when debugging FPS drops or jank in R3F/Three.js scenes, reviewing R3F/Three.js code for performance anti-patterns, running automated scans of a codebase for performance issues, or optimizing draw calls, memory usage, geometry/material creation, and component re-render frequency in R3F applications.
---

# R3F Performance Audit

## Workflow

```
User reports perf issue or wants audit
          │
          ├─ "My app is slow / dropping frames"
          │   → Live Debugging: see references/debugging.md
          │
          ├─ "Review my code / what am I doing wrong"
          │   → Code Review: check references/anti-patterns.md
          │
          └─ "Scan my project for issues"
              → Automated: run scripts/audit.py
```

## Quick Checks (Do These First)

1. **Draw calls** — renderer.info.render.calls > 100 is a red flag
2. **Re-renders** — React Profiler or r3f-perf showing unexpected component commits
3. **Memory leaks** — Check renderer.info.memory.geometries / textures growing over time
4. **frameloop** — Use `"demand"` ONLY if scene is static/interaction-only. If scene has ANY continuous animations (clouds, particles, tweens, camera follow), use `"always"`

## Key Anti-Pattern Categories

See `references/anti-patterns.md` for full examples with before/after code:

- Unmemoized geometries/materials (re-created each render)
- Missing `.dispose()` calls (memory leaks)
- `useState` in animation loops (triggers re-renders)
- Missing instancing for repeated meshes
- Unnecessary `useFrame` subscriptions
- `useThree()` overuse causing cascade re-renders
- Unbounded texture/shadow map sizes
- Missing `dpr` limits on Canvas
- ⚠️ **CRITICAL: `invalidate()` inside `useFrame` with `frameloop="demand"`** — Creates infinite render loop. Only call `invalidate()` when state changes (scroll, progress), NEVER inside animation frames

## Live Debugging Tools

See `references/debugging.md` for setup and usage:

- `@r3f/perf` — in-scene FPS, draw calls, memory overlay
- React DevTools Profiler — component re-render frequency/cost
- `renderer.info` — Three.js GPU stats (no extra packages needed)
- Chrome DevTools Performance — CPU/GPU flame graphs
- Spector.js — per-frame WebGL call capture

## frameloop Modes Explained

| Mode       | Use When                                                          | invalidate()                                  | Notes                                                                                  |
| ---------- | ----------------------------------------------------------------- | --------------------------------------------- | -------------------------------------------------------------------------------------- |
| `"always"` | Scene animates continuously (rotating objects, particles, tweens) | Never call inside useFrame                    | Default. Renders every frame. Safe for animations.                                     |
| `"demand"` | Scene is static (models, UI, interaction-only)                    | Call when state changes (scroll, click, etc.) | Only renders on demand. NEVER call invalidate() inside useFrame—creates infinite loop. |

**Golden Rule**: If your scene has ANY continuous animations (`useFrame` hooks that change properties), use `frameloop="always"`. Don't try to micro-optimize with `"demand"` if you have animations—it will cause infinite loops.

## Automated Scan

```bash
python3 scripts/audit.py ./src
python3 scripts/audit.py ./src --severity medium   # skip low-severity
python3 scripts/audit.py ./src --json > report.json
```

Scans `.jsx/.tsx/.js/.ts` files and reports anti-pattern matches with file:line references. Exits with code 1 if any high-severity findings are found (useful in CI).
