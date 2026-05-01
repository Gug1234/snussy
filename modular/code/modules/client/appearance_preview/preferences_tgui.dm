/**
 * preferences_tgui.dm — Phase 1, Step 8 TGUI surface for the tabbed
 * preferences preview shell.
 *
 * Wires `/datum/preferences` as a TGUI interface so the `PreferencesMenu`
 * tabbed window (`tgui/packages/tgui/interfaces/PreferencesMenu/`) can
 * mount the live `CharacterPreviewMapView` map control alongside the
 * appearance-preview tab bodies.
 *
 * ## Scope note
 *
 * Roguetown's main preferences menu is still an HTML `Topic()` surface
 * (see `code/modules/client/preferences.dm::ShowChoices`). That menu is
 * NOT being migrated in Step 8 — the migration surface would span dozens
 * of panels (species/job/flavor/loadout/trait/keybinds/game) well outside
 * the Phase 1 TDI-win scope.
 *
 * Step 8 instead lands the TABBED SHELL as a dedicated TGUI window
 * accessed via `/datum/preferences/proc/open_appearance_preferences`. The
 * shell owns:
 *   - The persistent `<CharacterPreviewMapView/>` pane (Step 7 component).
 *   - The 7-tab taxonomy (info/features/taur_offsets/markings/
 *     intimate_accessories/keybinds/game), with taur_offsets conditional.
 *   - Client-side dirty-modal (DirtyModal.tsx) enforcing the Step 5
 *     server-side `act_set_active_tab` contract.
 *
 * Steps 9 and 10 populate the TaurOffsets and IntimateAccessories tab
 * bodies. The other 5 tabs land as placeholders in this step that point
 * the user back to the legacy HTML prefs menu until a later migration.
 * This keeps the Phase 1 TDI win landing possible without blocking on a
 * full prefs-UI rewrite.
 */

/**
 * Player-facing opener. Lazily allocates the preview view, ensures the
 * default tab is INFO, and opens the tabbed TGUI window.
 *
 * Arguments:
 *   user — the mob whose client should host the preview map control and
 *          the TGUI window. Required; null short-circuits.
 */
/datum/preferences/proc/open_appearance_preferences(mob/user)
	if(!user || QDELETED(src))
		return
	if(!can_open_preferences_menu(user))
		return
	// Step 16: if fancy chat failed this session or the player opted into
	// classic HTML, delegate to the legacy ShowChoices() surface. The
	// `/client/proc/should_use_classic_prefs` gate lives in
	// modular/.../appearance_preview/prefs_fallback_trigger.dm.
	var/client/user_client = user.client
	if(user_client?.should_use_classic_prefs())
		current_tab = 1
		ShowChoices(user)
		return
	// Step 3: lazy-init the setter/action dispatch tables on first open.
	// Idempotent — subsequent calls fast-out on the registered flag.
	ensure_prefs_dispatch_tables()
	// Push rwmap1.png into the client RSC so the TGUI Origin body can
	// load it via resolveAsset('rwmap1.png'). The legacy HTML map
	// window does the same; without this, the image only appears after
	// the player opens the legacy window first.
	user << browse_rsc(file("html/rwmap1.png"), "rwmap1.png")
	// Ensure the view exists before ui_interact so ui_static_data has a
	// non-empty character_preview_view id to emit on the first render.
	create_character_preview_view(user)
	ui_interact(user)

/**
 * Step 2 stub for the ui_data snapshot builder landed in Step 4.
 *
 * Returns the current value of a pref key for inclusion in the TGUI
 * snapshot payload. Step 4 replaces this body with a switch over
 * PREF_KEY_* strings that reads the matching /datum/preferences var.
 *
 * Step 4: switch over the PREF_KEY_* constants registered in the Step 3
 * dispatch table. Keys NOT registered in GLOB.prefs_setter_table will
 * never reach this proc (build_prefs_snapshot iterates the table's
 * keyset), so an `else` branch returning null is enough to guard
 * forward-compat races where a new key is added to the snapshot but
 * not the setter table.
 */
