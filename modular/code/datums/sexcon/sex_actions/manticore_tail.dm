// ── Manticore Tail Sex Actions ──────────────────────────────────────────────
// All sex actions specific to the manticore tail maw orifice.
// Requires /obj/item/organ/tail/manticore on the user or target.
// Actions are split into: tailjob, tailpegging, oral, penetration,
// frot+engulf, fisting, pear of anguish (extreme), and chastity teasing.

/// Helper: returns the manticore tail organ on the mob, or null.
/proc/get_manticore_tail(mob/living/carbon/human/H)
	var/obj/item/organ/tail/T = H?.getorganslot(ORGAN_SLOT_TAIL)
	if(istype(T, /obj/item/organ/tail/manticore))
		return T
	return null

// ════════════════════════════════════════════════════════════════════════════
// TAILJOB — Maw wraps around target's cock, feelers milking
// ════════════════════════════════════════════════════════════════════════════

/// User forces their tail maw onto the target's cock.
/datum/sex_action/manticore_tailjob
	name = "Engulf their cock with tail maw"
	check_same_tile = FALSE
	target_sex_part = SEX_PART_COCK

/datum/sex_action/manticore_tailjob/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailjob/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailjob/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail blooms open, the bonelike plates fanning apart as the maw descends over [target]'s cock, feelers latching on with a wet, suckling desperation."))
	playsound(target, 'sound/misc/mat/insert (1).ogg', 25, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_tailjob/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user]'s tail pulses in slow, languid waves around [target]'s cock, the feelers inside tracing every ridge with agonizing care."
		if(SEX_FORCE_MID)
			message = "[user]'s tail maw suckles [target]'s cock in deliberate, milking contractions, the feelers spiraling tighter with each pulse."
		if(SEX_FORCE_HIGH)
			message = "[user]'s tail clamps down hard around [target]'s cock, the feelers inside writhing in frantic waves, the vacuum seal making an obscene, wet squelch."
		if(SEX_FORCE_EXTREME)
			message = "[user]'s tail maw bears down on [target]'s cock with bruising force, every feeler suctioned tight and pumping, the muscular walls milking in crushing, rhythmic spasms."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 3, 0, TRUE)
	target.sexcon.handle_passive_ejaculation(user)

/datum/sex_action/manticore_tailjob/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail releases [target]'s cock with a wet pop, the feelers reluctantly peeling free one by one."))
	playsound(target, 'sound/misc/mat/insert (2).ogg', 20, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_tailjob/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE

/// Target uses the manticore's tail maw on themselves.
/datum/sex_action/manticore_tailjob_receive
	name = "Use their tail maw on my cock"
	check_same_tile = FALSE
	user_sex_part = SEX_PART_COCK

/datum/sex_action/manticore_tailjob_receive/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailjob_receive/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailjob_receive/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] grabs [target]'s tail and pushes [user.p_their()] cock into the blooming maw, gasping as the feelers latch on."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 25, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_tailjob_receive/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user] slowly rocks [user.p_their()] hips into [target]'s tail maw, the feelers inside pulsing in response to each gentle thrust."
		if(SEX_FORCE_MID)
			message = "[user] fucks [target]'s tail with a steady rhythm, the maw's feelers wrapping tighter with each stroke, slick with sweet nectar."
		if(SEX_FORCE_HIGH)
			message = "[user] ruts into [target]'s tail maw with abandon, the orifice squelching around [user.p_their()] cock as feelers lash at the shaft."
		if(SEX_FORCE_EXTREME)
			message = "[user] rams [user.p_their()] cock into [target]'s tail with punishing force, the maw clenching so hard the feelers bruise, each thrust making the plates rattle."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.outercourse_noise(target, TRUE)
	user.sexcon.perform_sex_action(user, 3, 0, TRUE)
	user.sexcon.handle_passive_ejaculation(target)

/datum/sex_action/manticore_tailjob_receive/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] pulls free from [target]'s tail maw, strings of slick nectar trailing between them."))

/datum/sex_action/manticore_tailjob_receive/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE


// ════════════════════════════════════════════════════════════════════════════
// TAILPEGGING — Closed tail bud forced into someone's ass / receiving anal
// ════════════════════════════════════════════════════════════════════════════

