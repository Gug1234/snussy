// ===================== BURIAL BLADE INTENTS =====================

/// Burial Blade base - curved slash. R1 combo alternating horizontal slashes with the curved sword.
/datum/intent/burialblade/curvedslash
	name = "curved slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/burialblade/blade_hit1.ogg', 'modular/sounds/trickweapons/burialblade/blade_hit2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Burial Blade base - forward thrust. Quickstep/backstep R1, advancing with the blade point.
/datum/intent/burialblade/thrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "lunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/burialblade/blade_hit1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat1.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.05
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

/// Burial Blade base - overhead chop. R2 vertical top-to-bottom slash with short windup.
/datum/intent/burialblade/overheadchop
	name = "overhead chop"
	icon_state = "inchop"
	attack_verb = list("chops", "cleaves")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/burialblade/blade_hit2.ogg', 'modular/sounds/trickweapons/burialblade/blade_swing1.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.45
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "slash"

/// Burial Blade base - charged circle slash. Charged R2 full-circle horizontal arc.
/datum/intent/burialblade/circleslash
	name = "circle slash"
	icon_state = "incrush"
	attack_verb = list("carves through", "sweeps through")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/burialblade/blade_swing1.ogg', 'modular/sounds/trickweapons/burialblade/blade_swing2.ogg')
	chargetime = 5
	chargedrain = 2
	penfactor = 30
	damfactor = 2.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	item_d_type = "slash"

/// Burial Blade transformed - diagonal reap. R1 scythe diagonal slashes, reach 2.
/datum/intent/burialblade/diagreap
	name = "diagonal reap"
	icon_state = "incut"
	attack_verb = list("reaps", "sweeps")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/burialblade/scythe_swing1.ogg', 'modular/sounds/trickweapons/burialblade/scythe_swing2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "slash"

/// Burial Blade transformed - pulling cut. Backstep R1, pulling the scythe blade inward.
/datum/intent/burialblade/pullingcut
	name = "pulling cut"
	icon_state = "inslash"
	attack_verb = list("rakes", "pulls through")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/burialblade/scythe_swing1.ogg', 'modular/sounds/trickweapons/burialblade/blade_hit1.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.18
	clickcd = CLICK_CD_MELEE
	reach = 2
	item_d_type = "slash"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Burial Blade transformed - reaping sweep. R2 wide horizontal scythe arc.
/datum/intent/burialblade/reapingsweep
	name = "reaping sweep"
	icon_state = "insweep"
	attack_verb = list("reaps through", "scythes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/burialblade/scythe_swing2.ogg', 'modular/sounds/trickweapons/burialblade/scythe_swing1.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 25
	damfactor = 1.95
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	reach = 2
	item_d_type = "slash"

/// Burial Blade transformed - death's harvest. L2 multi-hit overhead slam combo.
/// Gehrman's signature: alternating ground slams into rising diagonal slashes.
/datum/intent/burialblade/deathsharvest
	name = "death's harvest"
	icon_state = "insmash"
	attack_verb = list("harvests", "reaps violently")
	animname = "chop"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/burialblade/scythe_swing1.ogg', 'modular/sounds/trickweapons/burialblade/scythe_swing2.ogg')
	chargetime = 6
	chargedrain = 3
	penfactor = 35
	damfactor = 2.05
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	no_early_release = TRUE
	misscost = 10
	reach = 3
	item_d_type = "slash"

// ===================== BURIAL BLADE =====================
// Base: One-handed curved sword. Quick cuts and thrusts.
// Transformed: Two-handed large scythe with extended reach.
// 2H FOCUSED in transformed state - reach 2 scythe sweeps.

/obj/item/rogueweapon/trickweapon/burialblade
	name = "gravereaper"
	desc = "A trick weapon said to have been blessed by Necra's gravediggers. In its folded form, a swift curved sword suited for close quarters. When unfolded, it extends into a massive scythe of terrible reach, sweeping through the undead with the inevitability of the death they were denied."
	icon_state = "burialblade"
	item_state = "burialblade"
	force = 21
	force_wielded = 24
	possible_item_intents = list(/datum/intent/burialblade/curvedslash, /datum/intent/burialblade/thrust, /datum/intent/burialblade/overheadchop)
	gripped_intents = list(/datum/intent/burialblade/curvedslash, /datum/intent/burialblade/thrust, /datum/intent/burialblade/overheadchop, /datum/intent/burialblade/circleslash)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_SWIFT
	wdefense = 5
	wdefense_wbonus = 2
	minstr = 7
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/burialblade/blade_swing1.ogg'
	untransform_sound = 'modular/sounds/trickweapons/burialblade/blade_swing2.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Large Scythe ---
	transformed_name = "gravereaper"
	transformed_desc = "The gravereaper, now unfolded into its full scythe form. The curved blade arcs outward on a long shaft, reaping everything in its path with sweeping, wide cuts. A weapon fit for one who sends the dead back to Necra's embrace."
	transformed_icon_state = "burialblade_t"
	transformed_item_state = "burialblade_t"
	transformed_force = 16 // Weaker 1H
	transformed_force_wielded = 28 // Strong 2H
	transformed_intents = list(/datum/intent/burialblade/diagreap, /datum/intent/burialblade/pullingcut)
	transformed_gripped_intents = list(/datum/intent/burialblade/diagreap, /datum/intent/burialblade/pullingcut, /datum/intent/burialblade/reapingsweep, /datum/intent/burialblade/deathsharvest)
	transformed_swingsound = BLADEWOOSH_HUGE
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 4
	transformed_wdefense_wbonus = 3
	transformed_minstr = 9
	transformed_associated_skill = /datum/skill/combat/polearms
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/burialblade/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)

