/mob/living/carbon/proc/carbon_modular_examine_extension(mob/user, t_He, m1, m2, m3)
	var/list/lines = list()
	if(sexcon?.has_chastity_cage() && get_location_accessible(src, BODY_ZONE_PRECISE_GROIN))
		lines += "[t_He] is wearing a chastity device!\n"
	return lines

/mob/living/carbon/human/proc/human_modular_examine_extension(mob/user, observer_privilege, m1, m2, m3)
	var/list/lines = list()
	var/perception_level = 15
	if(user != src && isliving(user))
		var/mob/living/L = user
		perception_level = L.STAPER

	var/obj/item/chastity/worn_chastity = chastity_device
	if(worn_chastity)
		var/cage_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(cage_exposed || (user != src && perception_level >= 15))
			if(perception_level >= 15)
				var/chastity_msg = cage_exposed ? "[m1] secured in a [worn_chastity.name]." : "[m1] wearing a chastity device under [m2] clothes."
				lines += span_aiprivradio(chastity_msg)
			else if(perception_level >= 8)
				lines += span_aiprivradio("[m1] wearing a [worn_chastity.name].")
			else
				lines += span_warning("[m1] wearing some kind of intimate restraint.")

	var/obj/item/intimate_accessory/rear/plug/worn_plug = intimate_rear
	if(worn_plug)
		var/plug_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(plug_exposed || (user != src && perception_level >= 15))
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
		if(piercing_exposed || (user != src && perception_level >= 15))
			if(perception_level >= 15)
				var/piercing_msg = piercing_exposed ? "[m1] wearing [worn_breast_piercing.name]." : "[m1] wearing nipple piercings under [m2] clothes."
				lines += span_aiprivradio(piercing_msg)
			else if(perception_level >= 8)
				lines += span_aiprivradio("[m1] wearing [worn_breast_piercing.name].")
			else
				lines += span_warning("[m1] nipples are pierced!")

	var/obj/item/intimate_accessory/genital/plug/worn_genital_plug = intimate_genital
	if(worn_genital_plug)
		var/genital_plug_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(genital_plug_exposed || (user != src && perception_level >= 15))
			if(perception_level >= 15)
				var/genital_plug_msg = genital_plug_exposed ? "[m1] wearing a [worn_genital_plug.name]." : "[m1] wearing a vaginal plug under [m2] clothes."
				lines += span_aiprivradio(genital_plug_msg)
			else if(perception_level >= 8)
				lines += span_aiprivradio("[m1] wearing a [worn_genital_plug.name].")
			else
				lines += span_warning("[m1] has something tucked in their cunt!")

	var/obj/item/intimate_accessory/piercing/genital/worn_genital_piercing = intimate_genital
	if(worn_genital_piercing)
		var/genital_exposed = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(genital_exposed || (user != src && perception_level >= 15))
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

	// Append an examine link to open the intimate accessories panel when the
	// subject has any accessories and both parties have intimate content enabled.
	if(length(intimate_accessories))
		var/viewer_ok = !user.client?.prefs || user.client.prefs.chastenable
		var/wearer_ok = !client?.prefs || client.prefs.chastenable
		if(viewer_ok && wearer_ok)
			lines += span_notice("<a href='?src=[REF(src)];task=view_intimate'>View [m2] intimate accessories...</a>")

	return lines

/mob/living/carbon/human/proc/human_modular_chastity_toy_examine_line(mob/user, m2, m3)
	if(chastity_device?.attached_toy)
		return "[m3] [chastity_device.attached_toy.get_examine_string(user)] attached to [m2] chastity device. "
	return null
