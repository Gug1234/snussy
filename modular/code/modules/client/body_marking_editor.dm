/**
 * body_marking_editor.dm — Server-side TGUI body marking editor datum.
 *
 * Phase 3 scaffolding: pairs with the sidecar JSON persistence in
 * preferences_body_markings_sidecar.dm. The TSX frontend
 * ("BodyMarkingEditor") is not shipped in this phase; ui_interact() still
 * opens the window because lobby players need the singleton/update wiring
 * validated, but the interface resources themselves land in Phase 4.
 *
 * Shape (matches preferences_body_markings.dm normalize_body_markings):
 *   body_markings[zone][name] = list(
 *     "color"=hex, "pixel_x"=int, "pixel_y"=int,
 *     "flip_x"=0|1, "flip_y"=0|1, "rotation"=0|90|180|270, "scale"=1|2,
 *   )
 *
 * Mutations set `dirty = TRUE`. Autosave to the sidecar fires on ui_close
 * (and on Destroy as a safety net).
 */

#define BODY_MARKING_EDITOR_MAX_ACTS_PER_SECOND 30
#define BODY_MARKING_EDITOR_RATE_WINDOW_DS 10
#define BODY_MARKING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS 300

/// Singleton: at most one body marking editor per client. Repeat opens
/// refocus the existing window rather than spawning duplicates.
/client/var/datum/body_marking_editor/body_marking_editor_instance

/datum/body_marking_editor
	/// Client that opened this editor. All prefs reads go through owner.prefs.
	var/client/owner
	/// TRUE when in-memory state has been mutated since the last sidecar write.
	var/dirty = FALSE
	/// Currently focused zone tab. Defaults to the first entry in GLOB.marking_zones.
	var/active_zone
	/// Shared ui_act() flood limiter.
	var/datum/ui_act_rate_limiter/rate_limiter

/datum/body_marking_editor/New(client/C)
	if(!C)
		qdel(src)
		return
	owner = C
	active_zone = GLOB.marking_zones[1]
	rate_limiter = new(
		"Body marking editor",
		BODY_MARKING_EDITOR_MAX_ACTS_PER_SECOND,
		BODY_MARKING_EDITOR_RATE_WINDOW_DS,
		BODY_MARKING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS,
	)

/datum/body_marking_editor/Destroy()
	if(dirty)
		_persist()
		dirty = FALSE
	if(owner?.body_marking_editor_instance == src)
		owner.body_marking_editor_instance = null
	owner = null
	QDEL_NULL(rate_limiter)
	return ..()

/datum/body_marking_editor/ui_state(mob/user)
	return GLOB.always_state

/datum/body_marking_editor/ui_close(mob/user)
	if(dirty)
		_persist()
		dirty = FALSE
	qdel(src)

/datum/body_marking_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BodyMarkingEditor", "Body Markings", 900, 720)
		// Match sibling lobby-capable editors: pin state on creation as well
		// as via ui_state() so status resolution from /mob/dead/new_player
		// is unambiguous.
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/body_marking_editor/ui_data(mob/user)
	var/list/data = list()
	var/datum/preferences/P = owner?.prefs

	data["active_zone"] = active_zone
	data["max_per_zone"] = MAXIMUM_MARKINGS_PER_LIMB
	data["offset_min"] = BODY_MARKING_OFFSET_MIN
	data["offset_max"] = BODY_MARKING_OFFSET_MAX

	var/list/zones_out = list()
	for(var/zone in GLOB.marking_zones)
		var/list/zone_entries = list()
		var/list/zone_map = P?.body_markings?[zone]
		if(islist(zone_map))
			for(var/name in zone_map)
				var/entry = zone_map[name]
				var/list/L = islist(entry) ? entry : body_marking_entry_defaults(entry)
				zone_entries += list(list(
					"name" = name,
					"color" = L["color"],
					"pixel_x" = L["pixel_x"],
					"pixel_y" = L["pixel_y"],
					"flip_x" = L["flip_x"] ? 1 : 0,
					"flip_y" = L["flip_y"] ? 1 : 0,
					"rotation" = L["rotation"],
					"scale" = L["scale"],
				))
		zones_out += list(list(
			"id" = zone,
			"label" = _zone_label(zone),
			"entries" = zone_entries,
		))
	data["zones"] = zones_out

	var/list/available = list()
	for(var/mname in GLOB.body_markings)
		var/datum/body_marking/BM = GLOB.body_markings[mname]
		if(!BM)
			continue
		available += list(list(
			"name" = BM.name,
			"key" = "[BM.type]",
			"icon" = "[BM.icon]",
			"icon_state" = BM.icon_state,
			"affected_bodyparts" = BM.affected_bodyparts,
			"default_color" = P ? BM.get_default_color(P.features, P.pref_species) : BM.default_color,
		))
	data["available_markings"] = available

	var/list/sets_out = list()
	for(var/sname in GLOB.body_marking_sets)
		var/datum/body_marking_set/BMS = GLOB.body_marking_sets[sname]
		if(!BMS)
			continue
		sets_out += list(list(
			"name" = BMS.name,
			"key" = "[BMS.type]",
		))
	data["sets"] = sets_out

	return data

