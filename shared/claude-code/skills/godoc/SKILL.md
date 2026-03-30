---
name: godoc
description: Write Go doc comments for functions, methods, types, packages, and constants. Use when adding, editing, or reviewing Go documentation, or when asked to document Go code.
---

# Go Doc Comments

Write godoc-compatible comments for Go declarations.

## Style

- British English in prose (behaviour, initialise, colour) — but never alter spellings inside code identifiers, import paths, or string literals (match the source)
- Concise but complete — capture everything needed to understand the declaration, cut everything that doesn't add to that
- Write like a human technical author: no padding, no restating the obvious, no formulaic filler
- En dashes (–) for inline asides and separators, not hyphens

## Formatting

- Go 1.19+ doc comment syntax applies: paragraphs separated by blank comment lines, code blocks indented with a tab, lists with `  - item`
- No blank line between the comment block and the declaration it documents
- All comment lines use `//`, not `/* */` (except cgo blocks)

## Comment Structure by Declaration

### Packages

- First line: `// Package name does X.` — one sentence, ends with a period
- For packages with multiple files, put the package comment in `doc.go`
- Include: purpose, scope, and any essential usage context a caller needs before reading the API

### Functions and Methods

- First line starts with the function/method name: `// FunctionName does X`
- No period unless the summary is multiple sentences
- For methods, use the receiver type only when disambiguation is needed
- Describe what the function does, not how it does it

### Types

- First line: `// TypeName is/represents X` or `// TypeName describes X`
- For interfaces, describe the contract, not an implementation
- For structs, describe the role of the type, not each field (document fields inline if non-obvious)

### Constants and Variables

- Group-level comment describes the group; inline `//` comments document individual values
- For iota enumerations, document the zero value and any sentinel values explicitly

## Special Markers

### `// Deprecated:`

- Must be its own paragraph within the comment
- Always name the replacement: `// Deprecated: Use NewFunc instead.`

### Doc Links (Go 1.19+)

- Reference other symbols with `[Symbol]` or `[pkg.Symbol]`
- Use for cross-references within the same package or to imported packages
- Only link when the reference adds genuine navigational value

## What to Document

- What the declaration does and any non-obvious behaviour
- Error conditions — when and why errors are returned
- Concurrency safety — whether the type or function is safe for concurrent use
- Env vars the function reads — list with backtick names and `(required)` / `(optional, default "x")` inline
- Zero-value behaviour for types where it's meaningful
- Panics — if the function panics under specific conditions, say so
- Omit anything already obvious from the type signature or declaration name

## Examples

Provide runnable examples as `Example*` functions in `_test.go` files, not in doc comments.

- Naming: `func ExampleFoo()`, `func ExampleFoo_suffix()` for multiple examples
- Include an `// Output:` comment block so `go test` can verify the output
- Keep examples minimal — one clear use case per function

```go
func ExampleNewClient() {
	c := NewClient("https://api.example.com")
	fmt.Println(c.BaseURL)
	// Output: https://api.example.com
}
```
