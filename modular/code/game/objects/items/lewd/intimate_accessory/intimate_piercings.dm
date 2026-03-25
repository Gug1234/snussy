// Shared piercing base.
/obj/item/intimate_accessory/piercing
	name = "intimate piercing"
	desc = "Intimate piercing parent/SOT. If you see this report it as a bug, specifically scream at Yuckuza on Discord."
	icon_state = "breast_pierce_item"
	item_state = "breast_pierce_item"
	mob_overlay_icon = "breast_pierce_pair"
	var/item_base_state = "breast_pierce_item"
	var/item_gem_state = "breast_pierce_item_gem"
	var/piercing_region_name = "breast"
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	intimate_gem_color = null
	intimate_flags = INTIMATE_FLAG_PIERCING
	sellprice = 10
	// Reserved for future nudist support.
	//nudist_approved = TRUE

/obj/item/intimate_accessory/piercing/Initialize()
	. = ..()
	update_item_visuals()
	// Attach the piercing reaction component so movement jingles and sex-action flavor text fire automatically.
	// Each item carries its own component instance; COMPONENT_DUPE_ALLOW_ALL on the component subtype
	// allows nipple + genital + rear piercings to all operate concurrently on the same wearer.
	AddComponent(/datum/component/intimate_reaction/piercing)

/// Binds the reaction component to H after the slot reference and wearer var are set by the base finalize_intimate_equip.
/obj/item/intimate_accessory/piercing/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	var/datum/component/intimate_reaction/piercing/reaction = GetComponent(/datum/component/intimate_reaction/piercing)
	if(reaction)
		reaction.bind_to_wearer(H)

/// Unbinds the reaction component from H before slot refs are cleared by the base remove_intimate_accessory.
/obj/item/intimate_accessory/piercing/remove_intimate_accessory(mob/living/carbon/human/H)
	var/datum/component/intimate_reaction/piercing/reaction = GetComponent(/datum/component/intimate_reaction/piercing)
	if(reaction)
		reaction.unbind_from_wearer(H)
	return ..()

/obj/item/intimate_accessory/piercing/proc/finalize_piercing_initialize(initial_variant_name = null)
	if(initial_variant_name)
		name = initial_variant_name
	update_dynamic_name()
	update_sellprice()

/obj/item/intimate_accessory/piercing/proc/refresh_piercing_state()
	update_dynamic_name()
	update_sellprice()
	update_item_visuals()

/obj/item/intimate_accessory/piercing/proc/play_piercing_sound(mob/living/carbon/human/H, sound_file)
	if(H)
		playsound(H, sound_file, 35, TRUE, ignore_walls = FALSE)

/obj/item/intimate_accessory/piercing/proc/update_item_visuals()
	apply_intimate_item_tint()

	icon_state = item_base_state
	item_state = item_base_state
	cut_overlays()

	if(has_socketed_insert() && item_gem_state)
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, item_gem_state)
		if(intimate_gem_color)
			gem_overlay.color = intimate_gem_color
		add_overlay(gem_overlay)

	update_icon()

/obj/item/intimate_accessory/piercing/proc/get_metal_descriptor()
	if(!intimate_metal_name)
		return "metal"
	return lowertext(intimate_metal_name)

/obj/item/intimate_accessory/piercing/proc/update_dynamic_name()
	var/metal_descriptor = get_metal_descriptor()
	if(current_gem_descriptor)
		name = "[current_gem_descriptor]-set [metal_descriptor] [piercing_region_name] piercing"
	else
		name = "[metal_descriptor] [piercing_region_name] piercing"

/obj/item/intimate_accessory/piercing/proc/update_sellprice()
	var/base_price = initial(sellprice)
	sellprice = max(1, base_price + gem_value_bonus)

/obj/item/intimate_accessory/piercing/proc/get_voice_tint_color()
	if(!has_socketed_insert())
		return null
	if(!intimate_gem_color)
		return null
	// Human voice_color is stored as raw hex without '#'; keep that format.
	return sanitize_hexcolor(intimate_gem_color, 6, FALSE)

/obj/item/intimate_accessory/piercing/on_socket_state_changed(reason = "")
	refresh_piercing_state()
	return ..()

