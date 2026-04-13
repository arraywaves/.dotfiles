---
name: optimise-video
description: >
  Batch-optimise videos for web projects. Processes MP4, MOV, AVI, MKV, WebM, M4V, and FLV
  files using ffmpeg. By default exports both MP4 (H.264/AAC) and WebM (VP9/Opus) for broad
  browser compatibility. Outputs to ./optimised by default with per-file results logs.
  Use when the user wants to compress or convert videos for web/app deployment, reduce
  video file sizes for production, or generate multi-format video assets.
---

# Optimise Video

Batch video optimiser for web projects. Requires ffmpeg.

Install: `brew install ffmpeg`

## Usage

```bash
python scripts/optimise-video.py [input_dir] [output_dir]
```

Defaults: `input_dir = .`, `output_dir = <input_dir>/optimised`

By default, each input video produces **two outputs**: an MP4 (H.264 + AAC) and a WebM (VP9 + Opus).

## Options

| Flag | Description |
|------|-------------|
| `--mp4-only` | Produce only MP4 output |
| `--webm-only` | Produce only WebM output |
| `--crf <n>` | H.264 CRF quality (0–51, lower = better, default: 23) |
| `--webm-crf <n>` | VP9 CRF quality (0–63, lower = better, default: 31) |
| `--preset <name>` | H.264 preset: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow (default: slow) |
| `--max-width <px>` | Max output width in pixels — height scales proportionally (default: 1920) |
| `--audio-bitrate <kbps>` | Audio bitrate in kbps (default: 128) |
| `--no-audio` | Strip audio from all outputs |
| `--strip-metadata` | Strip all metadata (default: true) |

## Supported Input Formats

| Format | Notes |
|--------|-------|
| MP4 | Most common web source |
| MOV | macOS / camera capture |
| AVI | Legacy format |
| MKV | Container with mixed codecs |
| WebM | VP8/VP9 source |
| M4V | iTunes video |
| FLV | Flash legacy |

## Output Formats

| Format | Codec | Audio | Compatibility |
|--------|-------|-------|---------------|
| MP4 | H.264 (libx264) | AAC | Universal — all browsers, devices |
| WebM | VP9 (libvpx-vp9) | Opus | Chrome, Firefox, Edge, Safari 14.1+ |

Both outputs use:
- `-movflags +faststart` (MP4) — enables progressive streaming before full download
- Even pixel dimensions — required by H.264 and VP9
- Metadata stripped by default

## Dimension Behaviour

Videos wider than `--max-width` are scaled down maintaining aspect ratio. Height is calculated
automatically and rounded to the nearest even number. Videos already within limits are not upscaled.

## Output Structure

```
output_dir/
├── results.md        # per-file success/failure log
├── error_log.md      # failed files only
└── <mirrors input structure>
    ├── video.mp4
    └── video.webm
```
