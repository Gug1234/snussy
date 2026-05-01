/**
 * _defines.dm — Shared constants for the custom piercing / sticker system.
 *
 * This is Phase 1 scaffolding. Data model + composer + sidecar plumbing only.
 * The actual render-path hooks and full TGUI editor are delivered in later
 * phases so this commit can land without changing any existing behavior for
 * players who have not opted in.
 *
 * Storage lives on /datum/preferences (character-scoped, not item-scoped) so
 * that the custom look survives item swaps, drops, and respawns. Nothing
 * renders unless (a) the character has a slot config with enabled = TRUE AND
 * (b) the corresponding intimate accessory item is actually equipped on the
 * wearer at render time. See composer.dm for the gate.
 */

/// Absolute cap on total custom-piercing entries stored on a single character
/// across all slots. Keeps sidecar JSON bounded and prevents sprite-bomb
/// griefing. Per-slot soft cap is enforced separately.
#define CUSTOM_PIERCING_MAX_TOTAL_ENTRIES 64

/// Maximum number of sticker entries allowed inside a single slot config.
#define CUSTOM_PIERCING_MAX_PER_SLOT 12

/// Maximum character length for player-authored custom names / descriptions
/// on the two reserved custom-subtype slots. Must be sanitized aggressively
/// because these strings appear in examine text seen by other players.
#define CUSTOM_PIERCING_MAX_NAME_LENGTH 48
#define CUSTOM_PIERCING_MAX_DESC_LENGTH 256

/// Clamp bounds for custom-piercing x/y pixel offsets. Mirrors the taur
/// genital editor range so a shared TGUI panel can reuse the same math.
#define CUSTOM_PIERCING_OFFSET_MAX 64
#define CUSTOM_PIERCING_OFFSET_MIN -64

/// Per-direction field keys on a sticker entry's props list. Mirrors the shared
/// appearance-preview schema so the same editor UI + offset math can be reused.
/// Full key is "[dir_key][field_key]" e.g. "sx", "nturn", "ehide".
GLOBAL_LIST_INIT(custom_piercing_dir_keys, list(
	APPEARANCE_PREVIEW_DIR_KEY_S,
	APPEARANCE_PREVIEW_DIR_KEY_N,
	APPEARANCE_PREVIEW_DIR_KEY_E,
	APPEARANCE_PREVIEW_DIR_KEY_W,
))
GLOBAL_LIST_INIT(custom_piercing_field_keys, list(
	APPEARANCE_PREVIEW_PROP_X,
	APPEARANCE_PREVIEW_PROP_Y,
	APPEARANCE_PREVIEW_PROP_TURN,
	APPEARANCE_PREVIEW_PROP_FLIP,
	APPEARANCE_PREVIEW_PROP_ABOVE,
	APPEARANCE_PREVIEW_PROP_HIDE,
	APPEARANCE_PREVIEW_PROP_SHRINK,
))

/// Canonical list of wearer-side intimate slots the custom-piercing system
/// knows about. The string keys are stable — they are persisted in sidecar
/// JSON and referenced by the TGUI editor. Do NOT rename without a migration.
///
/// These map 1:1 to the singleton `intimate_*_piercing` / `intimate_*_insertable`
/// vars on /mob/living/carbon (see examine_hooks.dm for the var list). The
/// "pintle" and "chastity" slots are body-anchored rather than item-anchored
/// so stickers can be placed on the character's own pintle/chastity device
/// without requiring a dedicated piercing item in that slot.
GLOBAL_LIST_INIT(custom_piercing_slot_keys, list(
	"ear",
	"nose",
	"tongue",
	"breast",
	"belly",
	"genital",
	"rear",
	"pintle",
	"chastity",
	"insertable_genital",
	"insertable_rear",
	"custom_upper",
	"custom_lower",
))

