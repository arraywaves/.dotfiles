---
name: web-components
description: >-
  Author, extend, and test Web Components using the native Custom Elements,
  Shadow DOM, and HTML Templates platform APIs. Covers Lit as a popular
  authoring library, reactive properties, Shadow DOM styling, slot patterns,
  custom events, accessibility, and testing. Use when working with
  customElements.define, LitElement, Shadow DOM, or @customElement decorators.
---

# Web Components

Build framework-agnostic UI using the browser's native Web Component platform: Custom Elements, Shadow DOM, and HTML Templates.

## Core Platform

### Custom Elements

Register a component class as an HTML tag:

```typescript
class MyComponent extends HTMLElement {
	connectedCallback() {
		this.attachShadow({ mode: "open" });
		this.shadowRoot!.innerHTML = `<p>Hello</p>`;
	}
}
customElements.define("my-component", MyComponent);
```

Use `customElements.whenDefined("my-component")` to await registration before interacting with instances.

### Shadow DOM

Shadow DOM encapsulates markup and styles. Attach via `element.attachShadow({ mode: "open" })`. Mode `"closed"` prevents external `shadowRoot` access.

### HTML Templates & Slots

```html
<template id="my-tmpl">
	<slot name="title"></slot>
	<slot></slot>
</template>
```

Clone and attach in `connectedCallback`:

```typescript
const tmpl = document.getElementById("my-tmpl") as HTMLTemplateElement;
this.shadowRoot!.appendChild(tmpl.content.cloneNode(true));
```

### Custom Events

Communicate upward with custom events. Set `bubbles: true` and `composed: true` to cross the Shadow DOM boundary:

```typescript
this.dispatchEvent(
	new CustomEvent("my-event", {
		detail: { value: this._value },
		bubbles: true,
		composed: true,
	})
);
```

---

## Authoring with Lit

[Lit](https://lit.dev) is the most widely used Web Component library. It adds declarative templating, reactive properties, and efficient updates on top of the native platform.

### Imports

```typescript
import { css, html, LitElement } from "lit";
import { customElement, property, state } from "lit/decorators.js";
```

### Component Structure

```typescript
@customElement("my-component")
export class MyComponent extends LitElement {
	static override styles = css`
		:host {
			display: block;
		}
	`;

	@property({ type: String }) label = "";
	@state() private _count = 0;

	override render() {
		return html`<div>${this.label}: ${this._count}</div>`;
	}
}
```

### Reactive Properties

- `@property()` — Public API. Reflected as an attribute; triggers re-render on change. Provide a `type` option for attribute conversion (`String`, `Number`, `Boolean`, `Array`, `Object`).
- `@state()` — Internal state. Not reflected; triggers re-render on change.

Always provide defaults. Avoid mutating `@property` arrays/objects directly — reassign to trigger reactivity.

---

## Shadow DOM Styling

- Style the host with `:host` and `:host([attribute])`
- Style slotted content with `::slotted(selector)` (one level deep only)
- Use CSS custom properties for theming: define defaults in `:host`, allow override from outside
- Integrate design tokens via `var(--token-name)`

```css
:host {
	display: block;
	color: var(--my-component-color, #333);
}
:host([disabled]) {
	opacity: 0.5;
}
::slotted(p) {
	margin: 0;
}
```

## Slots

Named slots for composable APIs:

```typescript
override render() {
	return html`
		<header><slot name="header"></slot></header>
		<main><slot></slot></main>
		<footer><slot name="footer"></slot></footer>
	`;
}
```

Use `slot="header"` on the consumer side. The default (unnamed) slot receives all unslotted children.

## Lifecycle

| Native callback | Lit equivalent | When |
|---|---|---|
| `connectedCallback()` | `connectedCallback()` | Element added to DOM |
| `disconnectedCallback()` | `disconnectedCallback()` | Element removed from DOM |
| _(first render)_ | `firstUpdated()` | After first render — one-time DOM setup |
| `attributeChangedCallback()` | _(handled by `@property`)_ | Observed attribute changed |
| _(after each render)_ | `updated(changedProperties)` | After each re-render — side effects |

Always call `super.connectedCallback()` / `super.disconnectedCallback()` when overriding in Lit. Clean up listeners and observers in `disconnectedCallback`.

## Accessibility

Web Components own their internal DOM, so ARIA roles and keyboard handling must be implemented explicitly.

- Set `role`, `aria-label`, and other ARIA attributes on the host or internal elements as appropriate
- Manage `tabindex` to ensure keyboard reachability
- Forward focus when wrapping native elements (`delegatesFocus: true` on `attachShadow`)
- Use `KeyboardEvent` listeners for arrow-key navigation in composite widgets (listbox, menu, tabs)

For projects that need accessible form controls or complex widgets out of the box, consider extending base classes from a library such as [`@lion/ui`](https://lion-web.netlify.app) or [`@open-wc`](https://open-wc.org), which implement WCAG patterns on top of Lit.

## Testing

Test Web Components with `@open-wc/testing` (Chai-based) or Vitest + `happy-dom`:

**@open-wc/testing**

```typescript
import { fixture, html, expect } from "@open-wc/testing";

it("renders label", async () => {
	const el = await fixture(html`<my-component label="test"></my-component>`);
	expect(el.shadowRoot!.textContent).to.include("test");
});
```

**Vitest + happy-dom**

```typescript
import { describe, it, expect } from "vitest";

describe("my-component", () => {
	it("reflects label property", async () => {
		document.body.innerHTML = `<my-component label="hi"></my-component>`;
		const el = document.querySelector("my-component")!;
		await customElements.whenDefined("my-component");
		expect(el.getAttribute("label")).toBe("hi");
	});
});
```
