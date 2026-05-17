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
	/// When TRUE this piercing emits audible movement jingles (visible_message) via the reaction component.
	/// Bell piercings set this to TRUE; plain bars, studs, hoops, and tongue bars are silent during movement.
	var/emits_movement_sound = FALSE
	/// Visual movement style for non-bell piercings. null = standard bars/studs/hoops.
	/// Set to "psydonic" or "zizite" on cross-bearing variants to dispatch to specific visual string banks.
	var/visual_movement_style = null
	/// Player-facing noun used only in examine text, e.g. "jacob's ladder".
	var/custom_piercing_descriptor = null
	/// Direct reference to our reaction component, cached to avoid GetComponent() on a COMPONENT_DUPE_ALLOWED type.
	/// Set during Initialize(); cleared on Destroy(). Each piercing item carries exactly one reaction instance.
	var/datum/component/intimate_reaction/piercing/reaction_component = null
	// Reserved for future nudist support.
	//nudist_approved = TRUE

/obj/item/intimate_accessory/piercing/Initialize()
	. = ..()
	update_item_visuals()
	// Attach the piercing reaction component so movement jingles and sex-action flavor text fire automatically.
	// Each item carries its own component instance; COMPONENT_DUPE_ALLOWED on the component subtype
	// allows nipple + genital + rear piercings to all operate concurrently on the same wearer.
	reaction_component = AddComponent(/datum/component/intimate_reaction/piercing)

/obj/item/intimate_accessory/piercing/Destroy()
	reaction_component = null
	return ..()

/// Binds the reaction component to H after the slot reference and wearer var are set by the base finalize_intimate_equip.
/obj/item/intimate_accessory/piercing/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	if(reaction_component)
		reaction_component.bind_to_wearer(H)

/// Unbinds the reaction component from H before slot refs are cleared by the base remove_intimate_accessory.
/obj/item/intimate_accessory/piercing/remove_intimate_accessory(mob/living/carbon/human/H)
	if(reaction_component)
		reaction_component.unbind_from_wearer(H)
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
	var/base_price = roundstart_equipped ? 0 : initial(sellprice)
	sellprice = max(1, base_price + gem_value_bonus)

/obj/item/intimate_accessory/piercing/proc/set_custom_piercing_descriptor(descriptor)
	custom_piercing_descriptor = sanitize_intimate_piercing_descriptor(descriptor)
	return TRUE

/obj/item/intimate_accessory/piercing/get_intimate_examine_plain_name()
	if(!custom_piercing_descriptor)
		return ..()
	var/metal_descriptor = get_metal_descriptor()
	var/display_name = "[metal_descriptor] [custom_piercing_descriptor]"
	if(current_gem_descriptor)
		display_name = "[current_gem_descriptor]-set [display_name]"
	if(is_beriddled())
		display_name = "beriddled [display_name]"
	return display_name

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
	if(H && H.intimate_breast_piercing == src)
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

// --- Breast bell piercings ---
// A nipple ring fitted with a small dangling bell that chimes audibly during movement.
// Inherits breast/Initialize(), so update_dynamic_name() picks up piercing_region_name and
// produces "[metal] nipple bell piercing" automatically without an extra Initialize override.
/obj/item/intimate_accessory/piercing/breast/bell
	desc = "A nipple ring fitted with a tiny dangling bell. Each step produces a soft, telltale chime that announces the wearer with musical indiscretion."
	piercing_region_name = "nipple bell"
	emits_movement_sound = TRUE

/obj/item/intimate_accessory/piercing/breast/bell/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 7

/obj/item/intimate_accessory/piercing/breast/bell/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 8

/obj/item/intimate_accessory/piercing/breast/bell/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/breast/bell/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 18

/obj/item/intimate_accessory/piercing/breast/bell/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 40
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/breast/bell/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 65

/obj/item/intimate_accessory/piercing/breast/bell/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 165

// --- Breast psydonic piercings ---
// A nipple piercing set with a fixed psycross pendant that dangles from each bar.
/obj/item/intimate_accessory/piercing/breast/psydonic
	name = "psydonic nipple piercing"
	desc = "A set of nipple bars, each hung with a tiny psycross pendant. The little devotionals dangle and sway from pierced flesh with pious indiscretion."
	icon_state = "breast_pierce_item_psy"
	item_state = "breast_pierce_item_psy"
	item_base_state = "breast_pierce_item_psy"
	item_gem_state = null
	visual_movement_style = "psydonic"
	intimate_metal_name = "stone"
	intimate_metal_color = "#9BADB7"
	intimate_gem_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/breast/psydonic/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] psydonic nipple piercing")

