#!/usr/bin/env python3
"""
R3F Performance Auditor

Scans React/Three.js source files for common react-three-fiber performance anti-patterns.

Usage:
    python3 audit.py <path> [--json] [--severity <min>]

Arguments:
    path            Directory or file to scan
    --json          Output results as JSON
    --severity      Minimum severity to report: low, medium, high (default: low)

Examples:
    python3 audit.py ./src
    python3 audit.py ./src --severity medium
    python3 audit.py ./src --json > report.json
"""

import re
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class Finding:
    file: str
    line: int
    severity: str          # "low", "medium", "high"
    rule: str
    message: str
    suggestion: str
    snippet: str = ""


# ---------------------------------------------------------------------------
# Rule definitions
# Each rule has:
#   id          - short identifier
#   severity    - low / medium / high
#   description - shown in output
#   suggestion  - fix hint
#   patterns    - list of (regex, flags) tuples; any match fires the rule
#   context_check - optional callable(lines, match_line_idx) -> bool for
#                   context-sensitive filtering (return False to suppress)
# ---------------------------------------------------------------------------

def _not_in_usememo(lines: list[str], idx: int) -> bool:
    """Return True (report) if the three preceding lines don't show useMemo."""
    window = "\n".join(lines[max(0, idx - 5): idx + 1])
    return "useMemo" not in window and "useRef" not in window


RULES = [
    {
        "id": "unmemoized-geometry",
        "severity": "high",
        "description": "Three.js geometry created outside useMemo/useRef",
        "suggestion": "Wrap in useMemo(() => new THREE.XGeometry(...), []) or use R3F JSX <boxGeometry />",
        "patterns": [
            (r"new\s+THREE\.\w*Geometry\s*\(", 0),
            (r"new\s+THREE\.BufferGeometry\s*\(", 0),
        ],
        "context_check": _not_in_usememo,
    },
    {
        "id": "unmemoized-material",
        "severity": "high",
        "description": "Three.js material created outside useMemo/useRef",
        "suggestion": "Wrap in useMemo(() => new THREE.XMaterial(...), []) or use R3F JSX <meshStandardMaterial />",
        "patterns": [
            (r"new\s+THREE\.\w*Material\s*\(", 0),
        ],
        "context_check": _not_in_usememo,
    },
    {
        "id": "setstate-in-useframe",
        "severity": "high",
        "description": "setState call detected inside useFrame (causes 60+ re-renders/sec)",
        "suggestion": "Use useRef and mutate ref.current directly instead of React state",
        "patterns": [
            # Heuristic: setState/set* call within a useFrame callback
            (r"useFrame\s*\([^)]*(?:\([^)]*\)|[^)])*\{[^}]*set[A-Z]\w*\s*\(", re.DOTALL),
        ],
    },
    {
        "id": "missing-dispose",
        "severity": "medium",
        "description": "Three.js object created without a paired .dispose() call visible nearby",
        "suggestion": "Call geometry.dispose() / material.dispose() / texture.dispose() in a useEffect cleanup",
        "patterns": [
            (r"new\s+THREE\.\w+(?:Geometry|Material|Texture)\s*\(", 0),
        ],
        "context_check": lambda lines, idx: (
            ".dispose()" not in "\n".join(lines[idx:min(len(lines), idx + 20)])
        ),
    },
    {
        "id": "useframe-every-frame-expense",
        "severity": "medium",
        "description": "Potentially expensive operation inside useFrame without throttling",
        "suggestion": "Throttle with a frame counter (if (tick++ % N !== 0) return) or move computation outside the loop",
        "patterns": [
            (r"useFrame\s*\([^{]*\{[^}]*(?:raycaster\.intersect|\.getBoundingBox|JSON\.parse|JSON\.stringify)", re.DOTALL),
        ],
    },
    {
        "id": "usethree-broad",
        "severity": "medium",
        "description": "useThree() called without a selector (subscribes to full store)",
        "suggestion": "Select only what you need: const camera = useThree(state => state.camera)",
        "patterns": [
            (r"useThree\s*\(\s*\)", 0),
        ],
    },
    {
        "id": "no-dpr-limit",
        "severity": "medium",
        "description": "<Canvas> without a dpr limit (defaults to full device pixel ratio)",
        "suggestion": 'Add dpr={[1, 2]} to <Canvas> to cap pixel ratio on high-DPI displays',
        "patterns": [
            (r"<Canvas(?![^>]*\bdpr\b)[^>]*>", re.DOTALL),
        ],
    },
    {
        "id": "frameloop-always",
        "severity": "low",
        "description": "<Canvas> uses frameloop=\"always\" (or default) — verify continuous animation is needed",
        "suggestion": 'Use frameloop="demand" for static/interaction-only scenes and call invalidate() on changes',
        "patterns": [
            (r'<Canvas(?![^>]*frameloop)[^>]*/?>|<Canvas[^>]*frameloop=["\']always["\']', re.DOTALL),
        ],
    },
    {
        "id": "shadow-default-mapsize",
        "severity": "low",
        "description": "castShadow without shadow-mapSize — uses engine default which may be oversized",
        "suggestion": "Set shadow-mapSize={[512, 512]} or [1024, 1024] and tighten shadow camera frustum",
        "patterns": [
            (r"castShadow(?![^<]*shadow-mapSize)", 0),
        ],
    },
    {
        "id": "large-texture-hint",
        "severity": "low",
        "description": "Texture loaded without explicit size check — verify dimensions are power-of-two and appropriately sized",
        "suggestion": "Log texture.image.width/height after load; use KTX2/Basis compression for production",
        "patterns": [
            (r"useTexture\s*\(|TextureLoader\(\)", 0),
        ],
    },
]


