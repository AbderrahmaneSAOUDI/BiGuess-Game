---
trigger: always_on
description: Flutter lifecycle, ownership, layout, and behavior preservation.
---

# Flutter quality

- Preserve existing behavior, public interfaces, comments, and local style while making the requested change; unexplained cleanup obscures regressions.
- Use `const` where valid and extract complex subtrees into widgets so rebuild boundaries remain useful. Keep business logic in its provider/use case rather than widget helper methods.
- After `await`, check the relevant `mounted` or `context.mounted` before `setState`, navigation, or UI context use; disposal can happen during the gap.
- Dispose resources you own: animation/text/scroll controllers, focus nodes, subscriptions, and timers. Use Riverpod `ref.onDispose` for provider-owned resources.
- Bound scroll/layout constraints and check compact screens and long labels; do not place an unbounded `Expanded` in a scrollable.
- Preserve actionable errors and cancellation behavior at service boundaries. Do not swallow failed validation or turn network failures into gameplay requirements.
- Add tests for changed behavior at its owner. For repeating animations use bounded pumps; see [test map](../sidecars/test-map.md).