/obj/item/intimate_accessory/piercing/breast/psydonic/update_dynamic_name()
	name = "[lowertext(intimate_metal_name)] psydonic nipple piercing"

/obj/item/intimate_accessory/piercing/breast/psydonic/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The psycross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/breast/psydonic/silver_cross
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	intimate_gem_color = "#C6D5E1"
	sellprice = 40

/obj/item/intimate_accessory/piercing/breast/psydonic/golden_cross
	intimate_metal_name = "golden"
	intimate_metal_color = "#C4B651"
	intimate_gem_color = "#C4B651"
	sellprice = 60

/obj/item/intimate_accessory/piercing/breast/psydonic/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

// --- Breast zizite piercings ---
// A nipple piercing set with a fixed zcross and morbid skull beadwork.
/obj/item/intimate_accessory/piercing/breast/zizite
	name = "zizite nipple piercing"
	desc = "A set of nipple bars hung with zcross pendants and tiny skull beads. The Dame of Progress's spite, threaded through tender flesh."
	icon_state = "breast_pierce_item_zizo"
	item_state = "breast_pierce_item_zizo"
	item_base_state = "breast_pierce_item_zizo"
	item_gem_state = null
	visual_movement_style = "zizite"
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	intimate_gem_color = "#9EA48E"
	sellprice = 15

/obj/item/intimate_accessory/piercing/breast/zizite/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] zizite nipple piercing")

/obj/item/intimate_accessory/piercing/breast/zizite/update_dynamic_name()
	name = "[lowertext(intimate_metal_name)] zizite nipple piercing"

/obj/item/intimate_accessory/piercing/breast/zizite/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The zcross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/breast/zizite/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

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
	if(H.intimate_genital_piercing == src && is_beriddled())
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
	if(H && H.intimate_genital_piercing == src)
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

// --- Genital bell piercings ---
// A genital kit supplemented with a dangle-bell charm that chimes with each step.
// Inherits beriddled/goodlover behaviour from the genital parent; only adds the movement-sound flag.
/obj/item/intimate_accessory/piercing/genital/bell
	desc = "A genital piercing kit dressed with a small dangling bell charm. Its soft chime makes no secret of what lies beneath."
	piercing_region_name = "genital bell"
	emits_movement_sound = TRUE

// Explicit Initialize so update_dynamic_name() produces
// "[metal] genital bell piercing" — the genital base Initialize handles finalize_piercing_initialize.
/obj/item/intimate_accessory/piercing/genital/bell/Initialize()
	. = ..()

/obj/item/intimate_accessory/piercing/genital/bell/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 7

/obj/item/intimate_accessory/piercing/genital/bell/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 8

/obj/item/intimate_accessory/piercing/genital/bell/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/genital/bell/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 18

/obj/item/intimate_accessory/piercing/genital/bell/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 40
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/genital/bell/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 65

/obj/item/intimate_accessory/piercing/genital/bell/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 165

/obj/item/intimate_accessory/piercing/genital/psydonic
	name = "psydonic genital piercing"
	desc = "A genital piercing kit wrought in a psydonic style, its bedazzled lines arranged in quiet devotion. Even intimate pain seems to break upon it and pass."
	icon_state = "genital_pierce_item_psy"
	item_state = "genital_pierce_item_psy"
	item_base_state = "genital_pierce_item_psy"
	item_gem_state = null
	visual_movement_style = "psydonic"
	intimate_metal_name = "stone"
	intimate_metal_color = "#9BADB7"
	intimate_gem_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/genital/psydonic/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] psydonic genital piercing")

/obj/item/intimate_accessory/piercing/genital/psydonic/update_dynamic_name()
	if(is_beriddled())
		return ..()
	name = "[lowertext(intimate_metal_name)] psydonic genital piercing"

/obj/item/intimate_accessory/piercing/genital/psydonic/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The psycross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/genital/psydonic/silver_cross
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	intimate_gem_color = "#C6D5E1"
	sellprice = 40

/obj/item/intimate_accessory/piercing/genital/psydonic/golden_cross
	intimate_metal_name = "golden"
	intimate_metal_color = "#C4B651"
	intimate_gem_color = "#C4B651"
	sellprice = 60

/obj/item/intimate_accessory/piercing/genital/psydonic/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

