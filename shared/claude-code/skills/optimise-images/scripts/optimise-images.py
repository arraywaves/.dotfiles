#!/usr/bin/env python3
"""Image optimisation script for web/app projects.

Supports PNG, WebP, JPEG/JPG, AVIF, GIF with alpha preservation where applicable.
Requires ImageMagick 7+ (magick command).

Usage:
    python optimise-images.py [input_dir] [output_dir] [options]

Options:
    --png-only               Process only PNG files
    --webp-only              Process only WebP files
    --jpeg-only              Process only JPEG/JPG files
    --avif-only              Process only AVIF files
    --gif-only               Process only GIF files
    --format <ext>           Convert all output to this format (e.g. webp, avif, jpg, png)
    --max-size <KB>          Max output file size in KB (default: 400)
    --quality-min <n>        Min quality (default: 70)
    --quality-max <n>        Max quality (default: 90)
    --low-quality-pattern    Filename substring that triggers reduced quality range
    --low-quality-min <n>    Min quality for matched files (default: 50)
    --low-quality-max <n>    Max quality for matched files (default: 70)
"""

import os
import sys
import subprocess
import argparse
import random
import shutil
from pathlib import Path
from datetime import datetime

# Quality settings (overridden by CLI args)
STANDARD_QUALITY_MIN = 70
STANDARD_QUALITY_MAX = 90
LOW_QUALITY_MIN = 50
LOW_QUALITY_MAX = 70
MAX_FILE_SIZE = 400_000  # bytes

# Supported input formats
SUPPORTED_FORMATS = {'.png', '.webp', '.jpg', '.jpeg', '.avif', '.gif'}

# ANSI colours
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'


def cprint(colour, text, end='\n'):
    print(f"{colour}{text}{NC}", end=end, flush=True)


def get_dimension_limit(filename: str) -> int:
    return 4096 if '@2x' in filename else 2048


def get_quality(filename: str, low_pattern: str) -> int:
    if low_pattern and low_pattern in filename:
        return random.randint(LOW_QUALITY_MIN, LOW_QUALITY_MAX)
    return random.randint(STANDARD_QUALITY_MIN, STANDARD_QUALITY_MAX)


def file_size(path: str) -> int:
    return os.path.getsize(path)


def get_dimensions(path: str) -> str:
    try:
        r = subprocess.run(['identify', '-format', '%wx%h', path], capture_output=True, text=True)
        return r.stdout.strip() or 'unknown'
    except Exception:
        return 'unknown'


def magick(*args) -> bool:
    try:
        r = subprocess.run(['magick', *args], capture_output=True)
        return r.returncode == 0
    except Exception:
        return False


# ── Format processors ─────────────────────────────────────────────────────────

def process_png(src: str, dst: str, dim: int, quality: int) -> bool:
    if not magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(quality),
                  '-alpha', 'on', '-background', 'none',
                  '-define', 'png:compression-level=9', dst):
        return False
    for colors in (192, 128):
        if file_size(dst) > MAX_FILE_SIZE:
            magick(src, '-resize', f'{dim}x{dim}>', '-colors', str(colors),
                   '-alpha', 'on', '-background', 'none', '-strip',
                   '-define', 'png:compression-level=9', dst)
    return True


def process_webp(src: str, dst: str, dim: int, quality: int) -> bool:
    if not magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(quality),
                  '-define', 'webp:lossless=false', dst):
        return False
    q = quality
    for step in (20, 15):
        if file_size(dst) > MAX_FILE_SIZE:
            q = max(15, q - step)
            magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(q),
                   '-define', 'webp:lossless=false', '-strip', dst)
    return True


def process_jpeg(src: str, dst: str, dim: int, quality: int) -> bool:
    if not magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(quality),
                  '-strip', '-interlace', 'Plane', '-sampling-factor', '4:2:0',
                  '-colorspace', 'sRGB', dst):
        return False
    q = quality
    for step in (15, 15):
        if file_size(dst) > MAX_FILE_SIZE:
            q = max(30, q - step)
            magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(q), '-strip', dst)
    return True


def process_avif(src: str, dst: str, dim: int, quality: int) -> bool:
    if not magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(quality), dst):
        return False
    q = quality
    for step in (20, 15):
        if file_size(dst) > MAX_FILE_SIZE:
            q = max(20, q - step)
            magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(q), '-strip', dst)
    return True


def process_gif(src: str, dst: str, dim: int) -> bool:
    if not magick(src, '-coalesce', '-resize', f'{dim}x{dim}>', '-deconstruct',
                  '-layers', 'Optimize', dst):
        return False
    if file_size(dst) > MAX_FILE_SIZE:
        magick(src, '-coalesce', '-resize', f'{dim}x{dim}>', '-colors', '128',
               '-deconstruct', '-layers', 'Optimize', dst)
    return True