/obj/item/intimate_accessory/piercing/breast
	name = "steel nipple piercing"
	desc = "A set of bars for your tits."
	intimate_slot = INTIMATE_SLOT_BREAST
	sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_breast

/obj/item/intimate_accessory/piercing/breast/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] nipple piercing")

/obj/item/intimate_accessory/piercing/breast/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/breast/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && H.intimate_breast == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

// Metal variants for breast piercings.
/obj/item/intimate_accessory/piercing/breast/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/breast/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/breast/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/breast/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/breast/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/breast/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/breast/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// Genital piercing variants.
/obj/item/intimate_accessory/piercing/genital
	name = "steel genital piercing kit"
	desc = "A kit of various gem socketable piercings, popular among fops and whores who wish their bits be bedazzaled. Comes with bars, hoops, cock rings, and studs."
	icon_state = "genital_pierce_item"
	item_state = "genital_pierce_item"
	item_base_state = "genital_pierce_item"
	item_gem_state = "genital_pierce_item_gem"
	piercing_region_name = "genital"
	intimate_slot = INTIMATE_SLOT_GENITAL
	sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_genital
	intimate_flags = INTIMATE_FLAG_PIERCING | INTIMATE_FLAG_BERIDDLEABLE
	var/beriddled_desc = "A genital piercing kit infused with a riddle of steel. Even the slightest touch promises scandalous delight."

/obj/item/intimate_accessory/piercing/genital/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] genital piercing")
	update_beriddled_glow()

/obj/item/intimate_accessory/piercing/genital/update_dynamic_name()
	if(is_beriddled())
		name = "beriddled [get_metal_descriptor()] genital piercing"
		return
	return ..()

/obj/item/intimate_accessory/piercing/genital/proc/get_goodlover_trait_source()
	return "[TRAIT_SOURCE_INTIMATE]-beriddled_genital_piercing"

/obj/item/intimate_accessory/piercing/genital/proc/sync_beriddled_goodlover(mob/living/carbon/human/H = wearer)
	if(!H)
		return
	if(H.intimate_genital == src && is_beriddled())
		ADD_TRAIT(H, TRAIT_GOODLOVER, get_goodlover_trait_source())
		return
	REMOVE_TRAIT(H, TRAIT_GOODLOVER, get_goodlover_trait_source())

/obj/item/intimate_accessory/piercing/genital/proc/update_beriddled_glow()
	if(is_beriddled())
		set_light(2, 2, 1, l_color = "#ff0d0d")
	else
		set_light(0)

/obj/item/intimate_accessory/piercing/genital/on_beriddle_state_changed(new_state)
	if(!!new_state)
		desc = beriddled_desc
	else
		desc = initial(desc)
	update_beriddled_glow()
	sync_beriddled_goodlover()

/obj/item/intimate_accessory/piercing/genital/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	sync_beriddled_goodlover(H)
	update_beriddled_glow()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/genital/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H)
		REMOVE_TRAIT(H, TRAIT_GOODLOVER, get_goodlover_trait_source())
	if(H && H.intimate_genital == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

/obj/item/intimate_accessory/piercing/genital/on_socket_state_changed(reason = "")
	. = ..()
	sync_beriddled_goodlover()
	update_beriddled_glow()

/obj/item/intimate_accessory/piercing/genital/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/genital/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/genital/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/genital/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/genital/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/genital/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/genital/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

/obj/item/intimate_accessory/piercing/genital/psydonic
	name = "psydonic genital piercing"
	desc = "A genital piercing kit wrought in a psydonic style, its bedazzled lines arranged in quiet devotion. Even intimate pain seems to break upon it and pass."
	icon_state = "genital_pierce_item_psy"
	item_state = "genital_pierce_item_psy"
	item_base_state = "genital_pierce_item_psy"
	item_gem_state = null

/obj/item/intimate_accessory/piercing/genital/psydonic/Initialize()
	. = ..()
	finalize_piercing_initialize("psydonic genital piercing")

/obj/item/intimate_accessory/piercing/genital/psydonic/update_dynamic_name()
	if(is_beriddled())
		return ..()
	name = "psydonic genital piercing"

/obj/item/intimate_accessory/piercing/genital/zizite
	name = "zizite genital piercing"
	desc = "A genital piercing kit set with a fixed zcross and morbid beadwork. It carries the Dame of Progress's spite into the bedchamber."

/obj/item/intimate_accessory/piercing/genital/zizite/Initialize()
	. = ..()
	finalize_piercing_initialize("zizite genital piercing")

/obj/item/intimate_accessory/piercing/genital/zizite/update_dynamic_name()
	if(is_beriddled())
		return ..()
	name = "zizite genital piercing"

// Tongue piercings reuse base piercing behavior and add speech/socket hooks.
/obj/item/intimate_accessory/piercing/tongue
	name = "steel tongue piercing"
	desc = "An ostentatious tongue bar with a socket for a gem accent. For those who enjoy the taste of coinage alongside their meals."
	icon_state = "tongue_pierce_item"
	item_state = "tongue_pierce_item"
	item_base_state = "tongue_pierce_item"
	item_gem_state = "tongue_pierce_item_gem"
	piercing_region_name = "tongue"
	intimate_slot = INTIMATE_SLOT_MOUTH
	var/original_voice_color = null

/obj/item/intimate_accessory/piercing/tongue/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] tongue piercing")