/obj/item/intimate_accessory/piercing/genital/zizite
	name = "zizite genital piercing"
	desc = "A genital piercing kit set with a fixed zcross and morbid beadwork. It carries the Dame of Progress's spite into the bedchamber."
	visual_movement_style = "zizite"
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	intimate_gem_color = "#9EA48E"
	sellprice = 15

/obj/item/intimate_accessory/piercing/genital/zizite/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] zizite genital piercing")

/obj/item/intimate_accessory/piercing/genital/zizite/update_dynamic_name()
	if(is_beriddled())
		return ..()
	name = "[lowertext(intimate_metal_name)] zizite genital piercing"

/obj/item/intimate_accessory/piercing/genital/zizite/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The zcross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/genital/zizite/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

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
	if(user.intimate_mouth_piercing != src)
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

	if(H.intimate_mouth_piercing == src)
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
	var/static/list/cached_verses = list()
	var/section = pick(psybible_sections)
	if(!cached_verses[section])
		cached_verses[section] = world.file2list(section)
	var/list/verses = cached_verses[section]
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
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel) || istype(I, /obj/item/clothing/neck/roguetown/psicross))
		return try_extract_socketed_item(user)
	if(istype(I, /obj/item/roguegem))
		to_chat(user, span_warning("The psycross fills the socket; there is no room for a gem."))
		return TRUE
	return ..()

/obj/item/intimate_accessory/piercing/tongue/zizite
	name = "zizite tongue piercing"
	desc = "A tongue bar set with a fixed zcross and skull-shaped bead. The points scrape against the bottom of ones mouth; so much for PROGRESS."
	icon_state = "tongue_pierce_item_zizo"
	item_state = "tongue_pierce_item_zizo"
	item_base_state = "tongue_pierce_item_zizo"
	item_gem_state = null

/obj/item/intimate_accessory/piercing/tongue/zizite/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("This zcross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/tongue/zizite/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel) || istype(I, /obj/item/clothing/neck/roguetown/psicross))
		return try_extract_socketed_item(user)
	if(istype(I, /obj/item/roguegem))
		to_chat(user, span_warning("The zcross fills the socket; there is no room for a gem."))
		return TRUE
	return ..()

/obj/item/intimate_accessory/piercing/tongue/zizite/proc/refresh_zizite_verbs(mob/living/carbon/human/H)
	if(!H)
		return

	if(H.intimate_mouth_piercing == src)
		H.verbs |= /mob/living/carbon/human/proc/speak_zizo_chant
		return

	H.verbs -= /mob/living/carbon/human/proc/speak_zizo_chant

/obj/item/intimate_accessory/piercing/tongue/zizite/proc/speak_in_zizo_chant(mob/living/carbon/human/user)
	if(!can_use_tongue_piercing_action(user))
		return FALSE

	var/chant_message = tgui_input_text(user, "What words do I offer to Zizo?", "Zizo Chant", "", 200)
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
	if(!required_type || !intimate_mouth_piercing)
		return null
	if(!istype(intimate_mouth_piercing, required_type))
		return null
	return intimate_mouth_piercing

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

// Rear piercing variants.

/obj/item/intimate_accessory/piercing/rear
	name = "steel rear piercing"
	desc = "A discreet piercing designed for the rear. It has a socket for a gem accent."
	icon_state = "rear_pierce_item"
	item_state = "rear_pierce_item"
	item_base_state = "rear_pierce_item"
	item_gem_state = "rear_pierce_item_gem"
	piercing_region_name = "rear"
	intimate_slot = INTIMATE_SLOT_REAR
	intimate_flags = INTIMATE_FLAG_PIERCING

/obj/item/intimate_accessory/piercing/rear/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] rear piercing")

/obj/item/intimate_accessory/piercing/rear/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/rear/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && H.intimate_rear_piercing == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

// Metal variants for rear piercings.
/obj/item/intimate_accessory/piercing/rear/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/rear/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/rear/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/rear/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/rear/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/rear/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/rear/blacksteel // unbreakable gouch, the pintle will waver before this fuckass piercing does
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// --- Rear bell piercings ---
// A rear ring fitted with a small dangling bell that chimes audibly during movement.
// Inherits rear/Initialize(), so update_dynamic_name() picks up piercing_region_name and
// produces "[metal] rear bell piercing" automatically without an extra Initialize override.
/obj/item/intimate_accessory/piercing/rear/bell
	desc = "A rear piercing fitted with a tiny dangling bell. Each step produces a soft, telltale chime from behind."
	piercing_region_name = "rear bell"
	emits_movement_sound = TRUE

