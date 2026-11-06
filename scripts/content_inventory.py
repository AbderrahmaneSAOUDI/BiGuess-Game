#!/usr/bin/env python3
"""
BiGuess Game - Content Inventory & Rights Quarantine Engine
Scans Topic and Pack assets, calculates content hashes, generates deterministic
stable entity UUIDs, detects duplicates, evaluates technical importability,
and enforces rights quarantine (separating importability from permission to publish).

Acceptance gates:
1. Reconciles exact counts against disk files (922 Anime across 6 packs + 252 Geography Flags = 1174).
2. Generates deterministic, byte-reproducible inventory exports.
3. Leaves all existing asset files completely untouched (no deletions/renames).
4. Flags unverified assets and quarantines them from public test publishing by default.
5. Manages confirmed-cleared fixture packs for automated test suites.
"""

import argparse
import hashlib
import io
import json
import os
import re
import sys
import unicodedata
import uuid
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

try:
    from PIL import Image
except ImportError:
    Image = None

# ANSI colors
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

# Canonical Namespaces for Deterministic UUIDv5 Generation (RFC 4122)
BIGUESS_ROOT_NAMESPACE = uuid.UUID("a78b5e60-49b2-4d2c-9d6e-8c3b9b46e3d1")
TOPIC_NAMESPACE = uuid.uuid5(BIGUESS_ROOT_NAMESPACE, "topic")
PACK_NAMESPACE = uuid.uuid5(BIGUESS_ROOT_NAMESPACE, "pack")
CARD_NAMESPACE = uuid.uuid5(BIGUESS_ROOT_NAMESPACE, "card")

VALID_IMAGE_EXTENSIONS = {".webp", ".png", ".jpg", ".jpeg"}

UNVERIFIED_QUARANTINE_REASON = (
    "Third-party copyrighted character/flag imagery without documented commercial or "
    "public-domain distribution license; quarantined from public distribution and "
    "public test publishing per T05 rights gate."
)


def normalize_text(text: str) -> str:
    """Return Unicode NFC normalized and trimmed text."""
    return unicodedata.normalize("NFC", text.strip())


def slugify(text: str) -> str:
    """Generate a clean alphanumeric comparison slug."""
    norm = normalize_text(text).lower()
    return re.sub(r"[^a-z0-9]", "", norm)


def generate_stable_topic_id(topic_name: str) -> str:
    """Generate deterministic UUIDv5 for a Topic."""
    return str(uuid.uuid5(TOPIC_NAMESPACE, normalize_text(topic_name)))


def generate_stable_pack_id(topic_name: str, pack_name: str) -> str:
    """Generate deterministic UUIDv5 for a Pack within a Topic."""
    key = f"{normalize_text(topic_name)}/{normalize_text(pack_name)}"
    return str(uuid.uuid5(PACK_NAMESPACE, key))


def generate_stable_card_id(topic_name: str, pack_name: str, display_name: str) -> str:
    """Generate deterministic UUIDv5 for a Card within a Topic and Pack."""
    key = f"{normalize_text(topic_name)}/{normalize_text(pack_name)}/{normalize_text(display_name)}"
    return str(uuid.uuid5(CARD_NAMESPACE, key))


@dataclass
class TechnicalImportability:
    status: str  # "importable", "corrupt", "unsupported_format", "unreadable"
    is_importable: bool
    format: Optional[str]
    width: Optional[int]
    height: Optional[int]
    issues: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "is_importable": self.is_importable,
            "format": self.format,
            "width": self.width,
            "height": self.height,
            "issues": self.issues,
        }


@dataclass
class RightsMetadata:
    rights_status: str  # "unverified", "cleared", "quarantined"
    permission_to_publish: bool
    public_test_publishable: bool
    quarantine_reason: Optional[str]
    source: str
    attribution: str
    license: str
    notes: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "rights_status": self.rights_status,
            "permission_to_publish": self.permission_to_publish,
            "public_test_publishable": self.public_test_publishable,
            "quarantine_reason": self.quarantine_reason,
            "source": self.source,
            "attribution": self.attribution,
            "license": self.license,
            "notes": self.notes,
        }


@dataclass
class DuplicateCandidate:
    source_path: str
    proposed_stable_id: str
    match_type: str  # "exact_sha256", "exact_name", "slug_match"
    detail: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "source_path": self.source_path,
            "proposed_stable_id": self.proposed_stable_id,
            "match_type": self.match_type,
            "detail": self.detail,
        }


