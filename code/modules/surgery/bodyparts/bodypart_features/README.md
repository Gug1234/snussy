# bodypart_features

## Purpose
Owns the `/datum/bodypart_feature` system: per-bodypart visual attachments (hair, facial hair, face detail, accessories, crests, underwear, legwear, chastity) that render as overlays on `/obj/item/bodypart` and, for some slots, spawn real worn items.

## Key files
- [_bodypart_feature.dm](_bodypart_feature.dm) — base `/datum/bodypart_feature`. Vars: `name`, `body_zone`, `accessory_type` (sprite_accessory path), `accessory_colors` (packed hex string), `feature_slot`. `add_bodypart_feature()` enforces slot uniqueness per bodypart. `get_bodypart_overlay(bodypart)` is the render entrypoint that returns the `mutable_appearance` composited onto the limb.
- [features.dm](features.dm) — concrete subtypes: hair (head + facial), face_detail, accessory, crest, underwear, legwear, chastity. Underwear / legwear / chastity are item-spawning slots: `set_accessory_type` does `qdel(old) + new(path)` to swap the real worn obj.

## Related subsystems
- `/datum/sprite_accessory` registry — accessory assets, icon states, and color key counts. See [code/modules/mob/dead/new_player/sprite_accessory/](../../../mob/dead/new_player/sprite_accessory/).
- `/datum/customizer_entry` — prefs-side savefile-persisted storage. See [code/modules/client/customizer/customizer_entry.dm](../../../client/customizer/customizer_entry.dm). Features are spawned from `customizer_entries` at character load via `apply_customizers_to_character()`.
- Render hook — `/obj/item/bodypart/get_limb_icon()` iterates `bodypart_features`. See [code/modules/surgery/bodyparts/_bodyparts.dm](../_bodyparts.dm) around L761-765.
- Current HTML editor — `print_customizers_page` + `handle_customizer_topic` in [code/modules/client/preferences_customizers.dm](../../../client/preferences_customizers.dm). Being replaced (see Planned rebuild).

## Data flow
Prefs `customizer_entries` (datum list, savefile-persisted) -> `apply_customizers_to_character()` at character spawn -> live `/datum/bodypart_feature` attached to bodypart -> `bodypart.get_limb_icon()` iterates features -> `feature.get_bodypart_overlay()` -> `sprite_accessory.get_appearance()` -> `mutable_appearance` composited onto the bodypart icon.

## Conventions / pitfalls
- **Slot uniqueness** is enforced in `add_bodypart_feature` — one feature per `(bodypart, feature_slot)` pair. The planned TGUI editor will drop this for hair / facial / face_detail / accessory / crest to enable composites.
- **No per-entry offset/transform today.** The `bodypart_overlays(standing)` hook exists but only hair uses it (for gradient child overlays). Planned editor adds per-entry `pixel_x` / `pixel_y` / `transform` vars wired through this hook.
- **`accessory_colors` is a packed hex string** (e.g. `"#aabbcc#112233"`), not a DM list. Preserve this format across any refactor; splitting/joining happens at sprite_accessory color-application time.
- **Item-spawning slots** (underwear / legwear / chastity) call `qdel + new` on `set_accessory_type`. Never fire this per-keystroke from the editor — commit on close / save only, or you will churn dozens of worn items.
- **Hair is special.** Its customizer_entry carries `hair_color`, `natural_gradient`, `natural_color`, `dye_gradient`, `dye_color` separately from `accessory_colors`. Hair gradients render as child overlays on the hair appearance, and in BYOND parent `standing.transform` does NOT propagate to children — any transform work must be applied per child.
- **Species gating.** `species.customizers` restricts which slots / accessory lists are valid for a given species. Editor UI must read from species, not a flat global list.

## Planned rebuild
Full context: [/memories/repo/bodypart_features.md](../../../../../memories/repo/bodypart_features.md).
Transform vetting policy (per-entry offsets, flag thresholds, admin review): [modular/code/datums/EXTREME_OFFSET_POLICY.md](../../../../../modular/code/datums/EXTREME_OFFSET_POLICY.md).
- Replace the HTML customizer menu with a TGUI editor modeled on the body markings editor.
- Add per-entry offset / transform and composite (stackable) entries on hair / facial / face_detail / accessory / crest.
- Sidecar JSON persistence is likely (mirrors body markings), pending architect decision — savefile per-entry ~64KB limit is the forcing function.