/datum/body_marking_editor/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!owner || !owner.prefs)
		return FALSE
	if(rate_limiter?.check_blocked(usr))
		return FALSE

	. = _dispatch_ui_act(action, params)
	// Refresh the lobby mannequin preview whenever the player actually
	// mutates appearance so rotation/color/offset/etc changes are visible
	// immediately. Navigation-only actions (tab switch, window close) skip
	// the (expensive) rebuild. Mirrors the taur genital offset editor.
	if(. && owner?.prefs && !(action in list("select_zone", "close")))
		owner.prefs.update_preview_icon()

/// Original ui_act switch body. Split off so the public ui_act wrapper can
/// refresh the lobby preview after successful mutations without rewriting
/// every branch.
/datum/body_marking_editor/proc/_dispatch_ui_act(action, list/params)
	var/datum/preferences/P = owner.prefs
	if(!islist(P.body_markings))
		P.body_markings = list()

	switch(action)
		if("select_zone")
			var/zone = params["zone"]
			if(!(zone in GLOB.marking_zones))
				return FALSE
			active_zone = zone
			return TRUE

		if("add_marking")
			var/zone = params["zone"]
			var/name = params["name"]
			if(!(zone in GLOB.marking_zones))
				return FALSE
			var/list/per_limb = GLOB.body_markings_per_limb[zone]
			if(!islist(per_limb) || !(name in per_limb))
				return FALSE
			var/datum/body_marking/BM = GLOB.body_markings[name]
			if(!BM)
				return FALSE
			var/list/zone_map = P.body_markings[zone]
			if(!islist(zone_map))
				zone_map = list()
				P.body_markings[zone] = zone_map
			if(length(zone_map) >= MAXIMUM_MARKINGS_PER_LIMB)
				return FALSE
			if(name in zone_map)
				return FALSE
			zone_map[name] = body_marking_entry_defaults(BM.get_default_color(P.features, P.pref_species))
			dirty = TRUE
			return TRUE

		if("remove_entry")
			var/zone = params["zone"]
			var/name = params["name"]
			var/list/zone_map = P.body_markings[zone]
			if(!islist(zone_map) || !(name in zone_map))
				return FALSE
			zone_map -= name
			if(!length(zone_map))
				P.body_markings -= zone
			dirty = TRUE
			return TRUE

		if("reorder")
			var/zone = params["zone"]
			var/name = params["name"]
			var/direction = params["direction"]
			var/list/zone_map = P.body_markings[zone]
			if(!islist(zone_map) || !(name in zone_map))
				return FALSE
			var/cur_idx = LAZYFIND(zone_map, name)
			if(!cur_idx)
				return FALSE
			var/new_idx
			switch(direction)
				if("up")
					new_idx = cur_idx - 1
				if("down")
					new_idx = cur_idx + 1
				else
					return FALSE
			if(new_idx < 1 || new_idx > length(zone_map))
				return FALSE
			var/content = zone_map[name]
			zone_map -= name
			zone_map.Insert(new_idx, name)
			zone_map[name] = content
			dirty = TRUE
			return TRUE

		if("set_color")
			var/zone = params["zone"]
			var/name = params["name"]
			var/list/entry = _entry_at(P, zone, name)
			if(!entry)
				return FALSE
			var/raw_color = params["color"]
			if(!istext(raw_color))
				return FALSE
			// Strip a leading '#' so sanitize_hexcolor sees the raw 6-hex string.
			if(length(raw_color) && copytext(raw_color, 1, 2) == "#")
				raw_color = copytext(raw_color, 2)
			var/sanitized = sanitize_hexcolor(raw_color, 6, FALSE, null)
			if(!sanitized)
				return FALSE
			entry["color"] = sanitized
			dirty = TRUE
			return TRUE

		if("nudge")
			var/zone = params["zone"]
			var/name = params["name"]
			var/list/entry = _entry_at(P, zone, name)
			if(!entry)
				return FALSE
			var/dx = text2num(params["dx"]) || 0
			var/dy = text2num(params["dy"]) || 0
			entry["pixel_x"] = clamp(text2num(entry["pixel_x"]) + dx, BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX)
			entry["pixel_y"] = clamp(text2num(entry["pixel_y"]) + dy, BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX)
			dirty = TRUE
			return TRUE

		if("set_offset")
			var/zone = params["zone"]
			var/name = params["name"]
			var/list/entry = _entry_at(P, zone, name)
			if(!entry)
				return FALSE
			var/px = text2num(params["pixel_x"])
			var/py = text2num(params["pixel_y"])
			if(isnum(px))
				entry["pixel_x"] = clamp(px, BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX)
			if(isnum(py))
				entry["pixel_y"] = clamp(py, BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX)
			dirty = TRUE
			return TRUE

		if("set_transform")
			var/zone = params["zone"]
			var/name = params["name"]
			var/list/entry = _entry_at(P, zone, name)
			if(!entry)
				return FALSE
			var/rotation = text2num(params["rotation"])
			var/scale = text2num(params["scale"])
			if(!(rotation in list(0, 90, 180, 270)))
				return FALSE
			if(!(scale in list(1, 2)))
				return FALSE
			entry["rotation"] = rotation
			entry["scale"] = scale
			entry["flip_x"] = params["flip_x"] ? 1 : 0
			entry["flip_y"] = params["flip_y"] ? 1 : 0
			dirty = TRUE
			return TRUE

		if("apply_set")
			var/set_name = params["set"]
			var/datum/body_marking_set/BMS = GLOB.body_marking_sets[set_name]
			if(!BMS)
				return FALSE
			P.body_markings = assemble_body_markings_from_set(BMS, P.features, P.pref_species)
			P.normalize_body_markings()
			dirty = TRUE
			return TRUE

		if("reset_zone")
			var/zone = params["zone"]
			if(!(zone in GLOB.marking_zones))
				return FALSE
			if(zone in P.body_markings)
				P.body_markings -= zone
				dirty = TRUE
			return TRUE

		if("reset_all")
			P.body_markings = list()
			dirty = TRUE
			return TRUE

		if("save")
			if(dirty)
				_persist()
				dirty = FALSE
			return TRUE

		if("close")
			SStgui.close_uis(src)
			return TRUE

	return FALSE