/datum/preferences/proc/get_pref_snapshot_field(key)
	switch(key)
		if(PREF_KEY_NICKNAME_COLOR)
			return nickname_color
		if(PREF_KEY_PER_CHAR_HARDMODE)
			return per_char_hardmode
		if(PREF_KEY_UI_PREFER_CLASSIC_HTML)
			return ui_prefer_classic_html
		if(PREF_KEY_UI_LOBBY_BUTTON_CLASSIC)
			return ui_lobby_button_classic
		if(PREF_KEY_CURSED_COLLAR_OPT)
			return cursed_collar_opt
		if(PREF_KEY_CURSED_COLLAR_MASTER_MODE)
			return cursed_collar_master_mode
		if(PREF_KEY_CURSED_COLLAR_SPECIFIED_NAME)
			return cursed_collar_specified_name
		// Identity (Step 10) — registered in modular/.../prefs_categories/identity.dm.
		if(PREF_KEY_REAL_NAME)
			return real_name
		if(PREF_KEY_NICKNAME)
			return nickname
		if(PREF_KEY_GENDER)
			return gender
		if(PREF_KEY_PRONOUNS)
			return pronouns
		if(PREF_KEY_VOICE_PACK)
			return voice_pack
		if(PREF_KEY_VOICE_TYPE)
			return voice_type
		if(PREF_KEY_VOICE_COLOR)
			return voice_color
		if(PREF_KEY_VOICE_PITCH_X100)
			// Snapshot the wire form so the client renders an integer.
			return round(voice_pitch * 100)
		if(PREF_KEY_CHAR_ACCENT)
			return char_accent
		if(PREF_KEY_BARK_ID)
			return bark_id
		if(PREF_KEY_BARK_SPEED)
			return bark_speed
		if(PREF_KEY_HEAR_BARKS)
			return hear_barks
		if(PREF_KEY_PATREON_SAY_COLOR)
			return patreon_say_color
		if(PREF_KEY_PATREON_SAY_COLOR_ENABLED)
			return patreon_say_color_enabled
		if(PREF_KEY_ORIGIN)
			// Surface the typepath string so the client can match it
			// against the static origin list.
			return origin ? "[origin.type]" : null
		if(PREF_KEY_FAMILY)
			return family
		if(PREF_KEY_SETSPOUSE)
			return setspouse
		if(PREF_KEY_GENDER_CHOICE)
			return gender_choice
		if(PREF_KEY_SONG_ARTIST)
			return song_artist
		if(PREF_KEY_SONG_TITLE)
			return song_title
		if(PREF_KEY_FLAVORTEXT)
			return flavortext
		if(PREF_KEY_OOC_NOTES)
			return ooc_notes
		if(PREF_KEY_NSFW_FLAVORTEXT)
			return nsfwflavortext
		if(PREF_KEY_ERP_OOC_NOTES)
			return erpprefs
		// Identity extras — Misc / Food / Gnoll / Familiar / Jelly.
		if(PREF_KEY_AGE)
			return age
		if(PREF_KEY_DNR)
			return dnr_pref
		if(PREF_KEY_DOMHAND)
			return domhand
		if(PREF_KEY_CULINARY_FAV_FOOD)
			return culinary_preferences ? "[culinary_preferences[CULINARY_FAVOURITE_FOOD]]" : null
		if(PREF_KEY_CULINARY_FAV_DRINK)
			return culinary_preferences ? "[culinary_preferences[CULINARY_FAVOURITE_DRINK]]" : null
		if(PREF_KEY_CULINARY_HATED_FOOD)
			return culinary_preferences ? "[culinary_preferences[CULINARY_HATED_FOOD]]" : null
		if(PREF_KEY_CULINARY_HATED_DRINK)
			return culinary_preferences ? "[culinary_preferences[CULINARY_HATED_DRINK]]" : null
		if(PREF_KEY_GNOLL_NAME)
			return gnoll_prefs?.gnoll_name
		if(PREF_KEY_GNOLL_PRONOUNS)
			return gnoll_prefs?.gnoll_pronouns
		if(PREF_KEY_GNOLL_PELT)
			if(!gnoll_prefs)
				return null
			var/list/pelt_options = gnoll_prefs.get_pelt_options()
			if(!pelt_options)
				return gnoll_prefs.pelt_type
			for(var/label in pelt_options)
				if(pelt_options[label] == gnoll_prefs.pelt_type)
					return label
			return gnoll_prefs.pelt_type
		if(PREF_KEY_GNOLL_PENIS)
			return (gnoll_prefs?.genitals && gnoll_prefs.genitals["penis"]) ? 1 : 0
		if(PREF_KEY_GNOLL_VAGINA)
			return (gnoll_prefs?.genitals && gnoll_prefs.genitals["vagina"]) ? 1 : 0
		if(PREF_KEY_GNOLL_BREASTS)
			return (gnoll_prefs?.genitals && gnoll_prefs.genitals["breasts"]) ? 1 : 0
		if(PREF_KEY_GNOLL_HEIGHT)
			return _pref_gnoll_descriptor_label("height")
		if(PREF_KEY_GNOLL_BODY)
			return _pref_gnoll_descriptor_label("body")
		if(PREF_KEY_GNOLL_FUR)
			return _pref_gnoll_descriptor_label("fur")
		if(PREF_KEY_GNOLL_VOICE)
			return _pref_gnoll_descriptor_label("voice")
		if(PREF_KEY_GNOLL_MUZZLE)
			return _pref_gnoll_descriptor_label("muzzle")
		if(PREF_KEY_GNOLL_EXPRESSION)
			return _pref_gnoll_descriptor_label("expression")
		if(PREF_KEY_FAMILIAR_NAME)
			return familiar_prefs?.familiar_name
		if(PREF_KEY_FAMILIAR_PRONOUNS)
			return familiar_prefs?.familiar_pronouns
		if(PREF_KEY_FAMILIAR_SPECIE)
			// Surface the display-name key so the client can populate
			// its dropdown directly from the familiar_types list.
			if(!familiar_prefs?.familiar_specie)
				return null
			return GLOB.familiar_display_names ? GLOB.familiar_display_names[familiar_prefs.familiar_specie] : null
		if(PREF_KEY_FAMILIAR_FLAVORTEXT)
			return familiar_prefs?.familiar_flavortext
		if(PREF_KEY_FAMILIAR_OOC_NOTES)
			return familiar_prefs?.familiar_ooc_notes
		if(PREF_KEY_FAMILIAR_HEADSHOT)
			return familiar_prefs?.familiar_headshot_link
		if(PREF_KEY_JELLY_ENABLED)
			return jelly_controller_enabled ? 1 : 0
		if(PREF_KEY_JELLY_NAME)
			return jelly_prefs?.jelly_name
		if(PREF_KEY_JELLY_PRONOUNS)
			return jelly_prefs?.jelly_pronouns
		if(PREF_KEY_JELLY_FLAVORTEXT)
			return jelly_prefs?.jelly_flavortext
		if(PREF_KEY_JELLY_OOC_NOTES)
			return jelly_prefs?.jelly_ooc_notes
		// Body (Step 11) — registered in modular/.../prefs_categories/body.dm.
		if(PREF_KEY_SPECIES)
			// Surface the species name string so the client matches it
			// against the static species_options list. pref_species is a
			// /datum/species instance; we want the human-readable name.
			return pref_species ? pref_species.name : null
		if(PREF_KEY_BODY_TYPE)
			return gender
		if(PREF_KEY_SKIN_TONE)
			return skin_tone
		if(PREF_KEY_EYE_COLOR)
			return eye_color
		if(PREF_KEY_HAIRSTYLE)
			return hairstyle
		if(PREF_KEY_HAIR_COLOR)
			return hair_color
		if(PREF_KEY_FACIAL_HAIRSTYLE)
			return facial_hairstyle
		if(PREF_KEY_FACIAL_HAIR_COLOR)
			return facial_hair_color
		if(PREF_KEY_DETAIL)
			return detail
		if(PREF_KEY_DETAIL_COLOR)
			return detail_color
		if(PREF_KEY_ACCESSORY)
			return accessory
		if(PREF_KEY_BODY_SIZE_X100)
			return round((features ? features["body_size"] : 1) * 100)
		// Step 12 part B — Extremities / Taur surface scalars.
		if(PREF_KEY_MUTANT_COLOR_1)
			return features ? features["mcolor"] : null
		if(PREF_KEY_MUTANT_COLOR_2)
			return features ? features["mcolor2"] : null
		if(PREF_KEY_MUTANT_COLOR_3)
			return features ? features["mcolor3"] : null
		if(PREF_KEY_ETHEREAL_COLOR)
			return features ? features["ethcolor"] : null
		if(PREF_KEY_TAUR_TYPE)
			return taur_type
		if(PREF_KEY_TAUR_COLOR)
			return taur_color
		if(PREF_KEY_TAUR_MARKINGS_COLOR)
			return taur_markings
		if(PREF_KEY_TAUR_TERTIARY_COLOR)
			return taur_tertiary
		if(PREF_KEY_USE_TAUR_GENITAL_SPRITES)
			return use_taur_genital_sprites
		if(PREF_KEY_TAUR_CONSISTENT_AROUSAL)
			return taur_consistent_arousal
		if(PREF_KEY_TAUR_MIRROR_EW)
			return taur_mirror_ew
		if(PREF_KEY_TESTICLE_MIRROR_EW)
			return testicle_mirror_ew
		// B7 — genital toggles (customizer_entry-backed shadow prefs).
		if(PREF_KEY_GENITAL_PENIS_ENABLED)
			return _pref_read_genital_enabled(/datum/customizer_entry/organ/penis)
		if(PREF_KEY_GENITAL_TESTICLES_ENABLED)
			return _pref_read_genital_enabled(/datum/customizer_entry/organ/testicles)
		if(PREF_KEY_GENITAL_BREASTS_ENABLED)
			return _pref_read_genital_enabled(/datum/customizer_entry/organ/breasts)
		if(PREF_KEY_GENITAL_VAGINA_ENABLED)
			return _pref_read_genital_enabled(/datum/customizer_entry/organ/vagina)
		if(PREF_KEY_GENITAL_PENIS_SIZE)
			return _pref_read_penis_field("size")
		if(PREF_KEY_GENITAL_PENIS_FUNCTIONAL)
			return _pref_read_penis_field("functional")
		if(PREF_KEY_GENITAL_PENIS_SHEATHED)
			return _pref_read_penis_field("sheathed")
		if(PREF_KEY_GENITAL_TESTICLES_SIZE)
			return _pref_read_testicles_field("size")
		if(PREF_KEY_GENITAL_TESTICLES_VIRILITY)
			return _pref_read_testicles_field("virility")
		if(PREF_KEY_GENITAL_BREASTS_SIZE)
			return _pref_read_breasts_field("size")
		if(PREF_KEY_GENITAL_BREASTS_LACTATING)
			return _pref_read_breasts_field("lactating")
		if(PREF_KEY_GENITAL_VAGINA_FERTILITY)
			return _pref_read_vagina_field("fertility")
		// B3 — heterochromia shadow prefs (customizer_entry-backed).
		if(PREF_KEY_HETEROCHROMIA_ENABLED)
			return _pref_read_heterochromia_enabled()
		if(PREF_KEY_SECOND_EYE_COLOR)
			return _pref_read_second_eye_color()
		// Identity v2 (TB1/I3/I4/I5/I7/I8/I9 + IN5/IN6 + chastity/ERP toggles).
		if(PREF_KEY_BARK_PITCH_X100)
			return round(bark_pitch * 100)
		if(PREF_KEY_BARK_VARIANCE_X100)
			return round(bark_variance * 100)
		if(PREF_KEY_FAITH)
			if(!selected_patron)
				return null
			var/datum/faith/patron_faith = GLOB.faithlist ? GLOB.faithlist[selected_patron.associated_faith] : null
			return patron_faith ? patron_faith.name : null
		if(PREF_KEY_PATRON)
			return selected_patron ? "[selected_patron.type]" : null
		if(PREF_KEY_RUMOR)
			return rumour
		if(PREF_KEY_NOBLE_GOSSIP)
			return noble_gossip
		if(PREF_KEY_OOC_IMAGE_URL)
			return flavor_ooc_image_url
		if(PREF_KEY_NSFW_OOC_IMAGE_URL)
			return nsfw_flavor_ooc_image_url
		if(PREF_KEY_COMBAT_MUSIC)
			return combat_music ? "[combat_music.type]" : null
		if(PREF_KEY_HEADSHOT_LINK)
			return headshot_link
		if(PREF_KEY_CHATHEADSHOT_ENABLED)
			return chatheadshot ? 1 : 0
		if(PREF_KEY_CURSED_ENABLED)
			return cursed_enabled ? 1 : 0
		if(PREF_KEY_EXTREME_ERP)
			return extreme_erp ? 1 : 0
		if(PREF_KEY_EDGING)
			return edging ? 1 : 0
		if(PREF_KEY_INTIMATE_ENABLED)
			return intimate_enabled ? 1 : 0
		if(PREF_KEY_INTIMATE_REACTION)
			return intimate_reaction_enabled ? 1 : 0
		if(PREF_KEY_SHOW_INTIMATE_EXAMINE)
			return show_intimate_examine ? 1 : 0
		if(PREF_KEY_CHASTITY_HARDMODE)
			return chastity_hardmode
		if(PREF_KEY_CHASTITY_ENABLED)
			return pref_chastity_enabled ? 1 : 0
		if(PREF_KEY_CHASTITY_FLAT)
			return pref_chastity_flat ? 1 : 0
		if(PREF_KEY_CHASTITY_ANAL)
			return pref_chastity_anal ? 1 : 0
		if(PREF_KEY_CHASTITY_SPIKED)
			return pref_chastity_spiked ? 1 : 0
		if(PREF_KEY_CHASTITY_LOCKED)
			return pref_chastity_locked ? 1 : 0
		if(PREF_KEY_CHASTITY_SPAWN_KEY)
			return pref_chastity_spawn_key ? 1 : 0
		if(PREF_KEY_CHASTITY_RANDOM_KEYS)
			return pref_chastity_random_keys ? 1 : 0
		if(PREF_KEY_CHASTITY_KEY_STASHES)
			return pref_chastity_key_stashes ? pref_chastity_key_stashes.Copy() : list()
		// B1 — race/nobility title.
		if(PREF_KEY_RACE_TITLE)
			return selected_title
		// C3/C4/C5 — class & stats inline picks. Wire format is the
		// typepath STRING so the TSX can match it against
		// data.statpack_options / virtue_options / vice_options.
		if(PREF_KEY_JOBLESS_ROLE)
			var/snapshot_joblessrole = joblessrole
			if(snapshot_joblessrole != RETURNTOLOBBY && snapshot_joblessrole != BERANDOMJOB)
				snapshot_joblessrole = RETURNTOLOBBY
			return snapshot_joblessrole
		if(PREF_KEY_STATPACK)
			return statpack ? "[statpack.type]" : ""
		if(PREF_KEY_VIRTUE)
			return virtue ? "[virtue.type]" : ""
		if(PREF_KEY_VIRTUE_TWO)
			return virtuetwo ? "[virtuetwo.type]" : ""
		if(PREF_KEY_VICE_1)
			return vice1 ? "[vice1.type]" : ""
		if(PREF_KEY_VICE_2)
			return vice2 ? "[vice2.type]" : ""
		if(PREF_KEY_VICE_3)
			return vice3 ? "[vice3.type]" : ""
		if(PREF_KEY_VICE_4)
			return vice4 ? "[vice4.type]" : ""
		if(PREF_KEY_VICE_5)
			return vice5 ? "[vice5.type]" : ""
		if(PREF_KEY_EXTRA_LANGUAGE_1)
			return extra_language_1
		if(PREF_KEY_EXTRA_LANGUAGE_2)
			return extra_language_2
	return null

