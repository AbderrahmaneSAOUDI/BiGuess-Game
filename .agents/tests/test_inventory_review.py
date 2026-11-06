"""Regression cases for truthful inventory reports and verified public test exports."""
from contextlib import redirect_stderr, redirect_stdout
import io
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import content_inventory as inventory


class InventoryReviewTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.fixture = self.root / "fixture"
        shutil.copytree(ROOT / "test/fixtures/cleared_shapes", self.fixture)

    def scan_fixture(self):
        return inventory.scan_assets(self.root / "absent", ROOT, [self.fixture])

    def test_missing_pillow_cannot_verify_a_header_as_an_image(self):
        with patch.object(inventory, "Image", None):
            status, data = inventory.inspect_image_file(self.fixture / "Circle.webp")
        self.assertTrue(data)
        self.assertFalse(status.is_importable)
        self.assertEqual(status.status, "unreadable")
        self.assertIn("Pillow", status.issues[0])

    def test_check_fails_for_unreadable_images_or_missing_requested_folders(self):
        images = self.root / "images"
        pack = images / "Topic" / "Pack"
        pack.mkdir(parents=True)
        shutil.copyfile(self.fixture / "Circle.webp", pack / "Circle.webp")
        commands = [
            ["inventory", "--images-dir", str(images), "--check"],
            ["inventory", "--images-dir", str(self.root / "missing"), "--check"],
            ["inventory", "--images-dir", str(images), "--include-fixtures",
             "--fixtures-dir", str(self.root / "missing"), "--check"],
        ]
        for command in commands:
            with self.subTest(command=command), patch.object(sys, "argv", command), \
                    patch.object(inventory, "Image", None), redirect_stdout(io.StringIO()), \
                    redirect_stderr(io.StringIO()):
                self.assertEqual(inventory.main(), 1)

    def test_incorrect_image_extension_is_rejected(self):
        wrong = self.fixture / "Circle.png"
        wrong.write_bytes((self.fixture / "Circle.webp").read_bytes())
        status, _ = inventory.inspect_image_file(wrong)
        self.assertFalse(status.is_importable)
        self.assertIn("encoding", status.issues[0])

    def test_fixture_records_cannot_hide_missing_source_records(self):
        images = self.root / "images"
        pack = images / "Topic" / "Pack"
        pack.mkdir(parents=True)
        for name in ("Circle", "Square"):
            shutil.copyfile(self.fixture / f"{name}.webp", pack / f"{name}.webp")
        records = inventory.scan_assets(images, self.root)
        incomplete = records[1:] + self.scan_fixture()
        report = inventory.build_inventory_report(incomplete, images, repo_root=self.root)
        reconciliation = report["summary"]["reconciliation"]
        self.assertFalse(reconciliation["is_reconciled"])
        self.assertIn("missing from inventory", " ".join(reconciliation["discrepancies"]))

    def test_proposed_id_collision_is_reported(self):
        images = self.root / "images"
        pack = images / "Topic" / "Pack"
        pack.mkdir(parents=True)
        from PIL import Image
        for suffix in ("png", "webp"):
            Image.new("RGB", (2, 2), "red").save(pack / f"Same.{suffix}")
        records = inventory.scan_assets(images, self.root)
        report = inventory.build_inventory_report(records, images, repo_root=self.root)
        self.assertFalse(report["summary"]["reconciliation"]["is_reconciled"])
        self.assertIn("ID collision", " ".join(report["summary"]["reconciliation"]["discrepancies"]))

    def test_empty_and_invalid_shapes_reports_do_not_fabricate_clearance(self):
        empty = inventory.build_inventory_report([], self.root / "absent")
        empty_markdown = inventory.generate_markdown_report(empty)
        self.assertIn("0.00%", empty_markdown)
        self.assertNotIn("Norway", empty_markdown)
        metadata = json.loads((self.fixture / "pack.json").read_text())
        metadata["pack"]["permission_to_publish"] = False
        (self.fixture / "pack.json").write_text(json.dumps(metadata))
        (self.fixture / "Circle.webp").write_bytes(b"broken")
        report = inventory.build_inventory_report(self.scan_fixture(), self.root / "absent")
        markdown = inventory.generate_markdown_report(report)
        self.assertIn("| Shapes | Geometric Shapes | 4 | 3 | 0 | 0 |", markdown)
        self.assertNotIn("100%", markdown)
        self.assertNotIn("Norway", markdown)

    def test_public_export_rejects_changed_bytes_before_writing(self):
        records = self.scan_fixture()
        (self.fixture / "Circle.webp").write_bytes(b"replacement")
        output = self.root / "public"
        with self.assertRaisesRegex(ValueError, "changed since inventory"):
            inventory.export_public_test_assets(records, output, ROOT)
        self.assertFalse(output.exists())

    def test_public_export_omits_corrupt_cleared_images(self):
        (self.fixture / "Circle.webp").write_bytes(b"broken")
        records = self.scan_fixture()
        output = self.root / "public"
        self.assertEqual(inventory.export_public_test_assets(records, output, ROOT), 3)
        self.assertFalse(any(output.rglob("Circle.webp")))

    def test_public_export_cannot_escape_with_fixture_labels(self):
        metadata = json.loads((self.fixture / "pack.json").read_text())
        metadata["topic"]["name"] = "../../outside"
        (self.fixture / "pack.json").write_text(json.dumps(metadata))
        output = self.root / "public"
        with self.assertRaisesRegex(ValueError, "escapes"):
            inventory.export_public_test_assets(self.scan_fixture(), output, ROOT)
        self.assertFalse(output.exists())
        self.assertFalse((self.root / "outside").exists())

    def test_public_export_refuses_reused_destination(self):
        output = self.root / "public"
        output.mkdir()
        stale = output / "unverified.webp"
        stale.write_bytes(b"stale")
        with self.assertRaisesRegex(ValueError, "empty destination"):
            inventory.export_public_test_assets(self.scan_fixture(), output, ROOT)
        self.assertEqual(stale.read_bytes(), b"stale")


if __name__ == "__main__":
    unittest.main()
