---
name: a11y-audit
description: >-
  Audit web projects for accessibility compliance using axe-core via Playwright,
  contrast ratio checking, keyboard navigation testing, and ARIA role validation.
  Use when asked to check accessibility, audit for WCAG compliance, test
  keyboard/screen-reader behaviour, or run automated a11y scans.
---

# Accessibility Audit

Run automated and manual accessibility checks against web pages.

## Automated Scan with axe-core

Use `@axe-core/playwright` for Playwright-based scans. This catches ~30–40% of WCAG violations automatically.

### Setup

```bash
vp add -D @axe-core/playwright
```

### Script

```typescript
import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto("http://localhost:3000");
await page.waitForLoadState("networkidle");

const results = await new AxeBuilder({ page })
  .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
  .analyze();

console.log(`Violations: ${results.violations.length}`);
for (const violation of results.violations) {
  console.log(`\n[${violation.impact}] ${violation.id}: ${violation.description}`);
  console.log(`  Help: ${violation.helpUrl}`);
  for (const node of violation.nodes) {
    console.log(`  Target: ${node.target.join(" > ")}`);
    console.log(`  HTML: ${node.html.slice(0, 120)}`);
  }
}

await browser.close();
process.exit(results.violations.length > 0 ? 1 : 0);
```

### Scoping

Scan specific areas to reduce noise:

```typescript
// Include only main content
new AxeBuilder({ page }).include("#main-content");

// Exclude known third-party widgets
new AxeBuilder({ page }).exclude(".third-party-widget");

// Disable specific rules
new AxeBuilder({ page }).disableRules(["color-contrast"]);
```

### CI Integration

Run against built HTML when no dev server is available:

```typescript
import { preview } from "vite";

const server = await preview({ preview: { port: 4173 } });
// ... run axe scan against http://localhost:4173
server.close();
```

## WCAG Rule Sets

| Tag             | Standard | Level       |
| --------------- | -------- | ----------- |
| `wcag2a`        | WCAG 2.0 | A (minimum) |
| `wcag2aa`       | WCAG 2.0 | AA (target) |
| `wcag21a`       | WCAG 2.1 | A           |
| `wcag21aa`      | WCAG 2.1 | AA          |
| `best-practice` | Not WCAG | Recommended |

Default: scan with `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`.

## Manual Checks

axe-core cannot catch everything. Check these manually:

### Keyboard Navigation

- Tab through every interactive element — verify logical focus order
- Enter/Space activates buttons and links
- Escape closes modals and dropdowns
- Arrow keys navigate within composite widgets (tabs, listboxes, menus)
- No keyboard traps — focus can always leave a component

### Focus Management

- Focus moves to modal content when opened; returns to trigger when closed
- Skip-to-content link is present and functional
- Focus is never lost after dynamic content updates (route changes, AJAX)

### Screen Reader

- All images have meaningful `alt` text (or `alt=""` for decorative)
- Form inputs have associated `<label>` elements
- Live regions (`aria-live`) announce dynamic content changes
- Heading hierarchy is logical (h1 → h2 → h3, no skips)
- Landmarks are present: `<main>`, `<nav>`, `<header>`, `<footer>`

### Colour and Contrast

- Text contrast ratio: 4.5:1 for normal text, 3:1 for large text (WCAG AA)
- UI component contrast: 3:1 against adjacent colours
- Information is not conveyed by colour alone (add icons, patterns, or text)

## Reporting

Structure the audit report as:

1. **Summary** — Total violations by impact (critical, serious, moderate, minor)
2. **Critical/Serious** — Each violation with: rule ID, description, affected elements, fix suggestion
3. **Moderate/Minor** — Grouped by category
4. **Manual checks** — Pass/fail for keyboard nav, focus management, screen reader, contrast
5. **Recommendations** — Prioritised list of fixes

## Impact Levels

| Impact   | Meaning                      | Action              |
| -------- | ---------------------------- | ------------------- |
| Critical | Blocks access entirely       | Fix immediately     |
| Serious  | Significantly impairs access | Fix before release  |
| Moderate | Some difficulty for users    | Fix in next sprint  |
| Minor    | Inconvenience                | Fix when convenient |
