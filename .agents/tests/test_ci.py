"""Read-only version gate regression checks using disposable version fixtures."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

HOOKS = Path(__file__).resolve().parents[1] / "hooks"
sys.path.insert(0, str(HOOKS))
spec = importlib.util.spec_from_file_location("ci_project_check", HOOKS / "project_check.py")
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class VersionGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "pubspec.yaml").write_text("version: 1.2.3+4\n")
        (self.root / "version.json").write_text(json.dumps({"latest_version": "1.2.3", "build_number": 4}))
        self.constants = self.root / "lib/core/constants/app_constants.dart"
        self.constants.parent.mkdir(parents=True)
        self.constants.write_text("  static const String defaultVersion = '1.2.3';\n")

    def test_synchronized_triad_passes(self):
        self.assertEqual(checker.version_issues(self.root), [])

    def test_semver_drift_fails_without_repair(self):
        manifest = self.root / "version.json"
        before = json.dumps({"latest_version": "9.9.9", "build_number": 4})
        manifest.write_text(before)
        self.assertTrue(checker.version_issues(self.root))
        self.assertEqual(manifest.read_text(), before)

    def test_build_drift_fails(self):
        (self.root / "version.json").write_text(json.dumps({"latest_version": "1.2.3", "build_number": 5}))
        self.assertTrue(checker.version_issues(self.root))

    def test_constants_drift_fails(self):
        self.constants.write_text("  static const String defaultVersion = '0.0.0';\n")
        self.assertTrue(checker.version_issues(self.root))

    def test_missing_build_fails(self):
        (self.root / "pubspec.yaml").write_text("version: 1.2.3\n")
        self.assertTrue(checker.version_issues(self.root))


if __name__ == "__main__":
    unittest.main()