/// Zone-id → display label for the TSX tab strip. Matches the labels from
/// the legacy print_body_markings_page.
/datum/body_marking_editor/proc/_zone_label(zone)
	switch(zone)
		if(BODY_ZONE_HEAD)
			return "Head"
		if(BODY_ZONE_CHEST)
			return "Chest"
		if(BODY_ZONE_L_ARM)
			return "Left Arm"
		if(BODY_ZONE_R_ARM)
			return "Right Arm"
		if(BODY_ZONE_L_LEG)
			return "Left Leg"
		if(BODY_ZONE_R_LEG)
			return "Right Leg"
		if(BODY_ZONE_PRECISE_L_HAND)
			return "Left Hand"
		if(BODY_ZONE_PRECISE_R_HAND)
			return "Right Hand"
	return zone

/// Resolves a (zone, name) pair to the mutable dict entry, upgrading a
/// legacy flat-hex entry in-place. Returns null when either lookup misses.
/datum/body_marking_editor/proc/_entry_at(datum/preferences/P, zone, name)
	if(!P || !islist(P.body_markings))
		return null
	var/list/zone_map = P.body_markings[zone]
	if(!islist(zone_map) || !(name in zone_map))
		return null
	var/entry = zone_map[name]
	if(!islist(entry))
		entry = body_marking_entry_defaults(entry)
		zone_map[name] = entry
	return entry

/// Flushes current `body_markings` to the sidecar JSON. Called on explicit
/// "save" ui_act and on window close / Destroy.
/datum/body_marking_editor/proc/_persist()
	if(!owner)
		return
	save_body_markings_sidecar(owner, owner.prefs?.default_slot)
	if(owner.prefs)
		owner.prefs.body_markings_v = 2

/// Entry point used by the legacy prefs UI. Creates the singleton if needed
/// and opens (or refocuses) the TGUI window.
/client/proc/open_body_marking_editor()
	if(!mob)
		return
	if(body_marking_editor_instance && QDELETED(body_marking_editor_instance))
		body_marking_editor_instance = null
	if(!body_marking_editor_instance)
		body_marking_editor_instance = new(src)
	body_marking_editor_instance.ui_interact(mob)

#undef BODY_MARKING_EDITOR_MAX_ACTS_PER_SECOND
#undef BODY_MARKING_EDITOR_RATE_WINDOW_DS
#undef BODY_MARKING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS
