// Periodic hallucination system for Blood Drunk Hunters. While the
// trait TRAIT_BEAST_DRUNK is present, the hunter occasionally sees
// everyone around them as werewolves or gnolls, BEASTS ALL OVER THE SHOP...
// Implemented as a status effect that ticks on its own timer,
// completely independent of the normal hallucination counter.

#define BLOODHUNT_DELUSION_MIN_INTERVAL 900 SECONDS
#define BLOODHUNT_DELUSION_MAX_INTERVAL 1800 SECONDS
#define BLOODHUNT_DELUSION_DURATION 120 SECONDS


/datum/status_effect/beast_drunk
	id = "beast_drunk_delusion"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1 // permanent until removed
	tick_interval = 10 SECONDS
	alert_type = null
	var/next_episode = 0
	var/datum/hallucination/delusion/beast_delusion/active_delusion
	var/base_cmode_music
	/// Frenzy combat music, about 2 minutes long so lasts duration of the delusion
	var/frenzy_cmode_music = 'sound/music/combat_blooddrunk2.ogg'

/datum/status_effect/beast_drunk/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE
	next_episode = world.time + BLOODHUNT_DELUSION_MIN_INTERVAL
	// Frenzy buffs similar to weeping psicross
	var/mob/living/carbon/human/H = owner
	H.change_stat(STATKEY_STR, 3)
	H.change_stat(STATKEY_SPD, 3)
	H.change_stat(STATKEY_WIL, 3)
	H.change_stat(STATKEY_LCK, -3)
	H.change_stat(STATKEY_INT, -3)
	ADD_TRAIT(H, TRAIT_NOCSHADES, "beast_drunk")
	ADD_TRAIT(H, TRAIT_STRONGBITE, "beast_drunk")
	ADD_TRAIT(H, TRAIT_STRENGTH_UNCAPPED, "beast_drunk")
	ADD_TRAIT(H, TRAIT_NOPAIN, "beast_drunk")
	ADD_TRAIT(H, TRAIT_DNR, "beast_drunk")
	ADD_TRAIT(H, TRAIT_PSYCHOSIS, "beast_drunk")
	return TRUE

/datum/status_effect/beast_drunk/tick()
	if(!owner?.client)
		return
	if(owner.stat == DEAD)
		return
	if(world.time < next_episode)
		return
	if(active_delusion && !QDELETED(active_delusion))
		return // still running
	trigger_episode()

/datum/status_effect/beast_drunk/proc/trigger_episode()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !H.client)
		return
	active_delusion = new /datum/hallucination/delusion/beast_delusion(H, TRUE, src)
	next_episode = world.time + rand(BLOODHUNT_DELUSION_MIN_INTERVAL, BLOODHUNT_DELUSION_MAX_INTERVAL)
	// Force combat mode on and lock it for the duration
	ADD_TRAIT(H, TRAIT_FORCED_CMODE, "beast_drunk_frenzy")
	if(!H.cmode)
		H.toggle_cmode()
	// Swap to frenzy music if the player hasn't set a custom override
	if(!length(H.cmode_music_override))
		if(!base_cmode_music)
			base_cmode_music = H.cmode_music
		H.cmode_music = frenzy_cmode_music
		if(H.cmode && H.client)
			SSdroning.play_combat_music(list(frenzy_cmode_music), H.client)

/datum/status_effect/beast_drunk/proc/on_episode_end()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	active_delusion = null
	REMOVE_TRAIT(H, TRAIT_FORCED_CMODE, "beast_drunk_frenzy")
	if(!length(H.cmode_music_override) && base_cmode_music)
		H.cmode_music = base_cmode_music
		if(H.cmode && H.client)
			SSdroning.play_combat_music(base_cmode_music, H.client)

/datum/status_effect/beast_drunk/on_remove()
	if(active_delusion && !QDELETED(active_delusion))
		qdel(active_delusion)
	active_delusion = null
	base_cmode_music = null
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.change_stat(STATKEY_STR, -3)
		H.change_stat(STATKEY_SPD, -3)
		H.change_stat(STATKEY_WIL, -3)
		H.change_stat(STATKEY_LCK, 3)
		H.change_stat(STATKEY_INT, 3)
		REMOVE_TRAIT(H, TRAIT_NOCSHADES, "beast_drunk")
		REMOVE_TRAIT(H, TRAIT_STRONGKICK, "beast_drunk")
		REMOVE_TRAIT(H, TRAIT_STRENGTH_UNCAPPED, "beast_drunk")
		REMOVE_TRAIT(H, TRAIT_NOPAIN, "beast_drunk")
	return ..()

