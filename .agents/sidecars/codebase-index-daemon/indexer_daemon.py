#!/usr/bin/env python3
"""Index active source locally; --watch is an optional foreground process.

Standard library only. Symbols are navigation hints, not a Dart parser.
"""
from __future__ import annotations

import argparse
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import signal
import sys
import tempfile
import threading

SOURCE_DIRS = (
    'lib', 'test', 'scripts', 'backend', 'android', 'ios', 'web', 'linux',
    'macos', 'windows', '.agents',
)
ROOT_FILES = {
    'AGENTS.md', 'README.md', 'pubspec.yaml', 'analysis_options.yaml',
    'version.json', 'shorebird.yaml', 'cloudflare.md',
}
PRUNE_DIRS = {
    '.git', '.dart_tool', '.gradle', '.idea', '.vscode', '.symlinks',
    '.wrangler', 'build', 'cache', 'node_modules', 'dist', 'venv', '.venv',
    '__pycache__', 'Pods', 'ephemeral', 'flutter',
}
CODE_EXTENSIONS = {
    '.dart', '.yaml', '.yml', '.json', '.md', '.kts', '.gradle', '.xml',
    '.py', '.sh', '.js', '.mjs', '.ts', '.sql', '.html', '.css',
    '.swift', '.kt', '.java', '.cmake', '.cpp', '.h', '.plist',
}
SKIP_FILES = {'pubspec.lock', 'package-lock.json', 'codebase_index.json'}
MAX_FILE_BYTES = 2 * 1024 * 1024
DECLARATION = re.compile(
    r'^\s*(?:(?:abstract|base|final|interface|sealed)\s+)*'
    r'(class|enum|mixin)\s+([A-Za-z_]\w*)', re.MULTILINE,
)
PROVIDER = re.compile(r'^final\s+([A-Za-z_]\w*Provider)\s*=', re.MULTILINE)


def get_project_root() -> Path:
    return Path(__file__).resolve().parents[3]


def source_files(project_root: Path) -> list[Path]:
    """Allowlist active trees so archives, images and cache never feed the index."""
    paths = [project_root / name for name in ROOT_FILES]
    for name in SOURCE_DIRS:
        directory = project_root / name
        if directory.is_symlink() or not directory.is_dir():
            continue
        for current, dirs, files in os.walk(directory, followlinks=False):
            dirs[:] = sorted(
                name for name in dirs if name not in PRUNE_DIRS
                and not (Path(current) / name).is_symlink()
            )
            paths.extend(Path(current) / name for name in sorted(files))
    return sorted(
        path for path in paths
        if not path.is_symlink() and path.is_file()
        and path.name not in SKIP_FILES
        and not path.name.endswith(('.g.dart', '.freezed.dart'))
        and path.suffix.lower() in CODE_EXTENSIONS
    )


def snapshot(project_root: Path) -> tuple[tuple[str, int, int], ...]:
    """Notice additions, deletions and renames, not just the newest file."""
    entries = []
    for path in source_files(project_root):
        try:
            metadata = path.stat()
            entries.append((path.relative_to(project_root).as_posix(),
                            metadata.st_mtime_ns, metadata.st_size))
        except FileNotFoundError:
            continue
    return tuple(entries)


def extract_symbols(content: str, ext: str) -> list[str]:
    if ext != '.dart':
        return []
    return [f'{kind}:{name}' for kind, name in DECLARATION.findall(content)] + [
        f'provider:{name}' for name in PROVIDER.findall(content)
    ]


def generate_index(project_root: Path) -> tuple[dict, str]:
    files = []
    skipped = []
    for path in source_files(project_root):
        relative = path.relative_to(project_root).as_posix()
        try:
            size = path.stat().st_size
            if size > MAX_FILE_BYTES:
                skipped.append({'path': relative, 'reason': 'over 2 MiB'})
                continue
            content = path.read_text(encoding='utf-8')
        except FileNotFoundError:
            continue
        except (OSError, UnicodeError) as error:
            skipped.append({'path': relative, 'reason': type(error).__name__})
            continue
        files.append({
            'path': relative, 'ext': path.suffix.lower(), 'bytes': size,
            'lines': len(content.splitlines()),
            'symbols': extract_symbols(content, path.suffix.lower()),
        })
    data = {
        'schemaVersion': 2,
        'updatedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'totalFiles': len(files),
        'totalLines': sum(item['lines'] for item in files),
        'files': files, 'skipped': skipped,
    }
    lines = [
        '# BiGuess Active Source Index', '',
        f"Generated (UTC): {data['updatedAt']}",
        f"Indexed: {data['totalFiles']} files; {data['totalLines']} source/configuration lines.",
        'Archives, binary assets, dependency/build trees and cache are excluded.',
        'Symbols use regular expressions; verify declarations in source.', '',
    ]
    for prefix in ('lib/', 'test/', 'backend/', 'scripts/', '.agents/'):
        lines.extend([f'## {prefix}', ''])
        for item in files:
            if item['path'].startswith(prefix):
                symbols = ', '.join(item['symbols'])
                suffix = f' — `{symbols}`' if symbols else ''
                lines.append(f"- `{item['path']}` ({item['lines']} lines){suffix}")
        lines.append('')
    return data, '\n'.join(lines)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode='w', encoding='utf-8', dir=path.parent, delete=False,
        ) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def run_once(project_root: Path) -> dict:
    data, summary = generate_index(project_root)
    cache = project_root / '.agents' / 'cache'
    atomic_write(cache / 'codebase_index.json', json.dumps(data, indent=2) + '\n')
    atomic_write(cache / 'codebase_summary.md', summary)
    print(f"Indexed {data['totalFiles']} active files.", file=sys.stderr)
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--once', action='store_true', help='refresh once (default)')
    mode.add_argument('--watch', action='store_true', help='watch in the foreground')
    parser.add_argument('--root', type=Path, default=get_project_root())
    parser.add_argument('--interval', type=float, default=5, help='watch interval, seconds')
    args = parser.parse_args()
    if args.interval < 1:
        parser.error('--interval must be at least 1 second')
    root = args.root.resolve()
    if not (root / 'pubspec.yaml').is_file():
        parser.error('--root must contain pubspec.yaml')
    cache = root / '.agents' / 'cache'
    cache.mkdir(parents=True, exist_ok=True)
    with (cache / 'indexer.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("An indexer already owns this project's cache.", file=sys.stderr)
            return 0
        stopped = threading.Event()
        for event in (signal.SIGINT, signal.SIGTERM):
            signal.signal(event, lambda *_: stopped.set())
        previous = None
        while not stopped.is_set():
            current = snapshot(root)
            if current != previous:
                run_once(root)
                previous = current
            if not args.watch:
                break
            stopped.wait(args.interval)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
