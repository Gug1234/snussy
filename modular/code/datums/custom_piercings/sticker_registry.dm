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

/// Global registry of all placeable sticker shapes. Keyed by `id`.
/// The list order is the order shown in the TGUI picker.
GLOBAL_LIST_INIT(custom_piercing_stickers, init_custom_piercing_sticker_registry())

/proc/init_custom_piercing_sticker_registry()
	var/list/registry = list()
	var/list/entries = list(
		// Studs.
		new /datum/piercing_sticker("stud", "Stud", "stud", TRUE, FALSE, list("ear", "nose", "tongue", "breast", "belly", "genital")),
		// Hoops (4-dir authored).
		new /datum/piercing_sticker("hoop_small", "Small Hoop", "hoop", FALSE, TRUE, list("ear", "nose", "tongue")),
		new /datum/piercing_sticker("hoop_large", "Large Hoop", "hoop", FALSE, TRUE, list("ear")),
		// Bars.
		new /datum/piercing_sticker("straightbar", "Straight Bar", "bar", FALSE, FALSE, list("ear", "tongue", "breast", "genital")),
		new /datum/piercing_sticker("barbell", "Barbell", "bar", TRUE, FALSE, list("ear", "tongue", "breast", "belly")),
		// Rings.
		new /datum/piercing_sticker("ring", "Ring", "ring", TRUE, FALSE, list("ear", "nose", "belly", "genital")),
		new /datum/piercing_sticker("vertical_ring", "Vertical Ring", "ring", FALSE, FALSE, list("nose", "tongue", "genital")),
		new /datum/piercing_sticker("thick_ring", "Thick Ring", "ring", FALSE, FALSE, list("genital", "breast")),
		new /datum/piercing_sticker("large_thick_ring", "Large Thick Ring", "ring", FALSE, FALSE, list("genital", "breast")),
		// Cockrings (4-dir authored).
		new /datum/piercing_sticker("cockring_small", "Cockring (Small)", "cockring", FALSE, TRUE, list("pintle")),
		new /datum/piercing_sticker("cockring_medium", "Cockring (Medium)", "cockring", FALSE, TRUE, list("pintle")),
		new /datum/piercing_sticker("cockring_large", "Cockring (Large)", "cockring", FALSE, TRUE, list("pintle")),
		// Plugs.
		new /datum/piercing_sticker("plug", "Plug", "plug", TRUE, FALSE, list("ear", "nose", "insertable_genital", "insertable_rear")),
		new /datum/piercing_sticker("heartplug", "Heart Plug", "plug", TRUE, FALSE, list("ear", "nose", "insertable_genital", "insertable_rear")),
		// Novelty.
		new /datum/piercing_sticker("cross", "Cross", "novelty", TRUE, FALSE, list("ear", "breast", "genital", "belly")),
		new /datum/piercing_sticker("bell", "Bell", "novelty", FALSE, FALSE, list("ear", "breast", "genital", "tongue")),
		new /datum/piercing_sticker("chain", "Chain", "novelty", FALSE, FALSE, list("breast", "belly", "genital")),
		new /datum/piercing_sticker("thin_chain", "Thin Chain", "novelty", FALSE, FALSE, list("breast", "belly", "genital")),
		// Bands (4-dir authored).
		new /datum/piercing_sticker("armband", "Arm Band", "band", FALSE, TRUE, list()),
		new /datum/piercing_sticker("legband", "Leg Band", "band", FALSE, TRUE, list()),
	)
	for(var/datum/piercing_sticker/S as anything in entries)
		registry[S.id] = S
	return registry

/// Returns the sticker datum for the given id, or null if unknown.
/proc/get_custom_piercing_sticker(sticker_id)
	if(!istext(sticker_id))
		return null
	return GLOB.custom_piercing_stickers[sticker_id]
