/**
 * preferences_erp_preview_tokens.dm - Per-character local preview token profile.
 *
 * Preview profile data is only for TGUI live previews in ERP text editors.
 * Runtime output still resolves from real mobs. custom_anatomy_tokens is the
 * shared per-character runtime override map used by both custom sex and
 * intimate reaction token resolution.
 */

/datum/preferences/var/list/erp_preview_tokens = null
/datum/preferences/var/list/custom_anatomy_tokens = null

/proc/get_default_erp_preview_tokens()
	var/list/profile = list(
		"user_name" = "Wearer",
		"user_they" = "they",
		"user_them" = "them",
		"user_their" = "their",
		"target_preset" = "john",
		"target_name" = "John Ratwood",
		"target_they" = "he",
		"target_them" = "him",
		"target_their" = "his",
		"penis_type" = "knotted cock",
		"sheath" = "sheath",
		"size_adj" = "heavy",
		"cock_size" = "thick, aching cock",
		"vag_adj" = "slick",
		"vag_type" = "furred cunt",
		"cup_adj" = "generous",
		"cup_size" = "generous breasts",
		"breast_type" = "soft pair of breasts",
		"taur" = "taur body",
		"genital_desc" = "aroused body",
		"user_cock" = "knotted cock",
		"user_shaft" = "knotted shaft",
		"user_size" = "impressive",
		"user_vag" = "delicate slit",
		"user_cup_size" = "plump",
		"user_breast_type" = "perky pair of breasts",
		"target_cock" = "barbed cock",
		"target_shaft" = "barbed shaft",
		"target_size" = "modest",
		"target_vag" = "glistening slit",
		"target_cup_size" = "ample",
		"target_breast_type" = "heavy breasts",
		"target_taur" = "none",
		"force" = "firmly",
		"plug" = "plug",
	)
	return profile

/proc/get_erp_preview_token_keys()
	return list(
		"user_name", "user_they", "user_them", "user_their",
		"target_preset", "target_name", "target_they", "target_them", "target_their",
		"penis_type", "sheath", "size_adj", "cock_size",
		"vag_adj", "vag_type", "cup_adj", "cup_size", "breast_type",
		"taur", "genital_desc",
		"user_cock", "user_shaft", "user_size", "user_vag", "user_cup_size", "user_breast_type",
		"target_cock", "target_shaft", "target_size", "target_vag", "target_cup_size", "target_breast_type", "target_taur",
		"force", "plug",
	)

/proc/sanitize_erp_preview_token_value(value)
	if(!istext(value))
		return null
	return strip_html_simple(sanitize_simple(copytext(value, 1, 96)))

/proc/get_custom_anatomy_token_keys()
	return list("cock", "shaft", "size", "vag", "cup_size", "breast_type")

/proc/sanitize_custom_anatomy_token_value(value)
	if(!istext(value))
		return null
	return strip_html_simple(sanitize_simple(html_decode(copytext(value, 1, 97))))

/datum/preferences/proc/validate_custom_anatomy_tokens()
	if(!islist(custom_anatomy_tokens))
		custom_anatomy_tokens = null
		return

	var/list/valid_keys = get_custom_anatomy_token_keys()
	var/list/validated = list()
	for(var/key in valid_keys)
		var/value = sanitize_custom_anatomy_token_value(custom_anatomy_tokens[key])
		if(!value || !length(value))
			continue
		validated[key] = value
	custom_anatomy_tokens = length(validated) ? validated : null

/datum/preferences/proc/get_custom_anatomy_tokens()
	validate_custom_anatomy_tokens()
	return islist(custom_anatomy_tokens) ? custom_anatomy_tokens : list()

/datum/preferences/proc/get_custom_anatomy_token(key)
	if(!(key in get_custom_anatomy_token_keys()))
		return null
	validate_custom_anatomy_tokens()
	if(!islist(custom_anatomy_tokens))
		return null
	return custom_anatomy_tokens[key]

/datum/preferences/proc/set_custom_anatomy_token(key, value)
	if(!(key in get_custom_anatomy_token_keys()))
		return FALSE
	var/clean_value = sanitize_custom_anatomy_token_value(value)
	if(!clean_value || !length(clean_value))
		return clear_custom_anatomy_token(key)
	if(!islist(custom_anatomy_tokens))
		custom_anatomy_tokens = list()
	custom_anatomy_tokens[key] = clean_value
	return TRUE

/datum/preferences/proc/clear_custom_anatomy_token(key)
	if(!(key in get_custom_anatomy_token_keys()))
		return FALSE
	if(islist(custom_anatomy_tokens))
		custom_anatomy_tokens.Remove(key)
		if(!length(custom_anatomy_tokens))
			custom_anatomy_tokens = null
	return TRUE

