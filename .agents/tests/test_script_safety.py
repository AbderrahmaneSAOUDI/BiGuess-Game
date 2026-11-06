"""Toolbox failure and preview guarantees; no SDK or publishing service is used."""
from contextlib import ExitStack, redirect_stderr, redirect_stdout
import importlib.util
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]


def load_script(name):
    spec = importlib.util.spec_from_file_location(
        f"script_safety_{name}", ROOT / "scripts" / f"{name}.py"
    )
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


build = load_script("build_app")
release = load_script("release")
menu = load_script("menu")

ABI_APKS = {
    "arm64-v8a": "app-arm64-v8a-release.apk",
    "armeabi-v7a": "app-armeabi-v7a-release.apk",
    "x86_64": "app-x86_64-release.apk",
}


def make_abi_files(root, directory="build/app/outputs/flutter-apk"):
    folder = root / directory
    folder.mkdir(parents=True, exist_ok=True)
    paths = []
    for abi, name in ABI_APKS.items():
        path = folder / name
        path.write_bytes(f"fixture APK for {abi}; no SDK involved".encode())
        paths.append(path)
    return paths


class QuietTests(unittest.TestCase):
    def setUp(self):
        self.output = io.StringIO()
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(redirect_stdout(self.output))
        self.stack.enter_context(redirect_stderr(self.output))


class BuildValidationTests(QuietTests):
    def test_analyzer_and_test_failures_stop_before_build(self):
        for failing in (["flutter", "analyze"], ["flutter", "test"]):
            with self.subTest(failing=failing):
                calls = []

                def step(title, command, cwd):
                    calls.append(command)
                    return command != failing

                with patch.object(sys, "argv", ["build_app.py", "apk"]), \
                        patch.object(build, "find_flutter_bin", return_value="flutter"), \
                        patch.object(build, "run_step", side_effect=step):
                    self.assertNotEqual(build.main(), 0)
                self.assertFalse(any(command[1:2] == ["build"] for command in calls))

    def test_requested_shorebird_never_silently_falls_back_to_flutter(self):
        with patch.object(sys, "argv", ["build_app.py", "appbundle", "--shorebird"]), \
                patch.object(build, "find_shorebird_bin", return_value=None), \
                patch.object(build, "run_step") as run:
            self.assertNotEqual(build.main(), 0)
            run.assert_not_called()


