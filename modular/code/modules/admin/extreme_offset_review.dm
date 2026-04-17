// Extreme Offset Review — Phase 5 admin TGUI.
//
// View-only admin tool for post-hoc inspection of players whose customizer
// entries were flagged by Phase 4 (report_extreme_offsets_on_roundjoin).
// NOT an approval gate — characters have already joined. Admins can PM,
// ahelp-bwoink, follow, note, dismiss, or force-revert a single flagged
// entry's transform.
//
// Related files:
//   modular/code/datums/extreme_offset_policy.dm         (flagging + ticket enqueue)
//   modular/code/__DEFINES/extreme_offset.dm              (thresholds)
//   tgui/packages/tgui/interfaces/ExtremeOffsetReview.tsx (frontend)
//
// Design constraints (see memories/repo/extreme_offset_vetting.md):
//   * Single-direction cyclable render, lazy on admin click.
//   * Render cache keyed by (ckey, dir, content_hash) — content_hash is a
//     DM-native int xor/shift mix, NOT md5.
//   * Only the currently-selected ticket's base64 is emitted in ui_data.
//   * Dummy pool: DUMMY_HUMAN_SLOT_PREFERENCES (taur editor precedent).
//   * Singleton per admin client.
//   * No persistence — tickets live in GLOB until world.Reboot().

// ---------------------------------------------------------------------------
// Ticket datum — one per flagged ckey per round.
// ---------------------------------------------------------------------------
/datum/extreme_offset_ticket
	/// Offending player's ckey at the time of flagging.
	var/ckey
	/// Prefs slot the flag was captured from.
	var/character_slot = 0
	/// Weakref to the joining human (may be null/stale if the player ghosted).
	var/datum/weakref/subject_ref
	/// Snapshots of each flagged customizer_entry captured at flag-emit time.
	/// Each element is an assoc list with keys:
	///   "customizer_type", "accessory_type", "pixel_x", "pixel_y", "scale",
	///   "flags", "flagged_dirs".
	var/list/flagged_entries_snapshot
	/// Aggregate offset budget usage snapshot.
	var/aggregate_used = 0
	var/aggregate_exceeded = FALSE
	/// Was acknowledge_extreme_offsets toggled on at join time?
	var/acknowledged = FALSE
	/// world.time at ticket creation.
	var/created_at = 0
	/// One of "pending", "dismissed", "noted", "reverted". Pending by default.
	var/status = "pending"
	/// Free-form admin note; persists for the round.
	var/note
	/// Assoc "[dir]_[content_hash]" → base64 PNG. Lazy populated.
	var/list/render_cache
	/// Last-viewed dir bit (NORTH/SOUTH/EAST/WEST). Defaults to first
	/// visible dir across all snapshot entries.
	var/selected_dir = SOUTH
	/// Cached content hash, invalidated on snapshot mutation. 0 means
	/// "not yet computed"; recompute lazily.
	var/cached_content_hash = 0

/datum/extreme_offset_ticket/New(mob/living/carbon/human/H, list/flagged_entries, datum/preferences/prefs)
	if(!istype(H) || !istype(prefs))
		return
	ckey = H.ckey
	character_slot = prefs.default_slot
	subject_ref = WEAKREF(H)
	created_at = world.time
	aggregate_used = prefs.aggregate_offset_budget_used
	aggregate_exceeded = prefs.aggregate_extreme
	acknowledged = prefs.acknowledge_extreme_offsets ? TRUE : FALSE
	flagged_entries_snapshot = list()
	if(islist(flagged_entries))
		for(var/datum/customizer_entry/entry as anything in flagged_entries)
			if(!istype(entry))
				continue
			// Phase 6: snapshot per sub-entry when the parent is composite,
			// keyed by (customizer_type, sub_index). One hard-flagged sub-
			// entry on a parent that would otherwise be unflagged still
			// produces one ticket row. For pre-migration / empty-sub
			// entries fall back to the legacy parent-only snapshot.
			if(LAZYLEN(entry.sub_entries))
				var/sub_idx = 0
				for(var/datum/customizer_sub_entry/sub as anything in entry.sub_entries)
					sub_idx++
					if(!istype(sub))
						continue
					if(!sub.is_hard_extreme)
						continue
					flagged_entries_snapshot += list(list(
						"customizer_type" = entry.customizer_type,
						"sub_index" = sub_idx,
						"accessory_type" = sub.accessory_type,
						"pixel_x" = sub.pixel_x,
						"pixel_y" = sub.pixel_y,
						"scale" = sub.scale,
						"flags" = sub.extreme_flags,
						"flagged_dirs" = sub.flagged_dirs,
					))
				continue
			flagged_entries_snapshot += list(list(
				"customizer_type" = entry.customizer_type,
				"sub_index" = 1,
				"accessory_type" = entry.accessory_type,
				"pixel_x" = entry.pixel_x,
				"pixel_y" = entry.pixel_y,
				"scale" = entry.scale,
				"flags" = entry.extreme_flags,
				"flagged_dirs" = entry.flagged_dirs,
			))
	// Pick the first visible dir across all snapshot entries for the
	// initial render; default SOUTH if somehow nothing is tagged.
	var/union_dirs = visible_dirs_bitfield()
	if(union_dirs & SOUTH)
		selected_dir = SOUTH
	else if(union_dirs & NORTH)
		selected_dir = NORTH
	else if(union_dirs & EAST)
		selected_dir = EAST
	else if(union_dirs & WEST)
		selected_dir = WEST

