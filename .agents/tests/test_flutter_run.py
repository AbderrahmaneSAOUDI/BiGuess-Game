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

    devices = [
        {'id': 'phone-id', 'name': 'My phone', 'targetPlatform': 'android-arm64', 'isSupported': True},
        {'id': 'browser-id', 'name': 'Chrome', 'targetPlatform': 'web-javascript', 'isSupported': True},
    ]

    def discovery(self, devices=None, code=0):
        return subprocess.CompletedProcess([], code, json.dumps(self.devices if devices is None else devices), '')

    def test_chosen_device_and_profile_type_launch_without_extra_prompts(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()) as discover, \
                patch.object(menu, 'read_line_with_esc', side_effect=['2', '2']) as prompt, \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        discover.assert_called_once_with(['flutter', 'devices', '--machine'], cwd=str(ROOT),
                                         capture_output=True, text=True, timeout=30)
        self.assertEqual(prompt.call_count, 2)
        run.assert_called_once_with(['flutter', 'run', '-d', 'browser-id', '--profile'])
        self.assertIn('My phone', self.output.getvalue())
        self.assertIn('Chrome', self.output.getvalue())
        self.assertIn('browser-id', self.output.getvalue())
        self.assertNotIn('Run mode', self.output.getvalue())

    def test_default_device_and_invalid_selection_reprompt(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['99', 'invalid', '', '']), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        run.assert_called_once_with(['flutter', 'run', '-d', 'phone-id', '--profile', '--no-resident'])

    def test_cancel_never_launches(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', return_value='0'), \
                patch.object(menu, 'run_command') as run:
            self.assertEqual(menu.run_single_task('run'), 0)
        run.assert_not_called()

    def test_empty_or_unusable_devices_do_not_prompt_or_launch(self):
        for devices in ([], [{'id': 'unsupported', 'isSupported': False}],
                        [None, {}, {'id': 1}, {'id': '  '}]):
            with self.subTest(devices=devices), \
                    patch.object(menu.subprocess, 'run', return_value=self.discovery(devices)), \
                    patch.object(menu, 'read_line_with_esc') as prompt, \
                    patch.object(menu, 'run_command') as run:
                menu.task_run_app()
            prompt.assert_not_called()
            run.assert_not_called()
            self.assertIn('No devices found', self.output.getvalue())

    def test_discovery_failures_are_reported_without_launching(self):
        for failure, code in ((subprocess.CompletedProcess([], 7, '', 'Connection failed'), 7),
                              (FileNotFoundError(), 127),
                              (subprocess.TimeoutExpired('flutter', 30), 1),
                              (subprocess.CompletedProcess([], 0, 'not JSON', ''), 1),
                              (subprocess.CompletedProcess([], 0, '{}', ''), 1)):
            with self.subTest(code=code), patch.object(menu.subprocess, 'run') as discover, \
                    patch.object(menu, 'read_line_with_esc') as prompt, \
                    patch.object(menu, 'run_command') as run:
                if isinstance(failure, Exception):
                    discover.side_effect = failure
                else:
                    discover.return_value = failure
                self.assertEqual(menu.run_single_task('run'), code)
                prompt.assert_not_called()
                run.assert_not_called()

    def test_launch_failure_preserves_flutter_exit_status(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['1', '2']), \
                patch.object(menu, 'run_command', side_effect=menu.ScriptFailed(7)):
            self.assertEqual(menu.run_single_task('run'), 7)

    def test_debug_stays_attached_and_explains_detach(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['1', '1']), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        run.assert_called_once_with(['flutter', 'run', '-d', 'phone-id', '--debug'])
        self.assertIn('d = detach', self.output.getvalue())

    def test_android_release_requires_signing_before_launch(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['1', '3', '2']), \
                patch.object(menu, 'android_release_signing_ready', return_value=False) as signing, \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        signing.assert_called_once()
        run.assert_called_once_with(['flutter', 'run', '-d', 'phone-id', '--profile', '--no-resident'])

    def test_configured_android_release_launches_standalone(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['1', '3']), \
                patch.object(menu, 'android_release_signing_ready', return_value=True), \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        run.assert_called_once_with(['flutter', 'run', '-d', 'phone-id', '--release', '--no-resident'])
        self.assertIn('installed and launched', self.output.getvalue())

    def test_non_android_release_keeps_host_running_without_android_signing(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['2', '3']), \
                patch.object(menu, 'android_release_signing_ready') as signing, \
                patch.object(menu, 'run_command') as run:
            menu.task_run_app()
        signing.assert_not_called()
        run.assert_called_once_with(['flutter', 'run', '-d', 'browser-id', '--release'])

    def test_build_type_cancel_or_invalid_choice_does_not_launch_prematurely(self):
        for answers in (['1', '0'], ['1', 'invalid', '0']):
            with self.subTest(answers=answers), \
                    patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                    patch.object(menu, 'read_line_with_esc', side_effect=answers), \
                    patch.object(menu, 'run_command') as run:
                self.assertEqual(menu.run_single_task('run'), 0)
                run.assert_not_called()

    def test_failed_launch_never_reports_success(self):
        with patch.object(menu.subprocess, 'run', return_value=self.discovery()), \
                patch.object(menu, 'read_line_with_esc', side_effect=['1', '2']), \
                patch.object(menu, 'run_command', side_effect=menu.ScriptFailed(1)):
            self.assertEqual(menu.run_single_task('run'), 1)
        self.assertNotIn('BiGuess installed and launched.', self.output.getvalue())

    def test_signing_check_errors_fail_closed_without_exposing_output(self):
        for outcome, expected in ((subprocess.CompletedProcess([], 0, 'private', 'private'), True),
                                  (subprocess.CompletedProcess([], 1, 'private', 'private'), False),
                                  (FileNotFoundError(), False),
                                  (subprocess.TimeoutExpired('gradle', 90), False)):
            with self.subTest(outcome=type(outcome).__name__), patch.object(menu.subprocess, 'run') as run:
                if isinstance(outcome, Exception):
                    run.side_effect = outcome
                else:
                    run.return_value = outcome
                self.assertEqual(menu.android_release_signing_ready(), expected)
                self.assertIn(':app:validateReleaseSigning', run.call_args.args[0])
        self.assertNotIn('private', self.output.getvalue())

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
