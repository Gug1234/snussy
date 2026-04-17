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
 *       "entries"         = list(       // ordered — back-to-front render
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
/// Mirrors default_taur_genital_props() semantics.
/proc/default_custom_piercing_props()
	var/list/props = list()
	for(var/dir_key in GLOB.custom_piercing_dir_keys)
		props["[dir_key]x"] = 0
		props["[dir_key]y"] = 0
		props["[dir_key]turn"] = 0
		props["[dir_key]flip"] = 0
		// Piercings render OVER the body by default, unlike most taur genitals.
		props["[dir_key]above"] = 1
		props["[dir_key]hide"] = 0
		props["[dir_key]shrink"] = 1.0
	return props

/// Sanitizes a per-direction prop list. Unknown keys are dropped; out-of-range
/// values are clamped. Defensively rebuilds from defaults if input is garbage.
/proc/sanitize_custom_piercing_props(list/props)
	var/list/out = default_custom_piercing_props()
	if(!islist(props))
		return out
	for(var/dir_key in GLOB.custom_piercing_dir_keys)
		for(var/field_key in GLOB.custom_piercing_field_keys)
			var/key = "[dir_key][field_key]"
			if(!(key in props))
				continue
			var/raw = props[key]
			switch(field_key)
				if("x", "y")
					out[key] = clamp(round(text2num_safe(raw, 0)), CUSTOM_PIERCING_OFFSET_MIN, CUSTOM_PIERCING_OFFSET_MAX)
				if("turn")
					var/t = round(text2num_safe(raw, 0))
					// Normalize into [0, 359].
					t = ((t % 360) + 360) % 360
					out[key] = t
				if("flip", "above", "hide")
					out[key] = (raw ? 1 : 0)
				if("shrink")
					out[key] = clamp(text2num_safe(raw, 1.0), 0.1, 4.0)
	return out

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
/proc/sanitize_custom_piercing_slot_config(list/cfg)
	var/list/out = list()
	out["enabled"] = 0
	out["suppress_legacy"] = 0
	out["display_name"] = null
	out["hide_from_examine"] = 0
	out["entries"] = list()
	if(!islist(cfg))
		return out
	out["enabled"] = cfg["enabled"] ? 1 : 0
	out["suppress_legacy"] = cfg["suppress_legacy"] ? 1 : 0
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
		var/list/cleaned_slot = sanitize_custom_piercing_slot_config(raw[slot_key])
		// Enforce global cap across slots.
		var/list/slot_entries = cleaned_slot["entries"]
		while(length(slot_entries) && total + length(slot_entries) > CUSTOM_PIERCING_MAX_TOTAL_ENTRIES)
			slot_entries.len--
		total += length(slot_entries)
		out[slot_key] = cleaned_slot
	return length(out) ? out : null
