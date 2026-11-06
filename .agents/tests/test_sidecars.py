"""Bounded tests for local sidecars; no Flutter or live watcher is required."""
from __future__ import annotations

import fcntl
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
INDEXER_PATH = ROOT / '.agents/sidecars/codebase-index-daemon/indexer_daemon.py'
WATCHER_PATH = ROOT / '.agents/sidecars/test-daemon/test_daemon.py'


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


indexer = load_module('biguess_indexer', INDEXER_PATH)
watcher = load_module('biguess_test_watcher', WATCHER_PATH)


class SidecarTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='biguess-sidecar-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.write('pubspec.yaml', 'name: fixture\n')

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')
        return path

    def invoke(self, script, *args, env=None):
        return subprocess.run(
            [sys.executable, str(script), '--root', str(self.root), *args],
            cwd='/tmp', capture_output=True, text=True, timeout=15, env=env,
        )

    def test_active_tree_includes_agent_and_backend_but_excludes_archives(self):
        for name in ('lib/main.dart', 'test/widget_test.dart', 'backend/src/index.js',
                     '.agents/hooks/check.py', 'old-lib/main.dart', 'old-test/test.dart',
                     'ChatGPT/notes.md', '.agents/cache/stale.md',
                     'backend/node_modules/dependency/index.js', 'ios/Pods/third/file.swift',
                     'lib/model.g.dart', 'build/generated.dart'):
            self.write(name, 'class Fixture {}\n')
        data, _ = indexer.generate_index(self.root)
        paths = {item['path'] for item in data['files']}
        self.assertEqual(paths, {'pubspec.yaml', 'lib/main.dart', 'test/widget_test.dart',
                                'backend/src/index.js', '.agents/hooks/check.py'})

    def test_symbols_include_dart_modifiers_and_multiline_providers(self):
        symbols = indexer.extract_symbols(
            'sealed class Decision {}\nfinal class Result {}\n'
            'abstract base class Base {}\nenum Mode { a }\nmixin Change {}\n'
            'final gameRoundProvider =\n Provider<int>((ref) => 0);\n', '.dart')
        self.assertEqual(symbols, ['class:Decision', 'class:Result', 'class:Base',
                                  'enum:Mode', 'mixin:Change', 'provider:gameRoundProvider'])
        self.assertEqual(indexer.extract_symbols('class NotDart {}', '.py'), [])

    def test_snapshot_detects_add_modify_delete_for_both_sidecars(self):
        for implementation in (indexer, watcher):
            initial = implementation.snapshot(self.root)
            path = self.write('lib/new.dart', 'one')
            added = implementation.snapshot(self.root)
            self.assertNotEqual(initial, added)
            path.write_text('a longer replacement')
            self.assertNotEqual(added, implementation.snapshot(self.root))
            path.unlink()
            self.assertEqual(initial, implementation.snapshot(self.root))

    def test_symlinked_sources_are_not_read(self):
        self.write('old-lib/secret.dart', 'class Secret {}')
        (self.root / 'lib').symlink_to(self.root / 'old-lib', target_is_directory=True)
        self.assertEqual([path.name for path in indexer.source_files(self.root)], ['pubspec.yaml'])
        self.assertEqual(len(watcher.snapshot(self.root)), 1)

    def test_oversized_file_is_reported_without_indexing_content(self):
        self.write('lib/huge.dart', 'x' * (indexer.MAX_FILE_BYTES + 1))
        data, _ = indexer.generate_index(self.root)
        self.assertEqual(data['skipped'], [{'path': 'lib/huge.dart', 'reason': 'over 2 MiB'}])

    def test_once_works_from_other_directory_and_cache_does_not_feed_itself(self):
        self.write('lib/main.dart', 'class App {}\n')
        result = self.invoke(INDEXER_PATH, '--once')
        self.assertEqual(result.returncode, 0, result.stderr)
        cache = self.root / '.agents/cache'
        index = json.loads((cache / 'codebase_index.json').read_text())
        self.assertIn('class:App', index['files'][0]['symbols'])
        self.assertTrue((cache / 'codebase_summary.md').is_file())
        self.assertEqual({p.name for p in cache.iterdir()},
                         {'indexer.lock', 'codebase_index.json', 'codebase_summary.md'})
        before = indexer.snapshot(self.root)
        self.invoke(INDEXER_PATH)
        self.assertEqual(before, indexer.snapshot(self.root))

    def test_process_locks_prevent_duplicate_sidecars(self):
        cache = self.root / '.agents/cache'
        cache.mkdir(parents=True)
        for script, name, code in ((INDEXER_PATH, 'indexer.lock', 0),
                                   (WATCHER_PATH, 'test-watcher.lock', 1)):
            with (cache / name).open('a') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                result = self.invoke(script, '--once')
                self.assertEqual(result.returncode, code, result.stderr)
                self.assertIn('already', result.stderr)

    def test_test_runner_forwards_targets_cwd_and_failure(self):
        binary = self.write('bin/flutter', '#!/usr/bin/env python3\n'
                            'import json, pathlib, sys\n'
                            'pathlib.Path("invocation.json").write_text(json.dumps(sys.argv[1:]))\n'
                            'sys.exit(3)\n')
        binary.chmod(0o755)
        env = dict(os.environ, PATH=f"{binary.parent}:{os.environ['PATH']}")
        result = self.invoke(WATCHER_PATH, '--once', 'test/unit/fixture_test.dart', env=env)
        self.assertEqual(result.returncode, 3, result.stderr)
        self.assertEqual(json.loads((self.root / 'invocation.json').read_text()),
                         ['test', 'test/unit/fixture_test.dart'])

    def test_test_runner_timeout_stops_child(self):
        binary = self.write('bin/flutter', '#!/usr/bin/env python3\nimport time\ntime.sleep(30)\n')
        binary.chmod(0o755)
        env = dict(os.environ, PATH=f"{binary.parent}:{os.environ['PATH']}")
        result = self.invoke(WATCHER_PATH, '--once', '--timeout', '1', env=env)
        self.assertEqual(result.returncode, 124, result.stderr)


if __name__ == '__main__':
    unittest.main()
