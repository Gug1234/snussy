/datum/preferences/proc/validate_body_markings()
	//validating body markings
	for(var/zone in body_markings)
		for(var/name in body_markings[zone])
			if(!(name in GLOB.body_markings_per_limb[zone]))
				body_markings[zone] -= name

/// Upgrades any flat-hex string entries in body_markings to the per-entry
/// dict shape used by the TGUI editor. Safe to call repeatedly; entries
/// already in dict shape are left alone (missing keys are back-filled from
/// defaults).
/datum/preferences/proc/normalize_body_markings()
	if(!islist(body_markings))
		body_markings = list()
		return
	for(var/zone in body_markings)
		var/list/zone_list = body_markings[zone]
		if(!islist(zone_list))
			continue
		for(var/name in zone_list)
			var/entry = zone_list[name]
			if(islist(entry))
				// Back-fill any missing keys so downstream reads are safe.
				var/list/defaults = body_marking_entry_defaults(entry["color"] || "FFFFFF")
				for(var/key in defaults)
					if(!(key in entry))
						entry[key] = defaults[key]
				// Clamp offsets defensively (hand-edited sidecars etc.).
				entry["pixel_x"] = clamp(entry["pixel_x"], BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX)
				entry["pixel_y"] = clamp(entry["pixel_y"], BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX)
			else
				zone_list[name] = body_marking_entry_defaults(entry)

/// Returns a legacy-shape copy of body_markings (zone → name → flat hex
/// string) suitable for writing to the main savefile. In-memory shape is
/// left untouched. Used by the savefile write path until sidecar-backed
/// persistence lands in Phase 3.
/datum/preferences/proc/serialize_body_markings_for_savefile()
	var/list/out = list()
	if(!islist(body_markings))
		return out
	for(var/zone in body_markings)
		var/list/zone_list = body_markings[zone]
		if(!islist(zone_list))
			continue
		var/list/flat = list()
		for(var/name in zone_list)
			flat[name] = body_marking_entry_color(zone_list[name])
		out[zone] = flat
	return out

/datum/preferences/proc/handle_body_markings_topic(mob/user, href_list)
	// Phase 3: marking mutations now flow through the TGUI editor datum
	// (/datum/body_marking_editor). The legacy href mutation router is
	// stubbed to a redirect so stale client browser windows don't runtime;
	// any action in those popups simply reopens the new editor.
	if(user?.client)
		user.client.open_body_marking_editor()
	return

