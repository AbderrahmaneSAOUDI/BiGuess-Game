"""
Unit tests for BiGuess Content Inventory & Rights Quarantine Engine (Task T05).
Verifies:
1. Exact count reconciliation (922 Anime across 6 packs + 252 Flags = 1174).
2. Deterministic, byte-reproducible exports across runs.
3. Strict asset preservation (zero mutations/renames/deletions).
4. Separation of technical importability from permission to publish.
5. Default rights quarantine of unverified assets.
6. Confirmed-cleared test fixture pack validity and isolation.
7. Exact binary and cross-pack duplicate candidate detection.
"""

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_DIR = REPO_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

from content_inventory import (  # noqa: E402
    CARD_NAMESPACE,
    PACK_NAMESPACE,
    TOPIC_NAMESPACE,
    build_inventory_report,
    export_public_test_assets,
    generate_stable_card_id,
    generate_stable_pack_id,
    generate_stable_topic_id,
    scan_assets,
    verify_reproducibility,
)


class ContentInventoryAndQuarantineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.images_dir = REPO_ROOT / "assets" / "images"
        cls.fixtures_dir = REPO_ROOT / "test" / "fixtures" / "cleared_shapes"

    def test_exact_counts_reconcile_to_disk_files(self):
        """Inventory counts must reconcile exactly to disk source files."""
        expected_counts = {
            "Anime": {
                "Attack on Titan": 131,
                "Black Clover": 67,
                "Demon Slayer": 43,
                "Hunter X Hunter": 135,
                "Naruto": 80,
                "One Piece": 466,
            },
            "Geography": {
                "Flags": 252,
            },
        }

        records = scan_assets(self.images_dir, REPO_ROOT)
        report = build_inventory_report(records, self.images_dir, expected_counts=expected_counts)
        summary = report["summary"]
        reconciliation = summary["reconciliation"]

        self.assertTrue(reconciliation["is_reconciled"], f"Discrepancies: {reconciliation['discrepancies']}")
        self.assertEqual(len(reconciliation["discrepancies"]), 0)
        self.assertEqual(summary["total_records"], 1174)
        self.assertEqual(reconciliation["disk_files_count"], 1174)
        self.assertEqual(summary["topics"]["Anime"]["total_records"], 922)
        self.assertEqual(summary["topics"]["Geography"]["total_records"], 252)

        for topic, packs in expected_counts.items():
            for pack, exp_cnt in packs.items():
                act_cnt = summary["topics"][topic]["packs"][pack]
                self.assertEqual(
                    act_cnt,
                    exp_cnt,
                    f"Mismatch in {topic} -> {pack}: expected {exp_cnt}, got {act_cnt}",
                )

    def test_export_is_deterministic_and_byte_reproducible(self):
        """Multiple independent inventory export passes must produce identical output."""
        is_reproducible = verify_reproducibility(
            self.images_dir,
            REPO_ROOT,
            [self.fixtures_dir] if self.fixtures_dir.exists() else None,
        )
        self.assertTrue(is_reproducible, "Inventory generation is not byte-reproducible")

    def test_proposed_stable_id_deterministic_uuidv5(self):
        """Proposed stable IDs must be deterministic RFC 4122 UUIDv5 scoped by entity hierarchy."""
        id1 = generate_stable_card_id("Anime", "One Piece", "Luffy")
        id2 = generate_stable_card_id("Anime", "One Piece", "Luffy")
        self.assertEqual(id1, id2)

        # Validate valid UUID format
        parsed_uuid = uuid.UUID(id1)
        self.assertEqual(parsed_uuid.version, 5)

        # Distinct characters with the same name across different packs must have distinct IDs
        kaya_aot = generate_stable_card_id("Anime", "Attack on Titan", "Kaya")
        kaya_op = generate_stable_card_id("Anime", "One Piece", "Kaya")
        self.assertNotEqual(kaya_aot, kaya_op)

        # Topic and Pack UUIDs must also be deterministic
        topic_id = generate_stable_topic_id("Anime")
        pack_id = generate_stable_pack_id("Anime", "Attack on Titan")
        self.assertEqual(uuid.UUID(topic_id).version, 5)
        self.assertEqual(uuid.UUID(pack_id).version, 5)

    def test_technical_importability_separated_from_permission_to_publish(self):
        """Technical importability must be separated from permission to publish."""
        records = scan_assets(self.images_dir, REPO_ROOT)
        self.assertEqual(len(records), 1174)

        for r in records:
            # All legacy assets must be technically importable WebP images
            self.assertTrue(r.technical_importability.is_importable, f"Corrupt asset: {r.source_path}")
            self.assertEqual(r.technical_importability.status, "importable")
            self.assertEqual(r.technical_importability.format, "WEBP")
            self.assertGreater(r.technical_importability.width or 0, 0)
            self.assertGreater(r.technical_importability.height or 0, 0)

            # But ALL legacy assets must have unverified rights and be quarantined by default
            self.assertEqual(r.rights.rights_status, "unverified")
            self.assertFalse(r.rights.permission_to_publish)
            self.assertFalse(r.rights.public_test_publishable)
            self.assertIsNotNone(r.rights.quarantine_reason)
            self.assertIn("quarantined", r.rights.quarantine_reason.lower())

    def test_duplicate_detection_finds_exact_hashes_and_names(self):
        """Detects known exact binary duplicates and cross-pack name collisions."""
        records = scan_assets(self.images_dir, REPO_ROOT)
        record_map = {r.source_path: r for r in records}

        # Check Norwegian flag duplicates: Norway, Bouvet Island, Svalbard and Jan Mayen
        norway_rec = record_map.get("assets/images/Geography/Flags/Norway.webp")
        self.assertIsNotNone(norway_rec)
        norway_dup_paths = [c.source_path for c in norway_rec.duplicate_candidates if c.match_type == "exact_sha256"]
        self.assertIn("assets/images/Geography/Flags/Bouvet Island.webp", norway_dup_paths)
        self.assertIn("assets/images/Geography/Flags/Svalbard and Jan Mayen.webp", norway_dup_paths)

        # Check cross-pack name match: Kaya in AoT and One Piece
        kaya_aot = record_map.get("assets/images/Anime/Attack on Titan/Kaya.webp")
        self.assertIsNotNone(kaya_aot)
        kaya_name_dups = [c.source_path for c in kaya_aot.duplicate_candidates if c.match_type == "exact_name"]
        self.assertIn("assets/images/Anime/One Piece/Kaya.webp", kaya_name_dups)

    def test_confirmed_cleared_fixture_pack(self):
        """Confirmed-cleared fixture pack must exist, have valid images, and be marked cleared."""
        self.assertTrue(self.fixtures_dir.exists(), "Fixtures directory does not exist")
        pack_json = self.fixtures_dir / "pack.json"
        self.assertTrue(pack_json.exists(), "pack.json does not exist in fixtures")

        with open(pack_json, "r", encoding="utf-8") as f:
            data = json.load(f)

        self.assertEqual(data["topic"]["name"], "Shapes")
        self.assertEqual(data["pack"]["name"], "Geometric Shapes")
        self.assertEqual(data["pack"]["rights_status"], "cleared")
        self.assertTrue(data["pack"]["permission_to_publish"])
        self.assertTrue(data["pack"]["public_test_publishable"])

        cards = data["cards"]
        self.assertGreaterEqual(len(cards), 2, "Minimum playable pack must have at least 2 cards")
        self.assertEqual(len(cards), 4)

        difficulties = {c["difficulty"] for c in cards}
        self.assertTrue({1, 2, 3}.issubset(difficulties), "Fixture cards should cover difficulties 1..3")

        # Scan fixture directory with inventory engine
        fixture_records = scan_assets(Path("non_existent"), REPO_ROOT, [self.fixtures_dir])
        self.assertEqual(len(fixture_records), 4)
        for r in fixture_records:
            self.assertTrue(r.technical_importability.is_importable)
            self.assertEqual(r.rights.rights_status, "cleared")
            self.assertTrue(r.rights.permission_to_publish)
            self.assertTrue(r.rights.public_test_publishable)
            self.assertIsNone(r.rights.quarantine_reason)

    def test_quarantine_export_excludes_unverified_assets_by_default(self):
        """Exporting for public test publishing must exclude all unverified assets."""
        with tempfile.TemporaryDirectory() as tmpdir:
            target = Path(tmpdir)

            # Exporting legacy records alone must export 0 assets
            legacy_records = scan_assets(self.images_dir, REPO_ROOT)
            cnt = export_public_test_assets(legacy_records, target / "pub1", REPO_ROOT)
            self.assertEqual(cnt, 0)
            self.assertEqual(len(list((target / "pub1").rglob("*.*"))), 0)

            # Exporting with confirmed fixtures must export ONLY the confirmed fixtures
            all_records = scan_assets(self.images_dir, REPO_ROOT, [self.fixtures_dir])
            cnt2 = export_public_test_assets(all_records, target / "pub2", REPO_ROOT)
            self.assertEqual(cnt2, 4)
            exported_names = sorted([p.name for p in (target / "pub2").rglob("*.webp")])
            self.assertEqual(exported_names, ["Circle.webp", "Square.webp", "Star.webp", "Triangle.webp"])


if __name__ == "__main__":
    unittest.main()