@dataclass
class AssetRecord:
    source_path: str
    proposed_stable_id: str
    proposed_topic_id: str
    proposed_pack_id: str
    topic: str
    pack: str
    display_name: str
    file_name: str
    extension: str
    size_bytes: int
    sha256: str
    technical_importability: TechnicalImportability
    rights: RightsMetadata
    duplicate_candidates: List[DuplicateCandidate] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "source_path": self.source_path,
            "proposed_stable_id": self.proposed_stable_id,
            "proposed_topic_id": self.proposed_topic_id,
            "proposed_pack_id": self.proposed_pack_id,
            "topic": self.topic,
            "pack": self.pack,
            "display_name": self.display_name,
            "file_name": self.file_name,
            "extension": self.extension,
            "size_bytes": self.size_bytes,
            "sha256": self.sha256,
            "technical_importability": self.technical_importability.to_dict(),
            "rights": self.rights.to_dict(),
            "duplicate_candidates": [d.to_dict() for d in self.duplicate_candidates],
        }


def inspect_image_file(file_path: Path) -> Tuple[TechnicalImportability, bytes]:
    """Inspect and decode image file, returning importability status and raw bytes."""
    issues: List[str] = []
    suffix = file_path.suffix.lower()

    if not file_path.exists():
        return (
            TechnicalImportability(
                status="unreadable",
                is_importable=False,
                format=None,
                width=None,
                height=None,
                issues=["File not found"],
            ),
            b"",
        )

    try:
        data = file_path.read_bytes()
    except Exception as e:
        return (
            TechnicalImportability(
                status="unreadable",
                is_importable=False,
                format=None,
                width=None,
                height=None,
                issues=[f"Read error: {e}"],
            ),
            b"",
        )

    if suffix not in VALID_IMAGE_EXTENSIONS:
        issues.append(f"Unsupported extension '{suffix}'")
        return (
            TechnicalImportability(
                status="unsupported_format",
                is_importable=False,
                format=suffix.lstrip(".").upper(),
                width=None,
                height=None,
                issues=issues,
            ),
            data,
        )

    if len(data) == 0:
        issues.append("File is 0 bytes")
        return (
            TechnicalImportability(
                status="corrupt",
                is_importable=False,
                format=None,
                width=None,
                height=None,
                issues=issues,
            ),
            data,
        )

    img_format: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None

    if Image is not None:
        try:
            with Image.open(io.BytesIO(data)) as img:
                img.verify()
                img_format = img.format
                width, height = img.size
            with Image.open(io.BytesIO(data)) as img:
                img.load()
                if img.format not in {"WEBP", "PNG", "JPEG"}:
                    raise ValueError("Unsupported image encoding")
                expected = {".webp": "WEBP", ".png": "PNG", ".jpg": "JPEG", ".jpeg": "JPEG"}
                if img.format != expected[suffix]:
                    raise ValueError("Image extension does not match its encoding")
                if getattr(img, "n_frames", 1) != 1:
                    raise ValueError("Animated images are unsupported")
        except Exception as e:
            issues.append(f"Corrupt image payload: {e}")
            return (
                TechnicalImportability(
                    status="corrupt",
                    is_importable=False,
                    format=img_format,
                    width=width,
                    height=height,
                    issues=issues,
                ),
                data,
            )
    else:
        return (TechnicalImportability(
            status="unreadable", is_importable=False, format=None,
            width=None, height=None,
            issues=["Pillow is required to verify image integrity; install Pillow"],
        ), data)

    return (
        TechnicalImportability(
            status="importable",
            is_importable=True,
            format=img_format,
            width=width,
            height=height,
            issues=[],
        ),
        data,
    )


def _unique_fixture_object(pairs: List[Tuple[str, Any]]) -> Dict[str, Any]:
    result: Dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate fixture metadata key: {key}")
        result[key] = value
    return result


def _fixture_manifest(directory: Path) -> Tuple[Dict[str, Any], Dict[str, Dict[str, Any]], Optional[str]]:
    """Read explicit fixture declarations; invalid metadata never grants rights."""
    try:
        with (directory / "pack.json").open(encoding="utf-8") as stream:
            metadata = json.load(stream, object_pairs_hook=_unique_fixture_object)
        if not isinstance(metadata, dict) or metadata.get("schema_version") != "1.0.0":
            raise ValueError("Missing or unsupported fixture manifest schema")
        for kind in ("topic", "pack"):
            row = metadata.get(kind)
            if not isinstance(row, dict) or any(
                not isinstance(row.get(key), str) or not row[key].strip()
                or row[key].strip() != row[key] for key in ("id", "name")
            ):
                raise ValueError(f"Invalid fixture {kind} metadata")
        cards = metadata.get("cards")
        if not isinstance(cards, list):
            raise ValueError("Fixture cards must be an array")
        by_image: Dict[str, Dict[str, Any]] = {}
        ids: Set[str] = set()
        for card in cards:
            if not isinstance(card, dict) or any(
                not isinstance(card.get(key), str) or not card[key].strip()
                or card[key].strip() != card[key] for key in ("id", "pack_id", "name", "image")
            ):
                raise ValueError("Invalid fixture Card metadata")
            image = card["image"]
            if image in (".", "..") or "/" in image or "\\" in image:
                raise ValueError("Fixture image must name a file in its directory")
            if card["pack_id"] != metadata["pack"]["id"]:
                raise ValueError("Fixture Card references another Pack")
            if type(card.get("difficulty")) is not int or card["difficulty"] not in (1, 2, 3):
                raise ValueError("Invalid fixture Card difficulty")
            if image in by_image or card["id"] in ids:
                raise ValueError("Duplicate fixture Card ID or image declaration")
            by_image[image] = card
            ids.add(card["id"])
        return metadata, by_image, None
    except (OSError, UnicodeError, ValueError) as error:
        return {}, {}, f"Invalid or missing fixture manifest: {error}"


