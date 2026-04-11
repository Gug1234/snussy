// ===================== SAW SPEAR =====================
// Base: Serrated short sword. Fast cuts and thrusts.
// Transformed: Extending serrated spear. Reach 2 thrusts and sweeps.
// Roughly equal effectiveness 1H and 2H.

// ===================== CUSTOM INTENT DATUMS ========================

// --- Saw Spear unique intents (use sawspear sounds) ---
// Base: Fast alternating slashes (physical). Compact serrated blade.
// Transformed: Thrust-focused extended spear with reach 2.

// --- Base mode: Compact saw blade ---

/// Diagonal slash — R1 combo opener. Fast alternating cut, top-right to lower-left.
/datum/intent/sawspear/diagslash
	name = "diagonal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "saws")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawspear/saw_hit1.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit2.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit3.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.0
	clickcd = 10
	swingdelay = 0
	item_d_type = "slash"

/// Horizontal slash — R2 attack. Brief windup, wide right-to-left cut.
/datum/intent/sawspear/horizslash
	name = "horizontal slash"
	icon_state = "inslash"
	attack_verb = list("slashes", "rips")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawspear/saw_hit1.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit2.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit3.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.2
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "slash"

/// Flat-side bash — blunt utility strike with the compact blade.
/datum/intent/sawspear/strike
	name = "saw bash"
	icon_state = "instrike"
	attack_verb = list("bashes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/sawspear/spear_hit1.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit2.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	swingdelay = 0
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR

/// Charged overhead slash — Charged R2. Blade brought behind, rapid overhead diagonal.
/datum/intent/sawspear/chargedslash
	name = "charged slash"
	icon_state = "inchop"
	attack_verb = list("cleaves", "carves")
	animname = "chop"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawspear/saw_hit1.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit2.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit3.ogg')
	chargetime = 4
	penfactor = 25
	damfactor = 1.9
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	no_early_release = TRUE
	item_d_type = "slash"

// --- Transformed mode: Extended serrated spear ---

/// Spear sweep — R1 horizontal slash at reach 2. Wide right-to-left arc.
/datum/intent/sawspear/spearsweep
	name = "spear sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/sawspear/saw_hit1.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit2.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit3.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.09
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	reach = 2
	item_d_type = "slash"

/// Spear thrust — R2 forward thrust at reach 2. Short windup, direct stab.
/datum/intent/sawspear/spearthrust
	name = "spear thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/sawspear/spear_hit1.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit2.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit3.ogg')
	chargetime = 0
	penfactor = 35
	damfactor = 1.34
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	reach = 2
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Overhead slam — Backstep R2. Spear raised and swept down vertically into the ground.
/datum/intent/sawspear/overheadslam
	name = "overhead slam"
	icon_state = "inchop"
	attack_verb = list("slams", "drives down")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/sawspear/spear_hit1.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit2.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit3.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.19
	clickcd = 14
	swingdelay = 4
	reach = 2
	item_d_type = "slash"

/// Charged spear thrust — Charged R2. Weapon brought back and driven forward hard.
/datum/intent/sawspear/chargedthrust
	name = "charged thrust"
	icon_state = "inthrust"
	attack_verb = list("drives", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/sawspear/spear_hit1.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit2.ogg', 'modular/sounds/trickweapons/sawspear/spear_hit3.ogg')
	chargetime = 5
	penfactor = 45
	damfactor = 1.75
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	reach = 2
	no_early_release = TRUE
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

// ===================== WEAPON DEFINITION =====================

/obj/item/rogueweapon/trickweapon/sawspear
	name = "saw spear"
	desc = "A trick weapon of the Artificer's Guild, designed for versatile engagement against the Rot. In its compact form it functions as a quick serrated blade. Extended, it becomes a fearsome barbed spear capable of impaling deadites from a safe distance."
	icon_state = "sawspear"
	serrated = TRUE
	item_state = "sawspear"
	force = 21
	force_wielded = 24
	possible_item_intents = list(/datum/intent/sawspear/diagslash, /datum/intent/sawspear/horizslash, /datum/intent/sawspear/strike)
	gripped_intents = list(/datum/intent/sawspear/diagslash, /datum/intent/sawspear/horizslash, /datum/intent/sawspear/strike, /datum/intent/sawspear/chargedslash)
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
	transform_sound = 'modular/sounds/trickweapons/sawspear/transform_open.ogg'
	untransform_sound = 'modular/sounds/trickweapons/sawspear/transform_close.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_STAB
	sellprice = 40
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Spear ---
	transformed_name = "saw spear"
	transformed_desc = "The saw spear, now fully extended. Its serrated blade sits atop a long shaft, capable of thrusting and sweeping at extended range. Keep the deadites at arm's length."
	transformed_icon_state = "sawspear_t"
	transformed_item_state = "sawspear_t"
	transformed_force = 20
	transformed_force_wielded = 24
	transformed_intents = list(/datum/intent/sawspear/spearsweep, /datum/intent/sawspear/spearthrust)
	transformed_gripped_intents = list(/datum/intent/sawspear/spearsweep, /datum/intent/sawspear/spearthrust, /datum/intent/sawspear/overheadslam, /datum/intent/sawspear/chargedthrust)
	transformed_swingsound = BLADEWOOSH_LARGE
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 3
	transformed_minstr = 7
	transformed_associated_skill = /datum/skill/combat/polearms
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/saw_spear_swipe
	transformed_special = /datum/special_intent/saw_spear_thrust

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/sawspear/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -7,"sy" = 2,"nx" = 7,"ny" = 3,"wx" = -2,"wy" = 1,"ex" = 1,"ey" = 1,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = -38,"sturn" = 37,"wturn" = 30,"eturn" = -30,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.8,"sx" = 13,"sy" = 0,"nx" = -13,"ny" = 0,"wx" = 12,"wy" = -4,"ex" = 13,"ey" = 3,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -10,"sturn" = 10,"wturn" = 30,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,"sx" = -6,"sy" = -7,"nx" = 2,"ny" = -5,"wx" = 0,"wy" = -4,"ex" = -5,"ey" = -5,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 90,"wturn" = -75,"eturn" = 75,"nflip" = 0,"sflip" = 1,"wflip" = 4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.5,"sx" = 0,"sy" = -3,"nx" = 0,"ny" = -3,"wx" = -1,"wy" = -3,"ex" = 2,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 6,"sturn" = 21,"wturn" = 21,"eturn" = -19,"nflip" = -4,"sflip" = 0,"wflip" = 0,"eflip" = 0)