/obj/item/intimate_accessory/piercing/rear/bell/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 7

/obj/item/intimate_accessory/piercing/rear/bell/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 8

/obj/item/intimate_accessory/piercing/rear/bell/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/rear/bell/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 18

/obj/item/intimate_accessory/piercing/rear/bell/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 40
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/rear/bell/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 65

/obj/item/intimate_accessory/piercing/rear/bell/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 165

// ════════════════════════════════════════════════════════════════════════════
// UNFINISHED PIERCING — Crafted at the anvil, used in hand to pick a body
// region and optional bell attachment. Replaces per-slot anvil recipes to
// cut down on crafting menu clutter while also enabling rear and tongue
// piercings to be crafted for the first time.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/unfinished_piercing
	name = "unfinished piercing"
	desc = "An unfinished piercing blank. Use in hand to shape it for a particular body part."
	icon = 'modular/icons/obj/lewd/intimate_accessories.dmi'
	icon_state = "breast_pierce_item"
	w_class = WEIGHT_CLASS_SMALL
	var/piercing_metal_name
	var/piercing_metal_color
	var/piercing_is_silver = FALSE
	var/base_sell = 10
	var/bell_sell = 15

/obj/item/unfinished_piercing/Initialize()
	. = ..()
	if(piercing_metal_name)
		name = "unfinished [piercing_metal_name] piercing"
	if(piercing_metal_color)
		color = piercing_metal_color

/obj/item/unfinished_piercing/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to shape it for a particular body part.")

/obj/item/unfinished_piercing/attack_self(mob/living/user)
	. = ..()
	if(!istype(user) || user.incapacitated())
		return
	customize(user)

/obj/item/unfinished_piercing/proc/customize(mob/living/user)
	var/list/slot_choices = list(
		"Breast (nipple piercings)",
		"Genital (genital piercings)",
		"Rear (rear piercing)",
		"Tongue (tongue bar)",
	)

	var/slot_choice = tgui_input_list(user, "Where should the piercing go?", "Piercing Location", slot_choices)
	if(!slot_choice || QDELETED(src) || user.incapacitated() || !in_range(user, src))
		return

	var/piercing_type
	var/sell = base_sell

	if(slot_choice == "Tongue (tongue bar)")
		// Tongue piercings have no bell variant.
		piercing_type = /obj/item/intimate_accessory/piercing/tongue
	else
		var/list/style_choices = list("Standard Piercing", "Bell Piercing")
		var/style_choice = tgui_input_list(user, "Should it have a bell?", "Bell Option", style_choices)
		if(!style_choice || QDELETED(src) || user.incapacitated() || !in_range(user, src))
			return

		var/is_bell = (style_choice == "Bell Piercing")
		if(is_bell)
			sell = bell_sell

		switch(slot_choice)
			if("Breast (nipple piercings)")
				piercing_type = is_bell ? /obj/item/intimate_accessory/piercing/breast/bell : /obj/item/intimate_accessory/piercing/breast
			if("Genital (genital piercings)")
				piercing_type = is_bell ? /obj/item/intimate_accessory/piercing/genital/bell : /obj/item/intimate_accessory/piercing/genital
			if("Rear (rear piercing)")
				piercing_type = is_bell ? /obj/item/intimate_accessory/piercing/rear/bell : /obj/item/intimate_accessory/piercing/rear

	if(!piercing_type)
		return

	var/obj/item/intimate_accessory/piercing/new_piercing = new piercing_type(get_turf(user))
	if(piercing_metal_name)
		new_piercing.intimate_metal_name = piercing_metal_name
	if(piercing_metal_color)
		new_piercing.intimate_metal_color = piercing_metal_color
	new_piercing.is_silver = piercing_is_silver
	new_piercing.sellprice = sell
	new_piercing.update_dynamic_name()
	new_piercing.update_item_visuals()

	to_chat(user, span_notice("You shape the metal into \a [new_piercing]."))
	if(!user.put_in_hands(new_piercing))
		new_piercing.forceMove(get_turf(user))
	qdel(src)

// ── Metal Variants ──────────────────────────────────────────────────────────

/obj/item/unfinished_piercing/iron
	piercing_metal_name = "iron"
	piercing_metal_color = "#9EA48E"
	base_sell = 5
	bell_sell = 7

/obj/item/unfinished_piercing/copper
	piercing_metal_name = "copper"
	piercing_metal_color = "#8C4734"
	base_sell = 5
	bell_sell = 8

