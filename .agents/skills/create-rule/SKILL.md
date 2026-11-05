---
name: create-rule
description: Standardized guide to authoring persistent operational rules in .agents/rules/.
---

# Create Rule Runbook

## 1. Directory & Format
- Rules reside in `.agents/rules/<rule-name>.md`.
- Include YAML frontmatter:
  ```yaml
  ---
  trigger: always_on
  description: Brief summary of the rule constraint.
  ---
  ```

## 2. Invariants
- Provide rationale for every constraint.
- Keep rules concise, unambiguous, and focused on invariant enforcement.
