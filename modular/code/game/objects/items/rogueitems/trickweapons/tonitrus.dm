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
	icon_state = "instab"
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
	icon_state = "instab"
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
	/// Bonus damage multiplier vs moths when charged. 0.3 = 30% extra.
	var/bugzapper_bonus = 0.3
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
	transform_sound = 'modular/sounds/trickweapons/tonitrus/electric_buff.ogg'
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
	special = /datum/special_intent/tonitrus_strike
	transformed_special = /datum/special_intent/tonitrus_discharge

/// Mob render properties for one-handed and wielded display (mace-sized).
/// Tonitrus uses the same sprite for both forms — only the charge effect changes.
/obj/item/rogueweapon/trickweapon/tonitrus/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.3,"sx" = -7,"sy" = -3,"nx" = 6,"ny" = -4,"wx" = -2,"wy" = -2,"ex" = -4,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -89,"sturn" = 0,"wturn" = -82,"eturn" = 82,"nflip" = 4,"sflip" = 1,"wflip" = 4,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.4,"sx" = 0,"sy" = 0,"nx" = 0,"ny" = 0,"wx" = 0,"wy" = 0,"ex" = 0,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 4,"eflip" = 0)

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
	// If we just entered charged mode, start the auto-revert timer and enable bugzapper
	if(transformed)
		charge_timer_id = addtimer(CALLBACK(src, PROC_REF(auto_revert)), charge_duration, TIMER_STOPPABLE)
		RegisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS, PROC_REF(apply_bugzapper_bonus), override = TRUE)
		to_chat(user, span_warning("Arcyne energy crackles through [src] \u2014 it won't last long!"))
	else
		UnregisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS)
		// Restore serrated signal if applicable (bugzapper override displaced it)
		update_serrated_signal()

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
	UnregisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS)
	// Restore serrated signal if applicable (bugzapper override displaced it)
	update_serrated_signal()
	playsound(loc, 'sound/combat/clash_draw.ogg', 80, TRUE)
	// Notify holder
	if(ismob(loc))
		var/mob/living/user = loc
		to_chat(user, span_warning("The arcyne charge fades from [src]."))
		if(user.get_active_held_item() == src)
			user.update_a_intents()
			user.update_inv_hands()

// ===================== BUGZAPPER SYSTEM =====================
// The Tonitrus deals bonus electrical damage to moths when charged.
// Bugs are funny, and lightning is particularly devastating to insectoids.

/**
 * Signal handler for COMSIG_ITEM_ATTACK_SUCCESS (charged mode only).
 * Applies bonus brute damage to insectoid and arachnid targets — the arcyne
 * charge acts as a bugzapper. Triggers against:
 * - Moth player characters (species id "moth")
 * - Shapespider wildshape druids (species id "shapespider")
 * - Spider simple mobs (faction "spiders")
 * - Any mob with the MOB_BUG biotype
 */
/obj/item/rogueweapon/trickweapon/tonitrus/proc/apply_bugzapper_bonus(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || !transformed)
		return
	if(!is_bugzapper_target(target))
		return
	var/bonus = round(force_dynamic * bugzapper_bonus)
	if(bonus <= 0)
		return
	target.apply_damage(bonus, BRUTE)
	// Visual/audio feedback — the zap is visceral
	playsound(target.loc, 'modular/sounds/trickweapons/tonitrus/electric_buff.ogg', 60, TRUE)

/**
 * Checks whether the given target qualifies as a bugzapper victim.
 * Returns TRUE for moths, spiders (simple mobs and wildshape), and MOB_BUG mobs.
 */
/obj/item/rogueweapon/trickweapon/tonitrus/proc/is_bugzapper_target(mob/living/target)
	// MOB_BUG biotype catches generic insects (butterflies, cockroaches, etc.)
	if(target.mob_biotypes & MOB_BUG)
		return TRUE
	// Spider simple mobs use the "spiders" faction
	if(istype(target, /mob/living/simple_animal) && ("spiders" in target.faction))
		return TRUE
	// Humanoid checks — moth species and shapespider wildshape
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.dna?.species)
			if(H.dna.species.id == "moth" || H.dna.species.id == "shapespider")
				return TRUE
	return FALSE

/**
 * Appends bugzapper examine text when inspecting a charged Tonitrus.
 */
/obj/item/rogueweapon/trickweapon/tonitrus/examine(mob/user)
	. = ..()
	if(transformed)
		. += span_warning("Arcyne lightning arcs hungrily across its surface \u2014 insects beware.")

