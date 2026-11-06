#!/usr/bin/env python3
"""Export complete, deterministic offline test Packs. See docs/migration/PACK_FORMAT.md."""

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import sys
from urllib.parse import quote
import zipfile


class PackError(ValueError):
    """Invalid source data or incomplete Pack."""


FORMATS = {"WEBP": ("webp", "image/webp"), "PNG": ("png", "image/png"),
           "JPEG": ("jpg", "image/jpeg")}
EXTENSIONS = {".webp", ".png", ".jpg", ".jpeg"}
RIGHTS_FIELDS = {"rights_status", "permission_to_publish", "public_test_publishable",
                 "source", "license", "attribution"}


def require(condition, message):
    if not condition:
        raise PackError(message)


def record(value, required, optional=()):
    require(isinstance(value, dict), "Expected an object")
    require(set(required) <= value.keys(), f"Missing fields: {set(required) - value.keys()}")
    require(value.keys() <= set(required) | set(optional), "Unexpected fields")
    return value


def text(value, field):
    require(isinstance(value, str) and bool(value) and value.strip() == value,
            f"{field}: expected nonempty trimmed text")
    require(not any(ord(c) < 32 or ord(c) == 127 for c in value), f"{field}: control character")
    # Reject unpaired surrogates before canonical UTF-8 encoding.
    try:
        value.encode("utf-8")
    except UnicodeEncodeError as error:
        raise PackError(f"{field}: invalid UTF-8 text") from error
    return value


def identifier(value):
    text(value, "id")
    require(not any(c.isspace() for c in value), "ID contains whitespace")
    return value


def positive(value, field):
    require(type(value) is int and value > 0, f"{field}: expected positive integer")
    return value


def unique_json(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def invalid_constant(value):
    raise PackError(f"Invalid JSON constant: {value}")


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_json,
                      parse_constant=invalid_constant)


def canonical_json(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True,
                       separators=(",", ":"), allow_nan=False) + "\n").encode("utf-8")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def image_format(data):
    try:
        from PIL import Image
    except ImportError as error:
        raise PackError("Pillow is required for image validation; install Pillow==12.3.0") from error
    try:
        with Image.open(io.BytesIO(data)) as image:
            fmt = image.format
            require(fmt in FORMATS, "Unsupported image encoding")
            require(getattr(image, "n_frames", 1) == 1, "Animated images are unsupported")
            image.verify()
        with Image.open(io.BytesIO(data)) as image:
            image.load()
            require(image.width > 0 and image.height > 0, "Empty image")
        return FORMATS[fmt]
    except (OSError, SyntaxError, ValueError, Image.DecompressionBombError) as error:
        raise PackError(f"Invalid image: {error}") from error


def local_image(root, reference):
    text(reference, "image")
    parts = PurePosixPath(reference).parts
    require(parts and not reference.startswith("/") and "\\" not in reference
            and all(p not in ("", ".", "..") for p in reference.split("/")),
            "Image must be a safe relative POSIX path")
    candidate = (root / reference).resolve()
    require(candidate.is_relative_to(root.resolve()), "Image escapes source directory")
    require(candidate.is_file(), f"Missing image: {reference}")
    require(candidate.suffix.lower() in EXTENSIONS, "Unsupported image extension")
    data = candidate.read_bytes()
    extension, media_type = image_format(data)
    require(candidate.suffix.lower().lstrip(".").replace("jpeg", "jpg") == extension,
            "Image extension does not match encoding")
    digest = sha256(data)
    key = f"objects/{digest}.{extension}"
    return key, data, {"key": key, "sha256": digest, "sizeBytes": len(data),
                       "mediaType": media_type}


def cleared_rights(value):
    rights = {key: value.get(key) for key in RIGHTS_FIELDS}
    require(rights["rights_status"] == "cleared"
            and rights["permission_to_publish"] is True
            and rights["public_test_publishable"] is True,
            "Fixture Pack and every Card must be explicitly cleared for public tests")
    for key in ("source", "license", "attribution"):
        text(rights[key], key)
    return rights


