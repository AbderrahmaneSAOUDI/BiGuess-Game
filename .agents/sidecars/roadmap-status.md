# BiGuess Roadmap & Project Status

## Current Phase: Phase 4 (Polishing & Experience Refinement)

### ✅ Phase 1: Core Mechanics & Offline Engine — COMPLETE
- 2-player character deduction flow
- Randomized card selection algorithm
- Offline asset loader & WebP rendering pipeline
- Turn timers and secret character reveal

### ✅ Phase 2: Topics & Expansions — COMPLETE
- 18+ legendary Anime franchises cataloged (920+ character cards)
- Geography Flag packs (250+ country flags)
- Pack selector with dynamic grid and topic filtering
- Animated card interactions and countdown components

### ✅ Phase 3: Hybrid OTA Update System — COMPLETE
- Shorebird instant hot-patching for Dart/asset fixes
- In-App ABI-split APK installer (`dio`, `open_filex`, `restart_app`)
- Mandatory update enforcement modal for outdated versions
- Release automation tooling (`scripts/release.py`)

### 🔄 Phase 4: Polish & Expansion — IN PROGRESS
- ✅ Operational agents setup (`.agents/rules`, `hooks`, `sidecars`, `skills`)
- ✅ Date-based semantic versioning (inception: 2025-05-27)
- ⬜ Additional custom topic packs (Gaming, Movies)
- ⬜ Sound effects & tactile haptic feedback toggles
- ⬜ Accessibility & high-contrast mode polish

---

## Architecture Alignment Roadmap (`TODO.md`)

### 🔄 Phase A: Freeze, verify, and make migration safe — IN PROGRESS
- [x] **T01 — GATE: Freeze the behavioral baseline** (`docs/migration/BASELINE.md`)
- [x] **T02 — GATE: Resolve implementation contracts and blueprint ambiguities** (`docs/migration/DECISIONS.md`)
- [ ] **T03 — Add continuous integration and fast verification** *(Next)*
- [ ] **T04 — GATE: Repair Android release safety without shipping**
- [ ] **T05 — GATE: Make a reversible content inventory and rights quarantine**
