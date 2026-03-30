// ===================== TONITRUS INTENTS =====================
// Base form: Simple mace â€” reliable blunt strikes.
// Charged form: Bolt-wreathed mace â€” temporarily enhanced damage, auto-reverts.

/// Tonitrus base - strike. Standard horizontal blunt strike.
/datum/intent/tonitrus/strike
	name = "strike"
	icon_state = "instrike"
	attack_verb = list("strikes", "bashes")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.0
	clickcd = CLICK_CD_MELEE
	swingdelay = 0
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Tonitrus base - overhead. Downward diagonal blow from over the shoulder.
/datum/intent/tonitrus/overhead
	name = "overhead"
	icon_state = "insmash"
	attack_verb = list("smashes", "hammers")
	animname = "chop"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Tonitrus base - jab. Quick forward thrust with the mace head.
/datum/intent/tonitrus/jab
	name = "jab"
	icon_state = "instrike"
	attack_verb = list("jabs", "prods")
	animname = "thrust"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	swingdelay = 0
	item_d_type = "blunt"

/// Tonitrus base - slam. Heavy overhead slam, fully charged.
/datum/intent/tonitrus/slam
	name = "slam"
	icon_state = "incrush"
	attack_verb = list("slams", "crushes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Tonitrus charged - bolt strike. Electrically enhanced horizontal strike.
/datum/intent/tonitrus/boltstrike
	name = "bolt strike"
	icon_state = "instrike"
	attack_verb = list("shocks", "jolts")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/tonitrus/electric_buff.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.2
	clickcd = CLICK_CD_MELEE
	swingdelay = 0
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Tonitrus charged - bolt overhead. Crackling downward blow with electrical discharge.
/datum/intent/tonitrus/boltoverhead
	name = "bolt overhead"
	icon_state = "insmash"
	attack_verb = list("electrocutes", "thunders into")
	animname = "chop"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/tonitrus/electric_buff.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Tonitrus charged - bolt jab. Fast electrified thrust.
/datum/intent/tonitrus/boltjab
	name = "bolt jab"
	icon_state = "instrike"
	attack_verb = list("zaps", "shocks")
	animname = "thrust"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/tonitrus/electric_buff.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.05
	clickcd = CLICK_CD_FAST
	swingdelay = 0
	item_d_type = "blunt"

/// Tonitrus charged - bolt slam. Devastating electrically charged overhead slam.
/datum/intent/tonitrus/boltslam
	name = "bolt slam"
	icon_state = "incrush"
	attack_verb = list("thunder-slams", "bolt-crushes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/tonitrus/electric_buff.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.6
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG



// ===================== TONITRUS =====================
// Base: Simple mace â€” reliable blunt strikes (maces skill).
// Transformed: Bolt-charged mace â€” temporarily enhanced damage, auto-reverts.
// A unique trick weapon contrived by an eccentric artificer of the Guild.
// Strikes with the force of a thunderbolt, powered by arcyne energy.
//
// Unique mechanic: Transformation is temporary. After a set duration,
// the weapon automatically reverts to base state via addtimer.

/obj/item/rogueweapon/trickweapon/tonitrus
	name = "tonitrus"
	desc = "A unique trick weapon contrived by an eccentric artificer of the Guild. In its base form, a simple but sturdy mace with an unusual metallic head. Hidden within is a mechanism that, when activated, wreathes the striking surface in crackling arcyne energy."
	icon_state = "tonitrus"
	item_state = "tonitrus"
	force = 22
	force_wielded = 25
	possible_item_intents = list(/datum/intent/tonitrus/strike, /datum/intent/tonitrus/overhead, /datum/intent/tonitrus/jab, /datum/intent/tonitrus/slam)
	gripped_intents = list(/datum/intent/tonitrus/strike, /datum/intent/tonitrus/overhead, /datum/intent/tonitrus/jab, /datum/intent/tonitrus/slam)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_NORMAL
	wdefense = 4
	wdefense_wbonus = 0
	minstr = 7
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall2.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_BLUNT
	smeltresult = /obj/item/ingot/steel
	sellprice = 55
	grid_width = 32
	grid_height = 64
	/// Duration of the electrical charge in deciseconds (default: 10 seconds).
	var/charge_duration = 10 SECONDS
	/// Timer ID for the auto-revert, so we can cancel it if manually reverted.
	var/charge_timer_id
	// --- Transformed state: Bolt-charged mace ---
	transformed_name = "tonitrus"
	transformed_desc = "The tonitrus, now crackling with arcyne energy. Arcs of lightning dance across the metallic head, each strike carrying the force of a thunderbolt. The charge is unstable â€” it will not last long."
	transformed_icon_state = "tonitrus_t"
	transformed_item_state = "tonitrus_t"
	transformed_force = 26
	transformed_force_wielded = 29
	transformed_intents = list(/datum/intent/tonitrus/boltstrike, /datum/intent/tonitrus/boltoverhead, /datum/intent/tonitrus/boltjab, /datum/intent/tonitrus/boltslam)
	transformed_gripped_intents = list(/datum/intent/tonitrus/boltstrike, /datum/intent/tonitrus/boltoverhead, /datum/intent/tonitrus/boltjab, /datum/intent/tonitrus/boltslam)
	transformed_swingsound = BLADEWOOSH_MED
	transformed_wlength = WLENGTH_SHORT
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 4
	transformed_wdefense_wbonus = 0
	transformed_minstr = 7
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_NORMAL

/// Mob render properties for one-handed and wielded display (mace-sized).
/obj/item/rogueweapon/trickweapon/tonitrus/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.5,"sx" = -7,"sy" = -4,"nx" = 7,"ny" = -4,"wx" = -3,"wy" = -4,"ex" = 1,"ey" = -4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 110,"sturn" = -110,"wturn" = -110,"eturn" = 110,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.6,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)

/**
 * Overrides transform_weapon to add auto-revert timer when charging,
 * and to cancel any existing timer when manually reverting.
 * The electrical charge is temporary â€” it fades after charge_duration.
 */
/obj/item/rogueweapon/trickweapon/tonitrus/transform_weapon(mob/living/user)
	// If already charged and user is manually reverting, cancel the auto-revert timer
	if(transformed && charge_timer_id)
		deltimer(charge_timer_id)
		charge_timer_id = null
	// Perform the standard transformation
	..()
	// If we just entered charged mode, start the auto-revert timer
	if(transformed)
		charge_timer_id = addtimer(CALLBACK(src, PROC_REF(auto_revert)), charge_duration, TIMER_STOPPABLE)
		to_chat(user, span_warning("Arcyne energy crackles through [src] â€” it won't last long!"))

/**
 * Called by the auto-revert timer when the charge expires.
 * Finds the current holder and reverts the weapon to base state.
 */
/obj/item/rogueweapon/trickweapon/tonitrus/proc/auto_revert()
	charge_timer_id = null
	if(!transformed)
		return
	// Revert to base state
	transformed = FALSE
	if(wielded || altgripped)
		var/mob/living/holder = loc
		if(istype(holder))
			ungrip(holder, show_message = FALSE)
	apply_base_state()
	update_icon()
	update_force_dynamic()
	wdefense_dynamic = wdefense
	playsound(loc, 'sound/combat/clash_draw.ogg', 80, TRUE)
	// Notify holder
	if(ismob(loc))
		var/mob/living/user = loc
		to_chat(user, span_warning("The arcyne charge fades from [src]."))
		if(user.get_active_held_item() == src)
			user.update_a_intents()
			user.update_inv_hands()