def _fixture_rights(pack: Dict[str, Any], card: Dict[str, Any], error: Optional[str]) -> RightsMetadata:
    def explicitly_cleared(row: Dict[str, Any]) -> bool:
        return (
            row.get("rights_status") == "cleared"
            and row.get("permission_to_publish") is True
            and row.get("public_test_publishable") is True
            and all(isinstance(row.get(key), str) and bool(row[key].strip())
                    for key in ("source", "license", "attribution"))
        )

    cleared = error is None and explicitly_cleared(pack) and explicitly_cleared(card)
    provenance = {
        key: card.get(key) if isinstance(card.get(key), str) and card[key].strip()
        else pack.get(key) if isinstance(pack.get(key), str) and pack[key].strip()
        else "unverified"
        for key in ("source", "attribution", "license")
    }
    return RightsMetadata(
        rights_status="cleared" if cleared else "unverified",
        permission_to_publish=cleared,
        public_test_publishable=cleared,
        quarantine_reason=None if cleared else (
            error or "Fixture Pack and matching Card lack explicit publication clearance"
        ),
        **provenance,
    )


def scan_assets(
    images_dir: Path,
    repo_root: Path,
    fixture_dirs: Optional[List[Path]] = None,
) -> List[AssetRecord]:
    """Scan Topic/Pack image folders and optionally confirmed fixture packs."""
    records: List[AssetRecord] = []

    # 1. Scan images_dir (Topic -> Pack -> Images)
    if images_dir.exists():
        topic_dirs = sorted([d for d in images_dir.iterdir() if d.is_dir() and not d.name.startswith(".")])
        for topic_dir in topic_dirs:
            topic_name = normalize_text(topic_dir.name)
            pack_dirs = sorted([p for p in topic_dir.iterdir() if p.is_dir() and not p.name.startswith(".")])
            for pack_dir in pack_dirs:
                pack_name = normalize_text(pack_dir.name)
                files = sorted(
                    [
                        f
                        for f in pack_dir.iterdir()
                        if f.is_file() and not f.name.startswith(".") and f.suffix.lower() in VALID_IMAGE_EXTENSIONS
                    ],
                    key=lambda x: normalize_text(x.name),
                )

                for file_path in files:
                    display_name = normalize_text(file_path.stem)
                    importability, data = inspect_image_file(file_path)
                    sha256_hash = hashlib.sha256(data).hexdigest()
                    size_bytes = len(data)

                    card_id = generate_stable_card_id(topic_name, pack_name, display_name)
                    topic_id = generate_stable_topic_id(topic_name)
                    pack_id = generate_stable_pack_id(topic_name, pack_name)

                    try:
                        rel_path = file_path.relative_to(repo_root).as_posix()
                    except ValueError:
                        rel_path = file_path.as_posix()

                    rights = RightsMetadata(
                        rights_status="unverified",
                        permission_to_publish=False,
                        public_test_publishable=False,
                        quarantine_reason=UNVERIFIED_QUARANTINE_REASON,
                        source="bundled_legacy_assets",
                        attribution="Unverified / Respective Owners (see AppConstants.imageDisclaimer)",
                        license="unverified",
                    )

                    records.append(
                        AssetRecord(
                            source_path=rel_path,
                            proposed_stable_id=card_id,
                            proposed_topic_id=topic_id,
                            proposed_pack_id=pack_id,
                            topic=topic_name,
                            pack=pack_name,
                            display_name=display_name,
                            file_name=file_path.name,
                            extension=file_path.suffix.lower(),
                            size_bytes=size_bytes,
                            sha256=sha256_hash,
                            technical_importability=importability,
                            rights=rights,
                        )
                    )

    # 2. Fixture directory selection does not itself grant publication rights.
    if fixture_dirs:
        for fdir in fixture_dirs:
            if not fdir.exists():
                continue
            meta, fixture_cards, metadata_error = _fixture_manifest(fdir)

            topic_name = normalize_text(meta.get("topic", {}).get("name", "TestTopic"))
            pack_name = normalize_text(meta.get("pack", {}).get("name", fdir.name))
            topic_id = meta.get("topic", {}).get("id") or generate_stable_topic_id(topic_name)
            pack_id = meta.get("pack", {}).get("id") or generate_stable_pack_id(topic_name, pack_name)

            files = sorted(
                [
                    f
                    for f in fdir.iterdir()
                    if f.is_file() and not f.name.startswith(".") and f.suffix.lower() in VALID_IMAGE_EXTENSIONS
                ],
                key=lambda x: normalize_text(x.name),
            )

            for file_path in files:
                display_name = normalize_text(file_path.stem)
                importability, data = inspect_image_file(file_path)
                sha256_hash = hashlib.sha256(data).hexdigest()
                size_bytes = len(data)

                card_id = generate_stable_card_id(topic_name, pack_name, display_name)
                try:
                    rel_path = file_path.relative_to(repo_root).as_posix()
                except ValueError:
                    rel_path = file_path.as_posix()

                declared_card = fixture_cards.get(file_path.name, {})
                rights = _fixture_rights(
                    meta.get("pack", {}), declared_card,
                    metadata_error or (None if declared_card else "Image has no matching fixture Card declaration"),
                )

                records.append(
                    AssetRecord(
                        source_path=rel_path,
                        proposed_stable_id=card_id,
                        proposed_topic_id=topic_id,
                        proposed_pack_id=pack_id,
                        topic=topic_name,
                        pack=pack_name,
                        display_name=display_name,
                        file_name=file_path.name,
                        extension=file_path.suffix.lower(),
                        size_bytes=size_bytes,
                        sha256=sha256_hash,
                        technical_importability=importability,
                        rights=rights,
                    )
                )

    # Deterministic sort by topic, pack, display_name, source_path
    records.sort(key=lambda r: (r.topic, r.pack, r.display_name, r.source_path))

    # 3. Detect duplicate candidates across all records
    _attach_duplicate_candidates(records)

    return records