/// User forces their sealed tail bud into the target's ass.
/datum/sex_action/manticore_tailpeg
	name = "Peg them with tail"
	check_same_tile = FALSE
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_ANUS

/datum/sex_action/manticore_tailpeg/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(anal_blocked_by_rear_plug(user, target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailpeg/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailpeg/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail curls between [target]'s legs, the sealed bud pressing against [target]'s rim before pushing inside with a slow, deliberate pressure."))
	playsound(target, 'sound/misc/mat/insert (1).ogg', 25, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_tailpeg/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user]'s tail eases in and out of [target]'s rear, the sealed bud's ridged plates dragging across [target]'s walls with each careful stroke."
		if(SEX_FORCE_MID)
			message = "[user] works [user.p_their()] tail deeper, the bud twisting as it pumps [target]'s ass, plates grinding against the stretched rim."
		if(SEX_FORCE_HIGH)
			message = "[user]'s tail pistons into [target]'s ass, the sealed bud punching deep enough to make [target]'s stomach bulge, plates rattling with each wet thrust."
		if(SEX_FORCE_EXTREME)
			message = "[user] ruts [target]'s guts with [user.p_their()] tail like an animal, the bud hammering [target]'s insides without care, each thrust accompanied by a sickening wet slap."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.outercourse_noise(target, TRUE)
	user.sexcon.perform_sex_action(target, 2, 3, TRUE)

/datum/sex_action/manticore_tailpeg/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail slides free from [target]'s ruined rear, the bud glistening with slick."))

/datum/sex_action/manticore_tailpeg/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

/// Target penetrates the manticore's tail maw.
/datum/sex_action/manticore_tailpeg_receive
	name = "Fuck their tail maw"
	check_same_tile = FALSE
	category = SEX_CATEGORY_PENETRATE
	user_sex_part = SEX_PART_COCK

/datum/sex_action/manticore_tailpeg_receive/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailpeg_receive/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tailpeg_receive/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] spreads apart the plates on [target]'s tail and sinks [user.p_their()] cock into the waiting maw, feelers immediately latching on with hungry suction."))

/datum/sex_action/manticore_tailpeg_receive/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user] gently rocks into [target]'s tail maw, the feelers inside pulsing around [user.p_their()] shaft in warm, milking waves."
		if(SEX_FORCE_MID)
			message = "[user] fucks [target]'s tail with growing need, the maw clenching in response, feelers spiraling tight around [user.p_their()] cock."
		if(SEX_FORCE_HIGH)
			message = "[user] pounds [target]'s tail maw, each thrust making the orifice squelch obscenely as the feelers inside writhe and grip."
		if(SEX_FORCE_EXTREME)
			message = "[user] uses [target]'s tail like a cocksleeve, hammering the maw with reckless force, feelers torn between gripping and being crushed by the brutality."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.outercourse_noise(target, TRUE)
	user.sexcon.perform_sex_action(user, 3, 0, TRUE)
	user.sexcon.handle_passive_ejaculation(target)

/datum/sex_action/manticore_tailpeg_receive/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] pulls [user.p_their()] cock free from [target]'s tail maw with a slick pop, trails of nectar clinging stubbornly."))

/datum/sex_action/manticore_tailpeg_receive/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return user.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// ORAL — Tail maw forced onto someone's mouth / someone eats the maw
// ════════════════════════════════════════════════════════════════════════════

/// User forces their tail maw over the target's mouth.
/datum/sex_action/manticore_tail_oral_force
	name = "Force tail maw onto their mouth"
	check_same_tile = FALSE
	target_sex_part = SEX_PART_JAWS

/datum/sex_action/manticore_tail_oral_force/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_oral_force/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_oral_force/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail rises and clamps over [target]'s mouth, the maw blooming open to seal around [target]'s lips, feelers spilling past [target]'s teeth."))

/datum/sex_action/manticore_tail_oral_force/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user]'s tail maw pulses gently over [target]'s mouth, the feelers lazily exploring [target]'s tongue and gums, secreting a tingling sweet nectar."
		if(SEX_FORCE_MID)
			message = "The feelers inside [user]'s tail push deeper into [target]'s mouth, curling around [target]'s tongue and pulling it into the warm, slick maw."
		if(SEX_FORCE_HIGH)
			message = "[user]'s tail maw clamps down on [target]'s face, feelers shoving deep into [target]'s throat, the orifice pulsing as it force-feeds its sweet slick down [target]'s gullet."
		if(SEX_FORCE_EXTREME)
			message = "[user]'s tail seals [target]'s mouth completely, the feelers writhing down [target]'s throat in a suffocating mass, pumping nectar until it bubbles from [target]'s nose."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 2, 2, TRUE)