EXTENSIONS = {".jsx", ".tsx", ".js", ".ts"}


def scan_file(path: Path, min_severity: str) -> list[Finding]:
    severity_rank = {"low": 0, "medium": 1, "high": 2}
    min_rank = severity_rank.get(min_severity, 0)

    try:
        source = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []

    lines = source.splitlines()
    findings: list[Finding] = []

    for rule in RULES:
        if severity_rank[rule["severity"]] < min_rank:
            continue

        for pattern, flags in rule["patterns"]:
            compiled = re.compile(pattern, flags)
            for m in compiled.finditer(source):
                line_idx = source[:m.start()].count("\n")
                # Optional context filter
                if "context_check" in rule and not rule["context_check"](lines, line_idx):
                    continue

                snippet = lines[line_idx].strip()[:120] if line_idx < len(lines) else ""
                findings.append(Finding(
                    file=str(path),
                    line=line_idx + 1,
                    severity=rule["severity"],
                    rule=rule["id"],
                    message=rule["description"],
                    suggestion=rule["suggestion"],
                    snippet=snippet,
                ))
                break  # one finding per rule per file is enough for most rules

    return findings


def scan_path(target: Path, min_severity: str) -> list[Finding]:
    findings: list[Finding] = []
    if target.is_file():
        if target.suffix in EXTENSIONS:
            findings.extend(scan_file(target, min_severity))
    elif target.is_dir():
        for path in sorted(target.rglob("*")):
            if path.suffix in EXTENSIONS and ".next" not in path.parts and "node_modules" not in path.parts:
                findings.extend(scan_file(path, min_severity))
    return findings


SEVERITY_COLORS = {
    "high":   "\033[31m",  # red
    "medium": "\033[33m",  # yellow
    "low":    "\033[36m",  # cyan
}
RESET = "\033[0m"


def print_text(findings: list[Finding]) -> None:
    if not findings:
        print("No issues found.")
        return

    by_severity = {"high": [], "medium": [], "low": []}
    for f in findings:
        by_severity[f.severity].append(f)

    for sev in ("high", "medium", "low"):
        group = by_severity[sev]
        if not group:
            continue
        color = SEVERITY_COLORS[sev]
        print(f"\n{color}{'━' * 60}{RESET}")
        print(f"{color}[{sev.upper()}] {len(group)} issue(s){RESET}")
        print(f"{color}{'━' * 60}{RESET}")
        for f in group:
            print(f"  {f.file}:{f.line}")
            print(f"  Rule   : {f.rule}")
            print(f"  Message: {f.message}")
            if f.snippet:
                print(f"  Code   : {f.snippet}")
            print(f"  Fix    : {f.suggestion}")
            print()

    counts = {s: len(g) for s, g in by_severity.items() if g}
    summary = ", ".join(f"{c} {s}" for s, c in counts.items())
    total = sum(counts.values())
    print(f"Total: {total} finding(s) — {summary}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit R3F source files for performance anti-patterns")
    parser.add_argument("path", help="File or directory to scan")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    parser.add_argument("--severity", default="low", choices=["low", "medium", "high"],
                        help="Minimum severity to report (default: low)")
    args = parser.parse_args()

    target = Path(args.path)
    if not target.exists():
        print(f"Error: path not found: {target}", file=sys.stderr)
        sys.exit(1)

    findings = scan_path(target, args.severity)

    if args.json:
        print(json.dumps([asdict(f) for f in findings], indent=2))
    else:
        print_text(findings)

    # Exit 1 if any high-severity findings (useful for CI)
    if any(f.severity == "high" for f in findings):
        sys.exit(1)


if __name__ == "__main__":
    main()