class ReleaseSafetyTests(QuietTests):
    def test_dry_run_has_no_commands_or_file_mutations_in_every_release_mode(self):
        forbidden = (
            "run", "write_pubspec_version", "sync_version_json", "update_app_constants",
            "build_apks", "git_commit_and_push", "create_github_release",
        )
        for flags in (
            ["--full-release", "--bump", "patch"], ["--patch"], [],
            ["--version-only", "--set-version", "1.2.3+4"],
        ):
            with self.subTest(flags=flags), ExitStack() as patches:
                patches.enter_context(patch.object(sys, "argv", ["release.py", "--dry-run", *flags]))
                patches.enter_context(patch.object(release, "read_pubspec_version", return_value="1.2.2+3"))
                operations = {
                    name: patches.enter_context(patch.object(release, name))
                    for name in forbidden
                }
                self.assertEqual(release.main(), 0)
                for operation in operations.values():
                    operation.assert_not_called()

    def test_failed_release_preflight_never_runs_a_build(self):
        for failing in (
            ["flutter", "clean"], ["flutter", "pub", "get"],
            ["flutter", "analyze"], ["flutter", "test"],
        ):
            with self.subTest(failing=failing):
                commands = []

                def run(command, **kwargs):
                    commands.append(command)
                    return subprocess.CompletedProcess(command, 7 if command == failing else 0)

                with patch.object(release, "run", side_effect=run):
                    self.assertEqual(release.build_apks(clean=True, use_shorebird=False), [])
                self.assertEqual(commands[-1], failing)
                self.assertFalse(any(command[1:2] == ["build"] for command in commands))

    def patch_args(self, **overrides):
        return SimpleNamespace(**{
            "skip_checks": False, "allow_native_diffs": False, "dry_run": False,
            "verbose": False, "notes": "Fixture patch", "min_version": None,
            "skip_git": False, **overrides,
        })

    def patch_fixtures(self, stack):
        stack.enter_context(patch.object(release, "ensure_committed_app_source", return_value=True))
        stack.enter_context(patch.object(release, "find_shorebird_bin", return_value="shorebird"))
        stack.enter_context(patch.object(release, "read_pubspec_version", return_value="1.2.3+4"))
        stack.enter_context(patch.object(release, "get_shorebird_active_releases", return_value=["1.2.3+4"]))
        stack.enter_context(patch.object(release, "detect_native_changes", return_value=(False, [])))
        return stack.enter_context(patch.object(release, "sync_version_json"))

    def test_failed_patch_validation_never_publishes_or_updates_metadata(self):
        for failing in (["flutter", "analyze"], ["flutter", "test"]):
            with self.subTest(failing=failing), ExitStack() as patches:
                sync = self.patch_fixtures(patches)
                commands = []

                def run(command, **kwargs):
                    commands.append(command)
                    return subprocess.CompletedProcess(command, 7 if command == failing else 0)

                patches.enter_context(patch.object(release, "run", side_effect=run))
                self.assertNotEqual(release.pipeline_patch_release(self.patch_args()), 0)
                self.assertEqual(commands[-1], failing)
                self.assertFalse(any(command[0] == "shorebird" for command in commands))
                sync.assert_not_called()

    def test_patch_git_failures_are_reported_without_later_git_operations(self):
        for operation in ("add", "commit", "push"):
            with self.subTest(operation=operation), ExitStack() as patches:
                self.patch_fixtures(patches)
                commands = []

                def run(command, **kwargs):
                    commands.append(command)
                    failed = command[:2] == ["git", operation]
                    return subprocess.CompletedProcess(command, 7 if failed else 0)

                patches.enter_context(patch.object(release, "run", side_effect=run))
                result = release.pipeline_patch_release(self.patch_args(skip_checks=True))
                self.assertNotEqual(result, 0)
                self.assertEqual(commands[-1][:2], ["git", operation])

    def test_retargeting_does_not_change_versions_before_native_or_validation_checks(self):
        for failure in ("native", "analyze", "test"):
            with self.subTest(failure=failure), ExitStack() as patches:
                sync = self.patch_fixtures(patches)
                patches.enter_context(patch.object(release, "get_shorebird_active_releases", return_value=["1.2.0+1"]))
                patches.enter_context(patch.object(release, "detect_native_changes", return_value=(failure == "native", ["android/fixture"])))
                write = patches.enter_context(patch.object(release, "write_pubspec_version"))
                constants = patches.enter_context(patch.object(release, "update_app_constants"))

                def run(command, **kwargs):
                    return subprocess.CompletedProcess(command, 7 if command == ["flutter", failure] else 0)

                patches.enter_context(patch.object(release, "run", side_effect=run))
                self.assertNotEqual(release.pipeline_patch_release(self.patch_args()), 0)
                write.assert_not_called()
                constants.assert_not_called()
                sync.assert_not_called()

    def test_failed_retargeted_patch_restores_exact_original_version_files(self):
        for raises in (False, True):
            with self.subTest(raises=raises), ExitStack() as patches:
                temporary = patches.enter_context(tempfile.TemporaryDirectory())
                root = Path(temporary)
                pubspec = root / "pubspec.yaml"
                constants = root / "lib/core/constants/app_constants.dart"
                constants.parent.mkdir(parents=True)
                pubspec.write_bytes(b"name: fixture\nversion: 1.2.3+4\n# preserve me\n")
                constants.write_bytes(b"  static const String defaultVersion = '1.2.3';\n// preserve me\n")
                originals = {path: path.read_bytes() for path in (pubspec, constants)}
                patches.enter_context(patch.object(release, "REPO_ROOT", root))
                patches.enter_context(patch.object(release, "PUBSPEC", pubspec))
                sync = self.patch_fixtures(patches)
                patches.enter_context(patch.object(release, "get_shorebird_active_releases", return_value=["1.2.0+1"]))

                def run(command, **kwargs):
                    self.assertIn("1.2.0+1", pubspec.read_text())
                    self.assertIn("'1.2.0'", constants.read_text())
                    if raises:
                        raise OSError("fixture command failure")
                    return subprocess.CompletedProcess(command, 7)

                patches.enter_context(patch.object(release, "run", side_effect=run))
                if raises:
                    with self.assertRaises(OSError):
                        release.pipeline_patch_release(self.patch_args(skip_checks=True))
                else:
                    self.assertNotEqual(release.pipeline_patch_release(self.patch_args(skip_checks=True)), 0)
                self.assertEqual({path: path.read_bytes() for path in originals}, originals)
                sync.assert_not_called()

    def full_args(self, **overrides):
        return SimpleNamespace(**{
            "dry_run": False, "skip_github": False, "skip_git": False,
            "draft": False, "prerelease": False, "skip_build": True,
            "skip_checks": True, "clean": False, "no_shorebird": True,
            "set_version": None, "bump": None, "native": False,
            "notes": "Fixture release", "min_version": None,
            "verbose": False, **overrides,
        })

    def test_active_manifest_is_pushed_only_after_successful_artifact_upload(self):
        for failure in (None, "prepare-tag", "upload", "push-manifest"):
            with self.subTest(failure=failure), ExitStack() as patches:
                temporary = patches.enter_context(tempfile.TemporaryDirectory())
                root = Path(temporary)
                make_abi_files(root)
                patches.enter_context(patch.object(release, "REPO_ROOT", root))
                patches.enter_context(patch.object(release, "ensure_committed_app_source", return_value=True))
                patches.enter_context(patch.object(release, "ensure_draft_branch", return_value=True))
                patches.enter_context(patch.object(release, "read_pubspec_version", return_value="1.2.3+4"))
                patches.enter_context(patch.object(release, "check_gh_cli", return_value=True))
                patches.enter_context(patch.object(release, "sync_version_json", return_value={"release_notes": "Fixture"}))
                patches.enter_context(patch.object(release, "update_app_constants"))
                operations = []

                def prepare(*args, **kwargs):
                    operations.append("prepare-tag")
                    self.assertFalse(kwargs["push_branch"])
                    return failure != "prepare-tag"

                def upload(*args, **kwargs):
                    operations.append("upload")
                    return failure != "upload"

                def run(command, **kwargs):
                    self.assertEqual(command, ["git", "push"])
                    operations.append("push-manifest")
                    return subprocess.CompletedProcess(command, 7 if failure == "push-manifest" else 0)

                patches.enter_context(patch.object(release, "git_commit_and_push", side_effect=prepare))
                patches.enter_context(patch.object(release, "create_github_release", side_effect=upload))
                patches.enter_context(patch.object(release, "run", side_effect=run))
                result = release.pipeline_full_release(self.full_args())
                expected = ["prepare-tag", "upload", "push-manifest"]
                if failure:
                    expected = expected[:expected.index(failure) + 1]
                    self.assertNotEqual(result, 0)
                else:
                    self.assertEqual(result, 0)
                self.assertEqual(operations, expected)

    def test_drafts_and_prereleases_tag_build_source_without_pushing_active_manifest(self):
        for option in ("draft", "prerelease"):
            with self.subTest(option=option), ExitStack() as patches:
                temporary = patches.enter_context(tempfile.TemporaryDirectory())
                root = Path(temporary)
                make_abi_files(root)
                patches.enter_context(patch.object(release, "REPO_ROOT", root))
                patches.enter_context(patch.object(release, "ensure_committed_app_source", return_value=True))
                patches.enter_context(patch.object(release, "ensure_draft_branch", return_value=True))
                patches.enter_context(patch.object(release, "read_pubspec_version", return_value="1.2.3+4"))
                patches.enter_context(patch.object(release, "check_gh_cli", return_value=True))
                patches.enter_context(patch.object(release, "sync_version_json", return_value={"release_notes": "Fixture"}))
                patches.enter_context(patch.object(release, "update_app_constants"))
                prepare = patches.enter_context(patch.object(release, "git_commit_and_push", return_value=True))
                upload = patches.enter_context(patch.object(release, "create_github_release", return_value=True))
                run = patches.enter_context(patch.object(release, "run"))
                self.assertEqual(release.pipeline_full_release(self.full_args(**{option: True})), 0)
                prepare.assert_called_once()
                self.assertFalse(prepare.call_args.kwargs["push_branch"])
                self.assertTrue(upload.call_args.kwargs[option])
                run.assert_not_called()

    def test_dirty_source_refusal_precedes_version_writes_and_publishing(self):
        for pipeline, args in (
            (release.pipeline_full_release, self.full_args()),
            (release.pipeline_patch_release, self.patch_args()),
        ):
            with self.subTest(pipeline=pipeline.__name__), ExitStack() as patches:
                patches.enter_context(patch.object(release, "ensure_committed_app_source", return_value=False))
                operations = [
                    patches.enter_context(patch.object(release, name))
                    for name in ("run", "write_pubspec_version", "sync_version_json", "update_app_constants")
                ]
                self.assertNotEqual(pipeline(args), 0)
                for operation in operations:
                    operation.assert_not_called()

    def test_draft_branch_refusal_precedes_version_writes_and_publishing(self):
        for option in ("draft", "prerelease"):
            with self.subTest(option=option), ExitStack() as patches:
                patches.enter_context(patch.object(release, "ensure_committed_app_source", return_value=True))
                patches.enter_context(patch.object(release, "ensure_draft_branch", return_value=False))
                operations = [
                    patches.enter_context(patch.object(release, name))
                    for name in ("run", "write_pubspec_version", "sync_version_json", "update_app_constants")
                ]
                self.assertNotEqual(release.pipeline_full_release(self.full_args(**{option: True})), 0)
                for operation in operations:
                    operation.assert_not_called()


