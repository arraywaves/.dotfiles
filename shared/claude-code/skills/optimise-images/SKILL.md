---
name: optimise-images
description: >
  Batch-optimise images for web and app projects. Processes PNG, WebP, JPEG/JPG, AVIF, and GIF
  files using ImageMagick. Outputs to ./optimised by default with per-file results logs.
  Use when the user wants to compress or resize images in a directory for production, reduce
  image file sizes for web/app deployment, or identify images that exceed size or dimension limits.
---

# Optimise Images

Batch image optimiser for web/app projects. Requires ImageMagick 7+.

Install: `brew install imagemagick`

## Usage

```bash
python scripts/optimise-images.py [input_dir] [output_dir]
```

Defaults: `input_dir = .`, `output_dir = <input_dir>/optimised`

## Options

| Flag | Description |
|------|-------------|
| `--png-only` | Process only PNG files |
| `--webp-only` | Process only WebP files |
| `--jpeg-only` | Process only JPEG/JPG files |
| `--avif-only` | Process only AVIF files |
| `--gif-only` | Process only GIF files |
| `--format <ext>` | Convert all output to this format (e.g. `webp`, `avif`, `jpg`, `png`) |
| `--max-size <KB>` | Max output file size in KB (default: 400) |
| `--quality-min <n>` | Minimum quality (default: 70) |
| `--quality-max <n>` | Maximum quality (default: 90) |
| `--low-quality-pattern <str>` | Filename substring that triggers reduced quality range |
| `--low-quality-min <n>` | Min quality for pattern-matched files (default: 50) |
| `--low-quality-max <n>` | Max quality for pattern-matched files (default: 70) |

## Supported Formats

| Format | Alpha | Notes |
|--------|-------|-------|
| PNG | ✓ | Progressive compression, colour reduction fallback |
| WebP | ✓ | Quality-based lossy compression |
| JPEG/JPG | — | Progressive, EXIF stripped, sRGB |
| AVIF | ✓ | Quality-based compression |
| GIF | ✓ | Frame optimisation, colour reduction fallback |

## Dimension Limits

- Standard images: 2048×2048 max
- `@2x` filenames: 4096×4096 max
- `-left` / `-right` filenames: reduced quality range (50–70)

## Output Structure

```
output_dir/
├── results.md        # per-file success/failure log
├── error_log.md      # failed files only
├── _oversized/       # files that couldn't meet the size limit
└── <mirrors input structure>
```

## Retry Behaviour

If an output file is larger than the input (negative reduction), the script retries with
progressively harder compression up to 3 times. Files that still exceed the max size after
all retries are moved to `_oversized/`.
