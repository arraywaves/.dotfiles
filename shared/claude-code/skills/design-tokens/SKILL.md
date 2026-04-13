---
name: design-tokens
description: >-
  Build, validate, and transform design tokens using Style Dictionary. Covers
  token source ingestion (DTCG, Figma exports, custom JSON), custom transforms
  (colour space, unit conversion, font styles), CSS custom property generation,
  and multi-brand JSON output. Use when working with style-dictionary.config.js,
  tokens.json, token build scripts, or any design token pipeline.
---

# Design Tokens

Build and maintain Style Dictionary token pipelines that transform design token JSON into platform-specific outputs.

## Source Format

Token sources are JSON with nested categories: colours, typography, spacing, borders, shadows, and brand metadata. Common formats include:

- **DTCG** (W3C Design Token Community Group) — the emerging standard; uses `$value`, `$type`, `$description` keys
- **Figma Design Tokens plugin** (org.lukasoppermann.figmaDesignTokens) — exported from Figma via the Tokens Studio or Lukasoppermann plugin
- **Handwritten JSON** — custom structures following project conventions

**Inspect first.** Read the token source files to identify the format before applying transforms. The format determines which custom transforms (if any) are needed.

## Pipeline Architecture

```
<tokens>.json → Style Dictionary → CSS variables (:root)
                                 → JSON (optional, non-CSS metadata)
                                 → font-face.css (optional)
                                 → typography utilities (optional)
```

**Inspect first.** Before modifying anything, read the existing token source files and `style-dictionary.config.*` to understand the source format, transforms, and output platforms already configured. Never assume paths or output targets.

## Custom Transforms

Register transforms for domain-specific token types that Style Dictionary does not handle natively.

### Colour: hex8-to-hex (conditional)

Only needed if the token source contains colours with alpha as 8-digit hex (`#RRGGBBAA`), common in Figma exports. Style Dictionary's built-in transforms do not handle this format. Check the token source first — if all colour values are 6-digit hex, skip this transform.

Convert 8-digit hex to 6-digit hex or `rgba()` when alpha < 1:

```javascript
StyleDictionary.registerTransform({
	name: "color/hex8-to-hex",
	type: "value",
	matcher: (token) => token.type === "color",
	transformer: (token) => {
		const hex = token.value.replace("#", "");
		if (hex.length === 8) {
			const alpha = parseInt(hex.slice(6, 8), 16) / 255;
			if (alpha < 1) {
				const r = parseInt(hex.slice(0, 2), 16);
				const g = parseInt(hex.slice(2, 4), 16);
				const b = parseInt(hex.slice(4, 6), 16);
				return `rgba(${r}, ${g}, ${b}, ${alpha.toFixed(2)})`;
			}
			return `#${hex.slice(0, 6)}`;
		}
		return token.value;
	},
});
```

### Font: composite to CSS

Decompose composite font token objects (`fontSize`, `fontFamily`, `fontWeight`, `lineHeight`, `letterSpacing`, `fontStyle`) into individual CSS properties.

### Size: px units

Append `px` to dimension, spacing, borderRadius, and borderWidth tokens.

## Custom Formatters

### CSS variables (`css/variables`)

Output `:root` block with CSS custom properties. Filter out non-CSS types (custom-grid, custom-shadow, booleans, objects). Group by category with comments.

### Brand info JSON (`json/brand-info`)

Nested JSON structure for non-CSS metadata: company name, domain, social media links, brand descriptions. Used by application code, not stylesheets.

### Font-face CSS (optional)

Generate `@font-face` rules from custom-fontStyle tokens. Auto-generate font paths from family names. Handle italic variants.

### Typography utilities (optional)

Generate utility classes with responsive typography using CSS `clamp()` and viewport-based scaling.

## Modes and Variants

For projects with theme support (light/dark, viewport-responsive):

- Token source uses a `modes` object: `{ "Light": "#dc2727", "Dark": "#dc2727" }`
- Custom parser preprocesses tokens, extracting modes into `$modes`
- CSS output generates both `:root` (default mode) and `.dark` (alternate) selectors
- Viewport modes use `@media` queries (e.g., `max-width: 768px`)

## Tailwind Integration

When tokens reference Tailwind framework variables, transform references:

- `{_Frameworks.Tailwind.Gray.--color-gray-200}` → `var(--color-gray-200)`
- Internal refs: `{Global.Radius.--radius-sm}` → `var(--radius-sm)`

## Workflow

1. **Discover** — find token source files (`.tokens.json`, `tokens.json`, or similar) and the Style Dictionary config (`style-dictionary.config.*`); read both before touching anything
2. **Detect** — identify which output platforms are configured (CSS, JSON, font-face, typography); note the build script and how to invoke it
3. **Modify** — update transforms, formatters, or token JSON as needed for the task
4. **Build** — run the existing build script (check `package.json` scripts for the token build command)
5. **Verify** — confirm generated outputs are correct; check for missing variables or broken references
