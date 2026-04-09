/datum/jelly_prefs
	/// Reference back to the owning preferences datum.
	var/datum/preferences/prefs
	/// Display name shown to jelly wearers when previewing this volunteer.
	var/jelly_name
	/// Pronouns shown on the volunteer card.
	var/jelly_pronouns = THEY_THEM
	/// Physical/descriptive flavor text shown to prospective wearers.
	var/jelly_flavortext
	/// OOC notes shown to prospective wearers.
	var/jelly_ooc_notes

/datum/jelly_prefs/New(datum/preferences/passed_prefs)
	. = ..()
	prefs = passed_prefs

/datum/jelly_prefs/proc/get_pronoun_display()
	var/list/pronoun_display = list(
		HE_HIM = "he/him",
		SHE_HER = "she/her",
		THEY_THEM = "they/them",
		IT_ITS = "it/its"
	)
	return pronoun_display[jelly_pronouns] ? pronoun_display[jelly_pronouns] : "they/them"

/datum/jelly_prefs/proc/get_rendered_text(raw_text)
	if(!raw_text)
		return null
	var/rendered = html_encode(parsemarkdown_basic(raw_text))
	rendered = replacetext(rendered, "\n", "<BR>")
	return rendered

/datum/jelly_prefs/proc/is_profile_ready()
	return !!(prefs?.jelly_controller_enabled && jelly_name && jelly_flavortext)

/datum/jelly_prefs/proc/jelly_show_ui()
	var/client/client = prefs?.parent
	if(!client)
		return

	var/list/dat = list()
	var/enabled_text = prefs?.jelly_controller_enabled ? "Enabled" : "Disabled"
	var/obj/item/intimate_accessory/jelly/eora/strange/active_application = get_jelly_controller_application_target(client)

	dat += "<div align='center'><font size=4 color='#bbbbbb'>Ooze Spirit Vessel</font></div>"
	dat += "<br><b>Role Offers:</b> [enabled_text]"
	dat += "<br><b>Display Name:</b> <a href='?_src_=jelly_prefs;preference=jelly_name;task=input'>[jelly_name ? jelly_name : "Unset"]</a>"
	dat += "<br><b>Pronouns:</b> <a href='?_src_=jelly_prefs;preference=jelly_pronouns;task=select'>[get_pronoun_display()]</a>"
	dat += "<br><b>Flavortext:</b> <a href='?_src_=jelly_prefs;preference=jelly_flavortext;task=input'>Change</a>"
	dat += "<br><b>OOC Notes:</b> <a href='?_src_=jelly_prefs;preference=jelly_ooc_notes;task=input'>Change</a>"
	if(is_profile_ready())
		dat += "<br><span class='notice'>Your vessel is prepared — the ooze may call upon you.</span>"
	else
		dat += "<br><span class='warning'>Set your name and descriptive flavortext, and enable Ooze Spirit Offers, before answering the call.</span>"
	if(active_application)
		dat += "<br><b>Current Petition:</b> [active_application.get_controller_application_target_label()]"
		dat += "<br><a href='?_src_=jelly_prefs;preference=jelly_application;task=withdraw'>Withdraw Petition</a>"
	else
		dat += "<br><b>Current Petition:</b> None"
		dat += "<br><a href='?_src_=jelly_prefs;preference=jelly_application;task=browse'>Seek an Ooze</a>"

	var/datum/browser/popup = new(client?.mob, "Jelly Controller Preferences", "<center>Ooze Spirit Preferences</center>", 360, 360)
	popup.set_window_options("can_close=1")
	popup.set_content(dat.Join())
	popup.open(FALSE)