/datum/extreme_offset_ticket/Destroy()
	subject_ref = null
	flagged_entries_snapshot = null
	render_cache = null
	return ..()

/datum/extreme_offset_ticket/proc/visible_dirs_bitfield()
	var/union = 0
	if(!islist(flagged_entries_snapshot))
		return union
	for(var/list/snap as anything in flagged_entries_snapshot)
		var/dirs = snap["flagged_dirs"]
		if(isnum(dirs))
			union |= dirs
	return union

/// Cheap DM-native xor/shift mix over snapshot transform fields so a
/// snapshot mutation invalidates the render cache. Never used for security.
/datum/extreme_offset_ticket/proc/content_hash()
	if(cached_content_hash)
		return cached_content_hash
	// Seed must fit in DM's signed 32-bit int. Use a 31-bit prime derived
	// from the golden-ratio constant (0x9E3779B1 truncated to 31 bits).
	var/hash = 0x1E3779B1
	if(islist(flagged_entries_snapshot))
		for(var/list/snap as anything in flagged_entries_snapshot)
			var/px = isnum(snap["pixel_x"]) ? snap["pixel_x"] : 0
			var/py = isnum(snap["pixel_y"]) ? snap["pixel_y"] : 0
			var/sc = isnum(snap["scale"]) ? round(snap["scale"] * 1000) : 1000
			var/fl = isnum(snap["flags"]) ? snap["flags"] : 0
			var/ctype_str = "[snap["customizer_type"]]"
			var/ctype_hash = 0
			for(var/i in 1 to length(ctype_str))
				ctype_hash = (ctype_hash * 31 + text2ascii(ctype_str, i)) & 0x7FFFFFFF
			hash ^= (px * 73856093) & 0x7FFFFFFF
			hash ^= (py * 19349663) & 0x7FFFFFFF
			hash ^= (sc * 83492791) & 0x7FFFFFFF
			hash ^= (fl << 7) & 0x7FFFFFFF
			hash ^= ctype_hash
			hash = (hash * 16777619) & 0x7FFFFFFF
	cached_content_hash = hash || 1
	return cached_content_hash

/datum/extreme_offset_ticket/proc/get_render(dir)
	if(!(dir in list(NORTH, SOUTH, EAST, WEST)))
		return ""
	var/key = "[dir]_[content_hash()]"
	if(!islist(render_cache))
		render_cache = list()
	if(render_cache[key])
		return render_cache[key]
	var/b64 = generate_render(dir)
	render_cache[key] = b64 || ""
	return render_cache[key]

