/mob/proc/update_intimate_invisibility_props()
	return

/mob/proc/add_intimate_magic_invisibility_source(source)
	return

/mob/proc/remove_intimate_magic_invisibility_source(source)
	return

/mob/proc/is_intimate_magic_invisible()
	return FALSE

/atom/movable/intimate_invisibility_visual
	name = ""
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER
	appearance_flags = RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM | TILE_BOUND | PIXEL_SCALE
	var/atom/movable/container

/atom/movable/intimate_invisibility_visual/Destroy()
	if(container)
		container.vis_contents -= src
		container = null
	return ..()

/mob/living/carbon/human/var/mutable_appearance/intimate_invisibility_appearance
/mob/living/carbon/human/var/atom/movable/intimate_invisibility_visual/intimate_invisibility_visual
/mob/living/carbon/human/var/list/intimate_magic_invisibility_sources

/mob/living/carbon/human/is_intimate_magic_invisible()
	if(world.time < mob_timers[MT_INVISIBILITY])
		return TRUE
	return length(intimate_magic_invisibility_sources) > 0

/mob/living/carbon/human/add_intimate_magic_invisibility_source(source)
	if(!source)
		source = "magic"
	if(!intimate_magic_invisibility_sources)
		intimate_magic_invisibility_sources = list()
	intimate_magic_invisibility_sources[source] = TRUE
	update_intimate_invisibility_props()

/mob/living/carbon/human/remove_intimate_magic_invisibility_source(source)
	if(!source || !intimate_magic_invisibility_sources)
		return
	intimate_magic_invisibility_sources -= source
	if(!length(intimate_magic_invisibility_sources))
		intimate_magic_invisibility_sources = null
	update_intimate_invisibility_props()

/mob/living/carbon/human/proc/get_intimate_invisibility_body_suffix()
	var/datum/species/species = dna?.species
	if(species?.clothes_id == "dwarf")
		return gender == FEMALE ? "fd" : "md"

	if(gender == MALE)
		if(is_species(src, /datum/species/elf))
			return "melf"
		if(species?.limbs_icon_m == 'icons/roguetown/mob/bodies/m/mt_muscular.dmi')
			return "mtm"
		return "mt"

	if(species?.limbs_icon_f == 'icons/roguetown/mob/bodies/f/ft_muscular.dmi')
		return "ftm"
	return "fm"

/mob/living/carbon/human/update_intimate_invisibility_props()
	if(intimate_invisibility_appearance)
		cut_overlay(intimate_invisibility_appearance)
		intimate_invisibility_appearance = null
	QDEL_NULL(intimate_invisibility_visual)

	if(!is_intimate_magic_invisible())
		return

	var/obj/item/intimate_accessory/rear/plug/rear_insertable = intimate_rear_insertable
	if(!rear_insertable?.has_intimate_invisibility_appearance())
		return

	var/body_suffix = get_intimate_invisibility_body_suffix()
	var/mutable_appearance/new_appearance = rear_insertable.build_intimate_invisibility_appearance(body_suffix)
	if(!new_appearance)
		return

	var/atom/movable/intimate_invisibility_visual/new_visual = new
	new_visual.appearance = new_appearance
	new_visual.appearance_flags = RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM | TILE_BOUND | PIXEL_SCALE
	new_visual.layer = ABOVE_MOB_LAYER
	new_visual.alpha = 255
	new_visual.invisibility = 0
	new_visual.dir = dir
	new_visual.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	new_visual.container = src
	vis_contents += new_visual
	intimate_invisibility_visual = new_visual
