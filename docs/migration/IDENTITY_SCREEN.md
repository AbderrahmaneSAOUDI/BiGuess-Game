# Identity screen (T16)

Product/UX sign-off received in the T16 conversation on 2026-11-06:
**“Immediate reveal after Start (recommended)”**. The approved proposal retains
the existing theme and Card artwork, uses a roughly 250 ms entrance, skips motion
with reduced motion enabled, removes the countdown, always displays the identity
name after reveal, and makes image/name taps harmless.

Configured games display `GameSession.assignedCard` through `IdentityCard`.
The name comes from the frozen Card metadata, including Unicode, rather than the
image filename or private storage reference. The existing `AnimatedCharacterCard`
renders the image through `contentImageLoaderProvider`, with the T11 bounded local
image loader and cache. Selection and image display require no remote request.
The isolated legacy reveal path remains available during migration.

The outward-facing name has no hide toggle. Image loading has an accessible
placeholder; an image failure retains both the readable name and a readable
error. The name wraps and the Card scrolls when necessary. The existing portrait
orientation policy is unchanged; compact landscape constraints and large text
also remain usable without replacing the assigned Card. Round controls have a
separate bounded scroll area so they cannot overflow the identity region.

Image and name taps neither redraw nor hide the identity. Round progression uses
the explicit action, whose stale-callback guard prevents duplicate dispatch in a
single frame. Session settings retain appearance controls and omit legacy
countdown, algorithm and name-hint settings. Reduced motion displays the image
without a flip or shimmer; ordinary identity motion settles within 250 ms.

Focused verification:

```bash
flutter test test/widget/identity_card_test.dart test/widget/session_identity_screen_test.dart
```

These tests cover Start-to-identity wiring, distinct Cards sharing an image,
canonical names, harmless taps, duplicate action dispatch, session settings,
loading, missing images, private fixture pixels, orientation, large text,
semantics and reduced motion. Completion and replay behavior belong to T17.
