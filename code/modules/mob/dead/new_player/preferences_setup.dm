
	//The mob should have a gender you want before running this proc. Will run fine without H
/datum/preferences/proc/random_character(gender_override, antag_override = FALSE, ft_reset = TRUE)
	if(!pref_species)
		random_species()
	real_name = pref_species.random_name(gender,1)
	if(gender_override)
		gender = gender_override
	else
		gender = pick(MALE,FEMALE)
	age = AGE_ADULT
	var/list/skins = pref_species.get_skin_list()
	skin_tone = skins[pick(skins)]
	eye_color = random_eye_color()
	if(ft_reset)
		flavortext = null
		nsfwflavortext = null
		ooc_extra_img = null
		ooc_extra_img_link = null
		nsfw_ooc_extra_img = null
		nsfw_ooc_extra_img_link = null
		erpprefs = null
		ooc_notes = null
		ooc_extra = null
		song_title = null
		song_artist = null
		headshot_link = null
		img_gallery = null
		nsfw_img_gallery = null
	features = pref_species.get_random_features()
	body_markings = pref_species.get_random_body_markings(features)
	accessory = "Nothing"
	bark_id = pick(GLOB.bark_random_list)
	bark_pitch = BARK_PITCH_RAND(gender)
	bark_variance = BARK_VARIANCE_RAND
	reset_all_customizer_accessory_colors()
	randomize_all_customizer_accessories()

/datum/preferences/proc/random_species()
	var/random_species_type = GLOB.species_list[pick(get_selectable_species())]
	pref_species = new random_species_type
	if(randomise[RANDOM_NAME])
		real_name = pref_species.random_name(gender,1)
	set_new_race(new random_species_type)

/datum/preferences/proc/update_preview_icon(jobOnly = FALSE)
	set waitfor = 0
	if(!parent)
		return
	if(parent.is_new_player())
		return
//	last_preview_update = world.time
	// Set up the dummy for its photoshoot
	var/datum/job/previewJob
	var/highest_pref = 0
	for(var/job in job_preferences)
		if(job_preferences[job] > highest_pref)
			previewJob = SSjob.GetJob(job)
			highest_pref = job_preferences[job]
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	copy_to(mannequin, 1, TRUE, TRUE)
	if(parent?.taur_genital_editor_instance && mannequin.sexcon)
		mannequin.sexcon.bottom_exposed = TRUE

	if(jobOnly)
		mannequin.job = previewJob.title
		previewJob.equip(mannequin, TRUE, preference_source = parent)

	if(preview_subclass && !jobOnly)
		testing("previewjob")
		mannequin.job = previewJob.title
		mannequin.patron = selected_patron
		preview_subclass.equipme(mannequin, dummy = TRUE)

	// Apply arousal preview state to the mannequin's penis organ so players can
	// verify genital sprite alignment at different erection levels from the lobby.
	// v2 editor note: the taur genital editor no longer mirrors its active arousal
	// tab to the lobby mannequin live -- its preview is self-contained and the
	// mannequin only reflects the baseline `preview_erect_state` set by the
	// character-preview controls.
	var/obj/item/organ/penis/preview_penis = mannequin.getorganslot(ORGAN_SLOT_PENIS)
	if(preview_penis)
		preview_penis.erect_state = preview_erect_state

	mannequin.regenerate_clothes()
	mannequin.update_body()
	mannequin.update_hair()
	// Redraw bodyparts so features applied after the copy_to() icon pass
	// (chastity devices, intimate accessories, etc.) are included in the snapshot.
	mannequin.update_body_parts(redraw = TRUE)
	mannequin.rebuild_obscured_flags()
	parent.show_character_previews(new /mutable_appearance(mannequin))
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	// Ensure the view exists and its dummy reflects the just-saved prefs.
	// create_character_preview_view is idempotent and runs an initial
	// update_body(), which emits COMSIG_PREFS_PREVIEW_UPDATED so any
	// already-attached lobby HUD refreshes automatically.
	var/atom/movable/screen/map_view/char_preview/view = character_preview_view
	if(!view || QDELETED(view))
		view = create_character_preview_view(parent)
	else
		view.update_body()
	// Attach (or refresh) the passive 4-cardinal observer on the lobby HUD.
	parent.show_character_previews_from_view(src)
#endif


/datum/preferences/proc/spec_check(mob/user)
	if(!istype(pref_species))
		return FALSE
	if(!(pref_species.name in get_selectable_species()))
		return FALSE
	if(!pref_species.check_roundstart_eligible())
		return FALSE
	if(user && (pref_species.patreon_req > user.patreonlevel()))
		return FALSE
	return TRUE

/mob/proc/patreonlevel()
	if(client)
		return client.patreonlevel()