/// Lazy render: claim the shared preferences dummy slot, clone the
/// subject's appearance (from the live mob if it exists, otherwise from
/// its prefs datum), strip clothing, getFlatIcon at `dir`, base64 encode.
/// Always returns a string (possibly empty on failure).
/datum/extreme_offset_ticket/proc/generate_render(dir)
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	if(!mannequin)
		return ""
	. = ""
	var/mob/living/carbon/human/subject = subject_ref?.resolve()
	var/datum/preferences/prefs = GLOB.preferences_datums[ckey]
	// Prefer live-mob appearance (reflects any mid-round mutations). Fall
	// back to prefs datum if the mob is gone (ghosted / deleted).
	if(istype(subject) && !QDELETED(subject) && subject.client?.prefs)
		subject.client.prefs.copy_to(mannequin, 1, TRUE, TRUE)
	else if(istype(prefs))
		prefs.copy_to(mannequin, 1, TRUE, TRUE)
	else
		unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
		return ""
	CHECK_TICK
	// Strip clothing — getFlatIcon would otherwise bake equipped gear.
	mannequin.unequip_everything()
	CHECK_TICK
	mannequin.setDir(dir)
	mannequin.regenerate_clothes()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(redraw = TRUE)
	mannequin.rebuild_obscured_flags()
	COMPILE_OVERLAYS(mannequin)
	var/icon/flat = getFlatIcon(mannequin, defdir = dir, no_anim = TRUE)
	CHECK_TICK
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	if(!flat)
		return ""
	return icon2base64(flat)

// ---------------------------------------------------------------------------
// Review manager — single global ticket registry.
// ---------------------------------------------------------------------------
GLOBAL_DATUM_INIT(extreme_offset_review_manager, /datum/extreme_offset_review_manager, new)

/datum/extreme_offset_review_manager
	/// ckey → /datum/extreme_offset_ticket. One ticket per ckey per round.
	/// The Phase 4 per-round dedupe (GLOB.extreme_offsets_logged_ckeys)
	/// already prevents duplicate enqueue; overwrite-on-collision here is
	/// defensive.
	var/list/tickets

/datum/extreme_offset_review_manager/New()
	tickets = list()

/datum/extreme_offset_review_manager/proc/enqueue_ticket(datum/extreme_offset_ticket/T)
	if(!istype(T) || !T.ckey)
		return
	var/existing = tickets[T.ckey]
	if(existing && existing != T)
		qdel(existing)
	tickets[T.ckey] = T

/datum/extreme_offset_review_manager/proc/get_ticket(ckey)
	if(!ckey)
		return null
	return tickets[ckey]

// ---------------------------------------------------------------------------
// Per-admin TGUI review datum.
// ---------------------------------------------------------------------------
/// Singleton slot on /client so repeat opens reuse the existing panel.
/client/var/datum/extreme_offset_review/extreme_offset_review_panel

/datum/extreme_offset_review
	/// Admin client that owns this panel.
	var/client/admin_client
	/// ckey of the ticket currently in focus (others ship metadata only).
	var/selected_ckey

/datum/extreme_offset_review/New(client/C)
	if(!istype(C))
		qdel(src)
		return
	admin_client = C

/datum/extreme_offset_review/Destroy()
	if(admin_client?.extreme_offset_review_panel == src)
		admin_client.extreme_offset_review_panel = null
	admin_client = null
	return ..()

/datum/extreme_offset_review/ui_close(mob/user)
	qdel(src)

/datum/extreme_offset_review/ui_state(mob/user)
	// Do NOT use the ADMIN_STATE(R_ADMIN) macro here: it indexes
	// GLOB.admin_states by a numeric permission bit, but that list is
	// initialized empty (see code/modules/tgui/states/admin.dm), so the
	// integer lookup throws "list index out of bounds" before the `||=`
	// can fall back to allocation. Build the state directly — one per
	// ui_state resolution is fine, matches fax_panel / ahelp conventions.
	return new /datum/ui_state/admin_state(R_ADMIN)

/datum/extreme_offset_review/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ExtremeOffsetReview", "Extreme Offset Review", 820, 640)
		ui.open()

/datum/extreme_offset_review/proc/open(client/C, focus_ckey)
	if(!istype(C) || !C.mob)
		return
	if(focus_ckey)
		selected_ckey = focus_ckey
	else if(!selected_ckey)
		// Default to the most recently created ticket, if any.
		var/latest_time = -1
		for(var/key in GLOB.extreme_offset_review_manager.tickets)
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.tickets[key]
			if(istype(T) && T.created_at > latest_time)
				latest_time = T.created_at
				selected_ckey = T.ckey
	ui_interact(C.mob)