// -------------------- Hallucination Datum --------------------

/datum/hallucination/delusion/beast_delusion
	natural = FALSE
	var/datum/status_effect/beast_drunk/parent_effect

/datum/hallucination/delusion/beast_delusion/Destroy()
	if(parent_effect && !QDELETED(parent_effect))
		parent_effect.on_episode_end()
	parent_effect = null
	return ..()

/datum/hallucination/delusion/beast_delusion/New(mob/living/carbon/C, forced, datum/status_effect/beast_drunk/effect)
	target = C
	parent_effect = effect
	feedback_details = "Type: beast_delusion"

	if(!target?.client)
		qdel(src)
		return

	var/kind = pick("werewolf", "gnoll")
	// Flavor text
	switch(kind)
		if("werewolf")
			to_chat(target, span_warning("What's that smell? The blood... you can smell it on them. Beasts, all of them."))
		if("gnoll")
			to_chat(target, span_warning("Their eyes gleam wrong in the dark. Hunched shapes. Gnolls all over the shop..."))

	for(var/mob/living/carbon/human/H in range(15, target))
		if(H == target)
			continue
		if(get_dist(target, H) > 15)
			continue
		var/image/A
		switch(kind)
			if("werewolf")
				A = image('icons/roguetown/mob/monster/werewolf.dmi', H, "wwolf_m")
				A.name = "Beast"
			if("gnoll")
				A = image('icons/roguetown/mob/monster/gnoll.dmi', H, "berserker")
				A.name = "Gnoll"
		A.override = 1
		delusions |= A
		target.client.images |= A

	target.playsound_local(target, pick(
		'sound/vo/mobs/wwolf/roar.ogg', 'sound/vo/mobs/hyena/gnoll_distant.ogg',
	), 35, TRUE)

	QDEL_IN(src, BLOODHUNT_DELUSION_DURATION)


/datum/action/cooldown/blood_drunk_frenzy
	name = "Forced Frenzy"
	desc = "Sink your teeth into your own arm, tearing at the flesh until the old blood boils over and the frenzy takes hold."
	button_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell"
	icon_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "bloodrage"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = BLOODHUNT_DELUSION_MIN_INTERVAL
	transparent_when_unavailable = FALSE

/datum/action/cooldown/blood_drunk_frenzy/Activate(atom/target)
	. = TRUE
	var/mob/living/carbon/human/user = owner
	if(!istype(user))
		return

	var/datum/status_effect/beast_drunk/BD = user.has_status_effect(/datum/status_effect/beast_drunk)
	if(!BD)
		to_chat(user, span_warning("The old blood is silent. There is nothing to call upon."))
		return

	if(BD.active_delusion && !QDELETED(BD.active_delusion))
		to_chat(user, span_warning("The frenzy already has you. There's no need to call it twice."))
		return

	var/arm_zone = (user.active_hand_index % 2 == 0) ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM
	var/obj/item/bodypart/arm = user.get_bodypart(arm_zone)
	if(!arm)
		arm_zone = (arm_zone == BODY_ZONE_L_ARM) ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM
		arm = user.get_bodypart(arm_zone)
	if(!arm)
		to_chat(user, span_warning("You have no arm to sink your teeth into."))
		return

	to_chat(user, span_boldwarning("You raise your arm to your mouth and bite down HARD, teeth grinding into your own flesh..."))
	user.visible_message(span_warning("[user] sinks their teeth into their own arm, gnawing savagely at the flesh!"))
	playsound(user, 'modular/sounds/trickweapons/kosparasite/blood_splat1.ogg', 50, TRUE)

	if(!do_after(user, 20 SECONDS, FALSE, user))
		to_chat(user, span_notice("You relent, pulling your bloody mouth away before the frenzy takes hold."))
		return

	arm.add_wound(/datum/wound/bite/large)
	user.apply_damage(15, BRUTE, arm)
	playsound(user, pick('modular/sounds/trickweapons/kosparasite/blood_splat1.ogg', 'modular/sounds/trickweapons/kosparasite/blood_splat2.ogg'), 60, TRUE)

	to_chat(user, span_hypnophrase("The blood runs hot. Your vision narrows to a crimson slit. Everything that moves is a beast — and you are the HUNTER."))
	user.visible_message(span_boldwarning("[user] rips their teeth free with a spray of blood, eyes wild and unfocused! They've gone BERSERK!"))
	BD.trigger_episode()
	BD.next_episode = world.time + rand(BLOODHUNT_DELUSION_MIN_INTERVAL, BLOODHUNT_DELUSION_MAX_INTERVAL)

	StartCooldown()