class ReleaseArtifactTests(QuietTests):
    def test_draft_branch_guard_requires_named_preparation_branch(self):
        for branch, returncode, expected in (
            ("main\n", 0, False), ("master\n", 0, False), ("", 1, False),
            ("", 0, False), ("release/prepare-1.2.3\n", 0, True),
        ):
            with self.subTest(branch=branch, returncode=returncode):
                result = subprocess.CompletedProcess([], returncode, stdout=branch)
                with patch.object(release, "run", return_value=result):
                    self.assertEqual(release.ensure_draft_branch(), expected)

    def test_source_guard_rejects_changed_or_untracked_inputs_and_git_errors(self):
        cases = (
            (0, "", 0, "", True),
            (0, "lib/game.dart\0", 0, "", False),
            (0, "", 0, "assets/new image.webp\0", False),
            (7, "", 0, "", False),
            (0, "", 7, "", False),
        )
        for diff_code, tracked, untracked_code, untracked, expected in cases:
            with self.subTest(tracked=tracked, untracked=untracked, diff_code=diff_code,
                              untracked_code=untracked_code):
                results = [
                    subprocess.CompletedProcess([], diff_code, stdout=tracked),
                    subprocess.CompletedProcess([], untracked_code, stdout=untracked),
                ]
                with patch.object(release, "run", side_effect=results):
                    self.assertEqual(release.ensure_committed_app_source(), expected)

    def test_complete_abi_set_is_deduplicated_and_excludes_universal_and_debug(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            expected = make_abi_files(root)
            make_abi_files(root, "build/app/outputs/apk/release")
            folder = expected[0].parent
            (folder / "app-release.apk").write_bytes(b"universal APK")
            (folder / "app-debug.apk").write_bytes(b"debug APK")
            with patch.object(release, "REPO_ROOT", root):
                actual = release.find_release_apks()
            self.assertEqual(set(actual), set(expected))
            self.assertEqual(len(actual), 3)

    def test_missing_empty_or_stale_abi_is_rejected_even_with_universal_apk(self):
        for state in ("missing", "empty", "stale"):
            for filename in ABI_APKS.values():
                with self.subTest(state=state, filename=filename), tempfile.TemporaryDirectory() as temporary:
                    root = Path(temporary)
                    paths = make_abi_files(root)
                    for path in paths:
                        os.utime(path, (1001, 1001))
                    victim = paths[0].parent / filename
                    if state == "missing":
                        victim.unlink()
                    elif state == "empty":
                        victim.write_bytes(b"")
                    else:
                        os.utime(victim, (998, 998))
                    (paths[0].parent / "app-release.apk").write_bytes(b"universal is not a replacement")
                    with patch.object(release, "REPO_ROOT", root):
                        self.assertEqual(release.find_release_apks(built_after=1000), [])

    def test_fresh_secondary_artifact_can_replace_stale_primary_candidate(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            expected = make_abi_files(root)
            for path in expected:
                os.utime(path, (1001, 1001))
            os.utime(expected[0], (998, 998))
            secondary = root / "build/app/outputs/apk/release" / expected[0].name
            secondary.parent.mkdir(parents=True)
            secondary.write_bytes(b"fresh ABI APK")
            os.utime(secondary, (1001, 1001))
            with patch.object(release, "REPO_ROOT", root):
                actual = release.find_release_apks(built_after=1000)
            self.assertEqual(set(actual), {secondary, *expected[1:]})

    def test_manifest_hashes_match_each_actual_abi_binary_and_pinned_version_urls(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            paths = make_abi_files(root)
            manifest = root / "version.json"
            with patch.object(release, "VERSION_JSON", manifest):
                payload = release.sync_version_json("1.2.3+4", has_native_changes=False, apk_files=paths)
            expected = {
                abi: hashlib.sha256((paths[0].parent / name).read_bytes()).hexdigest()
                for abi, name in ABI_APKS.items()
            }
            self.assertEqual(payload["sha256_hashes"], expected)
            self.assertEqual(payload["sha256"], expected["arm64-v8a"])
            self.assertEqual(json.loads(manifest.read_text()), payload)
            for abi, name in ABI_APKS.items():
                self.assertTrue(payload["apk_urls"][abi].endswith(f"/releases/download/v1.2.3/{name}"))
            self.assertEqual(payload["apk_url"], payload["apk_urls"]["arm64-v8a"])

    def test_metadata_only_sync_keeps_hashes_only_for_same_version_and_build(self):
        with tempfile.TemporaryDirectory() as temporary:
            manifest = Path(temporary) / "version.json"
            hashes = {
                "sha256_hashes": {"arm64-v8a": "a" * 64}, "sha256": "a" * 64,
                "apk_hashes": {"x86_64": "b" * 64}, "apk_sha256": "c" * 64,
            }
            for version in ("1.2.3+4", "1.2.3+5", "1.2.4+4"):
                with self.subTest(version=version):
                    manifest.write_text(json.dumps({"latest_version": "1.2.3", "build_number": 4, **hashes}))
                    with patch.object(release, "VERSION_JSON", manifest):
                        payload = release.sync_version_json(version, has_native_changes=False)
                    for key, value in hashes.items():
                        if version == "1.2.3+4":
                            self.assertEqual(payload[key], value)
                        else:
                            self.assertNotIn(key, payload)

    def test_incomplete_binary_hash_input_cannot_replace_existing_manifest(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            paths = make_abi_files(root)
            manifest = root / "version.json"
            manifest.write_bytes(b'{"latest_version":"1.0.0","build_number":1}\n')
            before = manifest.read_bytes()
            with patch.object(release, "VERSION_JSON", manifest), self.assertRaises(ValueError):
                release.sync_version_json("1.2.3+4", has_native_changes=False, apk_files=paths[:2])
            self.assertEqual(manifest.read_bytes(), before)

    def test_failed_github_creation_does_not_overwrite_existing_release_assets(self):
        with patch.object(release, "run", return_value=subprocess.CompletedProcess([], 7)) as run:
            self.assertFalse(release.create_github_release("1.2.3+4", [], "Fixture notes"))
            run.assert_called_once()
            self.assertEqual(run.call_args.args[0][:3], ["gh", "release", "create"])
            self.assertNotIn("--clobber", run.call_args.args[0])


class MenuSafetyTests(QuietTests):
    def test_child_failure_reaches_direct_task_exit_code(self):
        with patch.dict(menu.TASK_MAP, {"failure-fixture": lambda: menu.run_script("audit_assets.py", [])}), \
                patch.object(menu.subprocess, "run", return_value=subprocess.CompletedProcess([], 7)):
            self.assertEqual(menu.run_single_task("failure-fixture"), 7)

    def test_invalid_release_or_build_selection_never_launches_a_command(self):
        for task in (menu.task_release_pipeline, menu.task_build_app):
            with self.subTest(task=task.__name__), \
                    patch.object(menu, "prompt_input", return_value="invalid"), \
                    patch.object(menu, "run_script") as run:
                task()
                run.assert_not_called()

    def test_ordinary_build_choices_do_not_register_shorebird_releases(self):
        for choice in ("1", "2", "3"):
            with self.subTest(choice=choice), \
                    patch.object(menu, "prompt_input", side_effect=[choice, "n"]), \
                    patch.object(menu, "run_script") as run:
                menu.task_build_app()
                self.assertEqual(run.call_args.args[0], "build_app.py")
                self.assertNotIn("--shorebird", run.call_args.args[1])


class BaselineEvidenceTests(unittest.TestCase):
    def test_context_failure_does_not_skip_later_gate_evidence(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            binaries = root / "bin"
            binaries.mkdir()
            commands = {
                "flutter": '#!/bin/sh\ncase "$*" in --version) exit 9;; analyze*) exit 4;; esac\nexit 0\n',
                "python3": '#!/bin/sh\ncase "$1" in -c) exit 8;; esac\nexit 0\n',
                "dart": "#!/bin/sh\nexit 0\n",
            }
            for name, body in commands.items():
                executable = binaries / name
                executable.write_text(body, encoding="utf-8")
                executable.chmod(0o755)
            output = root / "evidence"
            result = subprocess.run(
                ["bash", str(ROOT / "scripts/baseline_check.sh"), "--fast", str(output)],
                env={**os.environ, "PATH": f"{binaries}{os.pathsep}/usr/bin{os.pathsep}/bin"},
                text=True, capture_output=True, timeout=20,
            )
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            summary = (output / "summary.tsv").read_text()
            self.assertIn("analyze\t4\n", summary)
            self.assertIn("tests\t0\n", summary)
            self.assertIn("agent_setup\t0\n", summary)


if __name__ == "__main__":
    unittest.main()