/datum/extreme_offset_review/ui_data(mob/user)
	var/list/data = list()
	// Ticket queue — metadata only, no renders.
	var/list/tickets_out = list()
	for(var/key in GLOB.extreme_offset_review_manager.tickets)
		var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.tickets[key]
		if(!istype(T))
			continue
		tickets_out += list(list(
			"ckey" = T.ckey,
			"flagged_count" = length(T.flagged_entries_snapshot),
			"aggregate" = T.aggregate_exceeded,
			"acknowledged" = T.acknowledged,
			"status" = T.status,
			"note_present" = T.note ? TRUE : FALSE,
			"created_at" = T.created_at,
		))
	data["tickets"] = tickets_out
	data["now"] = world.time
	data["aggregate_budget"] = GLOB.extreme_aggregate_budget

	// Selected ticket — full detail including one direction's render.
	var/datum/extreme_offset_ticket/sel = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
	if(istype(sel))
		var/list/entries_out = list()
		for(var/list/snap as anything in sel.flagged_entries_snapshot)
			entries_out += list(list(
				"customizer_type" = "[snap["customizer_type"]]",
				"accessory_type" = "[snap["accessory_type"]]",
				"pixel_x" = snap["pixel_x"],
				"pixel_y" = snap["pixel_y"],
				"scale" = snap["scale"],
				"flags" = snap["flags"],
				"flagged_dirs" = snap["flagged_dirs"],
			))
		var/list/dirs_out = list()
		var/dirbits = sel.visible_dirs_bitfield()
		if(dirbits & NORTH)
			dirs_out += "north"
		if(dirbits & SOUTH)
			dirs_out += "south"
		if(dirbits & EAST)
			dirs_out += "east"
		if(dirbits & WEST)
			dirs_out += "west"
		// Subject liveness — drives "Follow" button enable state.
		var/mob/subject_mob = sel.subject_ref?.resolve()
		var/subject_alive = istype(subject_mob) && !QDELETED(subject_mob)
		// Connected client presence — drives "PM/Ahelp" button enable state.
		var/client/subject_client
		for(var/client/SC in GLOB.clients)
			if(SC.ckey == sel.ckey)
				subject_client = SC
				break
		data["selected"] = list(
			"ckey" = sel.ckey,
			"character_slot" = sel.character_slot,
			"aggregate_used" = sel.aggregate_used,
			"aggregate_exceeded" = sel.aggregate_exceeded,
			"acknowledged" = sel.acknowledged,
			"created_at" = sel.created_at,
			"status" = sel.status,
			"note" = sel.note || "",
			"flagged_entries" = entries_out,
			"visible_dirs" = dirs_out,
			"selected_dir" = _dir_to_string(sel.selected_dir),
			"render_b64" = sel.get_render(sel.selected_dir),
			"subject_alive" = subject_alive,
			"subject_connected" = subject_client ? TRUE : FALSE,
		)
	else
		data["selected"] = null
	return data

/datum/extreme_offset_review/proc/_dir_to_string(dir)
	switch(dir)
		if(NORTH)
			return "north"
		if(EAST)
			return "east"
		if(WEST)
			return "west"
	return "south"

/datum/extreme_offset_review/proc/_string_to_dir(str)
	switch(str)
		if("north")
			return NORTH
		if("east")
			return EAST
		if("west")
			return WEST
	return SOUTH