def validate_manifest(manifest, objects):
    """Check the full v1 manifest and exact object bytes (no install or filesystem writes)."""
    record(manifest, {"schemaVersion", "kind", "topic", "pack", "cards", "objects", "provenance"})
    require(type(manifest["schemaVersion"]) is int and manifest["schemaVersion"] == 1,
            "Unsupported schemaVersion")
    require(manifest["kind"] == "full", "Expected a full Pack")
    topic = record(manifest["topic"], {"id", "name"})
    pack = record(manifest["pack"], {"id", "topicId", "name", "revision"})
    identifier(topic["id"])
    identifier(pack["id"])
    text(topic["name"], "topic.name")
    text(pack["name"], "pack.name")
    positive(pack["revision"], "revision")
    require(pack["topicId"] == topic["id"], "Pack references an unknown Topic")
    cards = manifest["cards"]
    require(isinstance(cards, list) and len(cards) >= 2, "A playable Pack needs at least 2 Cards")
    ids, references = set(), set()
    for card in cards:
        record(card, {"id", "packId", "name", "imageReference", "difficulty"})
        identifier(card["id"])
        require(card["id"] not in ids, "Duplicate Card ID")
        ids.add(card["id"])
        text(card["name"], "card.name")
        require(card["packId"] == pack["id"], "Card references an unknown Pack")
        require(type(card["difficulty"]) is int and card["difficulty"] in (1, 2, 3),
                "Difficulty must be 1, 2, or 3")
        references.add(text(card["imageReference"], "imageReference"))
    rows = manifest["objects"]
    require(isinstance(rows, list), "objects must be an array")
    keys = set()
    for obj in rows:
        record(obj, {"key", "sha256", "sizeBytes", "mediaType"})
        key = text(obj["key"], "object.key")
        digest = text(obj["sha256"], "sha256")
        require(re.fullmatch(r"[0-9a-f]{64}", digest) is not None, "Invalid SHA-256")
        require(key not in keys, "Duplicate object key")
        keys.add(key)
        require(key in objects, f"Missing object: {key}")
        data = objects[key]
        positive(obj["sizeBytes"], "sizeBytes")
        require(len(data) == obj["sizeBytes"] and sha256(data) == digest,
                f"Object size/hash mismatch: {key}")
        extension, media_type = image_format(data)
        require(key == f"objects/{digest}.{extension}" and obj["mediaType"] == media_type,
                "Invalid object reference or media type")
    require(keys == references == set(objects), "Unreferenced or missing image objects")
    provenance = record(manifest["provenance"], {"mode", "packRights", "cardRights"})
    if provenance["mode"] == "cleared-test":
        record(provenance["packRights"], RIGHTS_FIELDS)
        cleared_rights(provenance["packRights"])
        rights_rows = provenance["cardRights"]
        require(isinstance(rights_rows, list), "cardRights must be an array")
        rights_ids = set()
        for row in rights_rows:
            record(row, RIGHTS_FIELDS | {"id"})
            identifier(row["id"])
            require(row["id"] not in rights_ids, "Duplicate Card rights record")
            rights_ids.add(row["id"])
            cleared_rights(row)
        require(rights_ids == ids, "Missing or unknown Card rights records")
    else:
        require(provenance["mode"] == "legacy-development", "Unknown provenance mode")
        rights = record(provenance["packRights"], {
            "rights_status", "permission_to_publish", "public_test_publishable"})
        require(rights["rights_status"] == "unverified"
                and rights["permission_to_publish"] is False
                and rights["public_test_publishable"] is False
                and provenance["cardRights"] == [], "Legacy export cannot claim clearance")


def fixture_source(path):
    source = record(read_json(path), {"schema_version", "topic", "pack", "cards"})
    require(source["schema_version"] == "1.0.0", "Unsupported fixture schema")
    record(source["topic"], {"id", "name"})
    pack = record(source["pack"], {"id", "name"} | RIGHTS_FIELDS, {"description"})
    require(isinstance(source["cards"], list), "cards must be an array")
    cards, rights = [], []
    for card in source["cards"]:
        record(card, {"id", "pack_id", "name", "image", "difficulty"} | RIGHTS_FIELDS)
        cards.append({"id": card["id"], "packId": card["pack_id"], "name": card["name"],
                      "imageReference": card["image"], "difficulty": card["difficulty"]})
        rights.append({"id": card["id"], **cleared_rights(card)})
    return source["topic"], {"id": pack["id"], "name": pack["name"]}, cards, {
        "mode": "cleared-test", "packRights": cleared_rights(pack), "cardRights": rights}


