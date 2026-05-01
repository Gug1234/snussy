/*
 * loadout.dm — TGUI Preferences Menu, Class & Stats → Loadout inline
 * picker (plan addendum Turn 4 — C6).
 *
 * Inline replacement for the classic browse()-backed loadout popup.
 * The 10 /datum/preferences loadout slot vars (`loadout`,
 * `loadout2..loadout10`) already persist through savefile v39; we
 * reuse them verbatim. The custom name/desc/hex overrides remain
 * governed by the Classic flow for now — this envelope only owns
 * slot assignment and clearing.
 *
 * Wire shape:
 *   set_loadout_slot     {slot: 1..10, path: "/datum/loadout_item/..." | null}
 *   clear_loadout_slot   {slot: 1..10}
 *
 * Security:
 *   - slot is validated into 1..10.
 *   - path is matched against GLOB.loadout_items (static allow-list
 *     populated at init from subtypesof(/datum/loadout_item)). No
 *     `text2path(path) && new path()` — we copy the pre-existing
 *     instance reference out of the registry.
 *   - donator_ckey_check enforced against parent.ckey.
 *   - Duplicate detection + triumph-cost budget check mirror the
 *     legacy vices_menu.dm Topic path (~line 1440).
 *   - NOT registered in GLOB.prefs_setter_table — these are collection
 *     mutations, not scalar key/value writes.
 *
 * Performance:
 *   Each call does one O(N) walk of GLOB.loadout_items (N ≈ 200).
 *   build_loadout_catalog() emits the same walk once into static data.
 */

/datum/preferences/proc/act_set_loadout_slot(slot, path, mob/user)
	slot = text2num("[slot]")
	if(!slot || slot < 1 || slot > 10)
		return FALSE
	var/slot_var = (slot == 1) ? "loadout" : "loadout[slot]"

	// null/empty path = clear slot.
	if(isnull(path) || path == "" || path == "null")
		vars[slot_var] = null
		invalidate_stat_matrix()
		_pref_loadout_mark_dirty()
		return TRUE

	var/datum/loadout_item/selected = _pref_lookup_loadout_item("[path]")
	if(!selected)
		return FALSE

	// Donator gate. parent is the owning client; use its ckey.
	if(selected.donoritem && !selected.donator_ckey_check(parent?.ckey))
		return FALSE

	// Duplicate check against the other 9 slots.
	for(var/i in 1 to 10)
		if(i == slot)
			continue
		var/other_var = (i == 1) ? "loadout" : "loadout[i]"
		var/datum/loadout_item/other_item = vars[other_var]
		if(other_item && other_item.type == selected.type)
			return FALSE

	// Point-budget check. Mirrors vices_menu.dm ~line 1447.
	if(selected.triumph_cost)
		var/total_points = get_total_points()
		var/spent_points = 0
		for(var/i in 1 to 10)
			if(i == slot)
				continue
			var/other_var = (i == 1) ? "loadout" : "loadout[i]"
			var/datum/loadout_item/other_slot = vars[other_var]
			if(other_slot && other_slot.triumph_cost)
				spent_points += other_slot.triumph_cost
		if(spent_points + selected.triumph_cost > total_points)
			return FALSE

	vars[slot_var] = selected
	invalidate_stat_matrix()
	_pref_loadout_mark_dirty()
	return TRUE

/datum/preferences/proc/act_clear_loadout_slot(slot, mob/user)
	slot = text2num("[slot]")
	if(!slot || slot < 1 || slot > 10)
		return FALSE
	var/slot_var = (slot == 1) ? "loadout" : "loadout[slot]"
	vars[slot_var] = null
	invalidate_stat_matrix()
	_pref_loadout_mark_dirty()
	return TRUE

/**
 * Flag the loadout collection as having unsaved changes. Loadout slot
 * vars are not registered in GLOB.prefs_setter_table because they are
 * collection mutations, not key/value writes — but the player still
 * expects the Save button to light up after an inline edit. The client
 * mirrors this by staging PREF_KEY_PERSIST_ONLY in the DirtyLedger;
 * here we add a server-side dirty marker so prefs_persist_dirty's
 * `length(dirty_keys)` gate sees something to persist when the flush
 * arrives.
 */
/datum/preferences/proc/_pref_loadout_mark_dirty()
	if(!dirty_keys)
		dirty_keys = list()
	dirty_keys |= "loadout"

/**
 * No-op setter for PREF_KEY_PERSIST_ONLY. The sentinel only exists so
 * prefs_apply_commit accepts the key in a commit batch — actual
 * persistence is handled by prefs_persist_dirty's tail call once the
 * batch finishes.
 */