/// Canonical slot groups used by the rebuilt editor UI. These are the only
/// groupings the TGUI should use when building the regular-slot tabs.
GLOBAL_LIST_INIT(custom_piercing_slot_groups, list(
	"head" = list("ear", "nose", "tongue"),
	"torso" = list("breast", "belly"),
	"genital" = list("genital", "insertable_genital", "pintle"),
	"rear" = list("rear", "insertable_rear"),
	"custom" = list("custom_upper", "custom_lower"),
))

/// Slots that participate in the standard intimate accessory editor surface.
/// Freeform sticker slots and chastity are intentionally excluded.
GLOBAL_LIST_INIT(custom_piercing_regular_slot_keys, list(
	"ear",
	"nose",
	"tongue",
	"breast",
	"belly",
	"genital",
	"rear",
	"pintle",
	"insertable_genital",
	"insertable_rear",
))

/// Render families used by the shared composer and preview pipeline.
/// The editor can use these to decide whether a slot is a legacy overlay,
/// post-render overlay, or freeform sticker stack.
GLOBAL_LIST_INIT(custom_piercing_slot_render_families, list(
	"ear" = "legacy_overlay",
	"nose" = "post_render",
	"tongue" = "post_render",
	"breast" = "legacy_overlay",
	"belly" = "post_render",
	"genital" = "legacy_overlay",
	"rear" = "post_render",
	"pintle" = "legacy_overlay",
	"chastity" = "legacy_overlay",
	"insertable_genital" = "post_render",
	"insertable_rear" = "legacy_overlay",
	"custom_upper" = "freeform",
	"custom_lower" = "freeform",
))

/// Human-readable slot labels for the editor UI. Keyed by the strings above.
/// For freeform slots the label is only used when the player hasn't yet set
/// a custom `display_name` on the slot; once they do, the display_name wins
/// both in the editor tabs and on examine.
GLOBAL_LIST_INIT(custom_piercing_slot_labels, list(
	"ear" = "Ears",
	"nose" = "Nose",
	"tongue" = "Tongue",
	"breast" = "Breasts",
	"belly" = "Navel",
	"genital" = "Genitals",
	"rear" = "Rear",
	"pintle" = "Pintle",
	"chastity" = "Chastity",
	"insertable_genital" = "Genital Insertable",
	"insertable_rear" = "Rear Insertable",
	"custom_upper" = "Upper Decoration",
	"custom_lower" = "Lower Decoration",
))

/// Shared manifest category assignment for each slot key.
///
/// Intimate-accessory slots stay in the intimate-accessory bucket, while the
/// freeform slots are treated as sticker atlas content.
GLOBAL_LIST_INIT(custom_piercing_slot_manifest_categories, list(
	"ear" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"nose" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"tongue" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"breast" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"belly" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"genital" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"rear" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"pintle" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"chastity" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"insertable_genital" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"insertable_rear" = APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	"custom_upper" = APPEARANCE_PREVIEW_CATEGORY_STICKER,
	"custom_lower" = APPEARANCE_PREVIEW_CATEGORY_STICKER,
))

/// Returns the shared appearance-preview category for a slot key, or null if
/// the slot is unknown to the frozen manifest contract.
/proc/custom_piercing_slot_manifest_category(slot_key)
	if(!istext(slot_key))
		return null
	return GLOB.custom_piercing_slot_manifest_categories[slot_key]

/// Slots that are NOT tied to any equipped intimate accessory item — their
/// stickers render unconditionally when the slot is enabled, regardless of
/// what the character is wearing. These are player-authored markings /
/// custom body features rather than "piercings on an item". Players can
/// rename each slot (slot-level display_name) and choose whether other
/// players see the slot on examine (slot-level hide_from_examine).
GLOBAL_LIST_INIT(custom_piercing_freeform_slots, list(
	"custom_upper",
	"custom_lower",
))