/datum/sex_action/manticore_tail_oral_force/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail releases [target]'s mouth, the feelers peeling free with strings of nectar and saliva trailing between them."))

/datum/sex_action/manticore_tail_oral_force/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

/// Target eats out the manticore's tail maw.
/datum/sex_action/manticore_tail_oral_receive
	name = "Eat out their tail maw"
	check_same_tile = FALSE
	user_sex_part = SEX_PART_JAWS

/datum/sex_action/manticore_tail_oral_receive/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_oral_receive/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_oral_receive/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] buries [user.p_their()] face in [target]'s blooming tail maw, tongue pushing past the plates as the feelers latch on to [user.p_their()] lips."))

/datum/sex_action/manticore_tail_oral_receive/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user] laps gently at [target]'s tail maw, tongue tracing the rim of the plates as the feelers curl around [user.p_their()] chin, tasting salt and skin."
		if(SEX_FORCE_MID)
			message = "[user] pushes [user.p_their()] tongue deep into [target]'s tail, the feelers wrapping around the wet muscle and pulling it further inside, nectar flooding [user.p_their()] mouth."
		if(SEX_FORCE_HIGH)
			message = "[user] eats [target]'s tail maw with reckless hunger, tongue plunging in and out as the feelers lash and suckle at [user.p_their()] lips, both their faces slicked with sweet nectar."
		if(SEX_FORCE_EXTREME)
			message = "[user] buries [user.p_their()] face so deep in [target]'s tail the maw clamps around [user.p_their()] skull, feelers coating every inch of tongue and lips as the orifice tries to swallow [user.p_their()] head whole."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	target.sexcon.perform_sex_action(target, 3, 0, TRUE)

/datum/sex_action/manticore_tail_oral_receive/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] pulls [user.p_their()] drenched face from [target]'s tail maw, chin dripping with sweet nectar, the feelers straining after [user.p_them()]."))

/datum/sex_action/manticore_tail_oral_receive/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// FROT + ENGULF — Manticore frets their cock against target's, then maw engulfs both
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/manticore_frot_engulf
	name = "Frot then engulf both cocks with tail"
	check_same_tile = FALSE
	user_sex_part = SEX_PART_COCK
	target_sex_part = SEX_PART_COCK

/datum/sex_action/manticore_frot_engulf/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_frot_engulf/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_frot_engulf/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] presses [user.p_their()] cock against [target]'s, grinding the two together before [user.p_their()] tail maw blooms open and descends, engulfing both shafts in warm, feeler-lined flesh."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 25, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_frot_engulf/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user]'s tail maw pulses around both cocks in lazy, milking waves, the feelers individually tending to each shaft, curling between them where the two press together."
		if(SEX_FORCE_MID)
			message = "The feelers inside [user]'s tail spiral around both cocks in tandem, squeezing and massaging as the maw's walls undulate, slick nectar making both shafts glide against each other."
		if(SEX_FORCE_HIGH)
			message = "[user]'s tail clenches both cocks together with crushing pressure, the feelers going wild, suctioning to every inch of flesh as the maw pumps in hard, rhythmic contractions."
		if(SEX_FORCE_EXTREME)
			message = "[user]'s tail bears down on both cocks with bruising, desperate force, feelers writhing between the two shafts in frenzied knots, the maw's muscular walls spasming as it tries to milk both to completion simultaneously."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(user, 3, 0, TRUE)
	target.sexcon.handle_passive_ejaculation(user)
	user.sexcon.handle_passive_ejaculation(target)

/datum/sex_action/manticore_frot_engulf/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail reluctantly releases both cocks, the maw peeling open to reveal both shafts glistening with nectar and each other's spend."))

/datum/sex_action/manticore_frot_engulf/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check() || target.sexcon.finished_check())
		return TRUE
	return FALSE

