/mob/living/carbon/proc/carbon_modular_examine_extension(mob/user, t_He, m1, m2, m3)
	var/list/lines = list()
	if(sexcon?.has_chastity_cage() && get_location_accessible(src, BODY_ZONE_PRECISE_GROIN))
		lines += "[t_He] is wearing a chastity device!\n"
	return lines

/mob/living/carbon/human/proc/human_modular_examine_extension(mob/user, observer_privilege, m1, m2, m3)
	var/list/lines = list()
	var/user_is_gnoll = FALSE
	var/user_is_clergy = FALSE
	var/user_is_inquisition = FALSE
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		user_is_gnoll = H.dna?.species?.id == "gnoll"
		user_is_inquisition = HAS_TRAIT(H, TRAIT_INQUISITION) || (H.mind?.assigned_role in GLOB.inquisition_positions)
		user_is_clergy = user_is_inquisition || (H.mind?.assigned_role in GLOB.church_positions)
		if(user_is_gnoll)
			var/datum/antagonist/gnoll/gnoll_antag = H.mind?.has_antag_datum(/datum/antagonist/gnoll)
			if(gnoll_antag?.is_examine_marked_target(src))
				lines += span_cultsmall("Graggar has marked them!")
			if(src.has_gnoll_scent_this_round)
				lines += span_cultsmall("They have gnoll scent, a breeder!")
	if(src.has_gnoll_scent_this_round && !user_is_gnoll)
		if(user_is_inquisition)
			lines += span_warning("They reek of profane beast-taint. This demands scrutiny.")
		else if(user_is_clergy)
			lines += span_warning("A profane, feral scent clings to them.")
		else
			lines += span_warning("They have a strange scent about them...")
	var/perception_level = 15
	if(isliving(user))
		var/mob/living/L = user
		perception_level = L.STAPER

	// If the wearer has show_intimate_examine disabled, high-perception through-clothes detection
	// is suppressed — only physically exposed accessories are shown.
	var/wearer_allows_intimate = !client?.prefs || client.prefs.show_intimate_examine

	var/obj/item/chastity/worn_chastity = chastity_device
	if(worn_chastity)
		var/chastity_name = get_examine_item_name_with_custom_link(user, worn_chastity)
		var/cage_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(cage_exposed || (wearer_allows_intimate && user != src && perception_level >= 15))
			if(perception_level >= 15)
				lines += span_aiprivradio("[m1] secured in [chastity_name].")
			else if(perception_level >= 8)
				lines += span_aiprivradio("[m1] wearing [chastity_name].")
			else
				lines += span_warning("[m1] wearing some kind of intimate restraint.")

	var/obj/item/intimate_accessory/rear/plug/worn_plug = intimate_rear
	if(worn_plug)
		var/plug_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(plug_exposed || (wearer_allows_intimate && user != src && perception_level >= 15))
			if(perception_level >= 15)
				var/plug_msg = plug_exposed ? "[m1] wearing a [worn_plug.name]." : "[m1] wearing a buttplug under [m2] clothes."
				lines += span_aiprivradio(plug_msg)
			else if(perception_level >= 8)
				lines += span_aiprivradio("[m1] wearing a [worn_plug.name].")
			else
				lines += span_warning("[m1] shoved something up their butt!")

	var/obj/item/intimate_accessory/piercing/breast/worn_breast_piercing = intimate_breast
	if(worn_breast_piercing)
		var/piercing_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_CHEST)
		if(piercing_exposed || (wearer_allows_intimate && user != src && perception_level >= 15))
			if(perception_level >= 15)
				var/piercing_msg = piercing_exposed ? "[m1] wearing [worn_breast_piercing.name]." : "[m1] wearing nipple piercings under [m2] clothes."
				lines += span_aiprivradio(piercing_msg)
			else if(perception_level >= 8)
				lines += span_aiprivradio("[m1] wearing [worn_breast_piercing.name].")
			else
				lines += span_warning("[m1] nipples are pierced!")

	// Genital slot — could be a plug OR a piercing; use istype to avoid double display.
	if(intimate_genital)
		var/genital_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(genital_exposed || (wearer_allows_intimate && user != src && perception_level >= 15))
			if(istype(intimate_genital, /obj/item/intimate_accessory/genital/plug))
				var/obj/item/intimate_accessory/genital/plug/worn_genital_plug = intimate_genital
				if(perception_level >= 15)
					var/genital_plug_msg = genital_exposed ? "[m1] wearing a [worn_genital_plug.name]." : "[m1] wearing a vaginal plug under [m2] clothes."
					lines += span_aiprivradio(genital_plug_msg)
				else if(perception_level >= 8)
					lines += span_aiprivradio("[m1] wearing a [worn_genital_plug.name].")
				else
					lines += span_warning("[m1] has something tucked in their cunt!")
			else if(istype(intimate_genital, /obj/item/intimate_accessory/piercing/genital))
				var/obj/item/intimate_accessory/piercing/genital/worn_genital_piercing = intimate_genital
				if(perception_level >= 15)
					var/genital_msg = genital_exposed ? "[m1] wearing [worn_genital_piercing.name]." : "[m1] wearing genital piercings under [m2] clothes."
					lines += span_aiprivradio(genital_msg)
				else if(perception_level >= 8)
					lines += span_aiprivradio("[m1] wearing [worn_genital_piercing.name].")
				else
					lines += span_warning("[m1] privates are pierced!")

	var/obj/item/intimate_accessory/piercing/tongue/worn_tongue_piercing = intimate_mouth
	if(worn_tongue_piercing)
		var/mouth_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_MOUTH)
		if(mouth_exposed)
			lines += span_notice("[m1] wearing [worn_tongue_piercing.name].")

	// Append an examine link to open the intimate accessories panel when:
	//   • the subject has accessories worn
	//   • both parties have intimate accessories enabled
	//   • the wearer has opted in to showing the link (show_intimate_examine)
	if(length(intimate_accessories))
		var/viewer_ok = !user.client?.prefs || user.client.prefs.intimate_enabled
		var/wearer_ok = !client?.prefs || (client.prefs.intimate_enabled && client.prefs.show_intimate_examine)
		if(viewer_ok && wearer_ok)
			lines += span_notice("<a href='?src=[REF(src)];task=view_intimate'>View [m2] intimate accessories...</a>")

	return lines

/mob/living/carbon/human/proc/human_modular_chastity_toy_examine_line(mob/user, m2, m3)
	if(!chastity_device?.attached_toy)
		return null
	var/perception_level = 15
	if(isliving(user))
		var/mob/living/L = user
		perception_level = L.STAPER
	if(!isobserver(user) && !get_location_accessible(src, BODY_ZONE_PRECISE_GROIN))
		return null
	if(!isobserver(user) && perception_level < 8)
		return null
	return "[m3] [get_examine_item_name_with_custom_link(user, chastity_device.attached_toy)] attached to [m2] chastity device. "
