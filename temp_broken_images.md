# 🔍 Broken Images Audit Report

This report lists all image assets that fail to load in **BiGuess** and display the **"Error loading image"** screen (`animated_character_card.dart` / `errorBuilder`).

---

## 📊 Summary of Broken Images

| Category | Manifest Entries | Broken Images | Working Images | Failure Rate |
| :--- | :---: | :---: | :---: | :---: |
| ⚔️ **Attack on Titan** | 15 | **3** | 12 | 20.0% |
| 🍥 **Naruto** | 24 | **7** | 17 | 29.2% |
| 🏴‍☠️ **One Piece** | 466 | **3** | 463 | 0.6% |
| 🍀 **Black Clover** | 67 | **0** | 67 | 0% (All OK) |
| 🗡️ **Demon Slayer** | 43 | **0** | 43 | 0% (All OK) |
| 🎣 **Hunter X Hunter** | 135 | **0** | 135 | 0% (All OK) |
| **Total** | **750** | **13** | **737** | **1.7%** |

---

## 🚨 Detailed List of Broken Images

### 1. ⚔️ Attack on Titan (`assets/images/attack_on_titan/`)

| # | Manifest Path in `lib/assets_manifest.dart` | Status on Disk | Root Cause | Recommended Fix |
|---|---|---|---|---|
| 1 | `assets/images/attack_on_titan/Armin ARLERT.webp` (Line 4) | `Armin Arlelt.webp` exists | Filename spelling mismatch (`ARLERT` vs `Arlelt`) | Change manifest to `'assets/images/attack_on_titan/Armin Arlelt.webp'` or rename file |
| 2 | `assets/images/attack_on_titan/Hange ZOE.webp` (Line 12) | `Hange Zoë.webp` exists | Special character / case mismatch (`ZOE` vs `Zoë`) | Change manifest to `'assets/images/attack_on_titan/Hange Zoë.webp'` or rename file |
| 3 | `assets/images/attack_on_titan/Levi ACKERMAN.webp` (Line 15) | `Levi Ackermann.webp` exists | Double 'n' and case mismatch (`ACKERMAN` vs `Ackermann`) | Change manifest to `'assets/images/attack_on_titan/Levi Ackermann.webp'` or rename file |

> **Note on Attack on Titan:** There are **131 image assets** in `assets/images/attack_on_titan/`, but only **15** are registered in `lib/assets_manifest.dart`.

---

### 2. 🍥 Naruto (`assets/images/naruto/`)

| # | Manifest Path in `lib/assets_manifest.dart` | Status on Disk | Root Cause | Recommended Fix |
|---|---|---|---|---|
| 4 | `assets/images/naruto/Akamaru.webp` (Line 271) | `Kiba Inuzuka + Akamaru.webp` exists | No standalone `Akamaru.webp` file | Use `'assets/images/naruto/Kiba Inuzuka + Akamaru.webp'` or remove entry |
| 5 | `assets/images/naruto/Itachi Uchiha.webp` (Line 277) | `Itachi Utchiha.webp` exists | Disk file has typo (`Utchiha` with extra 't') | Rename file to `Itachi Uchiha.webp` or update manifest |
| 6 | `assets/images/naruto/Kiba Inuzuka.webp` (Line 280) | `Kiba Inuzuka + Akamaru.webp` exists | Combined character file on disk | Use `'assets/images/naruto/Kiba Inuzuka + Akamaru.webp'` |
| 7 | `assets/images/naruto/Konohamaru Sarutobi.webp` (Line 281) | ❌ File missing | Asset not present in folder | Add `Konohamaru Sarutobi.webp` or remove from manifest |
| 8 | `assets/images/naruto/Neji Hyuga.webp` (Line 286) | `Naji Hyuga.webp` exists | Disk file has typo (`Naji` instead of `Neji`) | Rename disk file to `Neji Hyuga.webp` or update manifest |
| 9 | `assets/images/naruto/Shizune.webp` (Line 293) | ❌ File missing | Asset not present in folder | Add `Shizune.webp` or remove from manifest |
| 10 | `assets/images/naruto/Tsunade.webp` (Line 294) | `Tsunade - 5th Hokage.webp` exists | Filename suffix mismatch | Update manifest to `'assets/images/naruto/Tsunade - 5th Hokage.webp'` or rename file |

> **Note on Naruto:** There are **80 image assets** in `assets/images/naruto/`, but only **24** are registered in `lib/assets_manifest.dart`.

---

### 3. 🏴‍☠️ One Piece (`assets/images/one_piece/`)

| # | Manifest Path in `lib/assets_manifest.dart` | Status on Disk | Root Cause | Recommended Fix |
|---|---|---|---|---|
| 11 | `assets/images/one_piece/Bell-mre.webp` (Line 318) | `Bell-mère.webp` exists | Mojibake / encoding corruption (`` instead of `è`) | Replace with `'assets/images/one_piece/Bell-mère.webp'` |
| 12 | `assets/images/one_piece/Charlotte Brle.webp` (Line 361) | `Charlotte Brûlée.webp` exists | Mojibake / encoding corruption (`` instead of `û` and `é`) | Replace with `'assets/images/one_piece/Charlotte Brûlée.webp'` |
| 13 | `assets/images/one_piece/Claomh D. Clover.webp` (Line 383) | `Claíomh D. Clover.webp` exists | Mojibake / encoding corruption (`` instead of `í`) | Replace with `'assets/images/one_piece/Claíomh D. Clover.webp'` |

---

## 🏷️ Category Logo Findings

- **Vinland Saga Logo (`assets/logos/`)**:
  - In `assets/logos/`, the file is named `Winland Saga.webp`.
  - In `lib/screens/categories_screen.dart`, it is mapped to `assets/logos/Winland Saga.webp` (currently displays fine, but file name on disk has `W` instead of `V`).
