// ===================== BEAST SENSE =====================
// Cooldown ability granted to trick-weapon hunter classes (Blood Drunk
// Hunter, Gnoll Hunter). Activating it scans for the nearest hostile
// beast — aggressive simple animals (wolves, trolls, bears, etc.),
// werewolves, and gnolls — and reports direction and distance to the user.

/// Maximum range (in tiles) the sense can detect beasts.
#define BEAST_SENSE_RANGE 50

/datum/action/cooldown/beast_sense
	name = "Beast Sense"
	desc = "Focus your hunter's instinct to detect the nearest beast."
	button_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell"
	icon_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "wolf_head_undead"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 30 SECONDS
	transparent_when_unavailable = FALSE

/datum/action/cooldown/beast_sense/Activate(atom/target)
	. = TRUE
	var/mob/living/user = owner
	if(!istype(user))
		return

	var/turf/user_turf = get_turf(user)
	if(!user_turf)
		return

	// Find nearest beast — iterate living mobs globally instead of
	// range(50) which scans all atoms in a 101x101 tile area.
	var/mob/living/closest_beast
	var/closest_dist = BEAST_SENSE_RANGE + 1

	for(var/mob/living/L in GLOB.alive_mob_list)
		if(L == user)
			continue
		if(L.z != user_turf.z)
			continue
		var/dist = get_dist(user, L)
		if(dist > BEAST_SENSE_RANGE)
			continue
		if(L.stat == DEAD)
			continue
		if(!is_beast_target(L))
			continue
		if(dist < closest_dist)
			closest_dist = dist
			closest_beast = L

	if(!closest_beast)
		to_chat(user, span_warning("Your senses find nothing... the hunt is quiet."))
		StartCooldown()
		return

	var/turf/beast_turf = get_turf(closest_beast)
	if(user_turf.z != beast_turf.z)
		to_chat(user, span_notice("You sense a beast somewhere [user_turf.z > beast_turf.z ? "below" : "above"] you."))
		StartCooldown()
		return

	var/dir_text = dir2text(get_dir(user, closest_beast))
	if(closest_dist <= 1)
		to_chat(user, span_boldnotice("The beast is right here! Steel yourself!"))
	else if(closest_dist <= 5)
		to_chat(user, span_notice("Your blood thrums. A beast is very close, to the [dir_text]."))
	else if(closest_dist <= 15)
		to_chat(user, span_notice("You sense a beast nearby, to the [dir_text]."))
	else if(closest_dist <= 30)
		to_chat(user, span_notice("A faint bestial presence lingers to the [dir_text]. It is some distance away."))
	else
		to_chat(user, span_notice("At the edge of your senses, something stirs far to the [dir_text]."))

	StartCooldown()

/**
 * Returns TRUE if the given mob counts as a beast for tracking purposes.
 * Checks for aggressive simple mobs with MOB_BEAST biotype (wolves,
 * trolls, bears, spiders, etc.) then checks species ID for werewolves
 * and gnolls. Passive farm animals are excluded by the aggressive check.
 */
/datum/action/cooldown/beast_sense/proc/is_beast_target(mob/living/L)
	// Hostile simple animals with MOB_BEAST biotype — wolves, trolls, bears, etc.
	if(L.mob_biotypes & MOB_BEAST)
		var/mob/living/simple_animal/hostile/retaliate/rogue/R = L
		if(istype(R) && R.aggressive)
			return TRUE
	// Humanoid beast-kin — werewolves and gnolls
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.dna?.species)
			var/species_id = H.dna.species.id
			if(species_id in GLOB.beast_sense_species)
				return TRUE
	return FALSE

/// Species IDs that Beast Sense can detect. Mirrors the serrated bonus
/// species list — beast-kin, anthromorphs, werewolves, and wildshapes.
GLOBAL_LIST_INIT(beast_sense_species, list(
	"werewolf",
	"gnoll",
))

#undef BEAST_SENSE_RANGE
