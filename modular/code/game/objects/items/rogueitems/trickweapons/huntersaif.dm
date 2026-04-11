// ===================== HUNTER SAIF INTENTS =====================

/// Hunter Saif base - overhead swipe. R1 combo slow overhead swipes with wide arcs.
/datum/intent/huntersaif/overheadswipe
	name = "overhead swipe"
	icon_state = "inchop"
	attack_verb = list("swipes", "chops")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/huntersaif/slash_hit1.ogg', 'modular/sounds/trickweapons/huntersaif/slash_hit2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Hunter Saif base - diagonal sweep. Quickstep R1, rising sweep from bottom right to top left.
/datum/intent/huntersaif/diagsweep
	name = "diagonal sweep"
	icon_state = "inslash"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/huntersaif/swing1.ogg', 'modular/sounds/trickweapons/huntersaif/swing2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.91
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Hunter Saif base - horizontal swipe. R2 wide horizontal sweep from right to left.
/datum/intent/huntersaif/horizswipe
	name = "horizontal swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "sweeps")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/huntersaif/slash_hit1.ogg', 'modular/sounds/trickweapons/huntersaif/swing1.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.32
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "slash"

/// Hunter Saif base - 360 ground smash. Charged R2 clockwise spin into overhead ground pound.
/datum/intent/huntersaif/groundsmash
	name = "360 ground smash"
	icon_state = "insmash"
	attack_verb = list("smashes", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/huntersaif/slash_clang1.ogg', 'modular/sounds/trickweapons/huntersaif/slash_hit2.ogg')
	chargetime = 5
	chargedrain = 2
	penfactor = 30
	damfactor = 1.63
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Hunter Saif transformed - lunge slash. R1 upward lunge attack with forward step.
/datum/intent/huntersaif/lungeslash
	name = "lunge slash"
	icon_state = "incut"
	attack_verb = list("lunges", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/huntersaif/swing2.ogg', 'modular/sounds/trickweapons/huntersaif/slash_hit1.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.85
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Hunter Saif transformed - forward thrust. R2 tip thrust with forward lunge.
/datum/intent/huntersaif/fwdthrust
	name = "forward thrust"
	icon_state = "inthrust"
	attack_verb = list("thrusts", "lunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/huntersaif/slash_hit2.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat1.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.18
	clickcd = CLICK_CD_MELEE
	item_d_type = "stab"

/// Hunter Saif transformed - forward swipe. Dash R1 quick right-to-left swipe.
/datum/intent/huntersaif/fwdswipe
	name = "forward swipe"
	icon_state = "insweep"
	attack_verb = list("swipes", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/huntersaif/swing1.ogg', 'modular/sounds/trickweapons/huntersaif/slash_hit1.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Hunter Saif transformed - ground slam. Charged R2 overhead slam, knocking enemies down.
/datum/intent/huntersaif/tgroundslam
	name = "ground slam"
	icon_state = "insmash"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/huntersaif/slash_clang1.ogg', 'modular/sounds/trickweapons/huntersaif/slash_hit2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 30
	damfactor = 1.45
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

// ===================== HUNTER SAIF =====================
// Base: Short curved blade. Fast slashes and thrusts.
// Transformed: Extended cleaver-form. Heavier chops with more reach.
// In Bloodborne the Saif's transformation attacks pull the hunter
// forward. Here we simulate this with faster, aggressive intents.

/obj/item/rogueweapon/trickweapon/huntersaif
	name = "hunter saif"
	desc = "A trick weapon of the Artificer's Guild, popular among hunters who favor aggression over caution. In its folded form, a compact curved blade perfect for quick, aggressive slashes in tight quarters. When extended, the blade unfolds outward into a longer cleaver-like form with greater reach and chopping power. Those who close the distance with deadites rather than keeping it preferred this weapon above all others."
	icon_state = "huntersaif"
	item_state = "huntersaif"
	force = 20
	force_wielded = 24
	possible_item_intents = list(/datum/intent/huntersaif/overheadswipe, /datum/intent/huntersaif/diagsweep, /datum/intent/huntersaif/horizswipe)
	gripped_intents = list(/datum/intent/huntersaif/overheadswipe, /datum/intent/huntersaif/diagsweep, /datum/intent/huntersaif/horizswipe, /datum/intent/huntersaif/groundsmash)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_SWIFT
	wdefense = 5
	wdefense_wbonus = 2
	minstr = 6
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/huntersaif/slash_clang1.ogg'
	throwforce = 8
	thrown_bclass = BCLASS_CUT
	sellprice = 45
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Extended cleaver ---
	transformed_name = "hunter saif"
	transformed_desc = "The hunter saif, now unfolded into its extended cleaver form. The blade stretches outward, offering greater reach and devastating chopping power at the cost of the compact form's speed. A weapon that rewards commitment to the attack."
	transformed_icon_state = "huntersaif_t"
	transformed_item_state = "huntersaif_t"
	transformed_force = 21
	transformed_force_wielded = 26
	transformed_intents = list(/datum/intent/huntersaif/lungeslash, /datum/intent/huntersaif/fwdthrust, /datum/intent/huntersaif/fwdswipe)
	transformed_gripped_intents = list(/datum/intent/huntersaif/lungeslash, /datum/intent/huntersaif/fwdthrust, /datum/intent/huntersaif/fwdswipe, /datum/intent/huntersaif/tgroundslam)
	transformed_swingsound = BLADEWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 4
	transformed_wdefense_wbonus = 3
	transformed_minstr = 7
	transformed_associated_skill = /datum/skill/combat/polearms
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/hunter_saif_rend
	transformed_special = /datum/special_intent/hunter_saif_dash

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/huntersaif/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -9,"sy" = -10,"nx" = 7,"ny" = -8,"wx" = -5,"wy" = -7,"ex" = 5,"ey" = -10,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 90,"wturn" = -75,"eturn" = 75,"nflip" = 0,"sflip" = 1,"wflip" = 4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.7,"sx" = 11,"sy" = 0,"nx" = -11,"ny" = -1,"wx" = 14,"wy" = -2,"ex" = 12,"ey" = 2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -23,"sturn" = 23,"wturn" = 30,"eturn" = 10,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,"sx" = -5,"sy" = -6,"nx" = 5,"ny" = -6,"wx" = 2,"wy" = -4,"ex" = -4,"ey" = -6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -90,"eturn" = 90,"nflip" = 0,"sflip" = -4,"wflip" = 4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.5,"sx" = 0,"sy" = -3,"nx" = 0,"ny" = -3,"wx" = -1,"wy" = -3,"ex" = 2,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -21,"sturn" = 21,"wturn" = 52,"eturn" = -19,"nflip" = -4,"sflip" = 0,"wflip" = 0,"eflip" = 0)