// ════════════════════════════════════════════════════════════════════════════
// FISTING — Someone fists the tail maw
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/manticore_fist_maw
	name = "Fist their tail maw"
	check_same_tile = FALSE

/datum/sex_action/manticore_fist_maw/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_fist_maw/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_fist_maw/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] pries apart the plates of [target]'s tail maw and pushes [user.p_their()] fist inside, the feelers immediately swarming [user.p_their()] fingers with desperate suction."))

/datum/sex_action/manticore_fist_maw/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user] slowly works [user.p_their()] fingers inside [target]'s tail maw, the feelers curling around each digit individually, tasting skin and pulling gently."
		if(SEX_FORCE_MID)
			message = "[user] pumps [user.p_their()] fist in and out of [target]'s tail, the maw's walls clenching around the intrusion as feelers coat [user.p_their()] wrist in warm, sweet slick."
		if(SEX_FORCE_HIGH)
			message = "[user] fists [target]'s tail maw with rough, twisting strokes, the orifice squelching obscenely around [user.p_their()] arm as the feelers grip and suckle at every knuckle."
		if(SEX_FORCE_EXTREME)
			message = "[user] rams [user.p_their()] arm elbow-deep into [target]'s tail maw, the muscular walls bearing down with bruising force as the feelers writhe and suction to [user.p_their()] skin in a frenzied mass."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	target.sexcon.perform_sex_action(target, 2, 3, TRUE)

/datum/sex_action/manticore_fist_maw/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] pulls [user.p_their()] arm free from [target]'s tail maw, the orifice gaping and trembling, feelers straining after the retreating limb."))

/datum/sex_action/manticore_fist_maw/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// CHASTITY TEASING — Feelers wriggle through cage bars
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/manticore_chastity_tease
	name = "Tease their cage with tail feelers"
	check_same_tile = FALSE
	target_sex_part = SEX_PART_COCK

/datum/sex_action/manticore_chastity_tease/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.chastity_device)
		return FALSE
	return TRUE

/datum/sex_action/manticore_chastity_tease/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.chastity_device)
		return FALSE
	return TRUE

/datum/sex_action/manticore_chastity_tease/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail maw blooms open against [target]'s cage, the feelers inside slipping between the bars to wriggle against the trapped flesh within."))

/datum/sex_action/manticore_chastity_tease/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "The feelers inside [user]'s tail lazily probe through [target]'s cage bars, tracing the contours of [target]'s trapped cock with infuriating slowness, each touch leaving a tingle of venom."
		if(SEX_FORCE_MID)
			message = "More feelers squeeze between [target]'s cage bars, the tiny tendrils wrapping around whatever flesh they can reach, pulsing with warmth and secreting their tingling nectar against [target]'s swelling, caged cock."
		if(SEX_FORCE_HIGH)
			message = "[user]'s tail feelers push aggressively through [target]'s cage, dozens of tendrils wriggling against the trapped shaft, probing [target]'s slit, and smearing venom into every crevice they can reach."
		if(SEX_FORCE_EXTREME)
			message = "[user]'s tail seals around [target]'s cage entirely, every feeler inside fighting through the bars in a swarming mass, coating the trapped cock in sweet nectar until it drools from the cage's drain hole."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 3, 0, TRUE)

/datum/sex_action/manticore_chastity_tease/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail withdraws from [target]'s cage, the feelers reluctantly unthreading from between the bars, strings of nectar trailing behind."))

/datum/sex_action/manticore_chastity_tease/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// EXTREME: PEAR OF ANGUISH — Tail bud forced in and spread apart
// Requires extreme_erp enabled on BOTH parties.
// Anal → pelvis fracture, Oral → jaw fracture, Vaginal → CBT
// ════════════════════════════════════════════════════════════════════════════

/// Helper: returns TRUE if both user and target have extreme ERP content enabled.
/proc/both_extreme_erp(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user?.client?.prefs?.extreme_erp)
		return FALSE
	if(!target?.client?.prefs?.extreme_erp)
		return FALSE
	return TRUE

/// Pear of Anguish — ANAL. Forces sealed tail bud into ass, then spreads plates apart.
/// Applies pelvis fracture on finish.
/datum/sex_action/manticore_pear_anal
	name = "Pear of Anguish (Anal)"
	check_same_tile = FALSE
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_ANUS