/**
 * TGUI entry point. Opens the `PreferencesMenu` interface. Follows the
 * roguetown convention (see `/datum/custom_piercing_editor/ui_interact`)
 * of pinning `GLOB.always_state` so status resolution from
 * `/mob/dead/new_player` (lobby) is unambiguous.
 */
/datum/preferences/ui_interact(mob/user, datum/tgui/ui)
	if(!can_open_preferences_menu(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PreferencesMenu", "Appearance & Preferences", 1100, 720)
		ui.set_state(GLOB.always_state)
		ui.open()
	// Step 4: mark the surface live so commit/close paths can reason
	// about whether a window is actually attached.
	active_tgui_surface = TRUE
	// Re-attach the preview map_view to the viewer's client.screen on
	// every ui_interact entry. display_to() is idempotent (LAZYADD into
	// registered_clients + |= into client.screen), so a redundant call
	// is cheap. This covers the case where a previous ui_close or a
	// reopen path dropped the screen registration but the prefs datum
	// itself still owned the view, leaving the BYOND map control empty
	// on the next open.
	if(!character_preview_view)
		create_character_preview_view(user)
	else
		character_preview_view.display_to(user)
		if(!character_preview_view.body || !character_preview_view.canvas)
			character_preview_view.update_body()

/**
 * State override so the lobby `/mob/dead/new_player` can open and use
 * the window the same way standalone editors do.
 */
/datum/preferences/ui_state(mob/user)
	return GLOB.always_state

/datum/preferences/proc/can_open_preferences_menu(mob/user)
	if(!SSticker || SSticker.current_state < GAME_STATE_PREGAME)
		if(user)
			to_chat(user, span_warning("The preferences menu is still initializing. Try again once the lobby countdown begins."))
		return FALSE
	return TRUE

/datum/preferences/proc/build_skin_tone_options()
	var/list/options = list()
	var/datum/species/species = pref_species
	if(!species || !species.use_skintones)
		return options
	var/list/skin_tones = species.get_skin_list()
	if(!skin_tones)
		return options
	for(var/skin_label as anything in skin_tones)
		var/skin_value = sanitize_hexcolor(skin_tones[skin_label], 6, FALSE)
		if(!skin_value)
			continue
		options += list(list(
			"id" = skin_value,
			"label" = "[skin_label]",
			"color" = "#[skin_value]",
		))
	return options

/**
 * Static data — the preview view id, the current tab, and the current
 * background state. These rarely change, so they ride static_data rather
 * than forcing a full `update_static_data()` every pref mutation.
 *
 * When tab or background state DOES change (via act_* handlers), the
 * handlers call `SStgui.update_uis(src)` or equivalent to republish.
 */
/datum/preferences/ui_static_data(mob/user)
	. = list()
	// Ref-string id of the BYOND map control. Empty string when the
	// view hasn't been allocated yet (cold path before first open).
	.["character_preview_view"] = character_preview_view ? character_preview_view.assigned_map : ""
	.["active_tab"] = active_tab
	.["background_state"] = background_state
	// Enum lists surfaced so the TSX can render labels without duplicating
	// the DM constants.
	.["valid_tabs"] = GLOB.appearance_preview_valid_tabs
	.["background_states"] = GLOB.appearance_preview_background_states
	// Step 6: prefs asset bundle metadata. The TSX shell asserts the
	// bundle landed before rendering sheet-backed widgets (hair tiles,
	// loadout previews, …). Names are emitted as strings so the client
	// doesn't need to know DM typepaths.
	.["prefs_bundle_children"] = get_prefs_bundle_child_names()
	// Step 10: Identity → Origin static region list. Emitted as a flat
	// array of `{id, label, x, y}` so the OriginMap widget can render
	// without a second round-trip. Source pixels match modular/origins
	// /origins.dm map_x / map_y values, addressed against the existing
	// rwmap1.png (550×400 source).
	var/list/origin_regions = list()
	if(GLOB.origins)
		for(var/otype as anything in GLOB.origins)
			var/datum/origin/region = GLOB.origins[otype]
			origin_regions += list(list(
				"id" = "[otype]",
				"label" = region.name,
				"x" = region.map_x,
				"y" = region.map_y,
			))
	.["origin_regions"] = origin_regions

	// Phase 3: pref_catalog manifest. Surfaced as a parsed object so the
	// TGUI <AccessoryPicker> can resolve sheet URLs + crop rects without
	// a second round-trip. Empty when the bundle hasn't been materialized
	// yet — the picker falls back to a name-only list in that case.
	.["pref_catalog_manifest"] = pref_catalog_load_manifest_for_static_data()

	// Addendum Turn 3 — C1/C2. Job + villain-role static payloads for
	// the Class & Stats inline pickers. Both walk live SSjob / GLOB
	// registries and tag each entry with the caller's jobban state so
	// the TSX can disable rows without a second round-trip.
	.["job_options"] = build_class_picker_options(user)
	.["villain_role_options"] = build_villain_role_options(user)

	// Step 11: Body category static option lists. Surfaced as flat
	// arrays of `{id, label}` so the dropdowns can render without a
	// second round-trip and without duplicating DM globals client-side.
	// Species options come from get_selectable_species() so the list
	// already filters on the roundstart_races config.
	var/list/species_options = list()
	for(var/species_name in get_selectable_species())
		species_options += list(list(
			"id" = species_name,
			"label" = species_name,
		))
	.["species_options"] = species_options

	.["skin_tone_options"] = build_skin_tone_options()
	.["skin_tone_label"] = pref_species?.skin_tone_wording || "Skin Tone"
	.["skin_tone_enabled"] = pref_species?.use_skintones ? 1 : 0
	.["mutant_color_enabled"] = (pref_species && (MUTCOLORS in pref_species.species_traits)) ? 1 : 0
	.["mutant_color_partsonly_enabled"] = (pref_species && (MUTCOLORS_PARTSONLY in pref_species.species_traits)) ? 1 : 0

	// Voicepack options — keys of GLOB.voice_packs_list emitted as
	// flat strings so the Identity/Voice dropdown can render labels
	// without duplicating the global client-side. Server-side
	// prefs_validate_string gates the actual write.
	var/list/voice_pack_options = list()
	if(GLOB.voice_packs_list)
		for(var/pack_name in GLOB.voice_packs_list)
			voice_pack_options += pack_name
	.["voice_pack_options"] = voice_pack_options

	// Hair / facial hair option lists are deferred to Step 12 part B,
	// which dumps the per-species sprite_accessory entries. Emit empty
	// arrays so the TSX shape stays stable and falls back to a freeform
	// Input until then.
	var/list/hair_options = list()
	.["hairstyle_options"] = hair_options

	var/list/fhair_options = list()
	.["facial_hairstyle_options"] = fhair_options

	// Body size bounds — wire form is integer percent (×100) so the
	// client can drive a Slider without re-importing the DNA defines.
	.["body_size_min_x100"] = round(BODY_SIZE_MIN * 100)
	.["body_size_max_x100"] = round(BODY_SIZE_MAX * 100)

	// Identity extras — option lists for Misc / Food / Gnoll / Familiar.
	.["age_options"] = ALL_AGES_LIST
	.["pronouns_options"] = GLOB.pronouns_list ? GLOB.pronouns_list.Copy() : list()

	var/list/food_options = list()
	if(GLOB.food_with_faretypes)
		for(var/list/row in GLOB.food_with_faretypes)
			food_options += list(list(
				"id" = "[row["type"]]",
				"label" = capitalize(row["name"]),
				"quality" = row["faretype"],
			))
	.["food_options"] = food_options

	var/list/drink_options = list()
	if(GLOB.drink_with_qualities)
		for(var/list/row in GLOB.drink_with_qualities)
			drink_options += list(list(
				"id" = "[row["type"]]",
				"label" = capitalize(row["name"]),
				"quality" = row["quality"],
			))
	.["drink_options"] = drink_options

	var/list/pelt_options = list()
	if(gnoll_prefs)
		var/list/pelt_map = gnoll_prefs.get_pelt_options()
		if(pelt_map)
			for(var/label in pelt_map)
				pelt_options += label
	.["gnoll_pelt_options"] = pelt_options

	// Per-descriptor-slot label lists. Enumerated server-side so the
	// client can render a dropdown per slot without pulling in every
	// /datum/mob_descriptor subtype.
	var/list/gnoll_desc_options = list()
	if(gnoll_prefs)
		for(var/slot in list("height","body","fur","voice","muzzle","expression"))
			var/list/opts = gnoll_prefs.get_descriptor_options(slot)
			var/list/labels = list()
			if(opts)
				for(var/label in opts)
					labels += label
			gnoll_desc_options[slot] = labels
	.["gnoll_descriptor_options"] = gnoll_desc_options

	var/list/familiar_options = list()
	if(GLOB.familiar_types)
		for(var/label in GLOB.familiar_types)
			familiar_options += label
	.["familiar_species_options"] = familiar_options

	// I5 — Faith + Patron option lists. Keyed by faith display name so
	// the TSX can bind both dropdowns from a single static payload.
	var/list/faith_options = list()
	var/list/patron_options_by_faith = list()
	if(GLOB.preference_faiths && GLOB.faithlist)
		for(var/faith_path as anything in GLOB.preference_faiths)
			var/datum/faith/faith = GLOB.faithlist[faith_path]
			if(!faith || !faith.name)
				continue
			faith_options += faith.name
			var/list/patrons_for_faith = list()
			var/list/pool = GLOB.patrons_by_faith ? GLOB.patrons_by_faith[faith_path] : null
			if(length(pool))
				for(var/ppath in pool)
					var/datum/patron/P = GLOB.patronlist[ppath]
					if(!P || P.disabled_patron)
						continue
					patrons_for_faith += list(list(
						"id" = "[ppath]",
						"label" = P.name,
					))
			patron_options_by_faith[faith.name] = patrons_for_faith
	.["faith_options"] = faith_options
	.["patron_options_by_faith"] = patron_options_by_faith

	// I9 — Combat music track options. Sourced from the existing
	// subtypesof(/datum/combat_music) registry.
	var/list/combat_music_options = list()
	if(GLOB.cmode_tracks_by_type)
		for(var/typepath as anything in GLOB.cmode_tracks_by_type)
			var/datum/combat_music/track = GLOB.cmode_tracks_by_type[typepath]
			if(!track)
				continue
			combat_music_options += list(list(
				"id" = "[typepath]",
				"label" = track.name,
				"shortname" = track.shortname,
				"credits" = track.credits,
			))
	.["combat_music_options"] = combat_music_options

	// B1 — per-species race/nobility title banks. Each species datum
	// carries its own `race_titles` list (gated by `use_titles`); we
	// emit both the flavor description AND the title bank in a single
	// species-name-keyed dictionary so the Race body can render the
	// dropdown only when the current species opts in.
	var/list/species_descriptions = list()
	var/list/species_race_titles = list()
	if(GLOB.species_list)
		for(var/species_name in GLOB.species_list)
			var/path = GLOB.species_list[species_name]
			if(!ispath(path, /datum/species))
				continue
			var/datum/species/proto = new path()
			var/desc = proto.desc
			if(!desc)
				desc = proto.expanded_desc || ""
			species_descriptions[species_name] = desc
			if(proto.use_titles && length(proto.race_titles))
				// Prepend "None" as the canonical empty slot; matches
				// the legacy tgui_input_list in preferences.dm:2135.
				var/list/bank = list("None")
				for(var/title in proto.race_titles)
					bank += title
				species_race_titles[species_name] = bank
			qdel(proto)
	.["species_descriptions"] = species_descriptions
	.["species_race_titles"] = species_race_titles

	// C3 — statpack inline picker. Emit the stat_array side-by-side with
	// flavor text so the TSX can render per-stat deltas + tooltips
	// without a second round-trip. Range cells serialize as `[min,max]`
	// lists; the client midpoints for display.
	var/list/statpack_options = list()
	if(GLOB.statpacks)
		for(var/path as anything in GLOB.statpacks)
			var/datum/statpack/proto = GLOB.statpacks[path]
			if(!proto)
				continue
			var/list/stats_copy = list()
			if(proto.stat_array)
				var/list/src_stats = proto.stat_array
				stats_copy = src_stats.Copy()
			statpack_options += list(list(
				"id" = "[path]",
				"label" = proto.name,
				"desc" = proto.desc,
				"stat_array" = stats_copy,
			))
	.["statpack_options"] = statpack_options

	// C4 — virtue / vice inline dropdowns. Both surface {id, label, desc}
	// so the TSX can render the Dropdown option with an inline flavor
	// line. Virtue picker uses the same list twice (for virtue and
	// virtuetwo); vice picker uses vice_options.
	var/list/virtue_options = list()
	if(GLOB.virtues)
		for(var/path as anything in GLOB.virtues)
			var/datum/virtue/proto = GLOB.virtues[path]
			if(!proto)
				continue
			if(!proto.name)
				continue
			virtue_options += list(list(
				"id" = "[path]",
				"label" = proto.name,
				"desc" = proto.desc || proto.custom_text || "",
			))
	.["virtue_options"] = virtue_options

	var/list/vice_options = list()
	if(GLOB.character_flaws)
		for(var/vice_label in GLOB.character_flaws)
			var/path = GLOB.character_flaws[vice_label]
			if(!ispath(path, /datum/charflaw))
				continue
			var/datum/charflaw/proto = GLOB.charflaw_singletons ? GLOB.charflaw_singletons[path] : null
			vice_options += list(list(
				"id" = "[path]",
				"label" = vice_label,
				"desc" = proto?.desc || "",
			))
	.["vice_options"] = vice_options

	// C5 — language inline dropdowns. GLOB.all_languages is a flat
	// list of language name strings; emit as {id,label} with the
	// triumph-cost for the second slot already baked into the label
	// so the client doesn't need to know the cost formula. Slot 1 is
	// free, slot 2 costs triumphs (the legacy vices_menu path applies
	// this at commit; we only annotate the label here).
	var/list/language_options = list()
	language_options += list(list("id" = "None", "label" = "None"))
	if(GLOB.all_languages)
		for(var/lang_name in GLOB.all_languages)
			language_options += list(list(
				"id" = lang_name,
				"label" = lang_name,
			))
	.["language_options"] = language_options

	// B7 — genital static data. Named size dropdowns come from the
	// same GLOB lists used by the legacy HTML picker so name/value
	// pairs stay in lockstep (edits to those GLOBs propagate
	// automatically). The availability flags let the TSX hide an
	// entire organ row when the current species declares no matching
	// customizer (e.g. species without breasts).
	var/list/named_penis_sizes = list()
	if(islist(GLOB.named_penis_sizes))
		for(var/label in GLOB.named_penis_sizes)
			named_penis_sizes += list(list("id" = GLOB.named_penis_sizes[label], "label" = label))
	.["named_penis_sizes"] = named_penis_sizes

	var/list/named_ball_sizes = list()
	if(islist(GLOB.named_ball_sizes))
		for(var/label in GLOB.named_ball_sizes)
			named_ball_sizes += list(list("id" = GLOB.named_ball_sizes[label], "label" = label))
	.["named_ball_sizes"] = named_ball_sizes

	var/list/named_breast_sizes = list()
	if(islist(GLOB.named_breast_sizes))
		for(var/label in GLOB.named_breast_sizes)
			named_breast_sizes += list(list("id" = GLOB.named_breast_sizes[label], "label" = label))
	.["named_breast_sizes"] = named_breast_sizes

	.["genital_customizers_available"] = list(
		"penis" = _pref_has_genital_customizer(/datum/customizer/organ/penis) ? 1 : 0,
		"testicles" = _pref_has_genital_customizer(/datum/customizer/organ/testicles) ? 1 : 0,
		"breasts" = _pref_has_genital_customizer(/datum/customizer/organ/breasts) ? 1 : 0,
		"vagina" = _pref_has_genital_customizer(/datum/customizer/organ/vagina) ? 1 : 0,
	)

	// Addendum Turn 4 — B3. Heterochromia availability probe. Some
	// species eyes customizers (e.g. moth compound eyes) set
	// allows_heterochromia=FALSE; Coloration.tsx hides the checkbox
	// on those species.
	.["eye_heterochromia_allowed"] = _pref_has_heterochromia() ? 1 : 0

	// Addendum Turn 4 — C6. Static loadout catalogue. Emitted once at
	// static-data time because GLOB.loadout_items is frozen at init.
	.["loadout_catalog"] = build_loadout_catalog(user)

	// Step 14: one-shot route hint set by prefs_resume_after_singleton().
	// Read once on first paint by the TSX shell to restore the player
	// to the row they came from. Cleared here so a manual reload of
	// the window doesn't redirect them again.
	if(pending_resume_category)
		.["resume_category"] = pending_resume_category
		.["resume_row"] = pending_resume_row
		// Bump a monotonic token so the TSX useEffect re-runs even if
		// the category/row string matches a prior hint (previously it
		// only fired on value change, which misses the "relaunch same
		// editor twice" case).
		pending_resume_token = (pending_resume_token || 0) + 1
		.["resume_token"] = pending_resume_token
		pending_resume_category = null
		pending_resume_row = null

/**
 * Per-tick data. Intentionally minimal — the preview stream is
 * out-of-band via the map control, and per-tab data lives in the tab
 * bodies (Steps 9/10). We only surface whether the taur-offsets tab
 * should be visible based on the current species' organ presence.
 */
/datum/preferences/ui_data(mob/user)
	. = list()
	// taur_offsets tab visibility hint. The TSX filters the tab list
	// against this flag; the server still enforces via act_set_active_tab
	// validation against GLOB.appearance_preview_valid_tabs.
	.["taur_offsets_available"] = _appearance_preview_taur_available()
	// Step 4: flat pref snapshot under a nested key so the shell's
	// existing top-level fields (active_tab, etc.) don't collide with
	// registered pref key strings. The TSX reads `data.prefs[key]`.
	.["prefs"] = build_prefs_snapshot(user)
	.["skin_tone_options"] = build_skin_tone_options()
	.["skin_tone_label"] = pref_species?.skin_tone_wording || "Skin Tone"
	.["skin_tone_enabled"] = pref_species?.use_skintones ? 1 : 0
	.["mutant_color_enabled"] = (pref_species && (MUTCOLORS in pref_species.species_traits)) ? 1 : 0
	.["mutant_color_partsonly_enabled"] = (pref_species && (MUTCOLORS_PARTSONLY in pref_species.species_traits)) ? 1 : 0
	// Step 5: stat-matrix aggregator. Cached on the datum so unrelated
	// edits (e.g. nickname_color) don't trigger a rebuild.
	.["stat_matrix"] = build_stat_matrix()
	// Step 15: bottom-bar descriptor fields. Hidden TSX-side when
	// standalone=1; the server still emits them so admin VV diagnostics
	// can see the current lobby gate state at a glance.
	var/list/join_gate = _bottom_bar_join_gate()
	.["can_join"] = join_gate["can_join"] ? 1 : 0
	.["join_block_reason"] = join_gate["reason"]
	.["migrant_waves"] = _bottom_bar_list_open_waves()
	.["lobby_status"] = _bottom_bar_status_line()
	// `standalone` here means "no lobby-join surface" — true whenever the
	// owning mob isn't a /mob/dead/new_player (admin VV on a logged-in
	// player, or any ingame edit path). BottomBar.tsx hides itself.
	.["standalone"] = _bottom_bar_new_player() ? 0 : 1
	// I12 — row-visibility gates for opt-in Identity subpanels.
	.["gnoll_row_visible"] = (be_special && (ROLE_GNOLL in be_special)) ? 1 : 0
	.["familiar_row_visible"] = (job_preferences && job_preferences["Witch"]) ? 1 : 0
	.["jelly_row_visible"] = jelly_controller_enabled ? 1 : 0
	// Addendum Turn 3 — C1/C2. Per-tick snapshots of the two
	// collection-valued pref stores. Emitted at top level (not via
	// build_prefs_snapshot) because their shape isn't a scalar.
	.["job_preferences_map"] = (islist(job_preferences) && length(job_preferences)) ? job_preferences.Copy() : list()
	.["villain_roles_enabled"] = (islist(be_special) && length(be_special)) ? be_special.Copy() : list()
	// IN6 — aggregate gate. Hide downstream Intimacy rows when the player
	// has no ERP content opt-ins enabled at all.
	.["intimacy_gated"] = (cursed_enabled || extreme_erp || edging || intimate_enabled || intimate_reaction_enabled || show_intimate_examine) ? 0 : 1
	.["active_slot"] = default_slot
	.["chastity_available"] = chastenable ? 1 : 0
	.["chastity_has_penis"] = has_genital_in_prefs(ORGAN_SLOT_PENIS) ? 1 : 0
	.["chastity_has_vagina"] = has_genital_in_prefs(ORGAN_SLOT_VAGINA) ? 1 : 0

	// Addendum Turn 4 — C6. Loadout dynamic state. Points total/spent
	// and the 10-slot array. Triumph total lives on the client side
	// (parent.get_triumphs()) — surfaced here so the TSX doesn't need
	// a separate query.
	// Step 17: phase-one regular intimate accessory offset scope. These
	// rows are compact and dynamic because selected accessory labels vary
	// by preference slot, while the allowed transform fields stay x/y-only.
	.["intimate_accessory_offset_allowed_fields"] = get_intimate_accessory_offset_allowed_fields()
	.["intimate_accessory_offset_scope"] = "phase_one_xy"
	.["intimate_accessory_offset_rows"] = get_intimate_accessory_offset_scope_data()
	.["intimate_accessory_offset_active_target"] = intimate_accessory_offset_active_target
	.["intimate_accessory_offset_descriptors"] = build_intimate_accessory_hybrid_offset_descriptor_grid(intimate_accessory_offset_active_target)
	.["intimate_accessory_offset_min"] = CUSTOM_PIERCING_OFFSET_MIN
	.["intimate_accessory_offset_max"] = CUSTOM_PIERCING_OFFSET_MAX

	.["loadout_slots"] = build_loadout_state()
	.["loadout_points_total"] = get_total_points()
	.["loadout_points_spent"] = get_loadout_points_spent()
	.["triumphs_available"] = (parent?.mob) ? parent.mob.get_triumphs() : 0

	// Phase 4: current AccessoryPicker selection map — maps each
	// /datum/customizer_choice typepath the species owns to the
	// manifest entry_key currently chosen on its customizer_entry.
	// Lets the picker render a "selected" highlight without a
	// per-row act round-trip.
	.["pref_catalog_selections"] = build_pref_catalog_selection_map()
	// Phase 4: per-customizer accessory color slots. Each entry is a
	// list of `#RRGGBB` strings indexed 1..color_keys. Empty list when
	// the customizer / accessory does not allow color customization.
	.["pref_catalog_colors"] = build_pref_catalog_color_map()

/**
 * Assets shipped with the window. Reuses the existing v2 appearance-preview
 * manifest asset so tab bodies can render sheet crops identically to the
 * standalone editor windows.
 */
/datum/preferences/ui_assets(mob/user)
	// Reuses the same simple asset bundle the standalone taur/piercing
	// editors ship (see `appearance_preview_commit.dm:ui_assets`). The
	// JSON-manifest asset type the plan called for does not exist in
	// this tree; the simple asset already serves the sheet+manifest the
	// tab bodies need.
	return list(
		get_asset_datum(/datum/asset/simple/appearance_preview),
		get_asset_datum(/datum/asset/simple/prefs_origin_map),
		get_asset_datum(/datum/asset/simple/pref_catalog),
	)

/**
 * Close hook — tear the preview view down when the TGUI window closes.
 * This matches addendum D.1: view lifetime == prefs TGUI window lifetime.
 */
/datum/preferences/ui_close(mob/user)
	// Step 4: clear the TGUI-surface flag so any signal-driven commit
	// path landing in later steps can short-circuit once the window is
	// gone. Intentionally does NOT auto-commit pending changes — the
	// client-side DirtyModal (Step 8) owns the Save/Discard decision.
	active_tgui_surface = FALSE
	destroy_character_preview_view()
	return ..()

/**
 * Action router. Forwards TGUI `act(...)` calls into the plain action
 * procs landed in Step 5. Unknown actions return FALSE so the TGUI layer
 * logs them as unrecognised.
 */
/datum/preferences/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	// Lazy-prime the dispatch tables. The menu can be opened through
	// paths that don't go via open_appearance_preferences (lobby
	// verbs, bottom-bar Join, test harnesses), so guard the first
	// ui_act with an idempotent ensure — O(1) after the first run.
	ensure_prefs_dispatch_tables()
	switch(action)
		if("set_pref")
			// Step 4: single-key staged write (autosave path / live edit).
			// Rate-limited because this is the highest-frequency envelope.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/ok = prefs_apply_set_pref(params["key"], params["value"], usr)
			if(ok)
				SStgui.update_uis(src)
			return TRUE
		if("commit")
			// Step 4: batched commit from the Save button. Rate-limited as
			// a single act regardless of batch size; PREFS_COMMIT_BATCH_MAX
			// protects the inner loop.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/list/failed = prefs_apply_commit(params["pairs"], usr)
			SStgui.update_uis(src)
			// Surface any per-key rejections so the player can see what's
			// failing instead of thinking the whole save silently dropped.
			// Validator/setter rejections are already logged admin-side;
			// this is the player-facing line.
			if(length(failed))
				to_chat(usr, span_warning("Some preferences failed to save: [jointext(failed, ", ")]. Check your input and try again."))
			return TRUE
		if("discard")
			// Step 4: Discard path of the DirtyModal. Wipes pending set
			// and reloads the slot from disk so the preview re-syncs.
			prefs_discard_dirty(usr)
			SStgui.update_uis(src)
			return TRUE
		if("close")
			// TopBar's Close button dispatches act('close'); forward to
			// SStgui so the window actually shuts. The native tgui.dm
			// close-typed message only fires for chrome-initiated
			// closes, not act() envelopes.
			SStgui.close_uis(src)
			return TRUE
		if("set_active_tab")
			var/ok = act_set_active_tab(params["tab"])
			if(ok)
				SStgui.update_uis(src)
			return TRUE
		if("rotate")
			act_rotate(params["backwards"])
			return TRUE
		if("preview_voice")
			// Play a short representative sample from the currently
			// selected voicepack. Uses a 5-second cooldown (shared
			// with barkpreview's COOLDOWN_DECLARE) to defang spam.
			act_preview_voice(usr, params["voice"])
			return TRUE
		if("preview_bark")
			// Thin wrapper around the legacy barkpreview href case so
			// the TGUI button reuses the proven playback path.
			act_preview_bark(usr, params["bark"])
			return TRUE
		if("request_examine_preview")
			// Mirror the legacy `ooc_preview` href: spawn a transient
			// /datum/examine_panel for the preview mannequin so the
			// player can see how their flavor/OOC stack renders.
			if(character_preview_view && character_preview_view.body)
				var/datum/examine_panel/preview_examine_panel = new(character_preview_view.body)
				preview_examine_panel.ui_interact(usr)
			else
				to_chat(usr, span_warning("Preview body not ready yet — reopen the menu and try again."))
			return TRUE
		if("update_background")
			var/ok = act_update_background(params["state"])
			if(ok)
				SStgui.update_uis(src)
			return TRUE
		if("set_intimate_accessory_offset_target")
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_set_intimate_accessory_offset_target(params["target_key"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("save_intimate_accessory_offset_props")
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/list/offset_props = islist(params["props"]) ? params["props"] : null
			if(act_save_intimate_accessory_offset_props(params["target_key"], offset_props, usr))
				SStgui.update_uis(src)
			else
				to_chat(usr, span_warning("Unable to save that intimate accessory offset. Reopen the menu and try again."))
			return TRUE
		if("open_taur_editor")
			// Step 9: player-path opener. Routes through the tabbed
			// shell — sets the active tab to taur_offsets, binds the
			// editor to prefs.active_editor (singleton), and opens the
			// standalone window beside the shell.
			open_taur_genital_editor(usr, params["part"] || "penis", standalone = FALSE)
			SStgui.update_uis(src)
			return TRUE
		if("open_piercing_editor")
			// Step 10: player-path opener for the custom piercing /
			// intimate accessories editor. Same pattern as Step 9 —
			// sets the intimate_accessories tab, binds the editor to
			// prefs.active_editor for the strip pass, opens the
			// standalone window alongside the shell.
			open_custom_piercing_editor(usr, params["slot"], standalone = FALSE)
			SStgui.update_uis(src)
			return TRUE
		if("launch_singleton")
			// Step 14: hand off to a registered standalone editor.
			// Stashes return state on the calling client so the editor's
			// ui_close can re-open the prefs window to the same row.
			// Not rate-limited — the action implicitly closes this UI.
			return handle_launch_singleton(params["editor"], params["return_category"], params["return_row"], usr)
		if("prefs_action")
			// Step 15: bottom-bar dispatch through the disjoint
			// GLOB.prefs_action_table. Rate-limited because these
			// handlers can launch heavier lobby flows (LateChoices,
			// observer transition); a rogue client flooding them
			// would be annoying even if not harmful.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/action_key = params["action"]
			if(!action_key)
				return TRUE
			var/datum/prefs_action/act_entry = GLOB.prefs_action_table[action_key]
			if(!act_entry)
				log_admin_private("prefs_action: unknown key '[action_key]' from ckey=[usr?.ckey || parent?.ckey]")
				return TRUE
			if(!hascall(src, act_entry.handler_name))
				stack_trace("prefs_action: handler '[act_entry.handler_name]' missing on /datum/preferences")
				return TRUE
			call(src, act_entry.handler_name)(usr, params)
			return TRUE
		if("set_job_priority")
			// Addendum Turn 3 C1. Dedicated envelope (not set_pref)
			// because job_preferences is assoc-list-valued, not scalar.
			// Rate-limited alongside set_pref since rapid toggles would
			// otherwise let a client flood SetJobPreferenceLevel's
			// HIGH-demotes-others loop.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_set_job_priority(params["title"], params["level"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("set_villain_role")
			// Addendum Turn 3 C2. Dedicated envelope for be_special
			// because the list shape doesn't match set_pref. Jobban
			// enforcement happens server-side; the TSX only uses the
			// static `banned` flag to disable the checkbox, which a
			// raw ui_act could bypass.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_set_villain_role(params["role"], params["enabled"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("set_loadout_slot")
			// Addendum Turn 4 C6. Dedicated envelope because slot
			// writes mutate `vars["loadout[N]"]` to a datum instance —
			// not representable through the scalar set_pref allow-list.
			// Rate-limited since the O(N) duplicate/budget scan is
			// non-trivial at 200+ items.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_set_loadout_slot(params["slot"], params["path"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("clear_loadout_slot")
			// Addendum Turn 4 C6. Thin wrapper kept separate from
			// set_loadout_slot so audit logs clearly distinguish clears
			// from assignments.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_clear_loadout_slot(params["slot"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("pref_catalog_select")
			// Phase 4: AccessoryPicker dispatch. The TGUI <AccessoryPicker>
			// emits the customizer_choice typepath + the entry key as
			// embedded in the manifest. The handler resolves the entry key
			// back to a sprite_accessory typepath (and a size value for
			// breasts/penis/testicles), then mutates the matching customizer
			// entry. Rate-limited because a misbehaving client could spam
			// click-through changes; each click ends in update_body() which
			// is non-trivial.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_pref_catalog_select(params["choice_type"], params["entry_key"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("pref_catalog_set_color")
			// Phase 4: per-slot accessory color writer. Mirrors the legacy
			// `acc_color` topic, but takes the hex value from the TGUI
			// <ColorBox>/<input type=color> directly rather than spawning a
			// modal color picker. Rate-limited alongside the rest of the
			// pref_catalog envelopes.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			if(act_pref_catalog_set_color(params["choice_type"], params["color_index"], params["hex"], usr))
				SStgui.update_uis(src)
			return TRUE
		if("export_slot")
			// TB1 — serialise the current character slot to a JSON
			// blob and hand it to the client via a transient textbox
			// so they can copy/paste it elsewhere. No disk I/O here
			// beyond what export_character_slot_json already does.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/slot = params["slot"]
			var/payload = export_character_slot_json(isnum(slot) ? slot : default_slot)
			if(payload)
				tgui_input_text(usr, "Copy this JSON to share or back up your character slot.", "Export Slot", payload, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			return TRUE
		if("import_slot")
			// Step 17 — prompt for a JSON payload, parse its envelope for
			// preview metadata (timestamp / source ckey / savefile version)
			// and require an explicit overwrite confirmation before
			// delegating to import_character_slot_json. Version mismatches
			// and other failures surface as toasts via the dict returned
			// by the importer.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/payload = tgui_input_text(usr, "Paste a character slot JSON export. This will overwrite slot [default_slot].", "Import Slot", "", multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(!istext(payload) || !length(payload))
				return TRUE
			var/list/meta = list()
			var/decoded = safe_json_decode(payload)
			if(islist(decoded))
				var/list/envelope = decoded
				if(istext(envelope["exported_at"]))
					meta["exported_at"] = envelope["exported_at"]
				if(istext(envelope["source_ckey"]))
					meta["source_ckey"] = envelope["source_ckey"]
				if(isnum(envelope["savefile_version"]))
					meta["savefile_version"] = envelope["savefile_version"]
			var/confirm_lines = list("This will OVERWRITE slot [default_slot]. Continue?")
			if(meta["exported_at"])
				confirm_lines += "Exported: [meta["exported_at"]]"
			if(meta["source_ckey"])
				confirm_lines += "Source ckey: [meta["source_ckey"]]"
			if(meta["savefile_version"])
				confirm_lines += "Savefile version: [meta["savefile_version"]]"
			if(tgui_alert(usr, jointext(confirm_lines, "\n"), "Confirm Import", list("Overwrite", "Cancel")) != "Overwrite")
				return TRUE
			var/list/result = import_character_slot_json(payload)
			if(islist(result) && result["ok"])
				load_character()
				SStgui.update_uis(src)
				to_chat(usr, span_notice("[result["message"] || "Slot imported."]"))
			else
				var/reason = (islist(result) && result["message"]) ? result["message"] : "payload was rejected"
				to_chat(usr, span_warning("Slot import failed: [reason]"))
			return TRUE
		if("toggle_bitfield")
			// O5 — flip a single bit in a whitelisted toggle field. The
			// field/mask pair is validated against a static allow-list
			// to keep this from becoming an arbitrary-memory writer.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/field = params["field"]
			var/mask = isnum(params["mask"]) ? params["mask"] : text2num("[params["mask"]]")
			if(!_prefs_toggle_bitfield_allowed(field, mask))
				return TRUE
			vars[field] ^= mask
			SStgui.update_uis(src)
			return TRUE
		if("preview_combat_music")
			// I9 — play a short sample of the selected combat-music track
			// to the prefs owner so they can hear it before saving.
			if(!_prefs_rate_limit_check(usr))
				return TRUE
			var/typepath = params["track"]
			var/path = text2path(typepath)
			if(!path)
				return TRUE
			var/datum/combat_music/track = GLOB.cmode_tracks_by_type ? GLOB.cmode_tracks_by_type[path] : null
			if(track && length(track.musicpath))
				SEND_SOUND(usr, sound(track.musicpath[1], volume = 60, channel = CHANNEL_LOBBYMUSIC))
			return TRUE
		if("preview_examine")
			// I6 / I7 — alias of request_examine_preview kept for the
			// TSX shorthand used by the Descriptors and Flavor bodies.
			if(character_preview_view && character_preview_view.body)
				var/datum/examine_panel/preview_examine_panel = new(character_preview_view.body)
				preview_examine_panel.ui_interact(usr)
			else
				to_chat(usr, span_warning("Preview body not ready yet — reopen the menu and try again."))
			return TRUE

/**
 * Internal helper: is the taur-offsets tab applicable to the current
 * character? Checks the live preview body for a taur body organ; the
 * tab is hidden otherwise to avoid a dead-end UX path.
 */
/datum/preferences/proc/_appearance_preview_taur_available()
	// Prefer the live preview body's taur-body organ because that is
	// the authoritative view on what the dummy is actually rendering.
	if(character_preview_view && character_preview_view.body)
		var/mob/living/carbon/human/dummy/body = character_preview_view.body
		if(!isnull(body.getorganslot(ORGAN_SLOT_TAUR_BODY)))
			return TRUE
	// Fallback: the taur_type pref itself. The preview body may not
	// be allocated yet on a cold first-open, or update_body() may
	// not have run to attach the organ, but a non-null taur_type
	// guarantees the player intends to be taur and the row must
	// therefore render so they can configure it.
	if(taur_type)
		return TRUE
	return FALSE
//Debug verb to open the prefs TGUI without going through the datum proc. 
/client/verb/open_prefs_tgui()
    set name = "Open Prefs TGUI"
    set category = "Debug"
    if(prefs)
        prefs.ui_interact(mob)

/**
 * Bitfield toggle allow-list (O5).
 *
 * Keyed by `/datum/preferences` field name; value is the OR of every
 * bit the TGUI layer is permitted to flip on that field. Any other
 * bit in a toggle_bitfield ui_act envelope is dropped silently.
 *
 * Security: this is the only gate on toggle_bitfield — the ui_act
 * handler XORs the requested mask into vars[field] without further
 * validation, so the mask MUST be pre-filtered here.
 */
GLOBAL_LIST_INIT(prefs_bitfield_allowed_masks, list(
	"toggles" = (SOUND_ADMINHELP | SOUND_MIDI | SOUND_AMBIENCE | SOUND_LOBBY | MEMBER_PUBLIC | SOUND_INSTRUMENTS | SOUND_SHIP_AMBIENCE | SOUND_PRAYERS | SOUND_ANNOUNCEMENTS),
	"chat_toggles" = (CHAT_OOC | CHAT_DEAD | CHAT_GHOSTEARS | CHAT_GHOSTSIGHT | CHAT_PRAYER),
	"floating_text_toggles" = (FLOATING_TEXT | XP_TEXT),
))

/datum/preferences/proc/_prefs_toggle_bitfield_allowed(field, mask)
	if(!istext(field) || !isnum(mask))
		return FALSE
	var/allowed = GLOB.prefs_bitfield_allowed_masks[field]
	if(!allowed)
		return FALSE
	// Mask must be a single bit OR a subset of the allow-list for the
	// field. Requiring a subset lets a future TSX widget flip multiple
	// related bits in one envelope (e.g. a "mute all sounds" button).
	return (mask & ~allowed) ? FALSE : TRUE
