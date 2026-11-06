---
name: create-skill
description: Standardized guide to authoring procedural playbooks and workflows in .agents/skills/.
---

# Maintain a BiGuess skill

Create `.agents/skills/<lowercase-hyphen-name>/SKILL.md` with YAML `name` matching the directory and a `description` stating the capability and when to use it. Read overlapping skills first and prefer extending their owner over adding duplicate triggers.

Ground paths, symbols, flags, and side effects in live source. Include only non-obvious project decisions and actionable workflow. Distinguish the implemented app from blueprint contracts; do not translate future architecture into fictitious current classes. Keep shared invariants in linked rules and detailed maps in sidecars. Add scripts/references only when they have a concrete repeated use.

Preserve task scope and authorization already given; building locally, syncing Git, publishing APKs, deploying Workers, and changing global settings are distinct actions. State actual script side effects rather than assuming a flag named `--dry-run` is safe.

Link the skill in `.agents/README.md`. Run `python3 .agents/scripts/validate_setup.py` and exercise added executable logic in fixtures. If available, also run the installed skill-creator's `scripts/quick_validate.py` on the skill. No placeholder files or unfinished scaffold should remain.