def dispatch(src: str, dst: str, dim: int, quality: int, out_ext: str) -> bool:
    """Dispatch to the correct processor based on OUTPUT format."""
    if out_ext == '.png':
        return process_png(src, dst, dim, quality)
    elif out_ext == '.webp':
        return process_webp(src, dst, dim, quality)
    elif out_ext in ('.jpg', '.jpeg'):
        return process_jpeg(src, dst, dim, quality)
    elif out_ext == '.avif':
        return process_avif(src, dst, dim, quality)
    elif out_ext == '.gif':
        return process_gif(src, dst, dim)
    return False


# ── Retry helpers ─────────────────────────────────────────────────────────────

def retry_png(src: str, dst: str, dim: int, attempt: int):
    colors, dither = [(96, False), (64, False), (32, True)][attempt - 1]
    args = [src, '-resize', f'{dim}x{dim}>', '-colors', str(colors),
            '-alpha', 'on', '-background', 'none', '-strip',
            '-define', 'png:compression-level=9']
    if dither:
        args += ['-dither', 'FloydSteinberg']
    magick(*args, dst)


def retry_lossy(src: str, dst: str, dim: int, quality: int, attempt: int, ext: str):
    if ext in ('.jpg', '.jpeg'):
        q = max(30, quality - 15 * attempt)
        magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(q), '-strip', dst)
    elif ext == '.webp':
        q = max(10, quality - 20 * attempt)
        magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(q),
               '-define', 'webp:lossless=false', '-strip', dst)
    elif ext == '.avif':
        q = max(20, quality - 20 * attempt)
        magick(src, '-resize', f'{dim}x{dim}>', '-quality', str(q), '-strip', dst)


# ── Main processor ────────────────────────────────────────────────────────────