/datum/jelly_prefs/proc/jelly_process_link(mob/user, list/href_list)
	if(!user)
		return

	var/task = href_list["task"]
	switch(href_list["preference"])
		if("jelly_name")
			var/new_name = input(user, "Choose the name whispered through the ooze:", "Spirit Name", jelly_name) as text|null
			if(new_name)
				new_name = reject_bad_name(new_name)
				if(new_name)
					jelly_name = new_name
					to_chat(user, span_notice("Spirit name set to [new_name]."))
				else
					to_chat(user, "<font color='red'>Invalid name. Your name should be at least 2 and at most [MAX_NAME_LEN] characters long. It may only contain the characters A-Z, a-z, -, ', . and ,.</font>")
		if("jelly_pronouns")
			var/list/pronoun_options = list(
				"he/him" = HE_HIM,
				"she/her" = SHE_HER,
				"they/them" = THEY_THEM,
				"it/its" = IT_ITS
			)
			var/choice = input(user, "Select the pronouns for your spirit vessel:", "Pronouns") as null|anything in pronoun_options
			if(choice)
				jelly_pronouns = pronoun_options[choice]
				to_chat(user, span_notice("Spirit pronouns set to [choice]."))
		if("jelly_flavortext")
			to_chat(user, span_notice("Describe the presence, demeanor, and aura you wish a host to perceive. Keep it evocative rather than backstory-heavy."))
			var/new_flavortext = input(user, "Describe the spirit the ooze reveals:", "Spirit Flavortext", jelly_flavortext) as message|null
			if(new_flavortext == null)
				return
			if(new_flavortext == "")
				jelly_flavortext = null
				jelly_show_ui()
				return
			jelly_flavortext = new_flavortext
			to_chat(user, span_notice("Successfully updated spirit flavortext."))
			log_game("[user] updated their jelly controller flavortext.")
		if("jelly_ooc_notes")
			var/new_ooc_notes = input(user, "Any OOC notes a host should know before welcoming you:", "OOC Notes", jelly_ooc_notes) as message|null
			if(new_ooc_notes == null)
				return
			if(new_ooc_notes == "")
				jelly_ooc_notes = null
				jelly_show_ui()
				return
			jelly_ooc_notes = new_ooc_notes
			to_chat(user, span_notice("Successfully updated spirit OOC notes."))
			log_game("[user] updated their jelly controller OOC notes.")
		if("jelly_application")
			if(task == "browse")
				show_open_jelly_application_browser(user)
				return
			if(task == "withdraw")
				var/obj/item/intimate_accessory/jelly/eora/strange/active_application = get_jelly_controller_application_target(user.client)
				if(active_application)
					active_application.withdraw_controller_application(user.client)

	if(user.client)
		prefs?.save_preferences()
		jelly_show_ui()

/proc/show_open_jelly_application_browser(mob/user)
	if(!user?.client)
		return FALSE
	if(!user.client.prefs?.jelly_controller_enabled)
		to_chat(user, span_warning("Enable Ooze Spirit Offers in ERP Preferences before answering the call."))
		return FALSE

	var/datum/jelly_prefs/pref = user.client.prefs?.jelly_prefs
	if(!pref?.is_profile_ready())
		to_chat(user, span_warning("Set your spirit name and flavortext before answering the call."))
		return FALSE

	var/list/open_jellies = list()
	for(var/obj/item/intimate_accessory/jelly/eora/strange/jelly in GLOB.open_jelly_controller_applications)
		if(!jelly || QDELETED(jelly))
			continue
		if(!jelly.is_accepting_controller_applications())
			jelly.sync_controller_application_listing()
			continue
		if(user.client.ckey == jelly.wearer?.ckey)
			continue
		var/base_label = jelly.get_controller_application_target_label()
		var/label = base_label
		var/duplicate_index = 2
		while(open_jellies[label])
			label = "[base_label] #[duplicate_index]"
			duplicate_index++
		open_jellies[label] = jelly

	if(!open_jellies.len)
		to_chat(user, span_notice("No oozes are presently calling for a spirit."))
		return FALSE

	var/choice = input(user, "Choose an ooze to offer yourself to:", "Open Oozes") as null|anything in open_jellies
	if(!choice)
		return FALSE

	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = open_jellies[choice]
	if(!jelly || QDELETED(jelly) || !jelly.is_accepting_controller_applications())
		to_chat(user, span_warning("That ooze is no longer calling for a spirit."))
		return FALSE
	if(alert(user, "Offer yourself to [jelly.get_controller_application_target_label()]?", "Answer the Call", "Offer", "Cancel") != "Offer")
		return FALSE
	return jelly.submit_controller_application(user.client)

/proc/show_jelly_candidate_preview(mob/user, datum/jelly_prefs/pref, mob/candidate_mob)
	if(!user || !pref)
		return

	var/list/dat = list()
	var/title = pref.jelly_name ? pref.jelly_name : "Nameless Spirit"
	var/status = "Drifting spirit"
	if(candidate_mob)
		if(isnewplayer(candidate_mob))
			status = "Spirit at the threshold"
		else if(isobserver(candidate_mob))
			status = "Drifting spirit"
		else if(ishuman(candidate_mob))
			status = "Embodied spirit"
		else
			status = "Spirit"

	dat += "<div align='center'><font size=5 color='#dddddd'><b>[title]</b></font></div>"
	dat += "<div align='center'><font size=3 color='#bbbbbb'>[pref.get_pronoun_display()]</font></div>"
	dat += "<div align='center'><font size=3 color='#bbbbbb'>[status]</font></div>"

	var/flavor = pref.get_rendered_text(pref.jelly_flavortext)
	if(flavor)
		dat += "<br><div align='left'>[flavor]</div>"

	var/ooc_notes = pref.get_rendered_text(pref.jelly_ooc_notes)
	if(ooc_notes)
		dat += "<br><div align='center'><b>OOC notes</b></div>"
		dat += "<div align='left'>[ooc_notes]</div>"

	var/datum/browser/popup = new(user, "Jelly Volunteer Inspect", nwidth = 520, nheight = 640)
	popup.set_content(dat.Join("\n"))
	popup.open(FALSE)