def _attach_duplicate_candidates(records: List[AssetRecord]) -> None:
    """Analyze and populate duplicate candidates across all records."""
    hash_map: Dict[str, List[AssetRecord]] = {}
    name_map: Dict[str, List[AssetRecord]] = {}
    slug_map: Dict[str, List[AssetRecord]] = {}

    for r in records:
        hash_map.setdefault(r.sha256, []).append(r)
        name_map.setdefault(r.display_name.lower(), []).append(r)
        slug_map.setdefault(slugify(r.display_name), []).append(r)

    for r in records:
        candidates: List[DuplicateCandidate] = []
        seen_paths: Set[str] = {r.source_path}

        # 1. Exact SHA-256 binary duplicate
        for other in hash_map.get(r.sha256, []):
            if other.source_path not in seen_paths:
                candidates.append(
                    DuplicateCandidate(
                        source_path=other.source_path,
                        proposed_stable_id=other.proposed_stable_id,
                        match_type="exact_sha256",
                        detail=f"Identical binary payload (SHA-256: {r.sha256[:12]}...)",
                    )
                )
                seen_paths.add(other.source_path)

        # 2. Exact display name match (e.g. cross-pack or cross-topic)
        for other in name_map.get(r.display_name.lower(), []):
            if other.source_path not in seen_paths:
                candidates.append(
                    DuplicateCandidate(
                        source_path=other.source_path,
                        proposed_stable_id=other.proposed_stable_id,
                        match_type="exact_name",
                        detail=f"Matching character name in '{other.topic} -> {other.pack}'",
                    )
                )
                seen_paths.add(other.source_path)

        # 3. Slug match (e.g., punctuation or space variation)
        slug = slugify(r.display_name)
        for other in slug_map.get(slug, []):
            if other.source_path not in seen_paths:
                candidates.append(
                    DuplicateCandidate(
                        source_path=other.source_path,
                        proposed_stable_id=other.proposed_stable_id,
                        match_type="slug_match",
                        detail=f"Normalized slug collision '{slug}' with '{other.display_name}' in '{other.topic} -> {other.pack}'",
                    )
                )
                seen_paths.add(other.source_path)

        candidates.sort(key=lambda c: (c.match_type, c.source_path))
        r.duplicate_candidates = candidates


