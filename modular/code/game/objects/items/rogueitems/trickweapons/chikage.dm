// ===================== CHIKAGE INTENTS =====================
// Base form: Silver katana â€” fast slashes and precise thrusts.
// Transformed: Blood-sheathed katana â€” stronger but drains user HP per hit.

/// Chikage base - diagonal slash. Quick downward diagonal cut, bread-and-butter attack.
/datum/intent/chikage/diagonalslash
	name = "diagonal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.0
	clickcd = CLICK_CD_MELEE
	swingdelay = 0
	item_d_type = "slash"

/// Chikage base - quick slash. Fast horizontal sweep, slightly weaker but rapid.
/datum/intent/chikage/quickslash
	name = "quick slash"
	icon_state = "inslash"
	attack_verb = list("swipes", "sweeps")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	swingdelay = 0
	item_d_type = "slash"

/// Chikage base - thrust. Precise forward stab, good armor penetration.
/datum/intent/chikage/thrust
	name = "thrust"
	icon_state = "inthrust"
	attack_verb = list("thrusts", "stabs")
	animname = "thrust"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "stab"

/// Chikage base - overhead slash. Charged vertical cut from above, high commitment.
/datum/intent/chikage/overheadslash
	name = "overhead slash"
	icon_state = "incrush"
	attack_verb = list("cleaves", "chops")
	animname = "chop"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = 20
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "slash"

/// Chikage transformed - blood slash. Two-handed diagonal cut with blood-sheathed blade.
/datum/intent/chikage/bloodslash
	name = "blood slash"
	icon_state = "incut"
	attack_verb = list("lacerates", "rends")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.05
	clickcd = CLICK_CD_MELEE
	swingdelay = 0
	item_d_type = "slash"