/obj/item/unfinished_piercing/steel
	piercing_metal_name = "steel"
	piercing_metal_color = "#9BADB7"
	base_sell = 10
	bell_sell = 15

/obj/item/unfinished_piercing/bronze
	piercing_metal_name = "bronze"
	piercing_metal_color = "#CBBF9A"
	base_sell = 12
	bell_sell = 18

/obj/item/unfinished_piercing/silver
	piercing_metal_name = "silver"
	piercing_metal_color = "#C6D5E1"
	piercing_is_silver = TRUE
	base_sell = 30
	bell_sell = 40

/obj/item/unfinished_piercing/gold
	piercing_metal_name = "gold"
	piercing_metal_color = "#C4B651"
	base_sell = 50
	bell_sell = 65

/obj/item/unfinished_piercing/blacksteel
	piercing_metal_name = "blacksteel"
	piercing_metal_color = "#A2CBE3"
	base_sell = 150
	bell_sell = 165

// ═══════════════════════════════════════════════════════════════════════════
// Earring piercings — visible on mob via sprite accessory overlay.
// ═══════════════════════════════════════════════════════════════════════════
/obj/item/intimate_accessory/piercing/ear
	name = "steel earring"
	desc = "A small hoop earring. Simple, decorative, and not remotely scandalous."
	icon_state = "ear_pierce_item"
	item_state = "ear_pierce_item"
	item_base_state = "ear_pierce_item"
	item_gem_state = "ear_pierce_item_gem"
	piercing_region_name = "ear"
	intimate_slot = INTIMATE_SLOT_EAR
	sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_ear

/obj/item/intimate_accessory/piercing/ear/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] earring")

/obj/item/intimate_accessory/piercing/ear/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/ear/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && H.intimate_ear_piercing == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

// Metal variants for earrings.
/obj/item/intimate_accessory/piercing/ear/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/ear/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/ear/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/ear/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/ear/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/ear/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/ear/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// --- Ear psydonic piercings ---
/obj/item/intimate_accessory/piercing/ear/psydonic
	name = "psydonic earring"
	desc = "An earring hung with a tiny psycross pendant. A small, quiet devotion worn close to the skull."
	icon_state = "ear_pierce_item_psy"
	item_state = "ear_pierce_item_psy"
	item_base_state = "ear_pierce_item_psy"
	item_gem_state = null
	visual_movement_style = "psydonic"
	intimate_metal_name = "stone"
	intimate_metal_color = "#9BADB7"
	intimate_gem_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/ear/psydonic/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] psydonic earring")

/obj/item/intimate_accessory/piercing/ear/psydonic/update_dynamic_name()
	name = "[lowertext(intimate_metal_name)] psydonic earring"

/obj/item/intimate_accessory/piercing/ear/psydonic/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The psycross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/ear/psydonic/silver_cross
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	intimate_gem_color = "#C6D5E1"
	sellprice = 40

/obj/item/intimate_accessory/piercing/ear/psydonic/golden_cross
	intimate_metal_name = "golden"
	intimate_metal_color = "#C4B651"
	intimate_gem_color = "#C4B651"
	sellprice = 60

/obj/item/intimate_accessory/piercing/ear/psydonic/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

// --- Ear zizite piercings ---
/obj/item/intimate_accessory/piercing/ear/zizite
	name = "zizite earring"
	desc = "An earring hung with a zcross pendant and a tiny skull bead. A surefire way to attract the worst sort of attention."
	icon_state = "ear_pierce_item_zizo"
	item_state = "ear_pierce_item_zizo"
	item_base_state = "ear_pierce_item_zizo"
	item_gem_state = null
	visual_movement_style = "zizite"
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	intimate_gem_color = "#9EA48E"
	sellprice = 15

/obj/item/intimate_accessory/piercing/ear/zizite/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] zizite earring")

/obj/item/intimate_accessory/piercing/ear/zizite/update_dynamic_name()
	name = "[lowertext(intimate_metal_name)] zizite earring"

/obj/item/intimate_accessory/piercing/ear/zizite/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The zcross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/ear/zizite/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

// ═══════════════════════════════════════════════════════════════════════════
// Nose piercings — visible on mob via sprite accessory overlay.
// ═══════════════════════════════════════════════════════════════════════════
/obj/item/intimate_accessory/piercing/nose
	name = "steel nose piercing"
	desc = "A small metal stud for the nose. Decorative, understated, and mildly painful to install."
	icon_state = "nose_pierce_item"
	item_state = "nose_pierce_item"
	item_base_state = "nose_pierce_item"
	item_gem_state = "nose_pierce_item_gem"
	piercing_region_name = "nose"
	intimate_slot = INTIMATE_SLOT_NOSE
	sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_nose