/datum/preferences/proc/set_pref_persist_only_noop(value)
	return


/datum/preferences/proc/_pref_lookup_loadout_item(path_str)
	if(!path_str)
		return null
	for(var/datum/loadout_item/item as anything in GLOB.loadout_items)
		if(!item)
			continue
		if("[item.type]" == path_str)
			return item
	return null

/*
 * Derive a short category bucket from the loadout_item's spawn path
 * prefix. The source file groups items by `//COMMENT` banners which
 * aren't reflected in the datum hierarchy, so we can't lean on
 * type paths — we classify by the spawned obj path instead.
 *
 * Buckets are intentionally coarse. Unknown paths fall through to
 * "Misc" so new items remain visible without a code change.
 */
/datum/preferences/proc/_pref_loadout_category(datum/loadout_item/item)
	if(!item || !item.path)
		return "Misc"
	var/p = "[item.path]"
	if(findtextEx(p, "/obj/item/clothing/head"))
		return "Hats"
	if(findtextEx(p, "/obj/item/clothing/cloak") || findtextEx(p, "/obj/item/clothing/neck"))
		return "Cloaks"
	if(findtextEx(p, "/obj/item/clothing/shoes"))
		return "Shoes"
	if(findtextEx(p, "/obj/item/clothing/under"))
		return "Shirts"
	if(findtextEx(p, "/obj/item/clothing/pants"))
		return "Pants"
	if(findtextEx(p, "/obj/item/clothing"))
		return "Accessories"
	if(findtextEx(p, "/obj/item/rogueweapon") || findtextEx(p, "/obj/item/gun"))
		return "Weapons"
	if(findtextEx(p, "/obj/item/reagent_containers/food/snacks/rogue/cookware") || findtextEx(p, "/obj/item/reagent_containers/glass") || findtextEx(p, "/obj/item/reagent_containers/food/drinks"))
		return "Cookware"
	if(findtextEx(p, "/obj/item/natural") || findtextEx(p, "/obj/item/broom") || findtextEx(p, "/obj/item/soap") || findtextEx(p, "/obj/item/candle") || findtextEx(p, "/obj/item/storage/keyring") || findtextEx(p, "/obj/item/flint"))
		return "Tools"
	if(findtextEx(p, "/obj/item/instrument"))
		return "Instruments"
	if(findtextEx(p, "/obj/item/cosmetic") || findtextEx(p, "/obj/item/lipstick") || findtextEx(p, "/obj/item/perfume"))
		return "Cosmetics"
	return "Misc"

/*
 * Build the static catalogue. Each row carries only the data the TSX
 * needs to render + filter without a round-trip. `donator_locked` is
 * separate from `accessible` so a non-donor can still see greyed-out
 * rows (mirrors classic behaviour where donor items are listed but
 * not selectable).
 */
/datum/preferences/proc/build_loadout_catalog(mob/user)
	var/list/rows = list()
	var/ckey_str = parent?.ckey
	for(var/datum/loadout_item/item as anything in GLOB.loadout_items)
		if(!item)
			continue
		var/accessible = TRUE
		if(item.donoritem && !item.donator_ckey_check(ckey_str))
			accessible = FALSE
		rows += list(list(
			"id" = "[item.type]",
			"name" = item.name,
			"desc" = item.desc || "",
			"category" = _pref_loadout_category(item),
			"triumph_cost" = item.triumph_cost || 0,
			"donator_locked" = item.donoritem ? 1 : 0,
			"accessible" = accessible ? 1 : 0,
		))
	return rows

/*
 * Build the dynamic 10-slot state array. Each entry always exists
 * (empty slots render as null `item_id`) so the TSX can map over a
 * fixed-length list without extra bookkeeping.
 */
/datum/preferences/proc/build_loadout_state()
	var/list/slots = list()
	for(var/i in 1 to 10)
		var/slot_var = (i == 1) ? "loadout" : "loadout[i]"
		var/datum/loadout_item/item = vars[slot_var]
		var/list/row = list(
			"slot" = i,
			"item_id" = null,
			"name" = null,
			"triumph_cost" = 0,
		)
		if(item)
			row["item_id"] = "[item.type]"
			// Prefer the per-slot name override if set, otherwise the
			// item's own name. Same precedence the classic loadout
			// render uses in vices_menu render paths.
			var/override_name = vars["loadout_[i]_name"]
			row["name"] = (override_name && override_name != "") ? override_name : item.name
			row["triumph_cost"] = item.triumph_cost || 0
		slots += list(row)
	return slots