def build_inventory_report(
    records: List[AssetRecord],
    images_dir: Path,
    expected_counts: Optional[Dict[str, Dict[str, int]]] = None,
    repo_root: Optional[Path] = None,
) -> Dict[str, Any]:
    """Compile comprehensive deterministic inventory report."""
    total_files = len(records)
    total_bytes = sum(r.size_bytes for r in records)

    topics_summary: Dict[str, Dict[str, Any]] = {}
    for r in records:
        if r.topic not in topics_summary:
            topics_summary[r.topic] = {"packs": {}, "total_records": 0}
        t_entry = topics_summary[r.topic]
        t_entry["packs"][r.pack] = t_entry["packs"].get(r.pack, 0) + 1
        t_entry["total_records"] += 1

    # Technical importability aggregation
    importable_count = sum(1 for r in records if r.technical_importability.is_importable)
    corrupt_count = sum(1 for r in records if r.technical_importability.status == "corrupt")
    unsupported_count = sum(1 for r in records if r.technical_importability.status == "unsupported_format")
    unreadable_count = sum(1 for r in records if r.technical_importability.status == "unreadable")

    # Rights aggregation
    unverified_count = sum(1 for r in records if r.rights.rights_status == "unverified")
    cleared_count = sum(1 for r in records if r.rights.rights_status == "cleared")
    quarantined_count = sum(1 for r in records if r.rights.rights_status == "quarantined")
    permission_to_publish_count = sum(1 for r in records if r.rights.permission_to_publish)
    public_test_publishable_count = sum(
        1 for r in records if r.rights.public_test_publishable
        and r.rights.permission_to_publish and r.technical_importability.is_importable
    )

    # Duplicate aggregation
    exact_hash_sets: Dict[str, List[str]] = {}
    for r in records:
        exact_hash_sets.setdefault(r.sha256, []).append(r.source_path)
    binary_duplicate_sets = {h: paths for h, paths in exact_hash_sets.items() if len(paths) > 1}
    binary_duplicate_files = sum(len(paths) for paths in binary_duplicate_sets.values())

    name_sets: Dict[str, Set[str]] = {}
    for r in records:
        name_sets.setdefault(r.display_name.lower(), set()).add(f"{r.topic}/{r.pack}")
    cross_pack_names = {n: packs for n, packs in name_sets.items() if len(packs) > 1}

    # Count disk files directly for reconciliation
    disk_paths: Set[Path] = set()
    if images_dir.exists():
        for p in images_dir.rglob("*"):
            if p.is_file() and not p.name.startswith(".") and p.suffix.lower() in VALID_IMAGE_EXTENSIONS:
                disk_paths.add(p.absolute())
    disk_files_count = len(disk_paths)
    source_root = repo_root or Path(__file__).resolve().parents[1]
    inventory_paths = [(source_root / r.source_path).absolute() for r in records]
    inventoried_source_paths = {p for p in inventory_paths if p.is_relative_to(images_dir.absolute())}

    discrepancies: List[str] = []
    for path in sorted(disk_paths - inventoried_source_paths):
        discrepancies.append(f"Source file missing from inventory: {path}")
    for path in sorted(inventoried_source_paths - disk_paths):
        discrepancies.append(f"Inventoried source file missing from disk: {path}")
    if len(set(inventory_paths)) != len(inventory_paths):
        discrepancies.append("Duplicate source paths in inventory")
    proposed_ids: Dict[str, Set[str]] = {}
    for row in records:
        proposed_ids.setdefault(row.proposed_stable_id, set()).add(row.source_path)
    for identifier, paths in sorted(proposed_ids.items()):
        if len(paths) > 1:
            discrepancies.append(f"Proposed Card ID collision: {identifier}: {', '.join(sorted(paths))}")
    # Check baseline expected numbers if supplied (e.g. 922 Anime + 252 Flags = 1174)
    if expected_counts:
        for exp_topic, exp_packs in expected_counts.items():
            if exp_topic not in topics_summary:
                discrepancies.append(f"Missing expected topic '{exp_topic}'")
                continue
            act_topic = topics_summary[exp_topic]
            for exp_pack, exp_cnt in exp_packs.items():
                act_cnt = act_topic["packs"].get(exp_pack, 0)
                if act_cnt != exp_cnt:
                    discrepancies.append(
                        f"Count mismatch in '{exp_topic}/{exp_pack}': expected {exp_cnt}, found {act_cnt}"
                    )

    is_reconciled = len(discrepancies) == 0

    summary = {
        "total_records": total_files,
        "total_topics": len(topics_summary),
        "total_packs": sum(len(t["packs"]) for t in topics_summary.values()),
        "total_bytes": total_bytes,
        "topics": topics_summary,
        "reconciliation": {
            "disk_files_count": disk_files_count,
            "inventoried_records_count": total_files,
            "inventoried_source_files_count": len(inventoried_source_paths),
            "is_reconciled": is_reconciled,
            "discrepancies": discrepancies,
        },
        "technical_importability": {
            "importable": importable_count,
            "corrupt": corrupt_count,
            "unsupported_format": unsupported_count,
            "unreadable": unreadable_count,
        },
        "rights_quarantine": {
            "unverified": unverified_count,
            "cleared": cleared_count,
            "quarantined": quarantined_count,
            "permission_to_publish_granted": permission_to_publish_count,
            "public_test_publishable_count": public_test_publishable_count,
        },
        "duplicate_analysis": {
            "exact_binary_duplicate_sets": len(binary_duplicate_sets),
            "exact_binary_duplicate_files": binary_duplicate_files,
            "cross_pack_name_matches": len(cross_pack_names),
        },
    }

    return {
        "inventory_version": "1.0.0",
        "export_deterministic": True,
        "summary": summary,
        "records": [r.to_dict() for r in records],
    }


