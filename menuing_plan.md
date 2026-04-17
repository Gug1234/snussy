# Menuing Repair Plan

Intro:
- State that this is a plan-only note for the menuing repair work.
- Say the goal is to fix the menuing contract, preview behavior, layout density, and drag performance without implementation details yet.

## Current Surfaces
- Lobby intimate preferences: `IntimatePrefsMenu.tsx` and the corresponding lobby menu DM path.
- Custom piercings: `CustomPiercingEditor.tsx`, the custom piercing DM datum, and the custom piercing preference persistence layer.
- Body markings: `BodyMarkingEditor.tsx` and the body marking preference / sidecar paths.
- Feature customizer: `FeatureCustomizerEditor.tsx` and the feature customizer DM paths.
- Taur reference: `TaurGenitalOffsetEditor.tsx` as the live-preview / ghost-drag pattern to copy.

## Problem Clusters
- Contract drift between lobby prefs and custom piercings.
- Layout density mismatch across non-taur editors.
- Oversized icon/button tiles and broken rotation labels / button wiring.
- Preview windows that are too small to read comfortably.
- Drag lag on taur-style offset editors when dragging is not client-side ghosted.

## Compatibility / Data Contract
- Custom piercings owns schema, slot identity, and persistence structure.
- Intimate prefs should only store user intent against stable slot keys through a thin adapter.
- Unknown or missing slots must load safely.
- No direct coupling to internal slot shapes in the lobby UI.
- Any rename or split needs a translation map; do not repurpose slot keys without migration.

## Likely Root Causes
- Different screens are reading different sources of truth for the same accessory state.
- Preview refresh is not tied to the correct commit boundary.
- Button and preview sizing are hardcoded per screen instead of following one density contract.
- Rotation labels are using the wrong glyph or a broken string source.
- Drag paths are doing too much server work instead of using a client-side ghost render.

## Phased Plan
1. Freeze the current contract and inventory the active menuing surfaces.
2. Repair the intimate prefs to custom piercing handoff through the stable adapter.
3. Normalize layout, preview sizing, and icon button density across the non-taur editors.
4. Bring preview refresh behavior in line with TaurGenitalOffsetEditor.
5. Move drag-heavy interactions to a client-side ghost model with one commit on release.
6. Validate each phase with focused UI smoke checks and narrow compile / TGUI build checks later.

## Validation Checklist
- Confirm the lobby selection and the piercing editor land on the same slot state.
- Confirm saved changes update the visible preview without reopening the editor.
- Confirm accessory option buttons are small square tiles and the icons are visible.
- Confirm rotation labels are readable and button clicks actually change state.
- Confirm taur-style dragging stays responsive and does not spam server work.

## Performance Risks
- Server-side preview regeneration on pointer move.
- Excessive layout work from oversized buttons and icons.
- Preview refreshes firing on no-op changes.
- Any future drag surface that does not use ghost-state locally.

## Open Questions
- Should all editors share a common preview component, or should each screen keep its own layout while following one contract?
Answer: common preview component is ideal for consistency and maintenance, but may be a bigger lift. If the shared component can be built behind an adapter that matches the existing screen contracts, it should be possible to swap in the new preview without a big refactor of each screen's layout. The adapter would also allow for incremental improvements to the preview behavior without changing the screen contracts again. The shared component should be flexible enough to support the different layout needs of each screen, but the core logic for rendering the preview and handling updates should be centralized. Since TaurGenitalOffsetEditor already has a good preview pattern, it can serve as the basis for the shared component, and the other screens can be adapted to use it with minimal changes to their existing layout and state management.
- Should preview updates happen on every mutation or only on commit / save for each editor?
 Answer: for simplicity and consistency with the existing taur editor, update on every mutation but optimize the refresh to be fast and no-op when nothing changed. Keep the preview client side and only send the committed state to the server for rendering.
- Which legacy menu paths remain during transition?
The content is all in flight and only exists at present on this local repository, so there is no live server contract to maintain yet. The plan is to migrate the lobby intimate prefs and custom piercing editor first, since they are the most closely coupled and have the most contract drift. The body marking editor and feature customizer can be migrated in later phases, and the taur reference can be used as a guide for the new pattern. During the transition, the old paths can be left in place but hidden behind feature flags or simply not linked from the UI until they are ready to be removed.
- Are any schema migrations required, or is a compatibility adapter enough?
A compatibility adapter should be sufficient for the intimate prefs to custom piercing handoff, as long as the adapter can translate between the lobby's stable slot keys and the custom piercing schema. For any new fields or changes in the custom piercing datum, the adapter can provide default values or handle missing data gracefully. If there are any significant changes to the underlying data structure that cannot be handled with an adapter, then a schema migration may be necessary, but the goal should be to avoid that if possible to minimize disruption.