def legacy_source(root, topic_name, pack_name):
    # Match the legacy adapter's Uri.encodeComponent IDs. These encode source keys,
    # not production identity; renaming/moving requires an explicit migration map.
    def encode(value):
        return quote(value, safe="-_.!~*'()")
    for name in (topic_name, pack_name):
        text(name, "legacy directory name")
        require(name not in (".", "..") and "/" not in name and "\\" not in name,
                "Topic and Pack must be single directory names")
    directory = root / "assets" / "images" / topic_name / pack_name
    require(directory.is_dir(), "Legacy Pack directory is missing")
    require(directory.resolve().is_relative_to((root / "assets" / "images").resolve()),
            "Legacy Pack escapes assets/images")
    topic_id = f"legacy:topic:{encode(topic_name)}"
    pack_key = f"{encode(topic_name)}:{encode(pack_name)}"
    pack_id = f"legacy:pack:{pack_key}"
    cards = []
    for path in sorted(directory.iterdir()):
        if path.name.startswith(".") or path.suffix.lower() not in EXTENSIONS:
            continue
        reference = path.relative_to(root).as_posix()
        cards.append({"id": f"legacy:card:{pack_key}:{encode(reference)}", "packId": pack_id,
                      "name": path.stem, "imageReference": reference, "difficulty": 1})
    return {"id": topic_id, "name": topic_name}, {"id": pack_id, "name": pack_name}, cards, {
        "mode": "legacy-development", "packRights": {"rights_status": "unverified",
        "permission_to_publish": False, "public_test_publishable": False}, "cardRights": []}


def build_pack(root, topic, pack, cards, provenance, revision=1):
    """Resolve all image bytes once, validate, then return manifest and reproducible ZIP bytes."""
    objects, rows, output_cards = {}, {}, []
    for card in cards:
        key, data, row = local_image(root, card["imageReference"])
        objects[key], rows[key] = data, row
        output_cards.append({**card, "imageReference": key})
    manifest = {"schemaVersion": 1, "kind": "full", "topic": topic,
                "pack": {**pack, "topicId": topic["id"], "revision": revision},
                "cards": output_cards, "objects": list(rows.values()), "provenance": provenance}
    validate_manifest(manifest, objects)
    manifest["cards"] = sorted(output_cards, key=lambda card: card["id"])
    manifest["objects"] = sorted(rows.values(), key=lambda row: row["key"])
    manifest["provenance"] = {**provenance, "cardRights": sorted(
        provenance["cardRights"], key=lambda row: row["id"])}
    entries = {"manifest.json": canonical_json(manifest), **objects}
    output = io.BytesIO()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_STORED) as archive:
        for key in sorted(entries):
            info = zipfile.ZipInfo(key, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, entries[key])
    return manifest, output.getvalue()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    fixture = commands.add_parser("fixture", help="Export explicitly cleared fixture metadata/images")
    fixture.add_argument("source", type=Path, help="Fixture pack.json (schema_version 1.0.0)")
    legacy = commands.add_parser("legacy", help="Development-only export; never grants publishing rights")
    legacy.add_argument("topic")
    legacy.add_argument("pack")
    legacy.add_argument("--development-only", action="store_true", required=True)
    legacy.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    for command in (fixture, legacy):
        command.add_argument("--revision", type=int, default=1)
        command.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        positive(args.revision, "revision")
        require(not args.output.exists(), "Output already exists; choose a new path")
        if args.command == "fixture":
            root = args.source.resolve().parent
            source = fixture_source(args.source)
        else:
            root = args.repo_root.resolve()
            source = legacy_source(root, args.topic, args.pack)
        manifest, data = build_pack(root, *source, revision=args.revision)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive creation preserves an existing output, even if created concurrently.
        with args.output.open("xb") as output:
            output.write(data)
        print(json.dumps({"output": str(args.output), "sizeBytes": len(data),
                          "manifestSha256": sha256(canonical_json(manifest)),
                          "archiveSha256": sha256(data)}, sort_keys=True))
        return 0
    except (PackError, OSError, ValueError, TypeError) as error:
        print(f"Pack export failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
