// ===================== STAKE DRIVER INTENTS =====================

/// Stake Driver base - horizontal slash. R1 combo sweeping left-to-right slashes at chest level.
/// Despite the sweeping motion, the stake blade has very little side range.
/datum/intent/stakedriver/horizslash
	name = "horizontal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "sweeps")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/iron_cut_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_cut_meat2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Stake Driver base - uppercut. Quickstep R1 rising slash from right to left, scraping the ground.
/datum/intent/stakedriver/uppercut
	name = "uppercut"
	icon_state = "incut"
	attack_verb = list("uppercuts", "rips upward")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/iron_cut_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_cut_meat2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Stake Driver base - forward jab. R1 combo finisher / backstep R1, a punching thrust straight ahead.
/datum/intent/stakedriver/forwardjab
	name = "forward jab"
	icon_state = "instab"
	attack_verb = list("jabs", "punches into")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/stakedriver/punch1.ogg', 'modular/sounds/trickweapons/stakedriver/punch2.ogg', 'modular/sounds/trickweapons/stakedriver/punch3.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

/// Stake Driver base - overhand punch. R2 overhand slash, cocking the arm back and slamming down.
/// Grazes the ground at the end of the swing. High commitment but good damage.
/datum/intent/stakedriver/overhandpunch
	name = "overhand punch"
	icon_state = "insmash"
	attack_verb = list("hammers down on", "overhand-slams")
	animname = "chop"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/stakedriver/punch1.ogg', 'modular/sounds/trickweapons/stakedriver/punch2.ogg', 'modular/sounds/trickweapons/stakedriver/punch3.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.35
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Stake Driver transformed - rapid jab. R1 combo of rapid forward jabs with low stamina cost.
/// Extremely short range, focused entirely in front. Fast and relentless against single targets.
/datum/intent/stakedriver/rapidjab
	name = "rapid jab"
	icon_state = "inpunch"
	attack_verb = list("jabs", "punches")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/stakedriver/punch1.ogg', 'modular/sounds/trickweapons/stakedriver/punch2.ogg', 'modular/sounds/trickweapons/stakedriver/punch3.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.97
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Stake Driver transformed - quick punch. Quickstep R1 short horizontal punch from right to left.
/datum/intent/stakedriver/quickpunch
	name = "quick punch"
	icon_state = "inpunch"
	attack_verb = list("punches", "strikes")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/stakedriver/punch1.ogg', 'modular/sounds/trickweapons/stakedriver/punch2.ogg', 'modular/sounds/trickweapons/stakedriver/punch3.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 0.90
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR

/// Stake Driver transformed - extending punch. R2 extending blow, blade fires outward mid-punch.
/// The hunter turns and punches forward as the stake fires outward.
/datum/intent/stakedriver/extendingpunch
	name = "extending punch"
	icon_state = "insmash"
	attack_verb = list("drives into", "extends into")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/stakedriver/combo1.ogg', 'modular/sounds/trickweapons/stakedriver/punch1.ogg')
	chargetime = 0
	penfactor = 35
	damfactor = 1.37
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Stake Driver transformed - pile bunker. Charged R2, the signature devastating explosion.
/// A drastically long windup followed by an explosive jab. Catastrophic damage if it lands.
/// 3.55x motion value from Bloodborne; highest single-hit damage in the game.
/datum/intent/stakedriver/pilebunker
	name = "pile bunker"
	icon_state = "insmash"
	attack_verb = list("pile bunkers", "detonates upon")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/stakedriver/explosion.ogg')
	penfactor = 70
	damfactor = 3.55
	chargetime = 15
	chargedrain = 3
	clickcd = CLICK_CD_HEAVY
	swingdelay = 12
	no_early_release = TRUE
	misscost = 20
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

// ===================== STAKE DRIVER =====================
// Base: Quick fist weapon. Jabs and hooks.
// Transformed: Primed pile bunker. One devastating hit, then reverts.
// 1H ONLY. Transformation primes the mechanism; landing a hit
// fires the pile bunker and automatically reverts to base state.

/obj/item/rogueweapon/trickweapon/stakedriver
	name = "stake driver"
	desc = "A trick weapon of the Artificer's Guild, fitted over the fist like a gauntlet. In its base form it delivers rapid punches augmented by a short metal stake. When primed, the internal mechanism charges a devastating pile bunker strike that fires on impact. Malum's ingenuity, miniaturized."
	icon_state = "stakedriver"
	item_state = "stakedriver"
	force = 18
	force_wielded = 0
	possible_item_intents = list(/datum/intent/stakedriver/horizslash, /datum/intent/stakedriver/uppercut, /datum/intent/stakedriver/forwardjab, /datum/intent/stakedriver/overhandpunch)
	gripped_intents = null
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_SWIFT
	wdefense = 2
	wdefense_wbonus = 0
	minstr = 8
	max_blade_int = 300
	max_integrity = 250
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/unarmed
	swingsound = list('sound/combat/wooshes/punch/punchwoosh (1).ogg', 'sound/combat/wooshes/punch/punchwoosh (2).ogg', 'sound/combat/wooshes/punch/punchwoosh (3).ogg')
	parrysound = list('sound/combat/parry/pugilism/unarmparry (1).ogg', 'sound/combat/parry/pugilism/unarmparry (2).ogg', 'sound/combat/parry/pugilism/unarmparry (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall2.ogg'
	throwforce = 8
	thrown_bclass = BCLASS_BLUNT
	sellprice = 55
	grid_width = 32
	grid_height = 32
	// --- Transformed state: Primed Pile Bunker ---
	transformed_name = "stake driver"
	transformed_desc = "The stake driver's internal mechanism is primed and ready. The next blow will unleash the full force of the pile bunker - a single, armor-shattering impact."
	transformed_icon_state = "stakedriver_t"
	transformed_item_state = "stakedriver_t"
	transformed_force = 35 // Massive single hit
	transformed_force_wielded = 0
	transformed_intents = list(/datum/intent/stakedriver/rapidjab, /datum/intent/stakedriver/quickpunch, /datum/intent/stakedriver/extendingpunch, /datum/intent/stakedriver/pilebunker)
	transformed_gripped_intents = null
	transformed_swingsound = list('sound/combat/wooshes/blunt/wooshmed (1).ogg', 'sound/combat/wooshes/blunt/wooshmed (2).ogg')
	transformed_wlength = WLENGTH_SHORT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 1
	transformed_wdefense_wbonus = 0
	transformed_minstr = 8
	transformed_associated_skill = /datum/skill/combat/unarmed
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_NORMAL

/// Mob render properties for one-handed display (gauntlet-style weapon).
/obj/item/rogueweapon/trickweapon/stakedriver/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -7,"sy" = -4,"nx" = 7,"ny" = -4,"wx" = -3,"wy" = -4,"ex" = 1,"ey" = -4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 110,"sturn" = -110,"wturn" = -110,"eturn" = 110,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)

/**
 * After landing a hit in primed (transformed) state, automatically
 * revert to base state. The pile bunker is a one-shot mechanism.
 */
/obj/item/rogueweapon/trickweapon/stakedriver/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!transformed)
		return
	if(!proximity_flag)
		return
	// Pile bunker fired - revert to base state
	transformed = FALSE
	apply_base_state()
	update_icon()
	update_force_dynamic()
	wdefense_dynamic = wdefense
	playsound(loc, 'sound/combat/hits/blunt/metalblunt (1).ogg', 100, TRUE)
	to_chat(user, span_warning("The pile bunker discharges with a thunderous crack!"))
	if(user.get_active_held_item() == src)
		user.update_a_intents()
		user.update_inv_hands()


