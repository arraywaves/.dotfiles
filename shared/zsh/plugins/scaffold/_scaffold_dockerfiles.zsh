# ── Dockerfiles ───────────────────────────────────────────────────────────────
_create_dockerfile_wagtail() {
  cat > Dockerfile <<'EOF'
FROM python:3.14-slim-bookworm AS builder

RUN apt-get update --yes --quiet && apt-get install --yes --quiet --no-install-recommends \
    build-essential \
    libpq-dev \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    libwebp-dev \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

FROM python:3.14-slim-bookworm

RUN apt-get update --yes --quiet && apt-get install --yes --quiet --no-install-recommends \
    libpq5 \
    libjpeg62-turbo \
    libwebp7 \
 && rm -rf /var/lib/apt/lists/*

RUN useradd wagtail

EXPOSE 8000

ENV PYTHONUNBUFFERED=1 \
    PORT=8000 \
    PATH="/app/.venv/bin:$PATH"

COPY --from=builder /app/.venv /app/.venv

WORKDIR /app
RUN chown wagtail:wagtail /app

COPY --chown=wagtail:wagtail . .

USER wagtail

ARG SECRET_KEY=build-placeholder
RUN SECRET_KEY=$SECRET_KEY python manage.py collectstatic --noinput --clear

CMD set -xe; python manage.py migrate --noinput; gunicorn app.wsgi:application --bind 0.0.0.0:${PORT:-8000}
EOF
}

_create_dockerfile_wagtail_pg() {
  cat > Dockerfile <<'EOF'
FROM python:3.14-slim-bookworm AS builder

RUN apt-get update --yes --quiet && apt-get install --yes --quiet --no-install-recommends \
    build-essential \
    libpq-dev \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    libwebp-dev \
 && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

FROM python:3.14-slim-bookworm

RUN apt-get update --yes --quiet && apt-get install --yes --quiet --no-install-recommends \
    libpq5 \
    libjpeg62-turbo \
    libwebp7 \
 && rm -rf /var/lib/apt/lists/*

RUN useradd wagtail

EXPOSE 8000

ENV PYTHONUNBUFFERED=1 \
    PORT=8000 \
    PATH="/app/.venv/bin:$PATH"

COPY --from=builder /app/.venv /app/.venv

WORKDIR /app
RUN chown wagtail:wagtail /app

COPY --chown=wagtail:wagtail . .

USER wagtail

ARG SECRET_KEY=build-placeholder
RUN SECRET_KEY=$SECRET_KEY python manage.py collectstatic --noinput --clear

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" || exit 1

CMD set -xe; python manage.py migrate --noinput; gunicorn app.wsgi:application --bind 0.0.0.0:${PORT:-8000}
EOF
}