/datum/sex_action/manticore_pear_anal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!both_extreme_erp(user, target))
		return FALSE
	if(anal_blocked_by_rear_plug(user, target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_pear_anal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!both_extreme_erp(user, target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_pear_anal/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user]'s tail presses its sealed bud against [target]'s rim, the interlocking plates grinding together as it forces its way inside with a cruel, deliberate slowness."), ignored_mobs = excluded)
	playsound(target, 'sound/misc/mat/insert (1).ogg', 35, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_pear_anal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user]'s tail bud begins to flower open inside [target]'s ass, the bonelike plates spreading apart with a grinding creak, stretching [target]'s insides far beyond what flesh was meant to accommodate. [target]'s screams are accompanied by the wet crack of something giving way deep inside."), ignored_mobs = excluded)
	playsound(target, 'sound/combat/fracture/fracturewet (1).ogg', 40, TRUE, ignore_walls = FALSE)
	user.sexcon.perform_sex_action(target, 0, 10, TRUE)

/datum/sex_action/manticore_pear_anal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user] rips [user.p_their()] tail free from [target]'s destroyed rear, the plates snapping shut with a wet crunch, leaving behind a gaping, prolapsed ruin."), ignored_mobs = excluded)
	// Apply pelvis fracture
	var/obj/item/bodypart/chest/chest = target.get_bodypart(BODY_ZONE_CHEST)
	if(chest)
		chest.add_wound(/datum/wound/fracture/groin)

/datum/sex_action/manticore_pear_anal/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

/// Pear of Anguish — ORAL. Forces sealed tail bud into mouth, then spreads plates apart.
/// Applies jaw fracture on finish.
/datum/sex_action/manticore_pear_oral
	name = "Pear of Anguish (Oral)"
	check_same_tile = FALSE
	target_sex_part = SEX_PART_JAWS

/datum/sex_action/manticore_pear_oral/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!both_extreme_erp(user, target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_pear_oral/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!both_extreme_erp(user, target))
		return FALSE
	return TRUE

/datum/sex_action/manticore_pear_oral/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user]'s tail forces its sealed bud past [target]'s lips, the ridged plates scraping across teeth and gums as it pushes deep into [target]'s mouth."), ignored_mobs = excluded)
	playsound(target, 'sound/misc/mat/insert (1).ogg', 35, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_pear_oral/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("The bud inside [target]'s mouth begins to blossom, the bonelike plates cranking apart with agonizing slowness, forcing [target]'s jaw wider and wider until the joints pop and creak, teeth cracking against the unyielding chitin."), ignored_mobs = excluded)
	playsound(target, 'sound/combat/fracture/fracturewet (1).ogg', 40, TRUE, ignore_walls = FALSE)
	user.sexcon.perform_sex_action(target, 0, 10, TRUE)

/datum/sex_action/manticore_pear_oral/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user] wrenches [user.p_their()] tail free from [target]'s ruined mouth, the plates folding shut as they drag loose teeth and blood with them, leaving [target]'s jaw hanging at a sickening angle."), ignored_mobs = excluded)
	// Apply jaw fracture
	var/obj/item/bodypart/head/head = target.get_bodypart(BODY_ZONE_HEAD)
	if(head)
		head.add_wound(/datum/wound/fracture/mouth)

/datum/sex_action/manticore_pear_oral/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

/// Pear of Anguish — VAGINAL. Forces sealed tail bud into cunt, then spreads plates apart.
/// Applies CBT wound (testicular torsion repurposed as genital trauma) on finish.
/datum/sex_action/manticore_pear_vaginal
	name = "Pear of Anguish (Vaginal)"
	check_same_tile = FALSE
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_CUNT

/datum/sex_action/manticore_pear_vaginal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!both_extreme_erp(user, target))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/manticore_pear_vaginal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!both_extreme_erp(user, target))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/manticore_pear_vaginal/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user]'s tail pushes its sealed bud between [target]'s legs, the interlocking plates pressing against [target]'s entrance before forcing inside with a sick, grinding push."), ignored_mobs = excluded)
	playsound(target, 'sound/misc/mat/insert (1).ogg', 35, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_pear_vaginal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("The tail bud blossoms inside [target], the plates spreading apart with merciless force, stretching walls that were never meant to give this far. Something tears deep inside, the wet sound of ripping flesh drowned out by [target]'s agonized screaming."), ignored_mobs = excluded)
	playsound(target, 'sound/combat/fracture/fracturewet (1).ogg', 40, TRUE, ignore_walls = FALSE)
	user.sexcon.perform_sex_action(target, 0, 10, TRUE)

