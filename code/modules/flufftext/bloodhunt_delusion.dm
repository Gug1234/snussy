// ===================== BLOOD DRUNK DELUSION =====================
// Periodic hallucination system for Blood Drunk Hunters. While the
// trait TRAIT_BEAST_DRUNK is present, the hunter occasionally sees
// everyone around them as werewolves or gnolls, beasts all over shop.
// Only affects how OTHER mobs appear to the hunter; never changes
// the hunter's own appearance.
//
// Implemented as a status effect that ticks on its own timer,
// completely independent of the normal hallucination counter.

/// Minimum time (deciseconds) between beast delusion episodes.
#define BLOODHUNT_DELUSION_MIN_INTERVAL 90 SECONDS
/// Maximum time (deciseconds) between beast delusion episodes.
#define BLOODHUNT_DELUSION_MAX_INTERVAL 240 SECONDS
/// How long each delusion episode lasts (deciseconds).
#define BLOODHUNT_DELUSION_DURATION 12 SECONDS

// -------------------- Status Effect --------------------

/datum/status_effect/beast_drunk
	id = "beast_drunk_delusion"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1 // permanent until removed
	tick_interval = 10 SECONDS
	alert_type = null
	/// Cooldown world.time — don't fire again until this time.
	var/next_episode = 0
	/// Active delusion datum (if any), so we don't stack.
	var/datum/hallucination/delusion/beast_delusion/active_delusion

/datum/status_effect/beast_drunk/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE
	next_episode = world.time + rand(30 SECONDS, BLOODHUNT_DELUSION_MIN_INTERVAL)
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
	active_delusion = new /datum/hallucination/delusion/beast_delusion(H, TRUE)
	next_episode = world.time + rand(BLOODHUNT_DELUSION_MIN_INTERVAL, BLOODHUNT_DELUSION_MAX_INTERVAL)

/datum/status_effect/beast_drunk/on_remove()
	if(active_delusion && !QDELETED(active_delusion))
		qdel(active_delusion)
	active_delusion = null
	return ..()

// -------------------- Hallucination Datum --------------------

/datum/hallucination/delusion/beast_delusion
	natural = FALSE // never picked by the normal hallucination roller

/datum/hallucination/delusion/beast_delusion/New(mob/living/carbon/C, forced)
	// Bypass parent New() entirely — we handle our own image creation.
	// Call the grandparent /datum/hallucination/New() for base setup.
	target = C
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

	// Subtle audio cue — a single growl or snarl, not the full combat barrage
	target.playsound_local(target, pick(
		'sound/vo/mobs/wwolf/roar.ogg',
	), 35, TRUE)

	QDEL_IN(src, BLOODHUNT_DELUSION_DURATION)
