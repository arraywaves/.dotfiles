---
name: monorepo-ops
description: >-
  Manage pnpm workspaces and multi-package repositories. Covers workspace
  topology inspection, dependency graph analysis, selective builds with
  pnpm --filter, cross-package linking, and coordinated operations. Use when
  working in a monorepo with pnpm-workspace.yaml, running filtered commands,
  or managing inter-package dependencies.
---

# Monorepo Operations

Manage pnpm workspaces for multi-package repositories.

## Package Manager

**Always detect before running any command.** Check the project root for:

1. `vite.config.*` or `vp` in `package.json` scripts → use `vp` (vite+, preferred)
2. `pnpm-workspace.yaml` or `pnpm-lock.yaml` → use `pnpm`
3. `yarn.lock` → use `yarn`
4. `package-lock.json` → use `npm`

`vp` (vite+) wraps pnpm with the same CLI flags — all commands below work identically with either. Substitute the detected command throughout.

## Workspace Detection

Check for `pnpm-workspace.yaml` at the repo root:

```yaml
packages:
  - "packages/*"
  - "apps/*"
```

## Inspecting the Workspace

```bash
# List all packages with their paths and versions
pnpm ls -r --depth -1

# Show the dependency graph
pnpm ls -r --depth 0

# Show which packages depend on a specific package
pnpm why <package-name> -r
```

## Filtered Commands

Run commands in specific packages using `--filter`:

```bash
# Run in a single package
pnpm --filter <package-name> build

# Run in a package and its dependencies
pnpm --filter <package-name>... build

# Run in packages that changed since main
pnpm --filter "...[origin/main]" build

# Run in all packages matching a glob
pnpm --filter "./packages/*" test

# Run in a package and everything that depends on it
pnpm --filter "...^<package-name>" build
```

### Filter Syntax

| Pattern              | Meaning                                 |
| -------------------- | --------------------------------------- |
| `<name>`             | Exact package name                      |
| `<name>...`          | Package and its dependencies            |
| `...<name>`          | Package and its dependents              |
| `...^<name>`         | Only dependents, not the package itself |
| `"./path/*"`         | Glob match on directory path            |
| `"...[origin/main]"` | Packages changed since ref              |

## Cross-Package Dependencies

### Internal Dependencies

In `package.json`, reference workspace packages:

```json
{
  "dependencies": {
    "@scope/core": "workspace:*"
  }
}
```

- `workspace:*` — Always resolve to the local package
- `workspace:^` — Use the local version with caret range
- `workspace:~` — Use the local version with tilde range

### Adding Dependencies

```bash
# Add to a specific package
pnpm --filter <package-name> add <dependency>

# Add as dev dependency
pnpm --filter <package-name> add -D <dependency>

# Add a workspace package as dependency
pnpm --filter <app-name> add @scope/core --workspace
```

## Build Order

pnpm respects the dependency graph when running commands:

```bash
# Build all packages in topological order
pnpm -r build

# Build in parallel where possible
pnpm -r --parallel build

# Build with concurrency limit
pnpm -r --workspace-concurrency 4 build
```

For complex build pipelines, use `pnpm -r --stream` to interleave output.

## Common Workflows

### Check All Packages

```bash
pnpm -r --parallel lint
pnpm -r --parallel typecheck
pnpm -r build
pnpm -r test
```

### Add a New Package

1. Create the package directory under the workspace glob pattern
2. Add `package.json` with the scoped name
3. Run `pnpm install` from the root to link it

### Publish

```bash
# Check what would be published
pnpm -r publish --dry-run

# Publish changed packages
pnpm -r publish --filter "...[origin/main]"
```

## Troubleshooting

### Dependency Resolution Issues

```bash
# Clear the store and reinstall
pnpm store prune
pnpm install --force
```

### Circular Dependencies

Inspect the graph for cycles:

```bash
pnpm ls -r --depth 0 | grep -E "workspace:"
```

If packages depend on each other, consider extracting shared code into a separate `shared` or `core` package.

### Lockfile Conflicts

After a merge conflict in `pnpm-lock.yaml`:

```bash
# Regenerate from package.json files
pnpm install --no-frozen-lockfile
```