/datum/sex_action/manticore_pear_vaginal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/excluded = get_extreme_content_excluded_mobs(target)
	user.visible_message(span_userdanger("[user] tears [user.p_their()] tail free from [target]'s savaged cunt, the plates folding shut with a crunch, dragging blood and tissue with them."), ignored_mobs = excluded)
	// Apply CBT wound as genital trauma
	var/obj/item/bodypart/chest/chest = target.get_bodypart(BODY_ZONE_CHEST)
	if(chest)
		chest.add_wound(/datum/wound/cbt)

/datum/sex_action/manticore_pear_vaginal/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// BREAST SUCKING — Tail maw latches onto target's breast and suckles
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/manticore_tail_suck_breast
	name = "Suckle their breast with tail maw"
	check_same_tile = FALSE

/datum/sex_action/manticore_tail_suck_breast/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_suck_breast/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_CHEST, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_suck_breast/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail rises and blooms open over [target]'s breast, the maw sealing around the soft flesh as feelers spill out to map every curve, latching onto the nipple with a wet, suckling pop."))
	playsound(target, 'sound/misc/mat/insert (1).ogg', 20, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_tail_suck_breast/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/organ/breasts/tits = target.getorganslot(ORGAN_SLOT_BREASTS)
	var/lactating = tits?.lactating
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			if(lactating)
				message = "[user]'s tail maw pulses in slow, coaxing waves around [target]'s breast, feelers tracing circles around the nipple as warm milk beads against the tiny tendrils, each drop eagerly siphoned into the orifice."
			else
				message = "[user]'s tail suckles [target]'s breast in lazy, kneading waves, the feelers curling around the nipple and tugging gently, leaving small circular marks in the soft flesh."
		if(SEX_FORCE_MID)
			if(lactating)
				message = "The feelers inside [user]'s tail wrap tight around [target]'s nipple and pull in rhythmic pulses, milking with mechanical precision as the maw's vacuum seal draws a steady flow of warm cream into the hungry orifice."
			else
				message = "[user]'s tail maw suckles harder, the feelers spiraling around [target]'s nipple in tight coils, each pulse of suction pulling the flesh deeper into the warm, slick maw."
		if(SEX_FORCE_HIGH)
			if(lactating)
				message = "[user]'s tail clamps [target]'s breast with bruising suction, the feelers aggressively pumping the nipple as milk sprays into the maw in thick jets, the orifice gulping audibly with each contraction."
			else
				message = "[user]'s tail bears down on [target]'s breast, the feelers suctioned so tight they leave angry welts, the maw chewing and massaging the flesh with its muscular walls."
		if(SEX_FORCE_EXTREME)
			if(lactating)
				message = "[user]'s tail maw swallows [target]'s entire breast, feelers coating every inch in suctioning tendrils that milk with desperate, bruising force, cream overflowing from the orifice's sealed edges as it drinks and drinks."
			else
				message = "[user]'s tail maw engulfs [target]'s breast whole, the feelers inside writhing against every inch of captured flesh, suctioning hard enough to leave the skin mottled dark when it finally releases."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 3, 0, TRUE)

/datum/sex_action/manticore_tail_suck_breast/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail releases [target]'s breast with a wet pop, the feelers peeling free reluctantly, leaving the flesh slick with nectar and covered in small, circular suction marks."))

/datum/sex_action/manticore_tail_suck_breast/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// SOUNDING — Feelers probe and penetrate the target's urethra
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/manticore_tail_sounding
	name = "Sound them with tail feelers"
	check_same_tile = FALSE
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_COCK

/datum/sex_action/manticore_tail_sounding/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	var/obj/item/organ/penis/cock = target.getorganslot(ORGAN_SLOT_PENIS)
	if(!cock)
		return FALSE
	// Slit-type penises have no discrete urethral opening
	if(cock.sheath_type == SHEATH_TYPE_SLIT)
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_sounding/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	var/obj/item/organ/penis/cock = target.getorganslot(ORGAN_SLOT_PENIS)
	if(!cock)
		return FALSE
	if(cock.sheath_type == SHEATH_TYPE_SLIT)
		return FALSE
	return TRUE

