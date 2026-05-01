/**
 * entry.dm — Data model for a single player-placed piercing sticker and the
 * per-slot container that holds them.
 *
 * Serialization contract (to/from sidecar JSON):
 *
 *   custom_piercings = list(
 *     "<slot_key>" = list(
 *       "enabled"         = 0|1,        // bool, gates whole slot
 *       "suppress_legacy" = 0|1,        // bool, hides legacy overlay
 *       "equipped_typepath" = null or "/obj/item/...", // base accessory
 *       "slot_props"      = list(...),  // per-dir transform block for the slot
 *       "entries"         = list(       // ordered sticker stack for freeform
 *         list(
 *           "sticker"       = "<id>",   // key from GLOB.custom_piercing_stickers
 *           "metal_color"   = "#RRGGBB",
 *           "gem_color"     = "#RRGGBB" or null,
 *           "props"         = list(...),  // per-dir schema (see _defines.dm)
 *           "custom_name"   = null or "text",
 *           "custom_desc"   = null or "text",
 *           "hide_when_covered" = 0|1,
 *         ),
 *         ...
 *       ),
 *     ),
 *     ...
 *   )
 *
 * All fields are sanitized on load; anything unrecognized is dropped.
 */

/// Default metal color (matches existing intimate accessory default).
#define CUSTOM_PIERCING_DEFAULT_METAL_COLOR "#9BADB7"
/// Default gem color (matches existing intimate accessory default).
#define CUSTOM_PIERCING_DEFAULT_GEM_COLOR "#55D6FF"

/// Returns a fresh per-direction prop list with sane defaults.
/// Mirrors default_taur_genital_props() semantics and is shared by both slot-
/// level transforms and freeform sticker entries.
/proc/default_custom_piercing_props()
	var/static/list/default_custom_piercing_props_template = list(
		"sx" = 0,
		"sy" = 0,
		"sturn" = 0,
		"sflip" = 0,
		"sabove" = 1,
		"shide" = 0,
		"sshrink" = 1.0,
		"nx" = 0,
		"ny" = 0,
		"nturn" = 0,
		"nflip" = 0,
		"nabove" = 1,
		"nhide" = 0,
		"nshrink" = 1.0,
		"ex" = 0,
		"ey" = 0,
		"eturn" = 0,
		"eflip" = 0,
		"eabove" = 1,
		"ehide" = 0,
		"eshrink" = 1.0,
		"wx" = 0,
		"wy" = 0,
		"wturn" = 0,
		"wflip" = 0,
		"wabove" = 1,
		"whide" = 0,
		"wshrink" = 1.0,
	)
	return default_custom_piercing_props_template.Copy()

/// Slot-level directional transform block. Kept as an explicit alias so the
/// rebuilt UI can talk about regular-slot offsets without entry terminology.
/proc/default_custom_piercing_slot_props()
	return default_custom_piercing_props()

/// Sanitizes a slot-level per-direction transform block.
/proc/sanitize_custom_piercing_slot_props(list/props)
	return sanitize_custom_piercing_props(props)

/// Sanitizes a per-direction prop list. Unknown keys are dropped; out-of-range
/// values are clamped. Defensively rebuilds from defaults if input is garbage.
/proc/sanitize_custom_piercing_props(list/props)
	var/list/out = default_custom_piercing_props()
	if(!islist(props))
		return out
	_sanitize_custom_piercing_dir_props(out, props, APPEARANCE_PREVIEW_DIR_KEY_S)
	_sanitize_custom_piercing_dir_props(out, props, APPEARANCE_PREVIEW_DIR_KEY_N)
	_sanitize_custom_piercing_dir_props(out, props, APPEARANCE_PREVIEW_DIR_KEY_E)
	_sanitize_custom_piercing_dir_props(out, props, APPEARANCE_PREVIEW_DIR_KEY_W)
	return out

/proc/_sanitize_custom_piercing_dir_props(list/out, list/props, dir_key)
	var/key = "[dir_key]x"
	if(key in props)
		out[key] = clamp(round(text2num_safe(props[key], 0)), CUSTOM_PIERCING_OFFSET_MIN, CUSTOM_PIERCING_OFFSET_MAX)

	key = "[dir_key]y"
	if(key in props)
		out[key] = clamp(round(text2num_safe(props[key], 0)), CUSTOM_PIERCING_OFFSET_MIN, CUSTOM_PIERCING_OFFSET_MAX)

	key = "[dir_key]turn"
	if(key in props)
		var/t = round(text2num_safe(props[key], 0))
		t = ((t % 360) + 360) % 360
		out[key] = t

	key = "[dir_key]flip"
	if(key in props)
		out[key] = props[key] ? 1 : 0

	key = "[dir_key]above"
	if(key in props)
		out[key] = props[key] ? 1 : 0

	key = "[dir_key]hide"
	if(key in props)
		out[key] = props[key] ? 1 : 0

	key = "[dir_key]shrink"
	if(key in props)
		out[key] = clamp(text2num_safe(props[key], 1.0), 0.1, 4.0)