def generate_markdown_report(report: Dict[str, Any]) -> str:
    """Render only facts from this inventory, including empty and failed scans."""
    summary = report["summary"]
    reconciliation = summary["reconciliation"]
    technical = summary["technical_importability"]
    rights = summary["rights_quarantine"]
    records = report["records"]
    total = summary["total_records"]

    def cell(value: Any) -> str:
        return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", " ")

    def percent(count: int) -> str:
        return f"{count / total * 100:.2f}%" if total else "0.00%"

    lines = [
        "# BiGuess content inventory and rights report", "",
        f"Source reconciliation: **{'PASS' if reconciliation['is_reconciled'] else 'FAIL'}**.", "",
        "| Check | Result |", "| --- | --- |",
        f"| Inventoried images (including selected fixtures) | {total} |",
        f"| Images on disk in the source tree | {reconciliation['disk_files_count']} |",
        f"| Total image size | {summary['total_bytes'] / (1024 * 1024):.2f} MiB |",
        f"| Topics / Packs | {summary['total_topics']} / {summary['total_packs']} |",
        f"| Verified images | {technical['importable']} ({percent(technical['importable'])}) |",
        f"| Corrupt / unsupported / unreadable images | {technical['corrupt']} / {technical['unsupported_format']} / {technical.get('unreadable', 0)} |",
        f"| Explicitly cleared images | {rights['cleared']} ({percent(rights['cleared'])}) |",
        f"| Unverified images | {rights['unverified']} |",
        f"| Images eligible for public test export | {rights['public_test_publishable_count']} |", "",
        "## Topics and Packs", "",
        "| Topic | Pack | Images | Verified | Cleared | Public test export |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for topic, topic_data in sorted(summary["topics"].items()):
        for pack, count in sorted(topic_data["packs"].items()):
            rows = [r for r in records if r["topic"] == topic and r["pack"] == pack]
            valid = sum(r["technical_importability"]["is_importable"] for r in rows)
            cleared = sum(r["rights"]["rights_status"] == "cleared" for r in rows)
            publishable = sum(r["rights"]["public_test_publishable"]
                              and r["rights"]["permission_to_publish"]
                              and r["technical_importability"]["is_importable"] for r in rows)
            lines.append(f"| {cell(topic)} | {cell(pack)} | {count} | {valid} | {cleared} | {publishable} |")
    if reconciliation["discrepancies"]:
        lines.extend(["", "## Reconciliation errors", ""])
        lines.extend(f"- {cell(issue)}" for issue in reconciliation["discrepancies"])
    lines.extend([
        "", "## Publication rights", "",
        "A readable image does not grant permission to publish it. Legacy assets remain "
        "unverified. A fixture is cleared only when its Pack and matching Card explicitly "
        "declare permission, source, license, and attribution. Folder and Topic names do not grant clearance.",
        "", "## Duplicate candidates", "",
    ])
    by_hash: Dict[str, List[str]] = {}
    by_name: Dict[str, List[Dict[str, Any]]] = {}
    for row in records:
        by_hash.setdefault(row["sha256"], []).append(row["source_path"])
        by_name.setdefault(row["display_name"].lower(), []).append(row)
    duplicates = [(digest, paths) for digest, paths in sorted(by_hash.items()) if len(paths) > 1]
    lines.append(f"Exact image-byte duplicate groups: {len(duplicates)}.")
    for digest, paths in duplicates:
        lines.append(f"- SHA-256 `{digest}`: " + ", ".join(f"`{cell(path)}`" for path in sorted(paths)))
    lines.extend(["", "Names shared across Packs:"])
    shared = [(name, rows) for name, rows in sorted(by_name.items())
              if len({(r["topic"], r["pack"]) for r in rows}) > 1]
    for name, rows in shared:
        packs = sorted({f"{r['topic']} / {r['pack']}" for r in rows})
        lines.append(f"- {cell(name)}: " + ", ".join(cell(pack) for pack in packs))
    if not shared:
        lines.append("- None found.")
    lines.extend(["", "Proposed IDs use deterministic UUIDv5 values scoped to the original "
                  "Topic, Pack, and name. ID collisions are reported as reconciliation errors.",
                  "", "Generated by `scripts/content_inventory.py`.", ""])
    return "\n".join(lines)


def export_public_test_assets(records: List[AssetRecord], target_dir: Path, repo_root: Path) -> int:
    """
    Export ONLY assets cleared for public test publishing into target directory.
    Guarantees that unverified / quarantined assets are completely excluded.
    Returns the count of exported assets.
    """
    if target_dir.exists() and any(target_dir.iterdir()):
        raise ValueError("Public test export needs an empty destination directory")
    outputs: List[Tuple[Path, bytes]] = []
    destination = target_dir.resolve()
    for r in records:
        if (r.rights.rights_status == "cleared" and r.rights.public_test_publishable
                and r.rights.permission_to_publish and r.technical_importability.is_importable):
            src = repo_root / r.source_path
            data = src.read_bytes()
            if len(data) != r.size_bytes or hashlib.sha256(data).hexdigest() != r.sha256:
                raise ValueError(f"Image changed since inventory: {r.source_path}")
            dst = (destination / r.topic / r.pack / r.file_name).resolve()
            if not dst.is_relative_to(destination):
                raise ValueError("Export path escapes the destination directory")
            outputs.append((dst, data))
    if len({path for path, _ in outputs}) != len(outputs):
        raise ValueError("Multiple images map to the same export path")
    target_dir.mkdir(parents=True, exist_ok=True)
    for dst, data in outputs:
        dst.parent.mkdir(parents=True, exist_ok=True)
        with dst.open("xb") as stream:
            stream.write(data)
    return len(outputs)


def verify_reproducibility(
    images_dir: Path,
    repo_root: Path,
    fixture_dirs: Optional[List[Path]] = None,
) -> bool:
    """Run two independent inventory sweeps and assert byte-for-byte identical JSON."""
    rec1 = scan_assets(images_dir, repo_root, fixture_dirs)
    rep1 = build_inventory_report(rec1, images_dir)
    json1 = json.dumps(rep1, indent=2, ensure_ascii=False)

    rec2 = scan_assets(images_dir, repo_root, fixture_dirs)
    rep2 = build_inventory_report(rec2, images_dir)
    json2 = json.dumps(rep2, indent=2, ensure_ascii=False)

    hash1 = hashlib.sha256(json1.encode("utf-8")).hexdigest()
    hash2 = hashlib.sha256(json2.encode("utf-8")).hexdigest()

    return hash1 == hash2


def main() -> int:
    parser = argparse.ArgumentParser(
        description="BiGuess Content Inventory & Rights Quarantine Engine",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-i",
        "--images-dir",
        type=Path,
        default=Path("assets/images"),
        help="Path to Topic/Pack images folder (default: assets/images)",
    )
    parser.add_argument(
        "--fixtures-dir",
        type=Path,
        default=Path("test/fixtures/cleared_shapes"),
        help="Path to confirmed-cleared test fixture directory (default: test/fixtures/cleared_shapes)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Write full JSON inventory to specified path",
    )
    parser.add_argument(
        "-m",
        "--markdown",
        type=Path,
        help="Write GitHub-Flavored Markdown summary report to specified path",
    )
    parser.add_argument(
        "--export-public-test",
        type=Path,
        help="Export only cleared/publishable assets to destination directory (verifying quarantine exclusion)",
    )
    parser.add_argument(
        "--include-fixtures",
        action="store_true",
        help="Include confirmed-cleared fixture packs in the main inventory scan",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Run reconciliation check and assert complete count and integrity pass (exit code 1 if failed)",
    )
    parser.add_argument(
        "--check-reproducible",
        action="store_true",
        help="Verify that inventory generation is deterministic and byte-reproducible across runs",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Display formatted console summary breakdown",
    )

    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    images_dir = repo_root / args.images_dir if not args.images_dir.is_absolute() else args.images_dir
    fixtures_dir = repo_root / args.fixtures_dir if not args.fixtures_dir.is_absolute() else args.fixtures_dir
    if not images_dir.is_dir():
        print(f"Image folder does not exist: {images_dir}", file=sys.stderr)
        return 1
    if args.include_fixtures and not fixtures_dir.is_dir():
        print(f"Fixture folder does not exist: {fixtures_dir}", file=sys.stderr)
        return 1

    fixture_dirs_to_scan: Optional[List[Path]] = None
    if args.include_fixtures and fixtures_dir.exists():
        fixture_dirs_to_scan = [fixtures_dir]

    expected_baseline_counts = {
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

    if args.check_reproducible:
        print(f"{CYAN}Checking export reproducibility (2 independent passes)...{RESET}")
        is_reproducible = verify_reproducibility(images_dir, repo_root, fixture_dirs_to_scan)
        if is_reproducible:
            print(f"{GREEN}✅ Export is 100% byte-reproducible and deterministic.{RESET}")
        else:
            print(f"{RED}❌ Export non-determinism detected!{RESET}")
            return 1

    records = scan_assets(images_dir, repo_root, fixture_dirs_to_scan)
    report = build_inventory_report(
        records,
        images_dir,
        expected_counts=expected_baseline_counts
        if images_dir.resolve() == (repo_root / "assets/images").resolve() else None,
    )

    # Handle outputs
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        print(f"{GREEN}✅ Inventory JSON exported to {args.output} ({len(records)} records){RESET}")

    if args.markdown:
        args.markdown.parent.mkdir(parents=True, exist_ok=True)
        md_text = generate_markdown_report(report)
        with open(args.markdown, "w", encoding="utf-8") as f:
            f.write(md_text)
        print(f"{GREEN}✅ Markdown report exported to {args.markdown}{RESET}")

    if args.export_public_test:
        try:
            count = export_public_test_assets(records, args.export_public_test, repo_root)
        except (OSError, ValueError) as error:
            print(f"Public test export failed: {error}", file=sys.stderr)
            return 1
        print(
            f"{CYAN}Public test export completed: {count} assets exported to {args.export_public_test} "
            f"({report['summary']['rights_quarantine']['unverified']} unverified assets safely excluded).{RESET}"
        )

    # Console summary
    show_summary = args.summary or (not args.output and not args.markdown and not args.export_public_test and not args.check)
    if show_summary or args.check:
        s = report["summary"]
        r = s["reconciliation"]
        t = s["technical_importability"]
        q = s["rights_quarantine"]
        d = s["duplicate_analysis"]

        print(f"\n{BOLD}{CYAN}======================================================================{RESET}")
        print(f"{BOLD}{CYAN}             📦 BiGuess Content Inventory & Rights Gate               {RESET}")
        print(f"{BOLD}{CYAN}======================================================================{RESET}")
        print(f"Total Assets Inventoried:    {BOLD}{s['total_records']}{RESET}")
        print(f"Total Data Volume:           {BOLD}{s['total_bytes'] / (1024 * 1024):.2f} MB{RESET}")
        print(f"Disk Files Scanned:          {BOLD}{r['disk_files_count']}{RESET}")
        print(f"Counts Reconciled:           {GREEN if r['is_reconciled'] else RED}{r['is_reconciled']}{RESET}")
        print(f"Image checks:                {GREEN}{t['importable']}{RESET} verified, {t['corrupt']} damaged, {t['unsupported_format']} unsupported, {t['unreadable']} unreadable")
        print(f"Rights Breakdown:            {YELLOW}{q['unverified']} unverified (quarantined){RESET}, {GREEN}{q['cleared']} cleared{RESET}")
        print(f"Public Test Publishable:     {GREEN if q['public_test_publishable_count'] > 0 else YELLOW}{q['public_test_publishable_count']}{RESET} (quarantine prevents public exposure)")
        print(f"Exact Duplicate Hash Sets:   {d['exact_binary_duplicate_sets']} ({d['exact_binary_duplicate_files']} files)")
        print(f"Cross-Pack Name Matches:     {d['cross_pack_name_matches']} characters")
        print(f"{BOLD}{CYAN}----------------------------------------------------------------------{RESET}")

        for topic, t_data in sorted(s["topics"].items()):
            print(f"{BOLD}{topic}{RESET} ({t_data['total_records']} cards):")
            for pack, count in sorted(t_data["packs"].items()):
                print(f"   • {pack}: {count} cards")
        print(f"{BOLD}{CYAN}======================================================================{RESET}\n")

    if args.check:
        if not report["summary"]["reconciliation"]["is_reconciled"]:
            print(f"{RED}❌ Reconciliation check failed! Discrepancies: {report['summary']['reconciliation']['discrepancies']}{RESET}")
            return 1
        if report["summary"]["technical_importability"]["importable"] != len(records):
            print(f"{RED}Image verification failed. Check corrupt, unsupported, and unreadable images.{RESET}")
            return 1
        print(f"{GREEN}✅ All counts reconciled and integrity checks passed!{RESET}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