/proc/get_default_custom_anatomy_token(mob/living/carbon/human/owner, key)
	if(!owner)
		return "none"

	var/obj/item/organ/penis/penis = owner.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/organ/vagina/vagina = owner.getorganslot(ORGAN_SLOT_VAGINA)
	var/obj/item/organ/breasts/breasts = owner.getorganslot(ORGAN_SLOT_BREASTS)
	switch(key)
		if("cock", "shaft")
			if(penis)
				return get_penis_type_label(penis.penis_type)
		if("size")
			if(penis)
				return _penis_size_adjective(penis.penis_size)
		if("vag")
			if(vagina)
				return _vagina_type_descriptor(vagina.accessory_type)
		if("cup_size")
			if(breasts)
				return _breast_size_adjective(breasts.breast_size)
		if("breast_type")
			if(breasts)
				return _breast_type_descriptor(breasts.accessory_type, breasts.breast_size)
	return "none"

/proc/resolve_custom_anatomy_token(mob/living/carbon/human/owner, key, mode = CUSTOM_ANATOMY_TOKEN_BARE, fallback_value = null, datum/preferences/prefs = null)
	var/resolved_text = null
	var/datum/preferences/source_prefs = prefs || owner?.client?.prefs
	if(source_prefs)
		resolved_text = source_prefs.get_custom_anatomy_token(key)
	if(!istext(resolved_text) || !length(trim(resolved_text)))
		resolved_text = istext(fallback_value) ? fallback_value : get_default_custom_anatomy_token(owner, key)
	if(!istext(resolved_text))
		return "none"

	var/trimmed_text = trim(resolved_text)
	if(!length(trimmed_text) || trimmed_text == "none")
		return trimmed_text

	switch(mode)
		if(CUSTOM_ANATOMY_TOKEN_SECOND_PERSON)
			return "your [trimmed_text]"
		if(CUSTOM_ANATOMY_TOKEN_POSSESSIVE)
			return "[owner ? owner.p_their() : "their"] [trimmed_text]"
	return trimmed_text

/datum/preferences/proc/validate_erp_preview_tokens()
	if(!islist(erp_preview_tokens))
		erp_preview_tokens = null
		return
	var/list/defaults = get_default_erp_preview_tokens()
	var/list/valid_keys = get_erp_preview_token_keys()
	var/list/validated = list()
	for(var/key in valid_keys)
		var/value = sanitize_erp_preview_token_value(erp_preview_tokens[key])
		if(!value || !length(value))
			value = defaults[key]
		validated[key] = value
	erp_preview_tokens = validated
	_apply_erp_preview_target_preset(erp_preview_tokens["target_preset"])

/datum/preferences/proc/get_erp_preview_tokens()
	if(!islist(erp_preview_tokens))
		return get_default_erp_preview_tokens()
	validate_erp_preview_tokens()
	return erp_preview_tokens

/datum/preferences/proc/set_erp_preview_token(key, value)
	if(!(key in get_erp_preview_token_keys()))
		return FALSE
	if(key == "target_preset")
		return _apply_erp_preview_target_preset(value)
	var/clean_value = sanitize_erp_preview_token_value(value)
	if(!clean_value || !length(clean_value))
		return FALSE
	if(!islist(erp_preview_tokens))
		erp_preview_tokens = get_default_erp_preview_tokens()
	erp_preview_tokens[key] = clean_value
	return TRUE

/datum/preferences/proc/_apply_erp_preview_target_preset(preset)
	if(!(preset in list("john", "jane", "jean")))
		preset = "john"
	if(!islist(erp_preview_tokens))
		erp_preview_tokens = get_default_erp_preview_tokens()
	erp_preview_tokens["target_preset"] = preset
	switch(preset)
		if("jane")
			erp_preview_tokens["target_name"] = "Jane Ratwood"
			erp_preview_tokens["target_they"] = "she"
			erp_preview_tokens["target_them"] = "her"
			erp_preview_tokens["target_their"] = "her"
		if("jean")
			erp_preview_tokens["target_name"] = "Jean Ratwood"
			erp_preview_tokens["target_they"] = "they"
			erp_preview_tokens["target_them"] = "them"
			erp_preview_tokens["target_their"] = "their"
		else
			erp_preview_tokens["target_name"] = "John Ratwood"
			erp_preview_tokens["target_they"] = "he"
			erp_preview_tokens["target_them"] = "him"
			erp_preview_tokens["target_their"] = "his"
	return TRUE

