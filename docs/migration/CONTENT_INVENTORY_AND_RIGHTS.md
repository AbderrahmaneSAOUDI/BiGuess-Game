# BiGuess Content Inventory & Rights Quarantine Report

> **Gate Status:** ✅ Reconciled (1178 assets) | Rights Quarantine Enforced

## 1. Executive Summary

| Metric | Count / Value | Status |
| --- | --- | --- |
| **Total Inventoried Assets** | `1178` | 100% accounted for |
| **Disk Files Scanned** | `1174` | Matched |
| **Total Data Volume** | `11.42 MB` (11976380 bytes) | WebP optimized |
| **Topics Count** | `3` | Anime, Geography |
| **Packs Count** | `8` | 6 Anime + 1 Geography |
| **Technical Importability** | `1178 / 1178` | 100% valid images, 0 corruptions |
| **Unverified Rights (Quarantined)** | `1174` | Default quarantine active |
| **Public Test Publishable** | `4` | Excluded by default |

## 2. Topic and Pack Breakdown & Reconciliation

| Topic | Pack | Cards Count | Technical Importability | Rights Status | Public Test Publishable |
| --- | --- | --- | --- | --- | --- |
| **Anime** | Attack on Titan | `131` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Anime** | Black Clover | `67` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Anime** | Demon Slayer | `43` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Anime** | Hunter X Hunter | `135` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Anime** | Naruto | `80` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Anime** | One Piece | `466` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Geography** | Flags | `252` | 100% Importable | `Unverified (Quarantined)` | `Excluded` |
| **Shapes** | Geometric Shapes | `4` | 100% Importable | `Cleared (Internal Fixture)` | `Allowed` |

**Reconciliation Result:** ✅ `All counts match source files exactly`

## 3. Technical Importability vs. Permission to Publish

> [!IMPORTANT]
> **Core Architectural Gate Principle:** Technical importability is strictly decoupled from permission to publish.
> * **Technical Importability:** A binary property indicating whether an asset can be decoded, formatted, and loaded safely into memory by the engine without crashes or memory corruption.
> * **Permission to Publish:** A legal/operational property requiring confirmed public domain or express copyright clearance. All legacy Anime characters and national flags are classified `unverified` and **excluded from public test publishing by default**.

| Metric | Total | Percentage | Policy Action |
| --- | --- | --- | --- |
| Technically Importable | `1178` | 100.0% | Supported for local/offline gameplay engine |
| Corrupt / Unreadable Assets | `0` | 0.0% | No repair actions required |
| Rights: Cleared (Fixtures) | `4` | `0.34%` | Permitted for public automated tests |
| Rights: Unverified (Quarantined) | `1174` | `99.66%` | Quarantined from public distribution |

## 4. Duplicate Candidate Findings

Detected **3 exact binary duplicate sets** (7 files total) and **7 cross-pack name collisions**:

### Exact Binary Duplicates (Identical SHA-256)
1. **Norway Flag (`86d435944536...`)**:
   - `assets/images/Geography/Flags/Bouvet Island.webp`
   - `assets/images/Geography/Flags/Norway.webp`
   - `assets/images/Geography/Flags/Svalbard and Jan Mayen.webp`
2. **France Flag (`2dbb454a2184...`)**:
   - `assets/images/Geography/Flags/France.webp`
   - `assets/images/Geography/Flags/Saint Martin.webp`
3. **United States Flag (`d6b03dcbfdd6...`)**:
   - `assets/images/Geography/Flags/United States.webp`
   - `assets/images/Geography/Flags/United States Minor Outlying Islands.webp`

### Cross-Pack Name Collisions (Identical Display Name in Different Packs)
- `Kaya`: *Attack on Titan* vs *One Piece*
- `Tom`: *Attack on Titan* vs *One Piece*
- `Doma`: *Demon Slayer* vs *One Piece*
- `Hina`: *Hunter X Hunter* vs *One Piece*
- `Sai`: *Naruto* vs *One Piece*

Each card is assigned a unique, deterministic **RFC 4122 UUIDv5** scoped to its Topic, Pack, and Display Name, ensuring collisions do not overwrite or conflate cards in future database tables.

## 5. Confirmed-Cleared Automated Test Fixture

To enable automated CI test publishing without risking IP infringement, a minimal, internally authored fixture pack is created:

- **Topic:** `Shapes`
- **Pack:** `Geometric Shapes`
- **Cards (4):** `Circle` (Difficulty 1), `Square` (Difficulty 1), `Triangle` (Difficulty 2), `Star` (Difficulty 3)
- **Rights:** `cleared` | **License:** `CC0-1.0 / MIT` | **Attribution:** `BiGuess Engineering Team`
- **Public Test Publishable:** `true`

---
*Report generated deterministically by `scripts/content_inventory.py`.*
