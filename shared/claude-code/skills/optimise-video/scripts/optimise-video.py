#!/usr/bin/env python3
"""Video optimisation script for web projects.

Produces MP4 (H.264/AAC) and WebM (VP9/Opus) outputs from common video sources.
Requires ffmpeg.

Usage:
    python optimise-video.py [input_dir] [output_dir] [options]

Options:
    --mp4-only               Produce only MP4 output
    --webm-only              Produce only WebM output
    --crf <n>                H.264 CRF quality (0-51, default: 23)
    --webm-crf <n>           VP9 CRF quality (0-63, default: 31)
    --preset <name>          H.264 preset (default: slow)
    --max-width <px>         Max output width in pixels (default: 1920)
    --audio-bitrate <kbps>   Audio bitrate in kbps (default: 128)
    --no-audio               Strip audio from all outputs
    --strip-metadata         Strip all metadata (default: true)
"""

import os
import sys
import subprocess
import argparse
import shutil
from pathlib import Path
from datetime import datetime

# Defaults (overridden by CLI args)
H264_CRF = 23
VP9_CRF = 31
H264_PRESET = 'slow'
MAX_WIDTH = 1920
AUDIO_BITRATE = 128
NO_AUDIO = False
STRIP_METADATA = True

# Supported input extensions
SUPPORTED_FORMATS = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v', '.flv'}

# ANSI colours
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'


def cprint(colour, text, end='\n'):
    print(f"{colour}{text}{NC}", end=end, flush=True)


def file_size(path: str) -> int:
    return os.path.getsize(path)


def human(size_bytes: int) -> str:
    """Return a human-readable file size string."""
    if size_bytes >= 1_048_576:
        return f"{size_bytes / 1_048_576:.1f}MB"
    return f"{size_bytes // 1024}KB"


def probe_dimensions(path: str) -> tuple[int, int]:
    """Return (width, height) of a video using ffprobe, or (0, 0) on failure."""
    try:
        r = subprocess.run(
            ['ffprobe', '-v', 'error', '-select_streams', 'v:0',
             '-show_entries', 'stream=width,height', '-of', 'csv=p=0', path],
            capture_output=True, text=True, timeout=30
        )
        parts = r.stdout.strip().split(',')
        if len(parts) >= 2:
            return int(parts[0]), int(parts[1])
    except Exception:
        pass
    return 0, 0


def build_scale_filter(width: int, height: int) -> str | None:
    """Return an ffmpeg scale filter if the video exceeds MAX_WIDTH, else None."""
    if width <= 0 or width <= MAX_WIDTH:
        return None
    # Scale to MAX_WIDTH, preserve aspect ratio, ensure even dimensions
    return f"scale={MAX_WIDTH}:-2"


def run_ffmpeg(args: list[str]) -> tuple[bool, str]:
    """Run an ffmpeg command. Returns (success, stderr)."""
    try:
        r = subprocess.run(
            ['ffmpeg', '-y', *args],
            capture_output=True, text=True, timeout=600
        )
        return r.returncode == 0, r.stderr
    except subprocess.TimeoutExpired:
        return False, 'ffmpeg timed out after 600s'
    except FileNotFoundError:
        return False, 'ffmpeg not found — install with: brew install ffmpeg'
    except Exception as e:
        return False, str(e)


def encode_mp4(src: str, dst: str, scale_filter: str | None) -> tuple[bool, str]:
    """Encode to H.264/AAC MP4."""
    vf_args = ['-vf', scale_filter] if scale_filter else []
    meta_args = ['-map_metadata', '-1'] if STRIP_METADATA else []
    audio_args = ['-an'] if NO_AUDIO else ['-c:a', 'aac', '-b:a', f'{AUDIO_BITRATE}k']

    cmd = [
        '-i', src,
        '-c:v', 'libx264',
        '-crf', str(H264_CRF),
        '-preset', H264_PRESET,
        *vf_args,
        *audio_args,
        *meta_args,
        '-movflags', '+faststart',
        dst,
    ]
    return run_ffmpeg(cmd)


def encode_webm(src: str, dst: str, scale_filter: str | None) -> tuple[bool, str]:
    """Encode to VP9/Opus WebM."""
    vf_args = ['-vf', scale_filter] if scale_filter else []
    meta_args = ['-map_metadata', '-1'] if STRIP_METADATA else []
    audio_args = ['-an'] if NO_AUDIO else ['-c:a', 'libopus', '-b:a', f'{AUDIO_BITRATE}k']

    cmd = [
        '-i', src,
        '-c:v', 'libvpx-vp9',
        '-crf', str(VP9_CRF),
        '-b:v', '0',
        *vf_args,
        *audio_args,
        *meta_args,
        dst,
    ]
    return run_ffmpeg(cmd)


# ── Per-file processor ────────────────────────────────────────────────────────