/obj/item/intimate_accessory/piercing/tongue/proc/update_voice_color()
	if(!wearer)
		return

	var/desired_color = get_voice_tint_color()
	if(desired_color)
		if(!original_voice_color)
			original_voice_color = sanitize_hexcolor(wearer.voice_color, 6, FALSE)
		wearer.voice_color = sanitize_hexcolor(desired_color, 6, FALSE)
		return

	if(original_voice_color)
		wearer.voice_color = sanitize_hexcolor(original_voice_color, 6, FALSE)
	original_voice_color = null

/obj/item/intimate_accessory/piercing/tongue/proc/reset_voice_color(mob/living/carbon/human/H)
	if(H && original_voice_color)
		H.voice_color = original_voice_color
	original_voice_color = null

/obj/item/intimate_accessory/piercing/tongue/proc/can_use_tongue_piercing_action(mob/living/carbon/human/user)
	if(!user)
		return FALSE
	if(user.intimate_mouth != src)
		to_chat(user, span_warning("I need to be wearing [src] to do that."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/on_socket_state_changed(reason = "")
	. = ..()
	update_voice_color()

/obj/item/intimate_accessory/piercing/tongue/attach_intimate_feature(mob/living/carbon/human/H)
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	if(H)
		update_voice_color()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/tongue/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H)
		reset_voice_color(H)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

/obj/item/intimate_accessory/piercing/tongue/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/clothing/neck/roguetown/psicross) || istype(I, /obj/item/clothing/neck/roguetown/zcross/iron))
		return try_socket_cross(I, user)
	return ..()

/obj/item/intimate_accessory/piercing/tongue/proc/try_socket_cross(obj/item/cross, mob/living/user)
	if(!cross || !user)
		return FALSE

	if(wearer)
		to_chat(user, span_warning("I need to remove [src] before socketing a cross into it."))
		return TRUE

	if(has_socketed_insert())
		to_chat(user, span_warning("[src] already has something socketed in it."))
		return TRUE

	if(is_psydonic_socket_item(cross))
		return convert_to_psydonic(cross, user)

	if(is_zizite_socket_item(cross))
		return convert_to_zizite(cross, user)

	to_chat(user, span_warning("[cross] does not fit this tongue piercing's socket."))
	return TRUE

// Tongue cross socket validation and conversion helpers.
/obj/item/intimate_accessory/piercing/tongue/proc/is_zizite_socket_item(obj/item/I)
	if(!I)
		return FALSE

	return istype(I, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy) \
		|| istype(I, /obj/item/clothing/neck/roguetown/zcross/iron)

/obj/item/intimate_accessory/piercing/tongue/proc/get_zizite_socket_descriptor(obj/item/cross)
	if(!cross)
		return "zcross"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy))
		return "ancient zcross"
	return "iron zcross"

/obj/item/intimate_accessory/piercing/tongue/proc/get_zizite_socket_color(obj/item/cross)
	if(!cross)
		return "#9EA48E"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy))
		return "#BB9696"
	return "#9EA48E"

