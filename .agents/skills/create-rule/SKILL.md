---
name: create-rule
description: Standardized guide to authoring persistent operational rules in .agents/rules/.
---

# Maintain a BiGuess rule

Rules live in `.agents/rules/<rule-name>.md` with YAML `trigger: always_on` and a concise `description`. Read the existing rules and AGENTS.md first; update the responsible rule instead of creating a second conflicting rule.

Write stable, source-backed invariants and their practical reason. Keep workflows in skills and architecture detail in sidecars. Avoid current versions/counts, copied manuals, speculative future architecture, or blanket prohibitions on useful verification. User instructions and existing authorization take precedence; do not invent permission gates for routine task work.

Link a new rule from AGENTS.md so the agent can discover it even when a host ignores `.agents/rules/` metadata. Update any moved references, then run `python3 .agents/scripts/validate_setup.py`. Documentation verification should check references and consistency, not tests that assert prose.
