"""Behavioral checks use disposable repositories; never stage or push this project."""
from __future__ import annotations

import datetime as dt
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

HOOKS = Path(__file__).resolve().parents[1] / "hooks"
sys.path.insert(0, str(HOOKS))
import version_increment as version
import git_auto_commit_push as helper


class VersionGitTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.today = version.BASE_DATE + dt.timedelta(days=2)
        self.write("pubspec.yaml", "name: sample\nversion: 1.1.4+5 # keep comment\ndescription: original\n")
        self.write("version.json", '{\n  "latest_version": "1.1.4",\n  "build_number": 5,\n  "release_notes": "original",\n  "apk_urls": {"arm64-v8a": "keep-url"}\n}\n')
        self.write(version.TRIAD[2], "class AppConstants {\n  static const String defaultVersion = '1.1.4';\n  static const String name = 'original';\n}\n")
        self.write("staged.txt", "initial staged\n")
        self.write("dirty.txt", "initial dirty\n")
        self.write(".agents/task.md", "original task\n")
        self.git("init", "-q")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "BiGuess Tests")
        self.git("add", ".")
        self.git("commit", "-qm", "initial")

    def write(self, name, text):
        destination = self.root / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(text, encoding="utf-8")

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True,
                              capture_output=True, text=True, timeout=20,
                              env=dict(os.environ, GIT_OPTIONAL_LOCKS="0")).stdout

    def snapshot(self):
        return {p.relative_to(self.root).as_posix(): p.read_bytes()
                for p in self.root.rglob("*") if p.is_file()}

    def test_sync_is_idempotent_and_repairs_stale_constants(self):
        self.write("pubspec.yaml", "name: sample\nversion: 1.2.5+6\n")
        success, semver = version.sync_triad(self.root, self.today)
        self.assertTrue(success)
        self.assertEqual(semver, "1.2.5")
        self.assertIn("'1.2.5'", (self.root / version.TRIAD[2]).read_text())
        first = self.snapshot()
        version.sync_triad(self.root, self.today)
        self.assertEqual(first, self.snapshot())

    def test_preserves_higher_prepared_version_build_and_metadata(self):
        text = (self.root / "pubspec.yaml").read_text().replace("1.1.4+5", "2.9999.40+100")
        self.write("pubspec.yaml", text)
        version.sync_triad(self.root, self.today)
        self.assertIn("2.9999.40+100 # keep comment", (self.root / "pubspec.yaml").read_text())
        data = json.loads((self.root / "version.json").read_text())
        self.assertEqual(data["build_number"], 100)
        self.assertEqual(data["release_notes"], "original")
        self.assertEqual(data["apk_urls"], {"arm64-v8a": "keep-url"})

    def test_invalid_triad_causes_no_partial_writes(self):
        self.write(version.TRIAD[2], "missing default version\n")
        before = self.snapshot()
        with self.assertRaises(ValueError):
            version.sync_triad(self.root, self.today)
        self.assertEqual(before, self.snapshot())

    def test_malformed_json_version_type_is_a_validation_failure(self):
        data = json.loads((self.root / "version.json").read_text())
        data["latest_version"] = 123
        self.write("version.json", json.dumps(data))
        before = self.snapshot()
        with self.assertRaises(ValueError):
            version.sync_triad(self.root, self.today)
        self.assertEqual(before, self.snapshot())

    def test_algiers_date_and_deterministic_override(self):
        class Clock(dt.datetime):
            @classmethod
            def now(cls, tz=None):
                self.assertEqual(str(tz), "Africa/Algiers")
                return dt.datetime(2025, 5, 30, tzinfo=tz)
        with patch.object(version.dt, "datetime", Clock):
            self.assertEqual(version.get_expected_minor(), 3)
        self.assertEqual(version.get_expected_minor(self.today), 2)

    def test_scoped_commit_preserves_other_staged_work_and_shared_file_edits(self):
        self.write("staged.txt", "already staged user change\n")
        self.git("add", "staged.txt")
        original_staged_blob = self.git("rev-parse", ":staged.txt")
        self.write("dirty.txt", "unstaged user change\n")
        self.write(".agents/task.md", "task change\n")
        for name in version.TRIAD:
            self.write(name, (self.root / name).read_text().replace("original", "user-owned"))
        original_triad = {p: self.git("show", f"HEAD:{p}") for p in version.TRIAD}
        helper.commit_selected(self.root, "chore(agents): update guidance", [".agents"],
                               push=False, today=self.today)
        self.assertEqual(original_staged_blob, self.git("rev-parse", ":staged.txt"))
        self.assertEqual(self.git("diff", "--cached", "--name-only").strip(), "staged.txt")
        self.assertEqual(self.git("show", "HEAD:dirty.txt"), "initial dirty\n")
        self.assertEqual((self.root / "dirty.txt").read_text(), "unstaged user change\n")
        self.assertEqual(self.git("show", "HEAD:.agents/task.md"), "task change\n")
        expected = version.rewrite_triad(original_triad, (1, 2, 5, 6))
        for name in version.TRIAD:
            self.assertEqual(self.git("show", f"HEAD:{name}"), expected[name])
            self.assertIn("user-owned", (self.root / name).read_text())
        self.assertEqual(self.git("log", "-1", "--format=%s").strip(),
                         "1.2.5 - chore(agents): update guidance")

    def test_dry_run_writes_nothing(self):
        self.write(".agents/task.md", "task change\n")
        before = self.snapshot()
        helper.commit_selected(self.root, "chore: preview", [".agents"], dry_run=True, today=self.today)
        self.assertEqual(before, self.snapshot())

    def test_selected_staged_paths_refused_before_any_write(self):
        self.write(".agents/task.md", "selected staged change\n")
        self.git("add", ".agents/task.md")
        before = self.snapshot()
        with self.assertRaises(ValueError):
            helper.commit_selected(self.root, "chore: reject", [".agents"], push=False, today=self.today)
        self.assertEqual(before, self.snapshot())

    def test_scope_required_and_escape_refused(self):
        for paths in ([], ["../outside"], [":(glob)**"]):
            with self.assertRaises(ValueError):
                helper.commit_selected(self.root, "chore: reject", paths, push=False, today=self.today)

    def test_explicit_triad_file_includes_authorized_dependency_changes(self):
        self.write("pubspec.yaml", (self.root / "pubspec.yaml").read_text().replace("original", "new dependency"))
        self.write("version.json", (self.root / "version.json").read_text().replace("original", "unrelated notes"))
        helper.commit_selected(self.root, "chore(deps): update dependency", ["pubspec.yaml"],
                               push=False, today=self.today)
        self.assertIn("new dependency", self.git("show", "HEAD:pubspec.yaml"))
        self.assertNotIn("unrelated notes", self.git("show", "HEAD:version.json"))
        self.assertIn("unrelated notes", (self.root / "version.json").read_text())

    def test_containing_directory_authorizes_constants_content(self):
        constants = version.TRIAD[2]
        self.write(constants, (self.root / constants).read_text().replace("original", "task setting"))
        helper.commit_selected(self.root, "feat(settings): update constant", ["lib/core"],
                               push=False, today=self.today)
        self.assertIn("task setting", self.git("show", f"HEAD:{constants}"))
        self.assertIn("'1.2.5'", self.git("show", f"HEAD:{constants}"))

    def test_explicit_all_includes_full_triad_worktree_content(self):
        for name in version.TRIAD:
            self.write(name, (self.root / name).read_text().replace("original", "authorized"))
        self.write("dirty.txt", "authorized all changes\n")
        helper.commit_selected(self.root, "chore: update selected project", [], all_paths=True,
                               push=False, today=self.today)
        for name in version.TRIAD:
            self.assertIn("authorized", self.git("show", f"HEAD:{name}"))
        self.assertEqual(self.git("show", "HEAD:dirty.txt"), "authorized all changes\n")
        self.assertEqual(self.git("status", "--porcelain"), "")

    def test_clean_selected_scope_is_a_true_noop(self):
        self.write("dirty.txt", "unrelated dirty work\n")
        before = self.snapshot()
        helper.commit_selected(self.root, "chore: no changes", [".agents"],
                               push=False, today=self.today)
        self.assertEqual(before, self.snapshot())

    def test_explicit_version_only_change_can_be_committed(self):
        self.write("pubspec.yaml", (self.root / "pubspec.yaml").read_text().replace("1.1.4+5", "1.2.8+9"))
        helper.commit_selected(self.root, "chore: bump version", ["pubspec.yaml"],
                               push=False, today=self.today)
        self.assertIn("1.2.8+9", self.git("show", "HEAD:pubspec.yaml"))

    def test_leading_zero_versions_are_rejected(self):
        for value in ("01.2.3", "1.02.3", "1.2.03", "1.2.3+01", True):
            with self.assertRaises(ValueError):
                version.parse_version(value)


if __name__ == "__main__":
    unittest.main()
