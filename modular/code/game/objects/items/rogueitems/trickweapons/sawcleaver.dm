// ===================== SAW CLEAVER =====================
// Base: Serrated short sword. Fast cuts and thrusts.
// Transformed: Extended cleaver. Heavy chops and slashes.
// Roughly equal effectiveness 1H and 2H.

// ===================== CUSTOM INTENT DATUMS ========================

/// Serrated slash - fast, moderate pen. Saw weapons sword mode.
/datum/intent/saw/cut
	name = "serrated cut"
	icon_state = "incut"
	attack_verb = list("cuts", "saws")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawcleaver/cleaver_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit3.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.1
	clickcd = 10
	item_d_type = "slash"

/// Serrated thrust - decent pen. Saw weapons sword mode.
/datum/intent/saw/thrust
	name = "serrated stab"
	icon_state = "instab"
	attack_verb = list("stabs", "gouges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/sawcleaver/cleaver_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit3.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1
	clickcd = 10
	item_d_type = "stab"

/// Cleaver chop - heavy, charged like maciejowski. Saw Cleaver transformed mode.
/datum/intent/saw/cleave
	name = "cleave"
	icon_state = "inchop"
	attack_verb = list("cleaves", "hacks")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/sawcleaver/cleaver_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit3.ogg')
	penfactor = 35
	chargetime = 5
	chargedrain = 1
	swingdelay = 8
	damfactor = 1.2
	clickcd = 14
	item_d_type = "slash"

/// Saw Cleaver transformed slash - wide, heavy cut. Charged windup.
/datum/intent/saw/heavycut
	name = "heavy slash"
	icon_state = "incut"
	attack_verb = list("slashes", "rips")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawcleaver/saw_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/saw_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/saw_hit3.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 20
	damfactor = 1.3
	clickcd = 12
	item_d_type = "slash"

/// Saw Spear transformed thrust - reach 2, spear-like.
/datum/intent/saw/spearthrust
	name = "serrated thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/sawcleaver/saw_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/saw_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/saw_hit3.ogg')
	penfactor = 40
	reach = 2
	damfactor = 1
	clickcd = CLICK_CD_CHARGED
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Saw Spear transformed cut - reach 2, slashing sweep.
/datum/intent/saw/spearcut
	name = "sweeping cut"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawcleaver/saw_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/saw_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/saw_hit3.ogg')
	penfactor = 15
	reach = 2
	damfactor = 0.9
	item_d_type = "slash"

/// Saw Cleaver blunt strike — flat-side bash with the compact saw blade.
/datum/intent/sawcleaver/strike
	name = "saw bash"
	icon_state = "instrike"
	attack_verb = list("bashes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/sawcleaver/cleaver_hit1.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit2.ogg', 'modular/sounds/trickweapons/sawcleaver/cleaver_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	swingdelay = 0
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR

// ===================== WEAPON DEFINITION =====================

/obj/item/rogueweapon/trickweapon/sawcleaver
	name = "saw cleaver"
	desc = "One of the trick weapons of the Artificer's Guild, commonly issued to hunters tasked with culling deadites and werewolves beyond the walls. This saw, effective at slicing through Rot-hardened flesh, transforms into a long cleaver that makes use of centrifugal force."
	icon_state = "sawcleaver"
	serrated = TRUE
	item_state = "sawcleaver"
	force = 22
	force_wielded = 25
	possible_item_intents = list(/datum/intent/saw/cut, /datum/intent/saw/thrust, /datum/intent/sawcleaver/strike)
	gripped_intents = list(/datum/intent/saw/cut, /datum/intent/saw/thrust, /datum/intent/sawcleaver/strike)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_NORMAL
	wdefense = 4
	wdefense_wbonus = 3
	minstr = 7
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/sawcleaver/transform_open.ogg'
	untransform_sound = 'modular/sounds/trickweapons/sawcleaver/transform_close.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 40
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Cleaver ---
	transformed_name = "saw cleaver"
	transformed_desc = "The saw cleaver, now extended into its full form. The long, serrated blade cleaves through deadite flesh and werewolf bone with brutal centrifugal force."
	transformed_icon_state = "sawcleaver_t"
	transformed_item_state = "sawcleaver_t"
	transformed_force = 24
	transformed_force_wielded = 27
	transformed_intents = list(/datum/intent/saw/cleave, /datum/intent/saw/heavycut, /datum/intent/sawcleaver/strike)
	transformed_gripped_intents = list(/datum/intent/saw/cleave, /datum/intent/saw/heavycut, /datum/intent/sawcleaver/strike)
	transformed_swingsound = BLADEWOOSH_LARGE
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 3
	transformed_minstr = 8
	transformed_associated_skill = /datum/skill/combat/axes
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/saw_cleaver_charge
	transformed_special = /datum/special_intent/saw_cleaver_rend

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/sawcleaver/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -9,"sy" = -10,"nx" = 7,"ny" = -8,"wx" = -5,"wy" = -7,"ex" = 5,"ey" = -10,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 90,"wturn" = -75,"eturn" = 75,"nflip" = 0,"sflip" = 1,"wflip" = 4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.8,"sx" = 11,"sy" = -3,"nx" = -11,"ny" = -3,"wx" = 9,"wy" = -8,"ex" = 13,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -10,"sturn" = 10,"wturn" = 30,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,"sx" = -5,"sy" = -6,"nx" = 5,"ny" = -6,"wx" = 2,"wy" = -4,"ex" = -4,"ey" = -6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -90,"eturn" = 90,"nflip" = 0,"sflip" = -4,"wflip" = 4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.5,"sx" = 0,"sy" = -3,"nx" = 0,"ny" = -3,"wx" = -1,"wy" = -3,"ex" = 2,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 6,"sturn" = 21,"wturn" = 21,"eturn" = -19,"nflip" = -4,"sflip" = 0,"wflip" = 0,"eflip" = 0)