/// Slots rendered via the update_body_parts() post-pass on /mob/living/carbon/human
/// instead of through a legacy sprite_accessory adjust_appearance_list hook.
/// Two groups:
///   • Freeform slots (no equipped item required).
///   • Item-gated slots whose underlying intimate accessory does not define a
///     legacy sprite_accessory overlay (nose / belly / tongue / rear piercing
///     / insertable_genital). For these the equip check in the composer still
///     gates rendering; the post-pass just gives them a render channel.
/// Slots that already render through a sprite_accessory subtype (ear / breast
/// / genital / pintle / chastity / insertable_rear) are NOT included here —
/// they go through adjust_appearance_list so they stay aligned to the same
/// body-offset pipeline as their legacy overlay.
GLOBAL_LIST_INIT(custom_piercing_post_render_slots, list(
	"custom_upper",
	"custom_lower",
	"nose",
	"belly",
	"tongue",
	"rear",
	"insertable_genital",
))

/// Allowlist of body zones a freeform entry can pin itself to for the
/// "hide when covered" check. When empty/null the entry is always rendered.
/// When set to one of these keys the composer skips the entry's appearances
/// if `get_location_accessible(wearer, zone)` is false (i.e. the zone is
/// currently under clothing). Keyed by the raw BYOND body zone strings so
/// we can pass them straight to `get_location_accessible`.
GLOBAL_LIST_INIT(custom_piercing_entry_zones, list(
	"",
	BODY_ZONE_HEAD,
	BODY_ZONE_CHEST,
	BODY_ZONE_PRECISE_STOMACH,
	BODY_ZONE_PRECISE_GROIN,
	BODY_ZONE_PRECISE_MOUTH,
	BODY_ZONE_PRECISE_NOSE,
	BODY_ZONE_PRECISE_NECK,
	BODY_ZONE_L_ARM,
	BODY_ZONE_R_ARM,
	BODY_ZONE_L_LEG,
	BODY_ZONE_R_LEG,
))

/// Player-facing labels for the entry zone dropdown. Index-aligned with
/// `custom_piercing_entry_zones`.
GLOBAL_LIST_INIT(custom_piercing_entry_zone_labels, list(
	"" = "Always visible",
	BODY_ZONE_HEAD = "Head",
	BODY_ZONE_CHEST = "Chest",
	BODY_ZONE_PRECISE_STOMACH = "Stomach",
	BODY_ZONE_PRECISE_GROIN = "Groin",
	BODY_ZONE_PRECISE_MOUTH = "Mouth",
	BODY_ZONE_PRECISE_NOSE = "Nose",
	BODY_ZONE_PRECISE_NECK = "Neck",
	BODY_ZONE_L_ARM = "Left Arm",
	BODY_ZONE_R_ARM = "Right Arm",
	BODY_ZONE_L_LEG = "Left Leg",
	BODY_ZONE_R_LEG = "Right Leg",
))

/// Maps a slot key to the /mob/living/carbon var name that holds the equipped
/// intimate accessory item (or pintle organ slot) for that slot. The composer
/// reads this to decide whether the slot is currently populated — custom
/// stickers only render when the underlying item is present.
///
/// Values prefixed with "organ:" reference an organ slot constant instead of
/// an item var; see composer.dm for the resolution.
GLOBAL_LIST_INIT(custom_piercing_slot_equip_lookup, list(
	"ear" = "intimate_ear_piercing",
	"nose" = "intimate_nose_piercing",
	"tongue" = "intimate_mouth_piercing",
	"breast" = "intimate_breast_piercing",
	"belly" = "intimate_belly_piercing",
	"genital" = "intimate_genital_piercing",
	"rear" = "intimate_rear_piercing",
	"pintle" = "organ:[ORGAN_SLOT_PENIS]",
	"chastity" = "organ:[ORGAN_SLOT_VAGINA]",
	"insertable_genital" = "intimate_genital_insertable",
	"insertable_rear" = "intimate_rear_insertable",
))
