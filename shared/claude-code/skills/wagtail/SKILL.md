---
name: wagtail
description: >-
  Build and maintain Wagtail CMS sites on Django. Covers page models,
  StreamField blocks, template tags, Wagtail hooks, image/document handling,
  search configuration, and Wagtail API setup. Use when working with Wagtail,
  Django CMS, or projects with wagtail in their dependencies. Python ecosystem
  conventions: uv over pip, ruff for linting, pyright for type-checking.
---

# Wagtail

Build content-managed sites with Wagtail on Django.

## Python Tooling

- **Package manager:** prefer `uv` when `pyproject.toml` is present; fall back to `poetry` or `pip`
- **Linting:** `ruff check` (replaces flake8 + isort + pyupgrade)
- **Formatting:** `ruff format` (replaces black)
- **Type-checking:** `pyright` or `mypy`
- **Task runner:** check for `Makefile`, `justfile`, or `pyproject.toml [tool.taskipy]`

## Page Models

```python
from wagtail.models import Page
from wagtail.fields import RichTextField, StreamField
from wagtail.admin.panels import FieldPanel

class BlogPage(Page):
    date = models.DateField("Post date")
    intro = models.CharField(max_length=250)
    body = RichTextField(blank=True)

    content_panels = Page.content_panels + [
        FieldPanel("date"),
        FieldPanel("intro"),
        FieldPanel("body"),
    ]
```

### Page Types

- **Page** — Base class for all page types
- **RoutablePageMixin** — Add sub-URL routes to a page
- **Page.get_context()** — Override to add template context
- **Page.serve()** — Override for custom response handling

### Parent/Child Rules

```python
class BlogIndexPage(Page):
    subpage_types = ["blog.BlogPage"]

class BlogPage(Page):
    parent_page_types = ["blog.BlogIndexPage"]
```

## StreamField

Use StreamField for flexible content areas:

```python
from wagtail.blocks import CharBlock, RichTextBlock, StructBlock, ListBlock, StreamBlock
from wagtail.images.blocks import ImageChooserBlock

class HeroBlock(StructBlock):
    heading = CharBlock()
    image = ImageChooserBlock()
    text = RichTextBlock(required=False)

    class Meta:
        template = "blocks/hero_block.html"
        icon = "image"

class BlogPage(Page):
    body = StreamField([
        ("hero", HeroBlock()),
        ("paragraph", RichTextBlock()),
        ("image", ImageChooserBlock()),
    ], use_json_field=True)

    content_panels = Page.content_panels + [
        FieldPanel("body"),
    ]
```

**Always** set `use_json_field=True` on StreamField (required since Wagtail 5+).

## Images and Documents

```python
from wagtail.images.models import Image
from wagtail.documents.models import Document

# In templates
{% load wagtailimages_tags %}
{% image page.hero_image fill-800x400 as hero %}
<img src="{{ hero.url }}" alt="{{ hero.alt }}">
```

### Custom Image Model

```python
from wagtail.images.models import AbstractImage, AbstractRendition

class CustomImage(AbstractImage):
    caption = models.CharField(max_length=255, blank=True)
    admin_form_fields = Image.admin_form_fields + ("caption",)

class CustomRendition(AbstractRendition):
    image = models.ForeignKey(CustomImage, related_name="renditions", on_delete=models.CASCADE)
```

Set in settings: `WAGTAILIMAGES_IMAGE_MODEL = "app.CustomImage"`

## Snippets

Register reusable content models:

```python
from wagtail.snippets.models import register_snippet

@register_snippet
class Category(models.Model):
    name = models.CharField(max_length=255)

    panels = [FieldPanel("name")]

    class Meta:
        verbose_name_plural = "categories"

    def __str__(self):
        return self.name
```

## Hooks

Extend Wagtail's behaviour without modifying core:

```python
from wagtail import hooks

@hooks.register("before_serve_page")
def add_analytics(page, request, serve_args, serve_kwargs):
    # Runs before every page serve
    pass

@hooks.register("after_publish_page")
def notify_on_publish(request, page):
    # Runs after a page is published
    pass
```

Common hooks: `before_serve_page`, `after_publish_page`, `after_create_page`, `construct_main_menu`, `register_rich_text_features`.

## Wagtail API

```python
from wagtail.api.v2.views import PagesAPIViewSet
from wagtail.api.v2.router import WagtailAPIRouter

api_router = WagtailAPIRouter("wagtailapi")
api_router.register_endpoint("pages", PagesAPIViewSet)

# In urls.py
urlpatterns += [path("api/v2/", api_router.urls)]
```

## Search

```python
from wagtail.search import index

class BlogPage(Page, index.Indexed):
    search_fields = Page.search_fields + [
        index.SearchField("intro"),
        index.SearchField("body"),
        index.FilterField("date"),
    ]
```

## Settings

Key Wagtail settings:

```python
WAGTAIL_SITE_NAME = "My Site"
WAGTAILADMIN_BASE_URL = "https://example.com"
WAGTAILIMAGES_IMAGE_MODEL = "app.CustomImage"  # if using custom
WAGTAILSEARCH_BACKENDS = {
    "default": {"BACKEND": "wagtail.search.backends.database"}
}
```

## Management Commands

```bash
uv run python manage.py makemigrations   # Make migrations
uv run python manage.py migrate          # Run migrations
uv run python manage.py createsuperuser  # Create admin user
uv run python manage.py update_index     # Rebuild search index
uv run python manage.py fixtree          # Fix page tree issues
```