/obj/item/intimate_accessory/piercing/nose/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] nose piercing")

/obj/item/intimate_accessory/piercing/nose/attach_intimate_feature(mob/living/carbon/human/H)
	return TRUE

/obj/item/intimate_accessory/piercing/nose/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/nose/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && H.intimate_nose_piercing == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

// Metal variants for nose piercings.
/obj/item/intimate_accessory/piercing/nose/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/nose/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/nose/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/nose/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/nose/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/nose/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/nose/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// ═══════════════════════════════════════════════════════════════════════════
// Belly button piercings — visible on mob via sprite accessory overlay.
// ═══════════════════════════════════════════════════════════════════════════
/obj/item/intimate_accessory/piercing/belly
	name = "steel belly button piercing"
	desc = "A curved barbell for the navel. The kind of thing a bored merchant's daughter gets on a dare."
	icon_state = "belly_pierce_item"
	item_state = "belly_pierce_item"
	item_base_state = "belly_pierce_item"
	item_gem_state = "belly_pierce_item_gem"
	piercing_region_name = "belly button"
	intimate_slot = INTIMATE_SLOT_BELLY
	sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_belly

/obj/item/intimate_accessory/piercing/belly/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] belly button piercing")

/obj/item/intimate_accessory/piercing/belly/attach_intimate_feature(mob/living/carbon/human/H)
	return TRUE

/obj/item/intimate_accessory/piercing/belly/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/belly/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && H.intimate_belly_piercing == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

// Metal variants for belly button piercings.
/obj/item/intimate_accessory/piercing/belly/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/piercing/belly/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/piercing/belly/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/piercing/belly/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/piercing/belly/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/piercing/belly/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/piercing/belly/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// --- Belly psydonic piercings ---
/obj/item/intimate_accessory/piercing/belly/psydonic
	name = "psydonic belly button piercing"
	desc = "A navel barbell hung with a small psycross charm. Pious vanity, tucked under the shirt."
	icon_state = "belly_pierce_item_psy"
	item_state = "belly_pierce_item_psy"
	item_base_state = "belly_pierce_item_psy"
	item_gem_state = null
	visual_movement_style = "psydonic"
	intimate_metal_name = "stone"
	intimate_metal_color = "#9BADB7"
	intimate_gem_color = "#9BADB7"
	sellprice = 15

/obj/item/intimate_accessory/piercing/belly/psydonic/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] psydonic belly button piercing")

/obj/item/intimate_accessory/piercing/belly/psydonic/update_dynamic_name()
	name = "[lowertext(intimate_metal_name)] psydonic belly button piercing"

/obj/item/intimate_accessory/piercing/belly/psydonic/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The psycross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/belly/psydonic/silver_cross
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	intimate_gem_color = "#C6D5E1"
	sellprice = 40

/obj/item/intimate_accessory/piercing/belly/psydonic/golden_cross
	intimate_metal_name = "golden"
	intimate_metal_color = "#C4B651"
	intimate_gem_color = "#C4B651"
	sellprice = 60

/obj/item/intimate_accessory/piercing/belly/psydonic/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50

// --- Belly zizite piercings ---
/obj/item/intimate_accessory/piercing/belly/zizite
	name = "zizite belly button piercing"
	desc = "A navel barbell strung with a zcross and skull beadwork. At least this one's more hidden."
	icon_state = "belly_pierce_item_zizo"
	item_state = "belly_pierce_item_zizo"
	item_base_state = "belly_pierce_item_zizo"
	item_gem_state = null
	visual_movement_style = "zizite"
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	intimate_gem_color = "#9EA48E"
	sellprice = 15

/obj/item/intimate_accessory/piercing/belly/zizite/Initialize()
	. = ..()
	finalize_piercing_initialize("[lowertext(intimate_metal_name)] zizite belly button piercing")

/obj/item/intimate_accessory/piercing/belly/zizite/update_dynamic_name()
	name = "[lowertext(intimate_metal_name)] zizite belly button piercing"

/obj/item/intimate_accessory/piercing/belly/zizite/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The zcross is fixed in place and cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/piercing/belly/zizite/ancient_cross
	intimate_metal_name = "ancient"
	intimate_metal_color = "#BB9696"
	intimate_gem_color = "#BB9696"
	sellprice = 50
