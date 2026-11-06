"""Exercise lifecycle hooks against disposable checkouts and stdin JSON events."""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
HOOKS = ROOT / '.agents/hooks'
HOOK_FILES = (
    'hook_common.py', 'project_check.py', 'dangerous_command_guard.py',
    'session_start.py', 'stop_guard.py',
)


def load_hook(name):
    sys.path.insert(0, str(HOOKS))
    try:
        spec = importlib.util.spec_from_file_location(f'biguess_hook_{name}', HOOKS / f'{name}.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        sys.path.pop(0)


guard = load_hook('dangerous_command_guard')
check = load_hook('project_check')


class HookTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='biguess-hooks-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for name in HOOK_FILES:
            path = self.root / '.agents/hooks' / name
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(HOOKS / name, path)
        self.write('pubspec.yaml', 'name: fixture\nversion: 1.2.3+4\n')
        self.manifest = {'latest_version': '1.2.3', 'build_number': 4, 'release_notes': 'fixture'}
        self.write_manifest()
        self.write('lib/core/constants/app_constants.dart',
                   "class AppConstants {\n  static const String defaultVersion = '1.2.3';\n}\n")

    def write(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding='utf-8')
        return path

    def write_manifest(self):
        self.write('version.json', json.dumps(self.manifest))

    def invoke(self, script, event=None, *args, raw=None):
        result = subprocess.run(
            [sys.executable, str(self.root / '.agents/hooks' / script), *args],
            input=raw if raw is not None else json.dumps(event or {}),
            text=True, capture_output=True, cwd='/tmp', timeout=15,
            env=dict(os.environ, PYTHONDONTWRITEBYTECODE='1', GIT_OPTIONAL_LOCKS='0'),
        )
        try:
            output = json.loads(result.stdout)
        except ValueError:
            self.fail(f'{script} did not emit one JSON value: {result.stdout!r}; {result.stderr!r}')
        self.assertIsInstance(output, dict)
        self.assertEqual(result.stderr, '', result.stderr)
        return result.returncode, output

    def source_snapshot(self):
        return {path.relative_to(self.root).as_posix(): path.read_bytes()
                for path in self.root.rglob('*') if path.is_file()}

    def test_command_extraction_understands_current_and_legacy_shapes(self):
        command = 'git reset --hard'
        events = [
            {'tool_name': 'Bash', 'tool_input': {'command': command}},
            {'tool_name': 'exec_command', 'tool_input': {'cmd': command}},
            {'tool_input': json.dumps({'cmd': command})},
            {'toolCall': {'args': {'CommandLine': command}}},
            {'tool_call': {'arguments': json.dumps({'command': command})}},
            {'command': command},
        ]
        for event in events:
            with self.subTest(event=event):
                self.assertEqual(guard.command_from_event(event), command)
                code, output = self.invoke('dangerous_command_guard.py', event)
                self.assertEqual(code, 0)
                self.assertEqual(output['hookSpecificOutput']['permissionDecision'], 'deny')
                self.assertEqual(output['hookSpecificOutput']['hookEventName'], 'PreToolUse')

    def test_ordinary_commands_and_quoted_text_remain_allowed(self):
        for command in (
            "echo 'git reset --hard'", "printf '%s' 'rm -rf lib'",
            "echo ':(){ :|:& };:'", 'rm -rf /tmp/biguess-cache',
            'rm lib/obsolete.dart', 'flutter test', 'git diff',
            'git push origin feature', 'git push --force-with-lease origin feature',
        ):
            with self.subTest(command=command):
                self.assertIsNone(guard.dangerous_reason(command, self.root))
                code, output = self.invoke('dangerous_command_guard.py', {'tool_input': {'cmd': command}})
                self.assertEqual((code, output), (0, {}))

    def test_obvious_destructive_operations_are_denied(self):
        for command in (
            'git reset --hard', 'git reset --hard=HEAD', 'git -C lib reset --hard HEAD',
            'git push --force origin main', 'git push -f origin', 'git push origin +HEAD:main',
            'rm -rf lib assets test scripts .git', 'rm -f pubspec.yaml version.json shorebird.yaml',
            'rm -rf .', 'rm -rf ..', 'rm -rf /', 'rm -rf "$HOME"',
            'sudo rm -rf lib', 'env EXAMPLE=1 rm -rf assets',
            "bash -lc 'rm -rf lib'", 'mkfs.ext4 /dev/example',
            'dd if=/dev/zero of=/dev/example', ':(){ :|:& };:', 'true; :(){ :|:& };:',
        ):
            with self.subTest(command=command):
                self.assertIsNotNone(guard.dangerous_reason(command, self.root))

    def test_nested_cwd_and_cd_cannot_delete_source_roots(self):
        nested = self.root / 'lib/presentation'
        nested.mkdir(parents=True)
        for command in ('rm -rf ..', 'rm -rf ../..', 'rm -rf ../../assets'):
            with self.subTest(command=command):
                event = {'cwd': str(nested), 'tool_input': {'cmd': command}}
                code, output = self.invoke('dangerous_command_guard.py', event)
                self.assertEqual(code, 0)
                self.assertEqual(output['hookSpecificOutput']['permissionDecision'], 'deny')
        self.assertIsNotNone(guard.dangerous_reason('cd lib/presentation && rm -rf ..', self.root))

    def test_missing_and_malformed_events_are_json_noops(self):
        for raw in ('', '{broken', 'null', '[]', 'true', '{"tool_input": 7}',
                    '{"tool_call": "not an object"}', '{"tool_input": "not json"}'):
            with self.subTest(raw=raw):
                self.assertEqual(self.invoke('dangerous_command_guard.py', raw=raw), (0, {}))

    def test_version_check_accepts_synced_triad_comments_and_both_dart_quotes(self):
        self.assertEqual(check.version_issues(self.root), [])
        self.write('pubspec.yaml', 'version: 1.2.3+4  # comment\n')
        self.write('lib/core/constants/app_constants.dart',
                   'class AppConstants {\n  static const String defaultVersion = "1.2.3";\n}\n')
        self.assertEqual(check.version_issues(self.root), [])
        self.assertEqual(self.invoke('project_check.py', {}, '--check'), (0, {'ok': True, 'issues': []}))

    def test_version_check_reports_each_drift_without_modifying_files(self):
        self.manifest.update(latest_version='1.2.4', build_number=5)
        self.write_manifest()
        self.write('lib/core/constants/app_constants.dart',
                   "class AppConstants {\n  static const String defaultVersion = '9.9.9';\n}\n")
        before = self.source_snapshot()
        issues = check.version_issues(self.root)
        self.assertEqual(len(issues), 3)
        code, output = self.invoke('project_check.py', {}, '--check')
        self.assertEqual(code, 1)
        self.assertFalse(output['ok'])
        code, output = self.invoke('project_check.py', {'tool_name': 'Edit', 'tool_input': {}})
        self.assertEqual(code, 0)
        self.assertEqual(output['hookSpecificOutput']['hookEventName'], 'PostToolUse')
        self.assertEqual(before, self.source_snapshot())

    def test_version_check_rejects_ambiguous_or_malformed_versions(self):
        for value in ('version: nope\n', 'version: 1.2.3\n', 'version: 1.2.3+oops\n',
                      'version: 1.2.3+4\nversion: 1.2.3+4\n',
                      '# version: 1.2.3+4\n', 'version:\n  1.2.3+4\n'):
            with self.subTest(value=value):
                self.write('pubspec.yaml', value)
                self.assertTrue(check.version_issues(self.root))

    def test_version_check_rejects_malformed_manifests_and_build_types(self):
        for value in ('{broken', '[]', 'null', '{"latest_version": "1.2.3"}'):
            with self.subTest(value=value):
                self.write('version.json', value)
                self.assertTrue(check.version_issues(self.root))
        for build in ('4', 4.0, True, -1, None, []):
            with self.subTest(build=build):
                self.manifest['build_number'] = build
                self.write_manifest()
                self.assertTrue(check.version_issues(self.root))

    def test_version_check_rejects_missing_or_duplicate_constants(self):
        for value in (
            "// static const String defaultVersion = '1.2.3';\n",
            "class AppConstants {\n static const String defaultVersion = '1.2.3';\n"
            " static const String defaultVersion = '1.2.3';\n}\n",
        ):
            self.write('lib/core/constants/app_constants.dart', value)
            self.assertTrue(check.version_issues(self.root))
        (self.root / 'version.json').unlink()
        self.assertTrue(check.version_issues(self.root))

    def test_session_and_stop_only_report_context_without_source_mutation(self):
        before = self.source_snapshot()
        code, session = self.invoke('session_start.py', {'source': 'startup'})
        self.assertEqual(code, 0)
        context = session['hookSpecificOutput']
        self.assertEqual(context['hookEventName'], 'SessionStart')
        self.assertIn('Version triad synchronized', context['additionalContext'])
        code, stop = self.invoke('stop_guard.py', {'stop_hook_active': True})
        self.assertEqual(code, 0)
        self.assertNotIn('decision', stop)
        if stop:
            self.assertEqual(stop['hookSpecificOutput']['hookEventName'], 'Stop')
        self.assertEqual(before, self.source_snapshot())
        self.assertFalse((self.root / '.agents/cache').exists())


if __name__ == '__main__':
    unittest.main()