/// Chikage transformed - blood sweep. Wide horizontal sweep, crowd control.
/datum/intent/chikage/bloodsweep
	name = "blood sweep"
	icon_state = "insweep"
	attack_verb = list("sweeps", "carves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "slash"

/// Chikage transformed - iaido draw. Sheathe-and-draw attack. High damage, charged.
/datum/intent/chikage/iaidodraw
	name = "iaido draw"
	icon_state = "inslash"
	attack_verb = list("draws through", "flash-cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg', 'modular/sounds/trickweapons/chikage/katana_draw1.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 25
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "slash"

/// Chikage transformed - blood thrust. Fast forward thrust with blood edge.
/datum/intent/chikage/bloodthrust
	name = "blood thrust"
	icon_state = "inthrust"
	attack_verb = list("impales", "pierces")
	animname = "thrust"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg', 'modular/sounds/trickweapons/chikage/katana_iai_strike2.ogg')
	chargetime = 0
	penfactor = 35
	damfactor = 1.15
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "stab"


// ===================== CHIKAGE =====================
// Base: Silver katana â€” fast slashes and precise thrusts (swords skill).
// Transformed: Blood-sheathed katana â€” stronger but drains user HP per hit.
// An instrument of Psydonic blood divination, wielded by those who embrace the old rites.
//
// Silver property: is_silver = TRUE (effective vs. undead/werewolves).
// Unique mechanic: afterattack drains user HP when hitting in blood mode.

/obj/item/rogueweapon/trickweapon/chikage
	name = "chikage"
	desc = "A trick weapon forged in the tradition of Psydonic blood divination. A silver katana of exquisite make, its slender blade is forged for swift, precise cuts. In the hands of one who knows the old rites, the blade can be sheathed in the wielder's own blood â€” at a cost."
	icon_state = "chikage"
	item_state = "chikage"
	force = 20
	force_wielded = 23
	possible_item_intents = list(/datum/intent/chikage/diagonalslash, /datum/intent/chikage/quickslash, /datum/intent/chikage/thrust, /datum/intent/chikage/overheadslash)
	gripped_intents = list(/datum/intent/chikage/diagonalslash, /datum/intent/chikage/quickslash, /datum/intent/chikage/thrust, /datum/intent/chikage/overheadslash)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_SWIFT
	wdefense = 6
	wdefense_wbonus = 0
	minstr = 5
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	is_silver = TRUE
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/chikage/katana_draw1.ogg'
	untransform_sound = 'modular/sounds/trickweapons/chikage/katana_draw2.ogg'
	throwforce = 8
	thrown_bclass = BCLASS_CUT
	smeltresult = /obj/item/ingot/silver
	sellprice = 65
	grid_width = 32
	grid_height = 64
	/// HP cost per hit in blood mode. Raw brute damage to the wielder.
	var/blood_drain_per_hit = 5
	// --- Transformed state: Blood-sheathed katana ---
	transformed_name = "chikage"
	transformed_desc = "The chikage, now sheathed in the wielder's own blood. The silver blade weeps crimson, each cut carrying the vitality of the one who wields it. Power demands sacrifice â€” every strike drains the life of its master."
	transformed_icon_state = "chikage_t"
	transformed_item_state = "chikage_t"
	transformed_force = 24
	transformed_force_wielded = 27
	transformed_intents = list(/datum/intent/chikage/bloodslash, /datum/intent/chikage/bloodsweep, /datum/intent/chikage/iaidodraw, /datum/intent/chikage/bloodthrust)
	transformed_gripped_intents = list(/datum/intent/chikage/bloodslash, /datum/intent/chikage/bloodsweep, /datum/intent/chikage/iaidodraw, /datum/intent/chikage/bloodthrust)
	transformed_swingsound = BLADEWOOSH_MED
	transformed_wlength = WLENGTH_NORMAL
	transformed_wbalance = WBALANCE_SWIFT
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 0
	transformed_minstr = 6
	transformed_associated_skill = /datum/skill/combat/swords
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_NORMAL
	special = /datum/special_intent/chikage_quickdraw
	transformed_special = /datum/special_intent/chikage_blood_rend

/// Mob render properties for one-handed and wielded display (katana-sized).
/obj/item/rogueweapon/trickweapon/chikage/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -16,"sy" = -13,"nx" = 14,"ny" = -10,"wx" = -15,"wy" = -11,"ex" = 9,"ey" = -10,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 80,"sturn" = -90,"wturn" = -75,"eturn" = 75,"nflip" = 0,"sflip" = 4,"wflip" = -4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.7,"sx" = 10,"sy" = 0,"nx" = -9,"ny" = 0,"wx" = -9,"wy" = 11,"ex" = 9,"ey" = 11,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -10,"sturn" = 10,"wturn" = 39,"eturn" = -39,"nflip" = 4,"sflip" = 0,"wflip" = -4,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.5,"sx" = -16,"sy" = -13,"nx" = 19,"ny" = -8,"wx" = -14,"wy" = -5,"ex" = 9,"ey" = -6,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 67,"sturn" = -90,"wturn" = -55,"eturn" = 55,"nflip" = 0,"sflip" = 4,"wflip" = -4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.7,"sx" = 9,"sy" = -1,"nx" = -10,"ny" = 0,"wx" = 11,"wy" = -7,"ex" = 12,"ey" = 2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 0,"sturn" = 0,"wturn" = 28,"eturn" = -17,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)

/**
 * Extends the base serrated signal management to also handle blood drain
 * in transformed (blood) mode. Both mechanics share COMSIG_ITEM_ATTACK_SUCCESS,
 * so we register a single combined handler that checks for each independently.
 */
/obj/item/rogueweapon/trickweapon/chikage/update_serrated_signal()
	UnregisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS)
	if(serrated || transformed)
		RegisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS, PROC_REF(on_chikage_hit))

/**
 * Combined COMSIG_ITEM_ATTACK_SUCCESS handler for serrated bonus and blood drain.
 * Only fires on confirmed successful melee hits — misses and blocks don't trigger.
 */
/obj/item/rogueweapon/trickweapon/chikage/proc/on_chikage_hit(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	// Serrated bonus (same logic as parent apply_serrated_bonus)
	if(serrated && isliving(target))
		var/multiplier = get_serrated_multiplier(target)
		if(multiplier)
			var/bonus = round(force_dynamic * serrated_bonus * multiplier)
			if(bonus > 0)
				target.apply_damage(bonus, BRUTE)
	// Blood drain in transformed mode
	if(transformed && isliving(user))
		var/mob/living/L = user
		L.adjustBruteLoss(blood_drain_per_hit)
		to_chat(user, span_danger("[src] drinks deep of your blood..."))


