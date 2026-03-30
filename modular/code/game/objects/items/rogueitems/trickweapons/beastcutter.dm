// ===================== BEAST CUTTER INTENTS =====================

/// Beast Cutter base - downward slash. R1 combo starter, overhead chop.
/datum/intent/beastcutter/downslash
	name = "downward slash"
	icon_state = "inchop"
	attack_verb = list("slashes", "chops")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/beastcutter/whip_crack1.ogg', 'modular/sounds/trickweapons/beastcutter/whip_crack2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Beast Cutter base - horizontal sweep. R2 backhand sweep from behind.
/datum/intent/beastcutter/horizsweep
	name = "horizontal sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "swings")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/beastcutter/whip_crack1.ogg', 'modular/sounds/trickweapons/beastcutter/whip_crack2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "slash"

/// Beast Cutter base - thrusting jab. Backstep R1 straight thrust.
/datum/intent/beastcutter/jab
	name = "thrusting jab"
	icon_state = "instab"
	attack_verb = list("jabs", "thrusts")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/beastcutter/whip_crack1.ogg', 'modular/sounds/trickweapons/beastcutter/whip_land.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

/// Beast Cutter base - overhead swing. Charged R2, heavy overhead smash.
/datum/intent/beastcutter/overheadswing
	name = "overhead swing"
	icon_state = "insmash"
	attack_verb = list("smashes", "slams")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/beastcutter/whip_crack1.ogg', 'modular/sounds/trickweapons/beastcutter/whip_crack2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 35
	damfactor = 1.9
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	item_d_type = "slash"

/// Beast Cutter transformed - chain sweep. R1 slow horizontal whip swings, reach 2.
/datum/intent/beastcutter/chainsweep
	name = "chain sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "lashes")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/beastcutter/chain1.ogg', 'modular/sounds/trickweapons/beastcutter/chain2.ogg', 'modular/sounds/trickweapons/beastcutter/whip_crack1.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.95
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "slash"

/// Beast Cutter transformed - chain uppercut. Dodge R1 rising swing at range.
/datum/intent/beastcutter/chainuppercut
	name = "chain uppercut"
	icon_state = "incut"
	attack_verb = list("uppercuts", "whips up")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/beastcutter/chain3.ogg', 'modular/sounds/trickweapons/beastcutter/chain4.ogg', 'modular/sounds/trickweapons/beastcutter/whip_crack2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	reach = 2
	item_d_type = "slash"

/// Beast Cutter transformed - chain slam. R2 downward chain smash extending outward.
/datum/intent/beastcutter/chainslam
	name = "chain slam"
	icon_state = "insmash"
	attack_verb = list("slams", "crashes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/beastcutter/whip_land.ogg', 'modular/sounds/trickweapons/beastcutter/chain1.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 25
	damfactor = 1.3
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	reach = 2
	item_d_type = "slash"

/// Beast Cutter transformed - chain thrust. Backstep R2 feint-to-thrust at range.
/datum/intent/beastcutter/chainthrust
	name = "chain thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "stabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/beastcutter/chain2.ogg', 'modular/sounds/trickweapons/beastcutter/whip_land.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

// ===================== BEAST CUTTER =====================
// Base: Heavy serrated club/cleaver. Blunt/chop strikes.
// Transformed: Extended whip-blade. Reach 2-3 sweeping cuts.
// The segmented blade unfolds into a long, flexible chain-sword.

/obj/item/rogueweapon/trickweapon/beastcutter
	name = "beast cutter"
	desc = "A trick weapon forged in a distant Zybantine workshop, designed for hunting werewolves and Rot-touched abominations. In its compact form, a heavy serrated cleaver with formidable weight behind each swing. When extended, the blade segments separate and unfurl into a long, flexible whip-sword capable of lashing out across great distances. Designed to topple creatures too large and savage to approach safely."
	icon_state = "beastcutter"
	item_state = "beastcutter"
	force = 23
	force_wielded = 27
	possible_item_intents = list(/datum/intent/beastcutter/downslash, /datum/intent/beastcutter/horizsweep, /datum/intent/beastcutter/jab)
	gripped_intents = list(/datum/intent/beastcutter/downslash, /datum/intent/beastcutter/horizsweep, /datum/intent/beastcutter/jab, /datum/intent/beastcutter/overheadswing)
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_HEAVY
	wdefense = 3
	wdefense_wbonus = 2
	minstr = 9
	max_blade_int = 250
	max_integrity = 250
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLUNTWOOSH_MED
	parrysound = list('sound/combat/parry/parrygen.ogg')
	pickup_sound = 'sound/foley/equip/swordlarge2.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_BLUNT
	sellprice = 50
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Whip-blade ---
	transformed_name = "beast cutter"
	transformed_desc = "The beast cutter, now fully extended. The segmented blade stretches outward in a long, sinuous chain-sword, capable of sweeping through multiple werewolves at range. Each lash carries the cutting force of the entire weapon's weight, concentrated along the serrated edge."
	transformed_icon_state = "beastcutter_t"
	transformed_item_state = "beastcutter_t"
	transformed_force = 14 // Weak 1H - designed for range
	transformed_force_wielded = 26
	transformed_intents = list(/datum/intent/beastcutter/chainsweep, /datum/intent/beastcutter/chainuppercut)
	transformed_gripped_intents = list(/datum/intent/beastcutter/chainsweep, /datum/intent/beastcutter/chainuppercut, /datum/intent/beastcutter/chainslam, /datum/intent/beastcutter/chainthrust)
	transformed_swingsound = BLADEWOOSH_HUGE
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 9
	transformed_associated_skill = /datum/skill/combat/whipsflails
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/beastcutter/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)


