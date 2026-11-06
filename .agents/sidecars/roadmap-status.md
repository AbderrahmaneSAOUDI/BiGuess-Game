# Roadmap navigation

`TODO.md` owns ticket ordering, checkboxes, acceptance criteria, and human gates. This file is an index, not a second backlog. Re-read the selected ticket before acting; audit SHAs, versions, inventories, and environment claims in that document are dated evidence.

| Scope | Where to read |
| --- | --- |
| Current application | [architecture.md](architecture.md), [file-map.md](file-map.md), source in `lib/` |
| Approved target contracts | `docs/migration/DECISIONS.md`; relevant `BIGUESS_PRODUCT_BLUEPRINT.md` sections |
| Baseline and migration decisions | `TODO.md` Phase A (T01–T05); `docs/migration/BASELINE.md` is historical verification |
| Local domain, installed packs, sessions | `TODO.md` Phase B (T06–T18) |
| Content backend contracts and infrastructure | `TODO.md` Phase C (T19–T25) |
| Separate trusted-contributor Studio | `TODO.md` Phase D (T26–T38) |
| Mobile catalog/download/sync integration | `TODO.md` Phase E (T39–T45) |
| Migration, release and playtest gates | `TODO.md` Phase F (T46–T49) |

Do not infer completion from scaffolding: the existing record API is not the planned content API; bundled assets are not installed downloadable Packs; version metadata is not a released binary. Do not start the next ticket merely because a document describes it. Apply the user's requested scope and explicit gate acceptance.