/datum/extreme_offset_review/ui_act(action, list/params, mob/user)
	. = ..()
	if(.)
		return
	if(!admin_client || user.client != admin_client)
		return TRUE
	if(!check_rights_for(admin_client, R_ADMIN))
		return TRUE

	switch(action)
		if("select_ticket")
			var/new_ckey = params["ckey"]
			if(new_ckey && GLOB.extreme_offset_review_manager.get_ticket(new_ckey))
				selected_ckey = new_ckey
			return TRUE
		if("cycle_dir")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			var/newdir = _string_to_dir(params["dir"])
			if(newdir & T.visible_dirs_bitfield())
				T.selected_dir = newdir
			return TRUE
		if("dismiss")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			T.status = "dismissed"
			log_admin("[key_name(user)] dismissed extreme-offset ticket for [T.ckey].")
			message_admins("[key_name_admin(user)] dismissed extreme-offset ticket for [T.ckey].")
			return TRUE
		if("note")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			var/text = params["text"]
			if(!istext(text))
				text = ""
			T.note = copytext_char(text, 1, 512)
			if(T.status == "pending" && length(T.note))
				T.status = "noted"
			log_admin("[key_name(user)] noted extreme-offset ticket for [T.ckey]: [T.note]")
			return TRUE
		if("pm")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			var/client/target_client
			for(var/client/SC in GLOB.clients)
				if(SC.ckey == T.ckey)
					target_client = SC
					break
			if(target_client)
				admin_client.cmd_admin_pm(target_client, null)
			else
				to_chat(user, span_warning("[T.ckey] is not currently connected."))
			return TRUE
		if("ahelp")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			var/client/target_client
			for(var/client/SC in GLOB.clients)
				if(SC.ckey == T.ckey)
					target_client = SC
					break
			if(target_client)
				// Admin-initiated ahelp (bwoink). /datum/admin_help/New
				// lives at code/modules/admin/verbs/adminhelp.dm L562.
				new /datum/admin_help("Extreme cosmetic offsets review", target_client, TRUE)
			else
				to_chat(user, span_warning("[T.ckey] is not currently connected."))
			return TRUE
		if("follow")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			var/mob/subject_mob = T.subject_ref?.resolve()
			if(!istype(subject_mob) || QDELETED(subject_mob))
				to_chat(user, span_warning("Subject mob no longer exists."))
				return TRUE
			admin_client.jumptomob(subject_mob)
			return TRUE
		if("revert_entry")
			var/datum/extreme_offset_ticket/T = GLOB.extreme_offset_review_manager.get_ticket(selected_ckey)
			if(!istype(T))
				return TRUE
			var/ctype = params["customizer_type"]
			if(!ctype)
				return TRUE
			// Resolve live prefs — the only source we can mutate. If the
			// player disconnected, their prefs datum may have been released;
			// check GLOB.preferences_datums.
			var/datum/preferences/prefs = GLOB.preferences_datums[T.ckey]
			if(!istype(prefs))
				to_chat(user, span_warning("[T.ckey]'s preferences datum is not loaded; cannot revert."))
				return TRUE
			var/reverted = FALSE
			for(var/datum/customizer_entry/entry as anything in prefs.customizer_entries)
				if(!istype(entry))
					continue
				if("[entry.customizer_type]" != "[ctype]")
					continue
				entry.pixel_x = 0
				entry.pixel_y = 0
				entry.scale = 1
				entry.recompute_extreme_flags()
				reverted = TRUE
			if(reverted)
				prefs.recompute_aggregate_extreme()
				// Mirror the revert onto the ticket snapshot so the admin
				// panel reflects the post-revert transform without a
				// separate re-flag pass. Invalidate render cache.
				for(var/list/snap as anything in T.flagged_entries_snapshot)
					if("[snap["customizer_type"]]" != "[ctype]")
						continue
					snap["pixel_x"] = 0
					snap["pixel_y"] = 0
					snap["scale"] = 1
					snap["flags"] = EXTREME_FLAG_NONE
					snap["flagged_dirs"] = 0
				T.cached_content_hash = 0
				T.render_cache = null
				T.status = "reverted"
				log_admin("[key_name(user)] reverted extreme-offset entry [ctype] on [T.ckey].")
				message_admins("[key_name_admin(user)] reverted extreme-offset entry [ctype] on [T.ckey].")
			else
				to_chat(user, span_warning("No matching customizer entry found on [T.ckey]."))
			return TRUE
	return FALSE

// ---------------------------------------------------------------------------
// Admin href routing — opens the review panel from the Phase 4 chat link.
// Invoked as a thin passthrough from /datum/admins/Topic() in
// code/modules/admin/topic.dm (which already validates admin rights +
// href token before any branch runs).
// ---------------------------------------------------------------------------
/datum/admins/proc/handle_extreme_offset_review_topic(list/href_list)
	if(!href_list["extreme_review"])
		return FALSE
	if(usr.client != src.owner || !check_rights(R_ADMIN))
		return TRUE
	var/datum/extreme_offset_review/panel = usr.client.extreme_offset_review_panel
	if(!istype(panel) || QDELETED(panel))
		panel = new /datum/extreme_offset_review(usr.client)
		usr.client.extreme_offset_review_panel = panel
	panel.open(usr.client, href_list["extreme_review"])
	return TRUE
