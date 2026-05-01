/**
 * sticker_registry.dm — Piercing sticker type registry.
 *
 * Each /datum/piercing_sticker describes one visual shape from the
 * intimate_stickers.dmi icon set. The registry is the whitelist of shapes a
 * player is allowed to place as a custom piercing sticker — the TGUI editor
 * picker lists exactly these entries and nothing else. Do not let player
 * input reference arbitrary icon_states.
 *
 * No mechanical slot restrictions: any sticker may be placed on any slot.
 * Server is age-vetted + whitelist only; misuse is handled administratively.
 *
 * DMI convention (authored by content team):
 *   <id>_metal — greyscale metal mask, tinted at runtime by material color.
 *   <id>_gem   — greyscale gem mask, tinted at runtime by gem color. Optional;
 *                absence of this state signals has_gem = FALSE.
 *
 * The un-suffixed base state is NOT used by the renderer. Authors may keep
 * it in the DMI for visual reference while drawing, but the composer only
 * ever reads `<id>_metal` and `<id>_gem`.
 */

/// Path to the sticker icon set. Single source of truth for the composer and
/// the TGUI preview pipeline. Keep in lockstep with the asset on disk.
#define CUSTOM_PIERCING_STICKER_ICON 'modular/icons/obj/lewd/intimate_stickers.dmi'

/datum/piercing_sticker
	/// Unique key; must match the base icon_state (without `_metal`/`_gem`).
	var/id
	/// Player-facing display name.
	var/name
	/// Broad category for editor grouping: stud/hoop/bar/ring/plug/band/novelty/cockring.
	var/category
	/// If TRUE, the sticker has a `<id>_gem` state and the editor shows a
	/// gem-color picker. If FALSE, only the metal layer renders.
	var/has_gem = FALSE
	/// Soft hint list of slot keys the editor highlights as suggested anchors
	/// to nudge players toward sensible placements. Does NOT restrict placement
	/// — any sticker can be placed on any slot. Misuse is handled administratively.
	var/list/suggested_slots
	/// If TRUE, the source icon has 4 direction frames authored. Purely
	/// informational — the renderer handles 1-dir and 4-dir icons the same
	/// way (BYOND auto-returns the single frame for 1-dir icons).
	var/directional = FALSE

/datum/piercing_sticker/New(id, name, category, has_gem = FALSE, directional = FALSE, list/suggested_slots)
	src.id = id
	src.name = name
	src.category = category
	src.has_gem = has_gem
	src.directional = directional
	src.suggested_slots = suggested_slots || list()

/// Returns the manifest category used by sticker atlas generation.
/datum/piercing_sticker/proc/get_preview_manifest_category()
	return APPEARANCE_PREVIEW_CATEGORY_STICKER

/// Returns the canonical icon-state key for this sticker.
/datum/piercing_sticker/proc/get_preview_manifest_icon_state_key()
	return appearance_preview_manifest_icon_state_key(id)

/**
 * Returns the server-owned metal mask icon_state for this sticker.
 *
 * TGUI receives this value from DM metadata instead of deriving
 * `<id>_metal` locally. Keeping the suffix convention behind the registry
 * lets the content contract evolve without creating a second naming mirror in
 * the browser editor.
 */
/datum/piercing_sticker/proc/get_preview_manifest_metal_icon_state_key()
	if(!istext(id) || !length(id))
		return null
	return appearance_preview_manifest_icon_state_key("[id]_metal")

/**
 * Returns the server-owned gem mask icon_state for this sticker, or null for
 * stickers that do not author a gem layer.
 */
/datum/piercing_sticker/proc/get_preview_manifest_gem_icon_state_key()
	if(!has_gem || !istext(id) || !length(id))
		return null
	return appearance_preview_manifest_icon_state_key("[id]_gem")

/// Global registry of all placeable sticker shapes. Keyed by `id`.
/// The list order is the order shown in the TGUI picker.
GLOBAL_LIST_INIT(custom_piercing_stickers, init_custom_piercing_sticker_registry())

/proc/init_custom_piercing_sticker_registry()
	var/list/registry = list()
	var/list/entries = list(
		// All 20 stickers now author 4-direction metal+gem pairs on the DMI.
		// `has_gem` and `directional` remain on the datum so the drift
		// detector test (custom_piercings.test.ts) can catch a regression
		// back to 1-dir or no-gem art without rewriting the schema.
		// Studs.
		new /datum/piercing_sticker("stud", "Stud", "stud", TRUE, TRUE, list("ear", "nose", "tongue", "breast", "belly", "genital")),
		// Hoops.
		new /datum/piercing_sticker("hoop_small", "Small Hoop", "hoop", TRUE, TRUE, list("ear", "nose", "tongue")),
		new /datum/piercing_sticker("hoop_large", "Large Hoop", "hoop", TRUE, TRUE, list("ear")),
		// Bars.
		new /datum/piercing_sticker("straightbar", "Straight Bar", "bar", TRUE, TRUE, list("ear", "tongue", "breast", "genital")),
		new /datum/piercing_sticker("barbell", "Barbell", "bar", TRUE, TRUE, list("ear", "tongue", "breast", "belly")),
		// Rings.
		new /datum/piercing_sticker("ring", "Ring", "ring", TRUE, TRUE, list("ear", "nose", "belly", "genital")),
		new /datum/piercing_sticker("vertical_ring", "Vertical Ring", "ring", TRUE, TRUE, list("nose", "tongue", "genital")),
		new /datum/piercing_sticker("thick_ring", "Thick Ring", "ring", TRUE, TRUE, list("genital", "breast")),
		new /datum/piercing_sticker("large_thick_ring", "Large Thick Ring", "ring", TRUE, TRUE, list("genital", "breast")),
		// Cockrings.
		new /datum/piercing_sticker("cockring_small", "Cockring (Small)", "cockring", TRUE, TRUE, list("pintle")),
		new /datum/piercing_sticker("cockring_medium", "Cockring (Medium)", "cockring", TRUE, TRUE, list("pintle")),
		new /datum/piercing_sticker("cockring_large", "Cockring (Large)", "cockring", TRUE, TRUE, list("pintle")),
		// Plugs.
		new /datum/piercing_sticker("plug", "Plug", "plug", TRUE, TRUE, list("ear", "nose", "insertable_genital", "insertable_rear")),
		new /datum/piercing_sticker("heartplug", "Heart Plug", "plug", TRUE, TRUE, list("ear", "nose", "insertable_genital", "insertable_rear")),
		// Novelty.
		new /datum/piercing_sticker("cross", "Cross", "novelty", TRUE, TRUE, list("ear", "breast", "genital", "belly")),
		new /datum/piercing_sticker("bell", "Bell", "novelty", TRUE, TRUE, list("ear", "breast", "genital", "tongue")),
		new /datum/piercing_sticker("chain", "Chain", "novelty", TRUE, TRUE, list("breast", "belly", "genital")),
		new /datum/piercing_sticker("thin_chain", "Thin Chain", "novelty", TRUE, TRUE, list("breast", "belly", "genital")),
		// Bands.
		new /datum/piercing_sticker("armband", "Arm Band", "band", TRUE, TRUE, list()),
		new /datum/piercing_sticker("legband", "Leg Band", "band", TRUE, TRUE, list()),
	)
	for(var/datum/piercing_sticker/S as anything in entries)
		registry[S.id] = S
	return registry

/// Returns the sticker datum for the given id, or null if unknown.
/proc/get_custom_piercing_sticker(sticker_id)
	if(!istext(sticker_id))
		return null
	return GLOB.custom_piercing_stickers[sticker_id]