def process_file(
    src: str,
    out_dir: str,
    results_log,
    error_log,
    produce_mp4: bool,
    produce_webm: bool,
) -> bool:
    filename = os.path.basename(src)
    stem = Path(src).stem
    in_ext = Path(src).suffix.lower()

    if in_ext not in SUPPORTED_FORMATS:
        return False

    in_size = file_size(src)
    width, height = probe_dimensions(src)
    scale_filter = build_scale_filter(width, height)
    dims_str = f"{width}x{height}" if width > 0 else 'unknown'

    cprint(BLUE, f"\nProcessing: {filename}")
    print(f"  Source:     {human(in_size)}  {dims_str}")

    results_log.write(f"### {filename}\n"
                      f"- **Input**: {src}\n"
                      f"- **Original Size**: {human(in_size)}\n"
                      f"- **Original Dimensions**: {dims_str}\n")

    any_success = False

    # ── MP4 ──────────────────────────────────────────────────────────────────
    if produce_mp4:
        mp4_dst = os.path.join(out_dir, f"{stem}.mp4")
        cprint(BLUE, f"  → MP4 (H.264)  ", end='')
        ok, stderr = encode_mp4(src, mp4_dst, scale_filter)

        if ok and os.path.exists(mp4_dst):
            out_size = file_size(mp4_dst)
            reduction = 100 - (out_size * 100 // in_size) if in_size > 0 else 0
            cprint(GREEN, f"✓  {human(out_size)}  ({reduction:+d}%)")
            results_log.write(f"- **MP4**: ✅ {human(out_size)} ({reduction:+d}% vs source)\n")
            any_success = True
        else:
            cprint(RED, f"✗  failed")
            results_log.write(f"- **MP4**: ❌ Encoding failed\n")
            error_log.write(f"### ❌ {filename} → MP4\n"
                            f"- **Input**: {src}\n"
                            f"- **ffmpeg stderr**: ```\n{stderr[-1000:]}\n```\n\n")

    # ── WebM ─────────────────────────────────────────────────────────────────
    if produce_webm:
        webm_dst = os.path.join(out_dir, f"{stem}.webm")
        cprint(BLUE, f"  → WebM (VP9)   ", end='')
        ok, stderr = encode_webm(src, webm_dst, scale_filter)

        if ok and os.path.exists(webm_dst):
            out_size = file_size(webm_dst)
            reduction = 100 - (out_size * 100 // in_size) if in_size > 0 else 0
            cprint(GREEN, f"✓  {human(out_size)}  ({reduction:+d}%)")
            results_log.write(f"- **WebM**: ✅ {human(out_size)} ({reduction:+d}% vs source)\n")
            any_success = True
        else:
            cprint(RED, f"✗  failed")
            results_log.write(f"- **WebM**: ❌ Encoding failed\n")
            error_log.write(f"### ❌ {filename} → WebM\n"
                            f"- **Input**: {src}\n"
                            f"- **ffmpeg stderr**: ```\n{stderr[-1000:]}\n```\n\n")

    results_log.write('\n')
    return any_success


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='Optimise videos for web projects')
    parser.add_argument('input_dir', nargs='?', default='.',
                        help='Input directory (default: current directory)')
    parser.add_argument('output_dir', nargs='?', default=None,
                        help='Output directory (default: <input_dir>/optimised)')
    parser.add_argument('--mp4-only', action='store_true', help='Produce only MP4 output')
    parser.add_argument('--webm-only', action='store_true', help='Produce only WebM output')
    parser.add_argument('--crf', type=int, default=23, metavar='N',
                        help='H.264 CRF quality (0-51, default: 23)')
    parser.add_argument('--webm-crf', type=int, default=31, metavar='N',
                        help='VP9 CRF quality (0-63, default: 31)')
    parser.add_argument('--preset', default='slow',
                        choices=['ultrafast', 'superfast', 'veryfast', 'faster',
                                 'fast', 'medium', 'slow', 'slower', 'veryslow'],
                        help='H.264 preset (default: slow)')
    parser.add_argument('--max-width', type=int, default=1920, metavar='PX',
                        help='Max output width in pixels (default: 1920)')
    parser.add_argument('--audio-bitrate', type=int, default=128, metavar='KBPS',
                        help='Audio bitrate in kbps (default: 128)')
    parser.add_argument('--no-audio', action='store_true', help='Strip audio from outputs')
    parser.add_argument('--strip-metadata', action='store_true', default=True,
                        help='Strip all metadata (default: true)')
    args = parser.parse_args()

    global H264_CRF, VP9_CRF, H264_PRESET, MAX_WIDTH, AUDIO_BITRATE, NO_AUDIO, STRIP_METADATA
    H264_CRF = args.crf
    VP9_CRF = args.webm_crf
    H264_PRESET = args.preset
    MAX_WIDTH = args.max_width
    AUDIO_BITRATE = args.audio_bitrate
    NO_AUDIO = args.no_audio
    STRIP_METADATA = args.strip_metadata

    produce_mp4 = not args.webm_only
    produce_webm = not args.mp4_only

    input_dir = os.path.abspath(args.input_dir)
    output_dir = (os.path.abspath(args.output_dir)
                  if args.output_dir else os.path.join(input_dir, 'optimised'))

    os.makedirs(output_dir, exist_ok=True)
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # Check ffmpeg is available
    if shutil.which('ffmpeg') is None:
        cprint(RED, 'Error: ffmpeg not found. Install with: brew install ffmpeg')
        sys.exit(1)

    formats_label = 'MP4 + WebM'
    if args.mp4_only:
        formats_label = 'MP4 only'
    elif args.webm_only:
        formats_label = 'WebM only'

    print()
    cprint(BLUE, '=' * 50)
    cprint(BLUE, f'Video Optimisation  [{formats_label}]')
    cprint(BLUE, '=' * 50)
    print(f"  Input:      {input_dir}")
    print(f"  Output:     {output_dir}")
    print(f"  H.264 CRF:  {H264_CRF}  preset: {H264_PRESET}")
    print(f"  VP9 CRF:    {VP9_CRF}")
    print(f"  Max width:  {MAX_WIDTH}px")
    if NO_AUDIO:
        print(f"  Audio:      stripped")
    else:
        print(f"  Audio:      {AUDIO_BITRATE}kbps")

    with (open(os.path.join(output_dir, 'results.md'), 'w') as results_log,
          open(os.path.join(output_dir, 'error_log.md'), 'w') as error_log):

        results_log.write(f"# Video Optimisation Results\n\nGenerated on: {now}\n\n"
                          f"## Settings\n\n"
                          f"- **Formats**: {formats_label}\n"
                          f"- **H.264 CRF**: {H264_CRF}  preset: {H264_PRESET}\n"
                          f"- **VP9 CRF**: {VP9_CRF}\n"
                          f"- **Max Width**: {MAX_WIDTH}px\n"
                          f"- **Audio**: {'stripped' if NO_AUDIO else f'{AUDIO_BITRATE}kbps'}\n\n"
                          f"## Files\n\n")
        error_log.write(f"# Video Optimisation Error Log\n\nGenerated on: {now}\n\n"
                        f"## Failed Encodings\n\n")

        total_ok = 0
        total_files = 0

        # Collect all video files (root + one level of subdirs, mirroring images skill)
        def collect_videos(directory: str) -> list[str]:
            return sorted(
                str(f) for f in Path(directory).iterdir()
                if f.is_file() and f.suffix.lower() in SUPPORTED_FORMATS
            )

        # Root-level files
        root_videos = collect_videos(input_dir)
        if root_videos:
            cprint(BLUE, '\nLocation: (root)')
            print('─' * 40)
            for src in root_videos:
                total_files += 1
                if process_file(src, output_dir, results_log, error_log,
                                produce_mp4, produce_webm):
                    total_ok += 1

        # Subdirectories
        for subdir in sorted(Path(input_dir).iterdir()):
            if not subdir.is_dir():
                continue
            if os.path.realpath(str(subdir)) == os.path.realpath(output_dir):
                continue
            if subdir.name.startswith('.'):
                continue
            # Skip directories that are previous script outputs
            if (subdir / 'results.md').exists() and (subdir / 'error_log.md').exists():
                continue

            sub_videos = collect_videos(str(subdir))
            if not sub_videos:
                continue

            sub_out = os.path.join(output_dir, subdir.name)
            os.makedirs(sub_out, exist_ok=True)

            cprint(BLUE, f'\nLocation: {subdir.name}')
            print('─' * 40)
            for src in sub_videos:
                total_files += 1
                if process_file(src, sub_out, results_log, error_log,
                                produce_mp4, produce_webm):
                    total_ok += 1

        # Summary
        total_failed = total_files - total_ok
        print()
        cprint(BLUE, '=' * 50)
        cprint(BLUE, 'Optimisation Complete')
        cprint(BLUE, '=' * 50)
        print(f"  Files processed:  {GREEN}{total_files}{NC}")
        print(f"  Succeeded:        {GREEN}{total_ok}{NC}")
        if total_failed > 0:
            print(f"  Failed:           {RED}{total_failed}{NC}")
        print()

        results_log.write(f"## Summary\n\n"
                          f"- **Total Files**: {total_files}\n"
                          f"- **Succeeded**: {total_ok}\n"
                          f"- **Failed**: {total_failed}\n"
                          f"- **Completed**: {now}\n\n")
        error_log.write(f"- **Total Errors**: {total_failed}\n"
                        f"- **Completed**: {now}\n\n")

        cprint(BLUE, 'Logs written:')
        print(f"  {GREEN}results.md{NC}   — full per-file log")
        print(f"  {GREEN}error_log.md{NC} — failed encodings only")
        print()

    if total_failed > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()