/// Sanitizes a single custom piercing entry (associative list). Returns null
/// if the entry is unsalvageable (e.g. unknown sticker id).
/proc/sanitize_custom_piercing_entry(list/entry)
	if(!islist(entry))
		return null
	var/sticker_id = entry["sticker"]
	if(!istext(sticker_id))
		return null
	var/datum/piercing_sticker/sticker = get_custom_piercing_sticker(sticker_id)
	if(!sticker)
		return null

	var/list/out = list()
	out["sticker"] = sticker.id
	out["metal_color"] = sanitize_hexcolor(entry["metal_color"], 6, TRUE, CUSTOM_PIERCING_DEFAULT_METAL_COLOR)
	if(sticker.has_gem)
		out["gem_color"] = sanitize_hexcolor(entry["gem_color"], 6, TRUE, CUSTOM_PIERCING_DEFAULT_GEM_COLOR)
	else
		out["gem_color"] = null
	out["props"] = sanitize_custom_piercing_props(entry["props"])
	out["hide_when_covered"] = entry["hide_when_covered"] ? 1 : 0

	// Body zone the entry pins to for the clothing-visibility check. Empty
	// string = always visible. Anything not in the allowlist is coerced to
	// "" so a tampered sidecar can't request a weird zone.
	var/raw_zone = entry["zone"]
	if(istext(raw_zone) && (raw_zone in GLOB.custom_piercing_entry_zones))
		out["zone"] = raw_zone
	else
		out["zone"] = ""

	// Player-authored name/desc on the two reserved custom subtype slots.
	// Strip HTML before truncation so we never emit pre-escaped entities.
	var/raw_name = entry["custom_name"]
	if(istext(raw_name) && length(raw_name))
		var/cleaned = strip_html_simple(sanitize_simple(html_decode(copytext(raw_name, 1, CUSTOM_PIERCING_MAX_NAME_LENGTH + 1))))
		out["custom_name"] = length(cleaned) ? cleaned : null
	else
		out["custom_name"] = null

	var/raw_desc = entry["custom_desc"]
	if(istext(raw_desc) && length(raw_desc))
		var/cleaned = strip_html_simple(sanitize_simple(html_decode(copytext(raw_desc, 1, CUSTOM_PIERCING_MAX_DESC_LENGTH + 1))))
		out["custom_desc"] = length(cleaned) ? cleaned : null
	else
		out["custom_desc"] = null

	return out

/// Sanitizes one slot's config block.
/proc/sanitize_custom_piercing_slot_config(slot_key, list/cfg)
	var/list/out = list()
	out["enabled"] = (slot_key in GLOB.custom_piercing_freeform_slots) ? 1 : 0
	out["suppress_legacy"] = 0
	out["equipped_typepath"] = null
	out["typepath"] = null
	out["slot_props"] = default_custom_piercing_slot_props()
	out["display_name"] = null
	out["hide_from_examine"] = 0
	out["entries"] = list()
	if(!islist(cfg))
		out["props"] = out["slot_props"]
		return out
	out["enabled"] = cfg["enabled"] ? 1 : 0
	out["suppress_legacy"] = cfg["suppress_legacy"] ? 1 : 0
	var/raw_equipped = cfg["equipped_typepath"]
	if(!istext(raw_equipped) && !ispath(raw_equipped, /obj/item/intimate_accessory))
		raw_equipped = cfg["typepath"]
	if(ispath(raw_equipped, /obj/item/intimate_accessory))
		out["equipped_typepath"] = "[raw_equipped]"
		out["enabled"] = 1
	else if(istext(raw_equipped) && length(raw_equipped))
		var/path = text2path(raw_equipped)
		if(ispath(path, /obj/item/intimate_accessory))
			out["equipped_typepath"] = "[path]"
			out["enabled"] = 1
	out["typepath"] = out["equipped_typepath"]
	var/list/raw_slot_props = cfg["slot_props"]
	if(!islist(raw_slot_props))
		raw_slot_props = cfg["props"]
	if(islist(raw_slot_props))
		out["slot_props"] = sanitize_custom_piercing_slot_props(raw_slot_props)
	out["props"] = out["slot_props"]
	out["hide_from_examine"] = cfg["hide_from_examine"] ? 1 : 0
	// Slot-level player-authored label. Used for freeform slots in both the
	// editor tabs and the examine hook. Sanitized identically to entry names.
	var/raw_display = cfg["display_name"]
	if(istext(raw_display) && length(raw_display))
		var/cleaned_display = strip_html_simple(sanitize_simple(html_decode(copytext(raw_display, 1, CUSTOM_PIERCING_MAX_NAME_LENGTH + 1))))
		out["display_name"] = length(cleaned_display) ? cleaned_display : null
	var/list/raw_entries = cfg["entries"]
	if(!islist(raw_entries))
		return out
	for(var/list/raw_entry in raw_entries)
		var/list/cleaned = sanitize_custom_piercing_entry(raw_entry)
		if(!cleaned)
			continue
		out["entries"] += list(cleaned)
		if(length(out["entries"]) >= CUSTOM_PIERCING_MAX_PER_SLOT)
			break
	return out

/// Sanitizes the whole custom_piercings container. Drops unknown slot keys,
/// enforces global entry cap, returns null if nothing valid survives.
/proc/sanitize_custom_piercings(list/raw)
	if(!islist(raw))
		return null
	var/list/out = list()
	var/total = 0
	for(var/slot_key in raw)
		if(!(slot_key in GLOB.custom_piercing_slot_keys))
			continue
		var/list/cleaned_slot = sanitize_custom_piercing_slot_config(slot_key, raw[slot_key])
		// Enforce global cap across slots.
		var/list/slot_entries = cleaned_slot["entries"]
		while(length(slot_entries) && total + length(slot_entries) > CUSTOM_PIERCING_MAX_TOTAL_ENTRIES)
			slot_entries.len--
		total += length(slot_entries)
		out[slot_key] = cleaned_slot
	return length(out) ? out : null
