// ===================== WHIRLIGIG SAW INTENTS =====================

/// Whirligig Saw base - diagonal slash. Standard R1 combo starter.
/datum/intent/whirligig/slash
	name = "diagonal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "swipes")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Whirligig Saw base - backstep thrust. Quick jabbing motion.
/datum/intent/whirligig/thrust
	name = "backstep thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Whirligig Saw base - overhead slam. Charged R2 slam downward.
/datum/intent/whirligig/slam
	name = "overhead slam"
	icon_state = "insmash"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Whirligig Saw base - power sweep. Wide charged horizontal swing.
/datum/intent/whirligig/powersweep
	name = "power sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "swings")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_HEAVY
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Whirligig Saw transformed - grinding sweep. Fast sawing slash.
/datum/intent/whirligig/grindingsweep
	name = "grinding sweep"
	icon_state = "incut"
	attack_verb = list("grinds into", "saws")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Whirligig Saw transformed - grinding thrust. Drilling stab.
/datum/intent/whirligig/grindingthrust
	name = "grinding thrust"
	icon_state = "instab"
	attack_verb = list("drills into", "grinds")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 2
	chargedrain = 1
	chargedloop = /datum/looping_sound/whirligig_saw
	penfactor = 40
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	item_d_type = "stab"

/// Whirligig Saw transformed - spinning saw (L2). Held grinding attack.
/// Simulates the iconic L2 held attack. Hold to grind, high stamina drain, lower per-hit damage.
/// Uses chargedloop to play the saw spinning sound while held.
/datum/intent/whirligig/spinningsaw
	name = "spinning saw"
	icon_state = "incrush"
	attack_verb = list("grinds through", "shreds")
	animname = "strike"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 1
	chargedrain = 3
	chargedloop = /datum/looping_sound/whirligig_saw
	penfactor = 25
	damfactor = 0.7
	clickcd = CLICK_CD_RAPID
	releasedrain = 3
	item_d_type = "slash"

/// Whirligig Saw transformed - grinding slam. Heavy overhead with spinning disc.
/datum/intent/whirligig/grindingslam
	name = "grinding slam"
	icon_state = "insmash"
	attack_verb = list("slams", "crashes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 5
	chargedrain = 2
	chargedloop = /datum/looping_sound/whirligig_saw
	penfactor = 35
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "slash"

// ---- Whirligig Saw looping sound ----
/// Looping sound for the Whirligig Saw's spinning disc.
/// Plays saw_spin_loop_start on activation, then loops saw_spin_loop while held.
/datum/looping_sound/whirligig_saw
	start_sound = 'modular/sounds/trickweapons/whirligigsaw/saw_spin_loop_start.ogg'
	start_length = 8
	mid_sounds = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_loop.ogg')
	mid_length = 10
	volume = 80
	extra_range = 3

// ===================== WHIRLIGIG SAW =====================
// Base: Heavy mace. Standard blunt strikes.
// Transformed: "Pizza Cutter" mode. Fast grinding blunt/cut attacks.
// The transformed mode uses rapid low-damage strikes to simulate
// the continuous grinding of the saw wheel.

/obj/item/rogueweapon/trickweapon/whirligigsaw
	name = "whirligig saw"
	desc = "A trick weapon devised by the heretical artificers of an age past. In its dormant form, a heavy mace-like bludgeon with a large serrated disc at its head. When activated, the disc spins at tremendous speed, grinding through Rot-bloated flesh and deadite bone like a millstone through grain. Affectionately dubbed the 'pizza cutter' by those with a dark sense of humor."
	icon_state = "whirligigsaw"
	item_state = "whirligigsaw"
	force = 22
	force_wielded = 26
	possible_item_intents = list(/datum/intent/whirligig/slash, /datum/intent/whirligig/thrust, /datum/intent/whirligig/slam)
	gripped_intents = list(/datum/intent/whirligig/slash, /datum/intent/whirligig/thrust, /datum/intent/whirligig/slam, /datum/intent/whirligig/powersweep)
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_HEAVY
	wdefense = 3
	wdefense_wbonus = 3
	minstr = 10
	max_blade_int = 300
	max_integrity = 300
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLUNTWOOSH_MED
	parrysound = list('sound/combat/parry/parrygen.ogg')
	pickup_sound = 'sound/foley/equip/swordlarge2.ogg'
	throwforce = 12
	thrown_bclass = BCLASS_BLUNT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Pizza Cutter ---
	transformed_name = "whirligig saw"
	transformed_desc = "The whirligig saw, now fully revved. The massive serrated disc spins with terrifying speed, shredding anything it contacts in a storm of sparks and gore. Hold it steady and let the wheel do the work."
	transformed_icon_state = "whirligigsaw_t"
	transformed_item_state = "whirligigsaw_t"
	transformed_force = 16 // Lower per-hit, but faster
	transformed_force_wielded = 22
	transformed_intents = list(/datum/intent/whirligig/grindingsweep, /datum/intent/whirligig/grindingthrust, /datum/intent/whirligig/spinningsaw)
	transformed_gripped_intents = list(/datum/intent/whirligig/grindingsweep, /datum/intent/whirligig/grindingthrust, /datum/intent/whirligig/spinningsaw, /datum/intent/whirligig/grindingslam)
	transformed_swingsound = BLADEWOOSH_LARGE
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/axes
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/whirligigsaw/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)