/obj/item/intimate_accessory/piercing/tongue/proc/get_zizite_metal_name(obj/item/cross) 
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy))
		return "avantyne"
	return "darksteel"

/obj/item/intimate_accessory/piercing/tongue/proc/convert_to_cross_variant(
	obj/item/cross,
	mob/living/user,
	variant_type,
	descriptor,
	gem_color,
	metal_name,
	reason,
	notice_message,
)
	if(!cross || !user || !variant_type)
		return FALSE

	var/obj/item/intimate_accessory/piercing/tongue/new_piercing = new variant_type(get_turf(src))
	new_piercing.socketed_item_type = cross.type
	new_piercing.current_gem_descriptor = descriptor
	new_piercing.intimate_gem_color = gem_color
	new_piercing.intimate_metal_name = metal_name
	new_piercing.intimate_metal_color = gem_color
	new_piercing.gem_value_bonus = max(0, cross.sellprice)
	new_piercing.on_socket_state_changed(reason)

	to_chat(user, span_notice(notice_message))
	playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)

	qdel(cross)
	if(!user.put_in_hands(new_piercing))
		new_piercing.forceMove(get_turf(user))
	qdel(src)
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/proc/convert_to_zizite(obj/item/cross, mob/living/user)
	if(!cross || !user)
		return FALSE

	return convert_to_cross_variant(
		cross,
		user,
		/obj/item/intimate_accessory/piercing/tongue/zizite,
		get_zizite_socket_descriptor(cross),
		get_zizite_socket_color(cross),
		get_zizite_metal_name(cross),
		"zizite_socketed",
		"I set [cross] into [src], the Dame of Progress reshaping it in HER image.",
	)

/obj/item/intimate_accessory/piercing/tongue/proc/is_psydonic_socket_item(obj/item/I)
	if(!I)
		return FALSE

	if(is_zizite_socket_item(I))
		return FALSE

	return istype(I, /obj/item/clothing/neck/roguetown/psicross) \
		|| istype(I, /obj/item/clothing/neck/roguetown/psicross/aalloy) \
		|| istype(I, /obj/item/clothing/neck/roguetown/psicross/silver) \
		|| istype(I, /obj/item/clothing/neck/roguetown/psicross/g)

/obj/item/intimate_accessory/piercing/tongue/proc/get_psydonic_socket_descriptor(obj/item/clothing/neck/roguetown/psicross/cross)
	if(!cross)
		return "psycross"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/silver))
		return "silver psycross"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/g))
		return "golden psycross"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/aalloy))
		return "ancient psycross"
	return "stone psycross"

/obj/item/intimate_accessory/piercing/tongue/proc/get_psydonic_socket_color(obj/item/clothing/neck/roguetown/psicross/cross)
	if(!cross)
		return "#9BADB7"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/silver))
		return "#C6D5E1"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/g))
		return "#C4B651"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/aalloy))
		return "#BB9696"
	return "#9BADB7"

/obj/item/intimate_accessory/piercing/tongue/proc/convert_to_psydonic(obj/item/clothing/neck/roguetown/psicross/cross, mob/living/user)
	if(!cross || !user)
		return FALSE

	return convert_to_cross_variant(
		cross,
		user,
		/obj/item/intimate_accessory/piercing/tongue/psydonic,
		get_psydonic_socket_descriptor(cross),
		get_psydonic_socket_color(cross),
		"psydonic",
		"psydonic_socketed",
		"I set [cross] into [src], reshaping it as if wrought from star-and-clay. It is deemed good.",
	)

// Tongue special variants.
/obj/item/intimate_accessory/piercing/tongue/psydonic
	name = "psydonic tongue piercing"
	desc = "A tongue bar set with a fixed psycross. 'The quiet was a blessing from HIM that must never be wasted, lest PSYDON himself speak again.'"
	icon_state = "tongue_pierce_item_psy"
	item_state = "tongue_pierce_item_psy"
	item_base_state = "tongue_pierce_item_psy"
	item_gem_state = null

