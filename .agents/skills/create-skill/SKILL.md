---
name: create-skill
description: Standardized guide to authoring procedural playbooks and workflows in .agents/skills/.
---

# Create Skill Runbook

## 1. Directory Structure
- Each skill is a directory under `.agents/skills/<skill-name>/` containing a `SKILL.md`.
- Include standard YAML frontmatter:
  ```yaml
  ---
  name: <skill-name>
  description: Clear description of when and why to activate this skill.
  ---
  ```

## 2. Best Practices
- Focus on procedural, actionable workflows.
- Provide copy-pasteable CLI commands and concrete examples.
