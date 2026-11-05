---
trigger: always_on
description: Universal safe refactoring, defensive coding, Flutter lifecycle safety, and documentation integrity rules.
---

# Code Quality & Non-Destructive Refactoring

## 1. Documentation & Code Integrity
- **Preserve Existing Comments**: Never strip existing comments, docstrings, or license headers from files unless explicitly tasked with rewriting documentation.
- **Preserve Coding Conventions**: Always respect the existing Dart style, spacing, formatting, and naming conventions of the repository.

## 2. Flutter & Dart Excellence
- **Widget Performance**:
  - Use `const` constructors wherever possible.
  - Extract complex UI subtrees into dedicated `StatelessWidget` classes rather than large private `_build*()` helper methods to enable Flutter element caching.
- **State & Lifecycle Safety**:
  - Always guard with `if (!mounted) return;` after async `await` calls before calling `setState()` or interacting with `BuildContext`.
  - Properly dispose all `TextEditingController`, `AnimationController`, `ScrollController`, `FocusNode`, and `StreamSubscription` instances in `dispose()`.
- **Layout & Rendering Stability**:
  - Prevent `RenderFlex` overflow: Use `Flexible`, `Expanded`, `SingleChildScrollView`, or `ListView` with proper bounding constraints.
  - Never place unbounded `Expanded` widgets inside unconstrained scrollables.
- **Modern Dart**: Prefer switch expressions, pattern matching, records, and concise constructors where appropriate.

## 3. Architecture & Clean Code
- **Separation of Concerns**: Keep business logic, state machines, and data access decoupled from presentation widgets.
- **Defensive Error Handling**: Catch specific exceptions, provide user-friendly error messages, and preserve existing project conventions.