/obj/item/intimate_accessory/piercing/tongue/psydonic/proc/is_psydonic_musical_cross()
	return ispath(socketed_item_type, /obj/item/clothing/neck/roguetown/psicross/silver) || ispath(socketed_item_type, /obj/item/clothing/neck/roguetown/psicross/g)

/obj/item/intimate_accessory/piercing/tongue/psydonic/proc/refresh_psydonic_verbs(mob/living/carbon/human/H)
	if(!H)
		return

	if(H.intimate_mouth == src)
		H.verbs |= /mob/living/carbon/human/proc/quote_psydonic_scripture
		return

	H.verbs -= /mob/living/carbon/human/proc/quote_psydonic_scripture

/obj/item/intimate_accessory/piercing/tongue/psydonic/proc/refresh_psydonic_signal()
	if(!wearer)
		return

	UnregisterSignal(wearer, COMSIG_MOB_SAY_POSTPROCESS)
	if(is_psydonic_musical_cross())
		RegisterSignal(wearer, COMSIG_MOB_SAY_POSTPROCESS, PROC_REF(on_psydonic_say_postprocess))

/obj/item/intimate_accessory/piercing/tongue/psydonic/proc/message_has_psydonic_keywords(message)
	if(!message)
		return FALSE

	var/lower = lowertext("[message]")
	var/static/list/psydonic_keywords = list(
		"endure",
		"lyfe",
		"lyves",
		"psydon",
		"psydonia",
		"comet syon",
		"syon",
		"psycross",
		"endvre",
		"absolved",
		"absolution",
		"redemption"
	)

	for(var/keyword in psydonic_keywords)
		if(findtext(lower, keyword))
			return TRUE

	return FALSE

/obj/item/intimate_accessory/piercing/tongue/psydonic/proc/on_psydonic_say_postprocess(datum/source, list/speech_args)
	SIGNAL_HANDLER

	if(!wearer || source != wearer)
		return
	if(!is_psydonic_musical_cross())
		return

	var/message = speech_args[SPEECH_MESSAGE]
	if(!message_has_psydonic_keywords(message))
		return

	speech_args[SPEECH_MESSAGE] = "<span style='font-size:125%; color:#46bacf;'><b>[message]</b></span>"


/obj/item/intimate_accessory/piercing/tongue/psydonic/proc/quote_psybible(mob/living/carbon/human/user)
	if(!can_use_tongue_piercing_action(user))
		return FALSE

	var/static/list/psybible_sections = list(
		"strings/psysect1.txt",
		"strings/psysect2.txt",
		"strings/psysect3.txt"
	)
	var/list/verses = world.file2list(pick(psybible_sections))
	if(!length(verses))
		to_chat(user, span_warning("No psydonic scripture comes to mind."))
		return FALSE

	var/verse = pick(verses)
	if(!verse)
		return FALSE

	user.say(verse)
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/psydonic/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	if(H)
		refresh_psydonic_verbs(H)
		refresh_psydonic_signal()

/obj/item/intimate_accessory/piercing/tongue/psydonic/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H)
		H.verbs -= /mob/living/carbon/human/proc/quote_psydonic_scripture
		UnregisterSignal(H, COMSIG_MOB_SAY_POSTPROCESS)
	return ..()

/obj/item/intimate_accessory/piercing/tongue/psydonic/on_socket_state_changed(reason = "")
	. = ..()
	if(wearer)
		refresh_psydonic_verbs(wearer)
		refresh_psydonic_signal()

