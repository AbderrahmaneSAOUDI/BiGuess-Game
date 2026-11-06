"""Tests for Android release signing, release linting, and credential safety gates."""
from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]


class ReleaseConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.gradle_file = REPO_ROOT / "android" / "app" / "build.gradle.kts"
        self.example_key_file = REPO_ROOT / "android" / "key.properties.example"
        self.root_gitignore = REPO_ROOT / ".gitignore"
        self.android_gitignore = REPO_ROOT / "android" / ".gitignore"

    def test_release_signing_never_uses_debug_key(self):
        """Release buildType in android/app/build.gradle.kts must not use debug signing config."""
        self.assertTrue(self.gradle_file.exists(), "build.gradle.kts not found")
        content = self.gradle_file.read_text(encoding="utf-8")

        # Extract the release block inside buildTypes
        release_match = re.search(r'buildTypes\s*\{[^}]*release\s*\{([^}]*)\}', content, re.DOTALL)
        self.assertIsNotNone(release_match, "release buildType block not found")
        release_block = release_match.group(1)

        self.assertNotIn(
            'signingConfigs.getByName("debug")',
            release_block,
            "CRITICAL SECURITY RISK: release buildType is explicitly using the debug signing configuration!"
        )

    def test_release_linting_is_not_bypassed(self):
        """Android lint configuration must not bypass release error checks."""
        content = self.gradle_file.read_text(encoding="utf-8")
        lint_match = re.search(r'lint\s*\{([^}]*)\}', content, re.DOTALL)
        self.assertIsNotNone(lint_match, "lint configuration block not found")
        lint_block = lint_match.group(1)

        self.assertIn("checkReleaseBuilds = true", lint_block)
        self.assertIn("abortOnError = true", lint_block)
        self.assertNotIn("abortOnError = false", lint_block)
        self.assertNotIn("checkReleaseBuilds = false", lint_block)

    def test_example_key_properties_exists_and_complete(self):
        """android/key.properties.example must exist with required property keys."""
        self.assertTrue(self.example_key_file.exists(), "android/key.properties.example not found")
        content = self.example_key_file.read_text(encoding="utf-8")

        required_keys = ["storeFile", "storePassword", "keyAlias", "keyPassword"]
        for key in required_keys:
            self.assertRegex(content, rf"(?m)^{key}=", f"Missing required property '{key}' in key.properties.example")

    def test_credentials_are_gitignored(self):
        """Both root and android .gitignore must ignore key.properties and keystore files."""
        root_content = self.root_gitignore.read_text(encoding="utf-8")
        android_content = self.android_gitignore.read_text(encoding="utf-8")

        self.assertIn("key.properties", root_content)
        self.assertIn("key.properties", android_content)
        self.assertIn("*.keystore", root_content)
        self.assertIn("*.keystore", android_content)
        self.assertIn("*.jks", root_content)
        self.assertIn("*.jks", android_content)

    def test_no_keystores_or_secrets_tracked_in_git(self):
        """Git index must not track any keystores, private keys, or properties containing secrets."""
        res = subprocess.run(
            ["git", "ls-files"],
            cwd=str(REPO_ROOT),
            capture_output=True,
            text=True,
            check=True
        )
        tracked = res.stdout.splitlines()
        for f in tracked:
            self.assertFalse(
                f.endswith(".keystore") or f.endswith(".jks"),
                f"Tracked keystore file found in git: {f}"
            )
            self.assertNotEqual(
                f, "android/key.properties",
                "android/key.properties must NEVER be tracked in git"
            )
            self.assertNotEqual(
                f, "key.properties",
                "key.properties must NEVER be tracked in git"
            )

    def test_validate_release_signing_gradle_task_exists(self):
        """Gradle task validateReleaseSigning must be runnable and succeed in unconfigured mode."""
        gradlew = REPO_ROOT / "android" / "gradlew"
        if not gradlew.exists():
            self.skipTest("gradlew not found")

        res = subprocess.run(
            [str(gradlew), ":app:validateReleaseSigning", "-q"],
            cwd=str(REPO_ROOT / "android"),
            capture_output=True,
            text=True,
            timeout=60
        )
        self.assertEqual(res.returncode, 0, f"validateReleaseSigning failed: {res.stderr}")
        self.assertIn("Release signing is NOT configured", res.stdout)


if __name__ == "__main__":
    unittest.main()