/datum/preferences/proc/refresh_erp_preview_tokens_from_preferences()
	var/list/existing = islist(erp_preview_tokens) ? erp_preview_tokens.Copy() : get_default_erp_preview_tokens()
	var/list/profile = get_default_erp_preview_tokens()
	for(var/key in profile)
		if(copytext(key, 1, 8) == "target_" || (key in list("force", "plug")))
			if(existing[key])
				profile[key] = existing[key]
	profile["user_name"] = real_name || profile["user_name"]

	var/p_they = "they"
	var/p_them = "them"
	var/p_their = "their"
	switch(pronouns)
		if(HE_HIM, HE_HIM_F)
			p_they = "he"
			p_them = "him"
			p_their = "his"
		if(SHE_HER, SHE_HER_M)
			p_they = "she"
			p_them = "her"
			p_their = "her"
		if(IT_ITS)
			p_they = "it"
			p_them = "it"
			p_their = "its"
	profile["user_they"] = p_they
	profile["user_them"] = p_them
	profile["user_their"] = p_their

	var/penis_type_label = "none"
	var/cocksize_label = "none"
	var/sizeadj_label = "none"
	var/sheath_label = "none"
	var/datum/customizer_entry/organ/penis/pe = get_customizer_entry_of_type(/datum/customizer_entry/organ/penis)
	if(pe && !pe.disabled && pe.customizer_choice_type)
		var/datum/customizer_choice/organ/penis/choice = CUSTOMIZER_CHOICE(pe.customizer_choice_type)
		if(choice)
			var/organ_path = choice.organ_type
			penis_type_label = get_penis_type_label(initial(organ_path:penis_type))
			cocksize_label = _penis_size_descriptor(pe.penis_size)
			sizeadj_label = _penis_size_adjective(pe.penis_size)
			switch(initial(organ_path:sheath_type))
				if(SHEATH_TYPE_NORMAL)
					sheath_label = "sheath"
				if(SHEATH_TYPE_SLIT)
					sheath_label = "genital slit"
	profile["penis_type"] = penis_type_label
	profile["cock_size"] = cocksize_label
	profile["size_adj"] = sizeadj_label
	profile["sheath"] = sheath_label
	profile["user_cock"] = penis_type_label
	profile["user_shaft"] = penis_type_label
	profile["user_size"] = sizeadj_label

	var/cup_label = "none"
	var/cup_short_label = "none"
	var/cupadj_label = "none"
	var/breast_type_label = "none"
	var/datum/customizer_entry/organ/breasts/be = get_customizer_entry_of_type(/datum/customizer_entry/organ/breasts)
	if(be && !be.disabled)
		cup_label = _breast_size_descriptor(be.breast_size)
		cup_short_label = find_key_by_value(GLOB.named_breast_sizes, be.breast_size) || "unknown"
		cupadj_label = _breast_size_adjective(be.breast_size)
		breast_type_label = _breast_type_descriptor(be.accessory_type, be.breast_size)
	profile["cup_size"] = cup_label
	profile["cup_adj"] = cupadj_label
	profile["breast_type"] = breast_type_label
	profile["user_cup_size"] = cupadj_label
	profile["user_breast_type"] = breast_type_label

	var/vagtype_label = "none"
	var/vagadj_label = "none"
	var/datum/customizer_entry/organ/vagina/ve = get_customizer_entry_of_type(/datum/customizer_entry/organ/vagina)
	if(ve && !ve.disabled)
		vagtype_label = _vagina_type_descriptor(ve.accessory_type)
		vagadj_label = _vagina_type_adjective(ve.accessory_type)
	profile["vag_type"] = vagtype_label
	profile["vag_adj"] = vagadj_label
	profile["user_vag"] = vagtype_label

	var/taur_label = "none"
	if(taur_type)
		taur_label = initial(taur_type:name)
	profile["taur"] = taur_label

	var/genital_desc = "smooth groin"
	if(penis_type_label != "none" && cup_short_label != "none")
		genital_desc = "[penis_type_label] and [cup_short_label] chest"
	else if(penis_type_label != "none")
		genital_desc = penis_type_label
	else if(vagtype_label != "none")
		if(cup_short_label != "none")
			genital_desc = "slit and [cup_short_label] chest"
		else
			genital_desc = "slit"
	else if(cup_short_label != "none")
		genital_desc = "[cup_short_label] chest"
	profile["genital_desc"] = genital_desc

	erp_preview_tokens = profile
	_apply_erp_preview_target_preset(erp_preview_tokens["target_preset"])
	return TRUE