/obj/item/intimate_accessory/piercing/tongue/psydonic/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("This psycross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/psydonic/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel) || istype(I, /obj/item/roguegem) || istype(I, /obj/item/clothing/neck/roguetown/psicross))
		return try_extract_socketed_item(user)
	return ..()

/obj/item/intimate_accessory/piercing/tongue/zizite
	name = "zizite tongue piercing"
	desc = "A tongue bar set with a fixed zcross and skull-shaped bead. The points scrape against the bottom of ones mouth; so much for PROGRESS."
	icon_state = "tongue_pierce_item_zizo"
	item_state = "tongue_pierce_item_zizo"
	item_base_state = "tongue_pierce_item_zizo"
	item_gem_state = null

/obj/item/intimate_accessory/piercing/tongue/zizite/proc/refresh_zizite_verbs(mob/living/carbon/human/H)
	if(!H)
		return

	if(H.intimate_mouth == src)
		H.verbs |= /mob/living/carbon/human/proc/speak_zizo_chant
		return

	H.verbs -= /mob/living/carbon/human/proc/speak_zizo_chant

/obj/item/intimate_accessory/piercing/tongue/zizite/proc/speak_in_zizo_chant(mob/living/carbon/human/user)
	if(!can_use_tongue_piercing_action(user))
		return FALSE

	var/chant_message = stripped_input(user, "What words do I offer to Zizo?", "Zizo Chant")
	if(!chant_message)
		return FALSE

	user.say(chant_message, language = /datum/language/undead)
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/zizite/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	if(H)
		refresh_zizite_verbs(H)

/obj/item/intimate_accessory/piercing/tongue/zizite/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H)
		H.verbs -= /mob/living/carbon/human/proc/speak_zizo_chant
	return ..()

/mob/living/carbon/human/proc/get_tongue_piercing_of_type(required_type)
	if(!required_type || !intimate_mouth)
		return null
	if(!istype(intimate_mouth, required_type))
		return null
	return intimate_mouth

/mob/living/carbon/human/proc/get_zizite_tongue_piercing()
	return get_tongue_piercing_of_type(/obj/item/intimate_accessory/piercing/tongue/zizite)

/mob/living/carbon/human/proc/speak_zizo_chant()
	set name = "Speak Zizo Chant"
	set category = "IC"

	var/obj/item/intimate_accessory/piercing/tongue/zizite/piercing = get_zizite_tongue_piercing()
	if(!piercing)
		to_chat(src, span_warning("I need to be wearing a zizite tongue piercing."))
		return FALSE

	return piercing.speak_in_zizo_chant(src)

/mob/living/carbon/human/proc/get_psydonic_tongue_piercing()
	return get_tongue_piercing_of_type(/obj/item/intimate_accessory/piercing/tongue/psydonic)

/mob/living/carbon/human/proc/quote_psydonic_scripture()
	set name = "Quote Psybible"
	set category = "IC"

	var/obj/item/intimate_accessory/piercing/tongue/psydonic/piercing = get_psydonic_tongue_piercing()
	if(!piercing)
		to_chat(src, span_warning("I need to be wearing a psydonic tongue piercing."))
		return FALSE

	return piercing.quote_psybible(src)

// Metal variants for tongue piercings.
// These stay a bit pricier because the tongue variants have extra visibility/effects.
/obj/item/intimate_accessory/piercing/tongue/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/tongue/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/tongue/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/tongue/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/tongue/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/tongue/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/tongue/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// Compatibility aliases for older mouth piercing paths.
/obj/item/intimate_accessory/piercing/mouth
	parent_type = /obj/item/intimate_accessory/piercing/tongue

/obj/item/intimate_accessory/piercing/mouth/iron
	parent_type = /obj/item/intimate_accessory/piercing/tongue/iron

/obj/item/intimate_accessory/piercing/mouth/copper
	parent_type = /obj/item/intimate_accessory/piercing/tongue/copper

/obj/item/intimate_accessory/piercing/mouth/steel
	parent_type = /obj/item/intimate_accessory/piercing/tongue/steel

/obj/item/intimate_accessory/piercing/mouth/bronze
	parent_type = /obj/item/intimate_accessory/piercing/tongue/bronze

/obj/item/intimate_accessory/piercing/mouth/silver
	parent_type = /obj/item/intimate_accessory/piercing/tongue/silver

/obj/item/intimate_accessory/piercing/mouth/gold
	parent_type = /obj/item/intimate_accessory/piercing/tongue/gold

/obj/item/intimate_accessory/piercing/mouth/blacksteel
	parent_type = /obj/item/intimate_accessory/piercing/tongue/blacksteel

// Rear plug variants.

/obj/item/intimate_accessory/piercing/rear
	name = "intimate rear piercing"
	desc = "A piercing designed for the rear. It has a socket for a gem accent."
	icon_state = "rear_pierce_item"
	item_state = "rear_pierce_item"
	intimate_slot = INTIMATE_SLOT_REAR
	intimate_flags = INTIMATE_FLAG_PIERCING
