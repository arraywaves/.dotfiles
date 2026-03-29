# Shields.io Badge Reference

All badges use `https://img.shields.io`. Replace `USERNAME/REPO` with the GitHub slug.

## Standard Set (used in template)

```markdown
![Build Status](https://img.shields.io/github/actions/workflow/status/USERNAME/REPO/ci.yml?branch=main)
![Version](https://img.shields.io/github/package-json/v/USERNAME/REPO)
![License](https://img.shields.io/github/license/USERNAME/REPO)
![Last Commit](https://img.shields.io/github/last-commit/USERNAME/REPO)
```

**Notes:**
- The build status badge requires a GitHub Actions workflow file. Replace `ci.yml` with the actual workflow filename if different. If no CI is set up, omit this badge.
- The version badge reads from `package.json` in the repo root — only include if the project has one.
- If the repo doesn't exist yet (planned slug only), these badges will render as "unknown" until the repo is created. That's fine — include them anyway.

## Optional Extras

```markdown
![Stars](https://img.shields.io/github/stars/USERNAME/REPO?style=social)
![Issues](https://img.shields.io/github/issues/USERNAME/REPO)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)
![Node Version](https://img.shields.io/node/v/PACKAGE_NAME)
![npm](https://img.shields.io/npm/v/PACKAGE_NAME)
```

## Static Badges (no repo required)

For projects without a GitHub repo or when specific info is needed:

```markdown
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-000000?logo=next.js&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-06B6D4?logo=tailwind-css&logoColor=white)
```

Format: `https://img.shields.io/badge/LABEL-COLOR?logo=LOGO_NAME&logoColor=white`

Logo names come from [Simple Icons](https://simpleicons.org) — lowercase, hyphen-separated.
