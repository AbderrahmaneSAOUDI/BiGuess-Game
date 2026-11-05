---
name: feature-development
description: Guided workflow for designing, scaffolding, implementing, and validating new features.
---

# Feature Development Runbook

Follow this standard procedure when building a new capability or service.

## 1. Architecture Alignment
- Identify the target layer according to `file-naming-and-structure.md`:
  - UI Component -> `c_*`
  - Screen/View -> `view_*`
  - Domain Model -> `mod_*`
  - Service/IO -> `srv_*`
  - Controller/State -> `vm_*`
- Ensure decoupling: do not mix IO operations inside UI widgets.

## 2. Implementation Steps
1. Scaffold models and contract interfaces first.
2. Implement backend/service integration with error handling.
3. Build the state management layer.
4. Construct presentation views using reusable atomic components.
5. Colocate unit tests and verify behavior against requirements.
