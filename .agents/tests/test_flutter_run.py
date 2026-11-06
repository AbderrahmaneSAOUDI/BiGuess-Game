"""Launch-menu and shell forwarding checks; never start a real Flutter app."""
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout, redirect_stderr
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('flutter_run_menu', ROOT / 'scripts/menu.py')
menu = importlib.util.module_from_spec(spec)
spec.loader.exec_module(menu)


class FlutterRunTests(unittest.TestCase):
    def setUp(self):
        self.output = io.StringIO()
        self.stdout = redirect_stdout(self.output)
        self.stderr = redirect_stderr(self.output)
        self.stdout.__enter__()
        self.stderr.__enter__()
        self.addCleanup(self.stdout.__exit__, None, None, None)
        self.addCleanup(self.stderr.__exit__, None, None, None)

    def test_blank_inputs_use_debug_and_default_entrypoint(self):
        with patch.object(menu, 'read_line_with_esc', side_effect=['', '', '', '', '']), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        run.assert_called_once_with(['flutter', 'run', '--debug', '--target', 'lib/main.dart'])

    def test_custom_device_target_defines_and_flags_remain_separate_arguments(self):
        answers = ['2', 'my device', 'lib/custom.dart', 'LABEL="My test build" FLAG=true',
                   '--flavor staging --web-port 8080 --verbose']
        with patch.object(menu, 'read_line_with_esc', side_effect=answers), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        run.assert_called_once_with([
            'flutter', 'run', '--profile', '--target', 'lib/custom.dart',
            '--device-id', 'my device', '--dart-define=LABEL=My test build',
            '--dart-define=FLAG=true', '--flavor', 'staging', '--web-port', '8080', '--verbose',
        ])

    def test_list_devices_returns_to_mode_selection_and_release_can_run(self):
        with patch.object(menu, 'read_line_with_esc', side_effect=['4', '3', '', '', '', '']), \
                patch.object(menu, 'android_release_signing_ready', return_value=True), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        self.assertEqual(run.call_args_list[0].args[0], ['flutter', 'devices'])
        self.assertEqual(run.call_args_list[1].args[0],
                         ['flutter', 'run', '--release', '--target', 'lib/main.dart'])

    def test_cancel_invalid_mode_or_bad_options_never_launch(self):
        for answers in (['0'], ['invalid'], ['1', '', '', 'NOT_A_DEFINE', ''],
                        ['1', '', '', 'KEY="unclosed', ''],
                        ['1', '', '', '', '--flavor "unclosed']):
            with self.subTest(answers=answers), \
                    patch.object(menu, 'read_line_with_esc', side_effect=answers), \
                    patch.object(menu, 'run_command') as run:
                self.assertEqual(menu.run_single_task('run'), 0)
                run.assert_not_called()

    def test_failure_and_missing_flutter_propagate_without_capture_or_shell(self):
        for failure, expected in ((subprocess.CompletedProcess([], 7), 7),
                                  (FileNotFoundError(), 127)):
            with self.subTest(expected=expected), \
                    patch.object(menu, 'read_line_with_esc', side_effect=['4']), \
                    patch.object(menu.subprocess, 'run') as run:
                if isinstance(failure, Exception):
                    run.side_effect = failure
                else:
                    run.return_value = failure
                self.assertEqual(menu.run_single_task('run'), expected)
                run.assert_called_once_with(['flutter', 'devices'], cwd=str(ROOT))

    def test_missing_android_signing_returns_to_modes_and_profile_remains_available(self):
        with patch.object(menu, 'read_line_with_esc', side_effect=['3', '2', '', '', '', '']), \
                patch.object(menu, 'android_release_signing_ready', return_value=False), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        run.assert_called_once_with(['flutter', 'run', '--profile', '--target', 'lib/main.dart'])
        self.assertIn('Android Release requires your release signing key', self.output.getvalue())

    def test_failed_signing_check_can_be_cancelled_without_launching(self):
        with patch.object(menu, 'read_line_with_esc', side_effect=['3', '0']), \
                patch.object(menu, 'android_release_signing_ready', return_value=False), \
                patch.object(menu, 'run_command') as run:
            self.assertEqual(menu.run_single_task('run'), 0)
        run.assert_not_called()

    def test_non_android_release_does_not_require_android_keys(self):
        with patch.object(menu, 'read_line_with_esc', side_effect=['5', 'chrome', '', '', '']), \
                patch.object(menu, 'android_release_signing_ready') as signing, \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        signing.assert_not_called()
        self.assertIn('--release', run.call_args.args[0])
        self.assertIn('chrome', run.call_args.args[0])

    def test_signing_help_does_not_run_gradle_or_build(self):
        with patch.object(menu, 'read_line_with_esc', side_effect=['6', '0']), \
                patch.object(menu, 'android_release_signing_ready') as signing, \
                patch.object(menu, 'run_command') as run:
            self.assertEqual(menu.run_single_task('run'), 0)
        signing.assert_not_called()
        run.assert_not_called()
        self.assertIn('ANDROID_KEYSTORE_PATH', self.output.getvalue())

    def test_signing_probe_uses_gradle_without_printing_its_output(self):
        for code, ready in ((0, True), (1, False)):
            with self.subTest(code=code), patch.object(menu.subprocess, 'run',
                    return_value=subprocess.CompletedProcess([], code, stdout='private-value',
                                                            stderr='private-value')) as run:
                self.assertEqual(menu.android_release_signing_ready(), ready)
                command = run.call_args.args[0]
                self.assertIn(':app:validateReleaseSigning', command)
                self.assertIn('-PrequireReleaseSigning=true', command)
                self.assertEqual(run.call_args.kwargs['timeout'], 90)
        self.assertNotIn('private-value', self.output.getvalue())

    def test_signing_probe_errors_do_not_launch_a_build(self):
        for error in (FileNotFoundError(), subprocess.TimeoutExpired('gradle', 90)):
            with self.subTest(error=type(error).__name__), \
                    patch.object(menu.subprocess, 'run', side_effect=error):
                self.assertFalse(menu.android_release_signing_ready())

    def test_menu_numbers_stay_sequential_and_run_aliases_match(self):
        entries = [entry for _, group in menu.TOOL_GROUPS for entry in group]
        self.assertEqual([int(entry[0]) for entry in entries], list(range(1, 16)))
        self.assertIs(menu.TASK_MAP['11'], menu.task_run_app)
        self.assertIs(menu.TASK_MAP['launch'], menu.task_run_app)
        for number, shortcut, _, _ in entries:
            self.assertIs(menu.TASK_MAP[number], menu.TASK_MAP[shortcut])

    def test_launcher_forwards_arguments_literally_and_returns_flutter_exit_code(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            executable = directory / 'flutter'
            executable.write_text(
                '#!' + sys.executable + '\n'
                'import json,os,sys\n'
                'from pathlib import Path\n'
                'Path(os.environ["RUN_ARGUMENTS"]).write_text(json.dumps(sys.argv[1:]))\n'
                'raise SystemExit(7)\n'
            )
            executable.chmod(0o755)
            arguments = directory / 'arguments.json'
            marker = directory / 'should-not-exist'
            flags = ['--debug', '-d', 'device with spaces',
                     '--dart-define=LABEL=a b', '--dart-define=VALUE=$(touch ' + str(marker) + ')']
            for alias in ('run', 'launch'):
                result = subprocess.run(
                    ['bash', str(ROOT / 'scripts/run.sh'), alias, *flags],
                    env={**os.environ, 'PATH': str(directory) + os.pathsep + os.environ['PATH'],
                         'RUN_ARGUMENTS': str(arguments)}, capture_output=True, text=True,
                )
                self.assertEqual(result.returncode, 7, result.stderr)
                self.assertEqual(json.loads(arguments.read_text()), ['run', *flags])
                self.assertFalse(marker.exists())


if __name__ == '__main__':
    unittest.main()
