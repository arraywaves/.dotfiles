---
name: pydoc
description: >-
  Write Python docstrings for functions, classes, and modules following
  Google-style conventions. Use when adding, editing, or reviewing Python
  documentation, or when asked to document Python/Django/Wagtail code.
---

# Python Docstrings

Write Google-style docstrings for Python functions, classes, and modules.

## Style

- British English in prose (behaviour, initialise, colour) — preserve code identifiers as-is
- Concise but complete
- En dashes (–) for inline asides/separators

## Formatting

Opening line: one sentence summarising what the function/class does. No period unless multiple sentences follow.

```python
def fetch_pages(site_id: int, *, published: bool = True) -> list[Page]:
    """Fetch all pages for a site, optionally filtering by publish status.

    Queries the page tree rooted at the given site and returns a flat list.
    Unpublished pages are excluded by default.

    Args:
        site_id: The database ID of the Wagtail Site.
        published: If True, return only live pages. Defaults to True.

    Returns:
        A list of Page instances ordered by path.

    Raises:
        Site.DoesNotExist: If no site matches the given ID.
    """
```

## Sections

Use these Google-style section headers (indented 4 spaces, each arg on its own line):

### Args

```python
Args:
    name: Description of the parameter.
    timeout: Maximum seconds to wait. Defaults to 30.
```

Omit when all parameters are obvious from type hints and names.

### Returns

```python
Returns:
    A dict mapping token names to their resolved CSS values.
```

For complex return types, describe the shape:

```python
Returns:
    A tuple of (success, message) where success is True if the
    operation completed and message contains any warnings.
```

### Raises

```python
Raises:
    ValueError: If the input string is not valid JSON.
    ConnectionError: If the upstream API is unreachable.
```

Only document exceptions the caller should expect to handle — not every possible error.

### Yields

For generators:

```python
Yields:
    Each page in the queryset, fully annotated with parent data.
```

### Example

Only when usage is non-obvious:

```python
Example:
    >>> tokens = build_tokens("src/tokens.json")
    >>> tokens["color-primary"]
    '#dc2727'
```

## Module Docstrings

Place at the top of the file, before imports:

```python
"""Page models for the blog application.

Defines BlogIndexPage and BlogPage with StreamField-based content,
category tagging, and date-based ordering.
"""
```

## Class Docstrings

Document the class purpose. Document `__init__` parameters in the class docstring, not in `__init__` itself:

```python
class TokenPipeline:
    """Transform and output design tokens from a JSON source.

    Args:
        source: Path to the token JSON file.
        output_dir: Directory for generated output files.
    """
```

## What to Document

- What the function/class does (not how — the code shows that)
- Non-obvious behaviour, side effects, or constraints
- Parameters whose purpose is not clear from name + type hint
- Return value shape when it is complex
- Exceptions the caller should expect
- Environment variables (with backticks, note required/optional inline)

## What to Omit

- Parameters obvious from their name and type hint
- Implementation details the caller does not need
- `self` and `cls` parameters
- Trivial getters/setters
- `@property` methods unless the computed value is non-obvious