def process_file(src: str, dst: str, oversized_dir: str,
                 results_log, error_log, format_filters: set,
                 output_format: str, low_pattern: str) -> bool:
    filename = os.path.basename(src)
    in_ext = Path(src).suffix.lower()

    # Format filter (based on input format)
    if format_filters and in_ext not in format_filters:
        return False

    # Determine output extension and path
    out_ext = output_format if output_format else in_ext
    if out_ext not in SUPPORTED_FORMATS:
        cprint(RED, f' ✗ Unknown output format: {out_ext}')
        return False

    # Replace extension in dst if converting formats
    if out_ext != in_ext:
        dst = str(Path(dst).with_suffix(out_ext))

    dim = get_dimension_limit(filename)
    quality = get_quality(filename, low_pattern)
    in_size = file_size(src)
    in_kb = in_size // 1024
    in_dims = get_dimensions(src)

    cprint(BLUE, f"Processing: {filename:<50}", end='')

    results_log.write(f"### Processing: {filename}\n"
                      f"- **Input**: {src}\n"
                      f"- **Output**: {dst}\n"
                      f"- **Format**: {in_ext} → {out_ext}\n"
                      f"- **Original Size**: {in_kb}KB\n"
                      f"- **Original Dimensions**: {in_dims}\n")

    ok = dispatch(src, dst, dim, quality, out_ext)

    if not ok or not os.path.exists(dst):
        cprint(RED, ' ✗ Conversion failed')
        results_log.write("- **Status**: ❌ Conversion failed\n\n")
        error_log.write(f"### ❌ {filename} - Conversion failed\n"
                        f"- **Input**: {src}\n"
                        f"- **Error**: {in_ext} → {out_ext} conversion failed\n\n")
        return False

    out_size = file_size(dst)
    out_kb = out_size // 1024
    out_dims = get_dimensions(dst)
    reduction = 100 - (out_size * 100 // in_size)

    # Retry loop for negative reduction
    for attempt in range(1, 4):
        if reduction >= 0:
            break
        cprint(YELLOW, f" ⚠ Negative reduction ({reduction}%), retrying...", end='')
        if out_ext == '.png':
            retry_png(src, dst, dim, attempt)
        elif out_ext != '.gif':
            retry_lossy(src, dst, dim, quality, attempt, out_ext)

        if os.path.exists(dst):
            out_size = file_size(dst)
            out_kb = out_size // 1024
            reduction = 100 - (out_size * 100 // in_size)
            out_dims = get_dimensions(dst)

        print(f"\n  Retry {attempt}: {reduction}% reduction")
        results_log.write(f"- **Retry {attempt}**: {reduction}% reduction\n")

    # Oversized check
    if out_size > MAX_FILE_SIZE:
        max_kb = MAX_FILE_SIZE // 1024
        out_filename = os.path.basename(dst)
        cprint(YELLOW, f" ⚠ Exceeds {max_kb}KB limit ({out_kb}KB) - moving to _oversized")
        results_log.write(f"- **Status**: ⚠ Exceeds {max_kb}KB limit - moved to _oversized\n"
                          f"- **Final Size**: {out_kb}KB\n\n")
        error_log.write(f"### ⚠ {filename} - {max_kb}KB size limit exceeded (moved to _oversized)\n"
                        f"- **Input**: {src}\n"
                        f"- **Final Size**: {out_kb}KB (exceeds {max_kb}KB limit)\n"
                        f"- **Location**: Moved to _oversized folder\n\n")
        try:
            shutil.move(dst, os.path.join(oversized_dir, out_filename))
        except Exception:
            os.remove(dst)
        return False

    # Negative reduction after retries
    if reduction < 0:
        cprint(RED, f" ✗ Could not achieve size reduction (final: {reduction}%)")
        results_log.write(f"- **Status**: ❌ Could not achieve size reduction\n"
                          f"- **Final Reduction**: {reduction}%\n\n")
        error_log.write(f"### ❌ {filename} - Size reduction failed\n"
                        f"- **Input**: {src}\n"
                        f"- **Final Reduction**: {reduction}% (negative size increase)\n\n")
        if os.path.exists(dst):
            os.remove(dst)
        return False

    cprint(GREEN, ' ✓')
    print(f"  Dimensions: {in_dims:<15} → {out_dims:<15}")
    print(f"  Size:       {in_kb}KB{'':<12} → {out_kb}KB{'':<12} ({reduction}% reduction)")

    results_log.write(f"- **Status**: ✅ Success\n"
                      f"- **Final Size**: {out_kb}KB\n"
                      f"- **Final Dimensions**: {out_dims}\n"
                      f"- **Size Reduction**: {reduction}%\n\n")
    return True


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='Optimise images for web/app projects')
    parser.add_argument('input_dir', nargs='?', default='.',
                        help='Input directory (default: current directory)')
    parser.add_argument('output_dir', nargs='?', default=None,
                        help='Output directory (default: <input_dir>/optimised)')
    parser.add_argument('--png-only', action='store_true')
    parser.add_argument('--webp-only', action='store_true')
    parser.add_argument('--jpeg-only', action='store_true')
    parser.add_argument('--avif-only', action='store_true')
    parser.add_argument('--gif-only', action='store_true')
    parser.add_argument('--format', metavar='EXT',
                        help='Convert all output to this format (e.g. webp, avif, jpg, png)')
    parser.add_argument('--max-size', type=int, default=400, metavar='KB',
                        help='Max output file size in KB (default: 400)')
    parser.add_argument('--quality-min', type=int, default=70)
    parser.add_argument('--quality-max', type=int, default=90)
    parser.add_argument('--low-quality-pattern', metavar='PATTERN', default='',
                        help='Filename substring that triggers reduced quality range')
    parser.add_argument('--low-quality-min', type=int, default=50)
    parser.add_argument('--low-quality-max', type=int, default=70)
    args = parser.parse_args()

    input_dir = os.path.abspath(args.input_dir)
    output_dir = (os.path.abspath(args.output_dir)
                  if args.output_dir else os.path.join(input_dir, 'optimised'))

    global MAX_FILE_SIZE, STANDARD_QUALITY_MIN, STANDARD_QUALITY_MAX, LOW_QUALITY_MIN, LOW_QUALITY_MAX
    MAX_FILE_SIZE = args.max_size * 1024
    STANDARD_QUALITY_MIN = args.quality_min
    STANDARD_QUALITY_MAX = args.quality_max
    LOW_QUALITY_MIN = args.low_quality_min
    LOW_QUALITY_MAX = args.low_quality_max

    # Normalise output format
    output_format = ''
    if args.format:
        output_format = args.format.lower().lstrip('.')
        # Normalise aliases
        if output_format == 'jpeg':
            output_format = 'jpg'
        output_format = f'.{output_format}'
        if output_format not in SUPPORTED_FORMATS:
            print(f"Unsupported output format: {args.format}")
            print(f"Supported: {', '.join(sorted(f.lstrip('.') for f in SUPPORTED_FORMATS))}")
            sys.exit(1)

    format_filters: set = set()
    if args.png_only:
        format_filters.add('.png')
    if args.webp_only:
        format_filters.add('.webp')
    if args.jpeg_only:
        format_filters.update({'.jpg', '.jpeg'})
    if args.avif_only:
        format_filters.add('.avif')
    if args.gif_only:
        format_filters.add('.gif')

    low_pattern = args.low_quality_pattern
    oversized_dir = os.path.join(output_dir, '_oversized')
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(oversized_dir, exist_ok=True)

    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    with (open(os.path.join(output_dir, 'results.md'), 'w') as results_log,
          open(os.path.join(output_dir, 'error_log.md'), 'w') as error_log):

        results_log.write(f"# Image Optimisation Results\n\nGenerated on: {now}\n\n## Summary\n\n")
        error_log.write(f"# Image Optimisation Error Log\n\nGenerated on: {now}\n\n## Failed Optimisations\n\n")

        format_note = f' → {output_format.lstrip(".")}' if output_format else ''
        print()
        cprint(BLUE, '=' * 40)
        cprint(BLUE, f'Image Optimisation{format_note}')
        cprint(BLUE, '=' * 40)
        print()

        # Root-level files
        cprint(BLUE, 'Location: (root)')
        print('---')
        for f in sorted(Path(input_dir).iterdir()):
            if f.is_file() and f.suffix.lower() in SUPPORTED_FORMATS:
                process_file(str(f), os.path.join(output_dir, f.name),
                             oversized_dir, results_log, error_log,
                             format_filters, output_format, low_pattern)
        print()

        # Subdirectories
        for subdir in sorted(Path(input_dir).iterdir()):
            if not subdir.is_dir():
                continue
            if os.path.realpath(str(subdir)) == os.path.realpath(output_dir):
                continue
            # Skip directories that are previous script outputs (contain marker files)
            if (subdir / 'results.md').exists() and (subdir / 'error_log.md').exists():
                continue
            if subdir.name.startswith('.'):
                continue

            sub_out = os.path.join(output_dir, subdir.name)
            os.makedirs(sub_out, exist_ok=True)
            cprint(BLUE, f'Location: {subdir.name}')
            print('---')
            for f in sorted(subdir.iterdir()):
                if f.is_file() and f.suffix.lower() in SUPPORTED_FORMATS:
                    process_file(str(f), os.path.join(sub_out, f.name),
                                 oversized_dir, results_log, error_log,
                                 format_filters, output_format, low_pattern)
            print()

        # Verification pass
        cprint(BLUE, '=' * 40)
        cprint(BLUE, 'Verification')
        cprint(BLUE, '=' * 40)
        print()

        violations = 0
        for f in sorted(Path(output_dir).rglob('*')):
            if not f.is_file() or f.suffix.lower() not in SUPPORTED_FORMATS:
                continue
            if '_oversized' in f.parts:
                continue
            sz = file_size(str(f))
            dim_limit = get_dimension_limit(f.name)
            dims = get_dimensions(str(f))

            if sz > MAX_FILE_SIZE:
                cprint(RED, f"✗ Size violation: {f.name} ({sz // 1024}KB exceeds {MAX_FILE_SIZE // 1024}KB)")
                violations += 1
            try:
                w, h = map(int, dims.split('x'))
                if w > dim_limit or h > dim_limit:
                    cprint(RED, f"✗ Dimension violation: {f.name} ({dims} exceeds {dim_limit}x{dim_limit})")
                    violations += 1
            except Exception:
                pass

        if violations == 0:
            cprint(GREEN, '✓ All files meet constraints')
        else:
            cprint(RED, f'✗ {violations} constraint violations found')

        # Final summary
        all_out = [f for f in Path(output_dir).rglob('*')
                   if f.is_file() and f.suffix.lower() in SUPPORTED_FORMATS]
        total_files = len(all_out)
        total_mb = sum(file_size(str(f)) for f in all_out) // (1024 * 1024)

        print()
        cprint(BLUE, '=' * 40)
        cprint(BLUE, 'Optimisation Complete')
        cprint(BLUE, '=' * 40)
        print()
        print(f"Total files optimised: {GREEN}{total_files}{NC}")
        print(f"Total size: {GREEN}{total_mb}MB{NC}")
        cprint(GREEN, 'Finished')
        print()

        results_log.write(f"- **Total Files Processed**: {total_files}\n"
                          f"- **Total Output Size**: {total_mb}MB\n"
                          f"- **Completed**: {now}\n\n")
        error_log.write(f"- **Total Errors**: {violations}\n"
                        f"- **Completed**: {now}\n\n")

        cprint(BLUE, 'Logs created:')
        print(f"- {GREEN}results.md{NC} - Detailed processing results")
        print(f"- {GREEN}error_log.md{NC} - Failed optimisations only")
        print()

    if violations > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()