/datum/sex_action/manticore_tail_sounding/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail maw blooms open against [target]'s cock, the feelers prodding curiously at the tip before a thin tendril traces circles around [target]'s slit, then pushes its way inside."))
	playsound(target, 'sound/misc/mat/insert (1).ogg', 15, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_tail_sounding/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "A single feeler worms its way deeper into [target]'s urethra, the tendril pulsing with warmth as it secretes a tingling venom that numbs the initial burn, slowly easing the tissue open from within."
		if(SEX_FORCE_MID)
			message = "Two feelers push into [target]'s dickhole, the tiny tendrils spiraling around each other as they probe deeper, their tips smearing venom against the hardly-touched inner walls until the burning fades into a buzzing, electric pleasure."
		if(SEX_FORCE_HIGH)
			message = "A bundle of feelers forces its way into [target]'s urethra, the tendrils wriggling deeper with each pulse, stretching the slit wider than it was ever meant to go as they pump their tingling toxin into every raw inch of tissue."
		if(SEX_FORCE_EXTREME)
			message = "[user]'s feelers flood [target]'s cock from within, a writhing mass of tendrils bulging the shaft visibly as they bore deeper, venom pouring into the abused canal until [target]'s entire length throbs and twitches with involuntary spasms."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	// Sounding: high pain, moderate arousal
	user.sexcon.perform_sex_action(target, 1, 7, TRUE)
	user.sexcon.try_do_pain_scream(target, 7)
	target.sexcon.handle_passive_ejaculation(user)

/datum/sex_action/manticore_tail_sounding/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s feelers slowly retract from [target]'s urethra one by one, each tendril pulling free with a faint pop, leaving the slit gaping and drooling a mixture of pre and sweet venom."))

/datum/sex_action/manticore_tail_sounding/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()

// ════════════════════════════════════════════════════════════════════════════
// MAW TO PUSSY — Tail maw seals over target's vagina, feelers invade
// ════════════════════════════════════════════════════════════════════════════

/// User presses their tail maw against the target's pussy.
/datum/sex_action/manticore_maw_to_pussy
	name = "Seal tail maw over their pussy"
	check_same_tile = FALSE
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_CUNT

/datum/sex_action/manticore_maw_to_pussy/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/manticore_maw_to_pussy/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_manticore_tail(user))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/manticore_maw_to_pussy/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail curls between [target]'s thighs, the maw blooming open to press flush against [target]'s cunt, sealing tight as the feelers inside spill out to taste the slick folds."))
	playsound(target, 'sound/misc/mat/insert (1).ogg', 25, TRUE, ignore_walls = FALSE)

/datum/sex_action/manticore_maw_to_pussy/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "[user]'s tail feelers lazily explore [target]'s folds, the tiny tendrils tracing the labia with maddening precision, a few bolder ones slipping just inside the entrance to taste the warmth within."
		if(SEX_FORCE_MID)
			message = "The feelers push deeper into [target]'s cunt, dozens of tiny tendrils wriggling past the entrance and carpeting [target]'s inner walls, each one pulsing independently as they secrete their sweet, tingling venom against every sensitive ridge."
		if(SEX_FORCE_HIGH)
			message = "[user]'s tail maw bears down on [target]'s pussy with crushing suction, the feelers invading in a writhing mass, filling [target]'s insides as the tendrils lash against [target]'s cervix, pumping venom and nectar in alternating waves."
		if(SEX_FORCE_EXTREME)
			message = "[user]'s tail seals [target]'s cunt completely, the maw vacuum-locked as every feeler inside bores deeper, a churning mass of tendrils stretching [target]'s walls and flooding [target]'s womb with sweet slick until [target]'s stomach visibly distends."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()
	user.sexcon.perform_sex_action(target, 4, 1, TRUE)

/datum/sex_action/manticore_maw_to_pussy/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user]'s tail peels free from [target]'s pussy with a long, wet sucking sound, the feelers withdrawing one by one as a flood of nectar pours from [target]'s gaping, trembling cunt."))

/datum/sex_action/manticore_maw_to_pussy/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return target.sexcon.finished_check()
