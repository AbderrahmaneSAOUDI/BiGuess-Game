# Known Issues & Tech Debt

## 🔴 Critical
*None*

## 🟡 Medium
### Shorebird Engine in Non-Release Mode
Shorebird code push reports warnings during unit/widget testing environments (`The Shorebird Updater is unavailable in the current environment`) which is expected behavior outside release binaries.

### Large Asset Footprint
Over 900 anime character cards are stored in `assets/images/`. Although compressed as WebP, continuous monitoring is needed for APK bundle size optimizations.

## 🟢 Low
### Web Support Nuances
Some mobile native plugins (`open_filex`, `restart_app`) require mock fallbacks or guards when running on Flutter Web.

---

## ✅ Resolved Issues
- **Mandatory Update Dialog Enforcement**: Resolved in commit d4ab660 with non-dismissible dialog when app version is below `min_required_version`.
- **Topic Pack Asset Hierarchy**: Reorganized asset directory structure and dynamic asset manifest resolution.
- **Split-ABI APK Generation**: Transitioned from fat APKs to split-per-abi architecture to reduce APK download size by ~50%.
