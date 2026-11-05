---
name: debugging
description: Systematic approach to diagnosing, isolating, and resolving bugs with minimal context overhead.
---

# Systematic Debugging Runbook

Follow this discipline when addressing regressions, test failures, or runtime crashes.

## 1. Reproduce & Isolate
- Locate the exact stack trace and failing assertion.
- Write a minimal failing test case or targeted command reproduction.
- Inspect only the files in the call chain using a single-turn parallel `view_file` call.

## 2. Root Cause Analysis
- Differentiate between the symptom (e.g. null pointer, render overflow, network timeout) and root cause (unhandled state, unconstrained widget, race condition).
- Avoid guessing or applying trial-and-error cosmetic fixes.

## 3. Surgical Fix & Regression Guard
- Apply changes using `replace_file_content` with minimal blast radius.
- Re-run the specific failing test to confirm resolution.
- Verify adjacent tests pass to prevent regressions.
