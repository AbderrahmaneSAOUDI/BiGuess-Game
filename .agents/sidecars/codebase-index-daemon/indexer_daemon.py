#!/usr/bin/env python3
"""BiGuess Continuous Background Codebase Index Daemon.

Maintains a fresh index of files, models, widgets, and symbols in:
- .agents/cache/codebase_index.json
- .agents/cache/codebase_summary.md
"""

from __future__ import annotations
import datetime
import json
import os
import re
import sys
import time
from pathlib import Path

CURRENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CURRENT_DIR.parents[2]
CACHE_DIR = PROJECT_ROOT / ".agents" / "cache"
INDEX_FILE = CACHE_DIR / "codebase_index.json"
SUMMARY_FILE = CACHE_DIR / "codebase_summary.md"
LOG_FILE = CURRENT_DIR / "indexer_daemon.log"
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "5"))

PRUNE_DIRS = {
    ".git", ".dart_tool", "build", "node_modules", "dist", "venv", ".venv",
    "__pycache__", ".idea", ".vscode", "ios/Pods", ".symlinks", "TO_BE_DELETED"
}

CODE_EXTENSIONS = {
    ".dart", ".yaml", ".json", ".md", ".kts", ".gradle", ".xml", ".py", ".sh"
}

CLASS_REGEX = re.compile(r'^\s*(?:abstract\s+)?class\s+([A-Za-z0-9_]+)', re.MULTILINE)
ENUM_REGEX = re.compile(r'^\s*enum\s+([A-Za-z0-9_]+)', re.MULTILINE)
MIXIN_REGEX = re.compile(r'^\s*mixin\s+([A-Za-z0-9_]+)', re.MULTILINE)

def log(msg: str) -> None:
    entry = f"[{datetime.datetime.now().isoformat()}] {msg}\n"
    sys.stdout.write(entry)
    sys.stdout.flush()
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(entry)
    except Exception:
        pass

def extract_symbols(content: str, ext: str) -> list[str]:
    if ext != ".dart":
        return []
    symbols = []
    for m in CLASS_REGEX.finditer(content):
        symbols.append(f"class:{m.group(1)}")
    for m in ENUM_REGEX.finditer(content):
        symbols.append(f"enum:{m.group(1)}")
    for m in MIXIN_REGEX.finditer(content):
        symbols.append(f"mixin:{m.group(1)}")
    return symbols

def generate_index() -> tuple[dict, str]:
    files_list = []
    total_lines = 0

    for root, dirs, files in os.walk(PROJECT_ROOT):
        dirs[:] = [d for d in dirs if d not in PRUNE_DIRS and not d.startswith(".")]
        for file in files:
            if file in ("pubspec.lock", "package-lock.json", "codebase_index.json"):
                continue
            ext = os.path.splitext(file)[1]
            if ext in CODE_EXTENSIONS:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, PROJECT_ROOT)
                try:
                    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                    lines = len(content.splitlines())
                    total_lines += lines
                    symbols = extract_symbols(content, ext)
                    files_list.append({
                        "path": rel_path,
                        "lines": lines,
                        "ext": ext,
                        "symbols": symbols
                    })
                except Exception:
                    pass

    data = {
        "updatedAt": datetime.datetime.now().isoformat(),
        "totalFiles": len(files_list),
        "totalLines": total_lines,
        "files": sorted(files_list, key=lambda x: x["path"])
    }

    # Markdown summary
    summary_lines = [
        "# BiGuess Codebase Summary",
        f"- **Last Updated:** {data['updatedAt']}",
        f"- **Total Indexed Files:** {data['totalFiles']}",
        f"- **Total Lines of Code:** {data['totalLines']}",
        "",
        "## Core Modules & Key Files",
    ]

    for item in data["files"]:
        if item["path"].startswith("lib/"):
            syms = f" — symbols: `{', '.join(item['symbols'])}`" if item["symbols"] else ""
            summary_lines.append(f"- **`{item['path']}`** ({item['lines']} lines){syms}")

    return data, "\n".join(summary_lines) + "\n"

def get_latest_mtime() -> float:
    latest = 0.0
    for root, dirs, files in os.walk(PROJECT_ROOT):
        dirs[:] = [d for d in dirs if d not in PRUNE_DIRS and not d.startswith(".")]
        for file in files:
            if file in ("pubspec.lock", "package-lock.json", "codebase_index.json"):
                continue
            ext = os.path.splitext(file)[1]
            if ext in CODE_EXTENSIONS:
                try:
                    mtime = os.path.getmtime(os.path.join(root, file))
                    if mtime > latest:
                        latest = mtime
                except Exception:
                    pass
    return latest

def run_once() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    data, summary = generate_index()
    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    with open(SUMMARY_FILE, "w", encoding="utf-8") as f:
        f.write(summary)
    log(f"Indexed {data['totalFiles']} files ({data['totalLines']} lines).")

def main() -> None:
    if "--once" in sys.argv:
        run_once()
        return

    log("BiGuess Codebase Index Daemon started.")
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    last_mtime = 0.0

    while True:
        try:
            current_mtime = get_latest_mtime()
            if current_mtime > last_mtime:
                log("Detected file modifications. Regenerating index...")
                data, summary = generate_index()
                with open(INDEX_FILE, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2)
                with open(SUMMARY_FILE, "w", encoding="utf-8") as f:
                    f.write(summary)
                last_mtime = current_mtime
                log(f"Indexed {data['totalFiles']} files ({data['totalLines']} lines).")
        except Exception as e:
            log(f"Error indexing: {e}")

        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
