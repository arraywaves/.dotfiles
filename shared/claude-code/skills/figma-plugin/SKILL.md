---
name: figma-plugin
description: >-
  Develop Figma plugins using the Figma Plugin API and TypeScript. Covers plugin
  manifest configuration, UI/sandbox communication via postMessage, node
  traversal, variable collection access, clientStorage persistence, and common
  plugin patterns. Use when working with @figma/plugin-typings, Figma plugin
  manifest.json, or code.ts/ui.html plugin files.
---

# Figma Plugin

Build and maintain Figma plugins using the Figma Plugin API with TypeScript.

## Project Structure

### Minimal

```
plugin-name/
├── manifest.json     # Plugin configuration
├── code.ts           # All plugin logic (sandbox)
├── ui.html           # Plugin UI (iframe)
├── tsconfig.json     # TypeScript config
└── package.json      # Dependencies (@figma/plugin-typings)
```

### Modular (recommended for larger plugins)

```
plugin-name/
├── manifest.json
├── code.ts           # Entry point — imports and wires up handlers
├── handlers/         # One file per feature or message type
│   ├── featureA.ts
│   └── featureB.ts
├── lib/              # Shared utilities (colour, geometry, etc.)
│   └── utils.ts
├── ui.html
├── tsconfig.json
└── package.json
```

`code.ts` compiles to a single `code.js` bundle (via `esbuild` or similar) — modules are resolved at build time, not at runtime.

## Manifest

```json
{
	"name": "Plugin Name",
	"id": "unique-id",
	"api": "1.0.0",
	"main": "code.js",
	"ui": "ui.html",
	"documentAccess": "dynamic-page",
	"editorType": ["figma"],
	"networkAccess": { "allowedDomains": ["none"] }
}
```

- `documentAccess`: `"dynamic-page"` for page-level access; omit for full document access
- `networkAccess`: restrict to `"none"` unless the plugin needs external API calls
- `editorType`: `"figma"`, `"figjam"`, or both

## UI/Sandbox Communication

The plugin runs in two isolated contexts. All communication uses `postMessage`.

### Code → UI

```typescript
figma.ui.postMessage({ type: "data-loaded", data: payload });
```

### UI → Code

```javascript
parent.postMessage({ pluginMessage: { type: "action", ...data } }, "*");
```

### Receiving Messages

**In code.ts:**

```typescript
figma.ui.onmessage = (msg) => {
	switch (msg.type) {
		case "run":
			handleRun(msg.options);
			break;
		case "close":
			figma.closePlugin();
			break;
	}
};
```

**In ui.html:**

```javascript
window.onmessage = (event) => {
	const msg = event.data.pluginMessage;
	if (msg.type === "data-loaded") {
		renderData(msg.data);
	}
};
```

## Plugin Lifecycle

```typescript
// Show UI
figma.showUI(__html__, { width: 400, height: 500 });

// Set up message handler
figma.ui.onmessage = (msg) => { ... };

// Load persisted settings
const settings = await figma.clientStorage.getAsync("settings-key");
figma.ui.postMessage({ type: "settings-loaded", settings });
```

## Client Storage

Persist user settings across sessions:

```typescript
// Save
await figma.clientStorage.setAsync("key", value);

// Load
const value = await figma.clientStorage.getAsync("key");

// Delete
await figma.clientStorage.deleteAsync("key");
```

Values must be JSON-serialisable. Use a single settings key with an object for related preferences.

## Node Traversal

```typescript
// Current selection
const selection = figma.currentPage.selection;

// Walk all nodes
function walk(node: SceneNode) {
	if ("children" in node) {
		for (const child of node.children) {
			walk(child);
		}
	}
}

// Find by name
const node = figma.currentPage.findOne((n) => n.name === "Target");
const nodes = figma.currentPage.findAll((n) => n.type === "FRAME");
```

## Common Plugin Patterns

### Selection manipulation

Read or modify properties on selected nodes:

```typescript
for (const node of figma.currentPage.selection) {
	if (node.type === "RECTANGLE") {
		node.fills = [{ type: "SOLID", color: { r: 1, g: 0, b: 0 } }];
	}
}
```

### Component / style scanning

Audit or bulk-edit nodes across the page:

```typescript
const textNodes = figma.currentPage.findAll((n) => n.type === "TEXT") as TextNode[];
```

### Export

```typescript
const bytes = await node.exportAsync({ format: "PNG", constraint: { type: "SCALE", value: 2 } });
```

Supported formats: `"PNG"`, `"JPG"`, `"SVG"`, `"PDF"`.

### Notifications

```typescript
figma.notify("Done!", { timeout: 2000 });
figma.notify("Something went wrong", { error: true });
```

### Network requests

Network calls must originate from the **UI context** (not the sandbox). Add the allowed domain to the manifest:

```json
"networkAccess": { "allowedDomains": ["https://api.example.com"] }
```

Then call `fetch` inside `ui.html` and relay results back via `postMessage`.

## Working with Variables

### Reading Variables

```typescript
const collections = figma.variables.getLocalVariableCollections();

for (const collection of collections) {
	for (const id of collection.variableIds) {
		const variable = figma.variables.getVariableById(id);
		if (!variable) continue;

		const modeId = collection.modes[0].modeId;
		const value = variable.valuesByMode[modeId];
		// value is RGBA | number | string | boolean | VariableAlias
	}
}
```

### Creating Variables

```typescript
const collection = figma.variables.createVariableCollection("Tokens");
const variable = figma.variables.createVariable("color-primary", collection.id, "COLOR");
variable.setValueForMode(collection.modes[0].modeId, { r: 0.86, g: 0.15, b: 0.15, a: 1 });
```

### Variable Aliases (References)

```typescript
const alias: VariableAlias = {
	type: "VARIABLE_ALIAS",
	id: targetVariable.id,
};
variable.setValueForMode(modeId, alias);
```

### Variable Scopes

Set which properties a variable can bind to:

```typescript
function getValidScopes(type: VariableResolvedDataType): VariableScope[] {
	switch (type) {
		case "COLOR":
			return ["ALL_FILLS", "STROKE_COLOR", "EFFECT_COLOR"];
		case "FLOAT":
			return ["WIDTH_HEIGHT", "GAP", "CORNER_RADIUS", "STROKE_FLOAT"];
		case "STRING":
			return ["FONT_FAMILY", "FONT_STYLE"];
		default:
			return [];
	}
}
```

## Colour Utilities

Figma uses normalised RGBA (0–1). Helpers for converting to/from hex are useful whenever a plugin reads or writes fills:

```typescript
function rgbToHex(r: number, g: number, b: number): string {
	const toHex = (c: number) =>
		Math.round(c * 255).toString(16).padStart(2, "0");
	return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

function hexToRgb(hex: string): RGB {
	const h = hex.replace("#", "");
	return {
		r: parseInt(h.slice(0, 2), 16) / 255,
		g: parseInt(h.slice(2, 4), 16) / 255,
		b: parseInt(h.slice(4, 6), 16) / 255,
	};
}
```

## TypeScript Configuration

```json
{
	"compilerOptions": {
		"target": "ES6",
		"lib": ["ES2017"],
		"strict": true,
		"typeRoots": ["./node_modules/@figma/plugin-typings"]
	}
}
```

Install typings using the project's package manager (`vp add -D @figma/plugin-typings` / `pnpm add -D @figma/plugin-typings`).
