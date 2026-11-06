"""T09 acceptance: reproducibility, strict validation, and offline completeness."""

import copy
import io
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import zipfile
import zlib

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts"))
import export_pack as exporter


def png(red):
    """Internally authored one-pixel PNG, generated without external artwork."""
    def chunk(kind, data):
        return struct.pack("!I", len(data)) + kind + data + struct.pack(
            "!I", zlib.crc32(kind + data) & 0xffffffff)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack("!2I5B", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes([0, red, 0, 0]))) + chunk(b"IEND", b""))


class PackExportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.rights = {"rights_status": "cleared", "permission_to_publish": True,
                       "public_test_publishable": True, "license": "CC0-1.0",
                       "source": "internally_authored_test_fixture", "attribution": "BiGuess tests"}
        self.source = {"schema_version": "1.0.0", "topic": {"id": "topic:test", "name": "Colors"},
                       "pack": {"id": "pack:test", "name": "Test colors", **self.rights},
                       "cards": [{"id": f"card:{i}", "pack_id": "pack:test", "name": name,
                                  "image": f"{name}.png", "difficulty": i, **self.rights}
                                 for i, name in enumerate(("Rouge é", "Green", "Blue"), start=1)]}
        for i, card in enumerate(self.source["cards"]):
            (self.root / card["image"]).write_bytes(png(i * 50))
        self.path = self.root / "pack.json"
        self.write_source()

    def write_source(self):
        self.path.write_text(json.dumps(self.source, ensure_ascii=False), encoding="utf-8")

    def build(self):
        self.write_source()
        return exporter.build_pack(self.root, *exporter.fixture_source(self.path))

    def unpack(self, data):
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            return {key: archive.read(key) for key in archive.namelist() if key != "manifest.json"}

    def test_archive_is_reproducible_despite_order_mtimes_and_location(self):
        manifest, first = self.build()
        self.source["cards"].reverse()
        for card in self.source["cards"]:
            os.utime(self.root / card["image"], (1700000000, 1700000000))
        second_manifest, second = self.build()
        self.assertEqual(manifest, second_manifest)
        self.assertEqual(first, second)
        self.assertEqual(exporter.sha256(first), exporter.sha256(second))
        moved = self.root / "moved"
        moved.mkdir()
        for card in self.source["cards"]:
            (moved / card["image"]).write_bytes((self.root / card["image"]).read_bytes())
        self.assertEqual(first, exporter.build_pack(moved, *exporter.fixture_source(self.path))[1])

    def test_offline_archive_has_every_asset_and_valid_hash(self):
        manifest, data = self.build()
        objects = self.unpack(data)
        exporter.validate_manifest(manifest, objects)
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            self.assertEqual(archive.read("manifest.json"), exporter.canonical_json(manifest))
            self.assertEqual(archive.namelist(), sorted(archive.namelist()))
            for info in archive.infolist():
                self.assertEqual(info.date_time, (1980, 1, 1, 0, 0, 0))
                self.assertEqual(info.compress_type, zipfile.ZIP_STORED)
        for card in manifest["cards"]:
            self.assertEqual(set(card), {"id", "packId", "name", "imageReference", "difficulty"})
            self.assertIn(card["imageReference"], objects)
        for obj in manifest["objects"]:
            self.assertEqual(obj["sha256"], exporter.sha256(objects[obj["key"]]))
            self.assertEqual(obj["sizeBytes"], len(objects[obj["key"]]))

    def test_changed_metadata_revision_or_image_changes_output(self):
        _, initial = self.build()
        self.source["cards"][0]["name"] = "Renamed"
        self.assertNotEqual(initial, self.build()[1])
        _, before = self.build()
        self.assertNotEqual(before, exporter.build_pack(
            self.root, *exporter.fixture_source(self.path), revision=2)[1])
        (self.root / self.source["cards"][0]["image"]).write_bytes(png(255))
        self.assertNotEqual(before, self.build()[1])

    def test_shared_image_is_stored_once_without_conflating_cards(self):
        self.source["cards"][1]["image"] = self.source["cards"][0]["image"]
        manifest, data = self.build()
        self.assertEqual(len(manifest["cards"]), 3)
        self.assertEqual(len(self.unpack(data)), 2)

    def test_invalid_source_records_fail(self):
        mutations = [
            lambda s: s["cards"].append(copy.deepcopy(s["cards"][0])),
            lambda s: s.update(cards=s["cards"][:1]),
            lambda s: s["cards"][0].update(pack_id="unknown"),
            lambda s: s["cards"][0].pop("name"),
            lambda s: s["cards"][0].update(name=" "),
            lambda s: s["cards"][0].update(id="bad id"),
            lambda s: s["cards"][0].update(id=None),
            lambda s: s["cards"][0].update(difficulty=True),
            lambda s: s["cards"][0].update(difficulty=1.0),
            lambda s: s["cards"][0].update(difficulty=4),
            lambda s: s["cards"][0].update(subtitle="Unrequested"),
            lambda s: s["cards"][0].update(image="missing.png"),
            lambda s: s["cards"][0].update(image="../outside.png"),
            lambda s: s["cards"][0].update(image="/absolute.png"),
            lambda s: s["cards"][0].update(image="https://example.com/image.png"),
            lambda s: s["cards"][0].update(image="folder\\image.png"),
            lambda s: s.update(schema_version="future"),
            lambda s: s.update(cards={}),
            lambda s: s.update(topic=[]),
            lambda s: s["pack"].update(rights_status="unverified"),
            lambda s: s["cards"][0].update(permission_to_publish=False),
            lambda s: s["cards"][0].update(public_test_publishable=1),
            lambda s: s["cards"][0].update(license=""),
        ]
        original = copy.deepcopy(self.source)
        for mutation in mutations:
            with self.subTest(mutation=mutations.index(mutation)):
                self.source = copy.deepcopy(original)
                mutation(self.source)
                with self.assertRaises(exporter.PackError):
                    self.build()

    def test_duplicate_json_keys_and_non_json_numbers_fail(self):
        for content in ('{"topic":1,"topic":2}', '{"value":NaN}', '{"value":Infinity}'):
            self.path.write_text(content)
            with self.assertRaises(exporter.PackError):
                exporter.read_json(self.path)

    def test_corrupt_truncated_and_mislabeled_images_fail(self):
        path = self.root / self.source["cards"][0]["image"]
        for data in (b"not an image", png(0)[:30], b""):
            path.write_bytes(data)
            with self.assertRaises(exporter.PackError):
                self.build()
        path.write_bytes(png(0))
        mislabeled = self.root / "fake.webp"
        mislabeled.write_bytes(png(0))
        self.source["cards"][0]["image"] = mislabeled.name
        with self.assertRaises(exporter.PackError):
            self.build()

    def test_symlink_cannot_escape_source(self):
        directory = self.root / "nested"
        directory.mkdir()
        (directory / "escape.png").symlink_to(self.root / self.source["cards"][0]["image"])
        with self.assertRaises(exporter.PackError):
            exporter.local_image(directory, "escape.png")

    def test_manifest_rejects_missing_extra_duplicate_and_tampered_objects(self):
        manifest, data = self.build()
        objects = self.unpack(data)
        bad_objects = [dict(list(objects.items())[1:]), {**objects, "extra": png(1)},
                       {**objects, next(iter(objects)): png(255)}]
        for changed in bad_objects:
            with self.assertRaises(exporter.PackError):
                exporter.validate_manifest(manifest, changed)
        mutations = [
            lambda m: m["objects"].append(copy.deepcopy(m["objects"][0])),
            lambda m: m["objects"][0].update(sizeBytes=True),
            lambda m: m["objects"][0].update(sha256="0" * 64),
            lambda m: m["objects"][0].update(mediaType="image/jpeg"),
            lambda m: m["objects"][0].update(key="../escape"),
            lambda m: m["pack"].update(topicId="unknown"),
            lambda m: m["pack"].update(revision=0),
            lambda m: m["pack"].update(revision=True),
            lambda m: m.update(schemaVersion=True),
            lambda m: m["provenance"].update(cardRights=[]),
        ]
        for mutation in mutations:
            changed = copy.deepcopy(manifest)
            mutation(changed)
            with self.assertRaises(exporter.PackError):
                exporter.validate_manifest(changed, objects)

    def test_legacy_preserves_names_and_is_explicitly_development_only(self):
        directory = self.root / "assets/images/Tópico/Pack with spaces"
        directory.mkdir(parents=True)
        for name in ("One é", "Two"):
            (directory / f"{name}.png").write_bytes(png(1))
        source = exporter.legacy_source(self.root, "Tópico", "Pack with spaces")
        manifest, data = exporter.build_pack(self.root, *source)
        self.assertEqual({card["name"] for card in manifest["cards"]}, {"One é", "Two"})
        self.assertTrue(all(card["difficulty"] == 1 for card in manifest["cards"]))
        self.assertTrue(manifest["pack"]["id"].startswith("legacy:pack:T%C3%B3pico:"))
        self.assertEqual(manifest["provenance"]["mode"], "legacy-development")
        self.assertFalse(manifest["provenance"]["packRights"]["public_test_publishable"])
        self.assertEqual(len(self.unpack(data)), 1)
        result = self.cli("legacy", "Tópico", "Pack with spaces", "--repo-root", str(self.root))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--development-only", result.stderr)

    def cli(self, *args):
        return subprocess.run([sys.executable, str(REPO / "scripts/export_pack.py"), *args,
                               "--output", str(self.root / "output.biguesspack")],
                              capture_output=True, text=True, timeout=30)

    def test_cli_hashes_match_archive_and_existing_output_is_preserved(self):
        before = {path.name: path.read_bytes() for path in self.root.iterdir() if path.is_file()}
        result = self.cli("fixture", str(self.path))
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        data = (self.root / "output.biguesspack").read_bytes()
        self.assertEqual(report["sizeBytes"], len(data))
        self.assertEqual(report["archiveSha256"], exporter.sha256(data))
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            self.assertEqual(report["manifestSha256"], exporter.sha256(archive.read("manifest.json")))
        again = self.cli("fixture", str(self.path))
        self.assertNotEqual(again.returncode, 0)
        self.assertEqual((self.root / "output.biguesspack").read_bytes(), data)
        for name, contents in before.items():
            self.assertEqual((self.root / name).read_bytes(), contents)
        # A fresh process and output location also produce the same bytes.
        second_output = self.root / "second.biguesspack"
        second = subprocess.run([sys.executable, str(REPO / "scripts/export_pack.py"),
                                 "fixture", str(self.path), "--output", str(second_output)],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(second_output.read_bytes(), data)

    def test_cli_bad_input_leaves_no_output(self):
        for raw in ('{"topic":', '[]', '{"topic":true,"topic":false}'):
            self.path.write_text(raw)
            result = self.cli("fixture", str(self.path))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Pack export failed:", result.stderr)
            self.assertFalse((self.root / "output.biguesspack").exists())


if __name__ == "__main__":
    unittest.main()