/datum/preferences/proc/print_body_markings_page()
	var/list/dat = list()
	dat += "Use a <b>markings preset</b>: <a href='?_src_=prefs;preference=use_preset;task=change_marking'>Choose</a>  | <a href='?_src_=prefs;preference=reset_all_colors;task=change_marking'>Reset marking colors</a>"
	/*
	dat += "<table width='100%' align='center'>"
	dat += " Mutant color #1:<span style='border: 1px solid #161616; background-color: #[features["mcolor"]];'>&nbsp;&nbsp;&nbsp;</span> <a href='?_src_=prefs;preference=mutant_color;task=input'>Change</a>"
	dat += " Mutant color #2:<span style='border: 1px solid #161616; background-color: #[features["mcolor2"]];'>&nbsp;&nbsp;&nbsp;</span> <a href='?_src_=prefs;preference=mutant_color2;task=input'>Change</a>"
	dat += " Mutant color #3:<span style='border: 1px solid #161616; background-color: #[features["mcolor3"]];'>&nbsp;&nbsp;&nbsp;</span> <a href='?_src_=prefs;preference=mutant_color3;task=input'>Change</a>"
	dat += "</table>"
	*/
	dat += "<table width='100%'>"
	dat += "<td valign='top' width='50%'>"
	var/iterated_markings = 0
	for(var/zone in GLOB.marking_zones)
		var/named_zone = " "
		switch(zone)
			if(BODY_ZONE_R_ARM)
				named_zone = "Right Arm"
			if(BODY_ZONE_L_ARM)
				named_zone = "Left Arm"
			if(BODY_ZONE_HEAD)
				named_zone = "Head"
			if(BODY_ZONE_CHEST)
				named_zone = "Chest"
			if(BODY_ZONE_R_LEG)
				named_zone = "Right Leg"
			if(BODY_ZONE_L_LEG)
				named_zone = "Left Leg"
			if(BODY_ZONE_PRECISE_R_HAND)
				named_zone = "Right Hand"
			if(BODY_ZONE_PRECISE_L_HAND)
				named_zone = "Left Hand"
		dat += "<center><h3>[named_zone]</h3></center>"
		dat += "<table align='center'; width='100%'; height='100px'; style='background-color:#1c1313'>"
		dat += "<tr style='vertical-align:top'>"
		dat += "<td width=10%><font size=2> </font></td>"
		dat += "<td width=10%><font size=2> </font></td>"
		dat += "<td width=40%><font size=2> </font></td>"
		dat += "<td width=25%><font size=2> </font></td>"
		dat += "<td width=15%><font size=2> </font></td>"
		dat += "</tr>"

		if(body_markings[zone])
			for(var/key in body_markings[zone])
				var/can_move_up = " "
				var/can_move_down = " "
				var/color_line = " "
				var/current_index = LAZYFIND(body_markings[zone], key)
				var/color = body_marking_entry_color(body_markings[zone][key])
				color_line = "<a href='?_src_=prefs;name=[key];key=[zone];preference=reset_color;task=change_marking'>R</a>"
				color_line += "<a href='?_src_=prefs;name=[key];key=[zone];preference=change_color;task=change_marking'><span class='color_holder_box' style='background-color:["#[color]"]'></span></a>"
				if(current_index < length(body_markings[zone]))
					can_move_down = "<a href='?_src_=prefs;name=[key];key=[zone];preference=marking_move_down;task=change_marking'>Down</a>"
				if(current_index > 1)
					can_move_up = "<a href='?_src_=prefs;name=[key];key=[zone];preference=marking_move_up;task=change_marking'>Up</a>"
				dat += "<tr style='vertical-align:top;'>"
				dat += "<td>[can_move_up]</td>"
				dat += "<td>[can_move_down]</td>"
				dat += "<td><a href='?_src_=prefs;name=[key];key=[zone];preference=change_marking;task=change_marking'>[key]</a></td>"
				dat += "<td>[color_line]</td>"
				dat += "<td><a href='?_src_=prefs;name=[key];key=[zone];preference=remove_marking;task=change_marking'>Remove</a></td>"
				dat += "</tr>"

		if(!(body_markings[zone]) || body_markings[zone].len < MAXIMUM_MARKINGS_PER_LIMB)
			dat += "<tr style='vertical-align:top;'>"
			dat += "<td> </td>"
			dat += "<td> </td>"
			dat += "<td> </td>"
			dat += "<td> </td>"
			dat += "<td><a href='?_src_=prefs;key=[zone];preference=add_marking;task=change_marking'>Add</a></td>"
			dat += "</tr>"

		dat += "</table>"

		iterated_markings += 1
		if(iterated_markings >= 4)
			dat += "</td><td valign='top' width='50%'>"
			iterated_markings = 0

	dat += "</td></tr></table>"
	return dat

/datum/preferences/proc/ShowMarkings(mob/user)
	// Phase 3: ShowMarkings is now a thin shim that redirects to the TGUI
	// body marking editor. The legacy browser popup is retired, but the proc
	// itself stays in place so stale client hrefs (and the change_marking
	// task handler below) don't runtime on old saves. See
	// modular/code/modules/client/body_marking_editor.dm for the real UI.
	if(user?.client)
		user.client.open_body_marking_editor()

/datum/preferences/proc/reset_body_marking_colors()
	for(var/zone in body_markings)
		var/list/bml = body_markings[zone]
		for(var/key in bml)
			var/datum/body_marking/BM = GLOB.body_markings[key]
			var/default_color = BM.get_default_color(features, pref_species)
			var/entry = bml[key]
			if(islist(entry))
				entry["color"] = default_color
			else
				bml[key] = default_color
