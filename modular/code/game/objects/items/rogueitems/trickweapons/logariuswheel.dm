// ===================== LOGARIUS WHEEL INTENTS =====================

/// Logarius Wheel base - wheel strike. Smashing the wheel into the ground from overhead.
/datum/intent/logarius/wheelstrike
	name = "wheel strike"
	icon_state = "instrike"
	attack_verb = list("slams", "smashes")
	animname = "chop"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/land.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Logarius Wheel base - horizontal sweep. The R2 wide arc from right to left.
/datum/intent/logarius/horizsweep
	name = "horizontal sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "swings")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/land.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.18
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Logarius Wheel base - charged sweep. Full-spin charged R2, devastating arc.
/datum/intent/logarius/chargedsweep
	name = "charged sweep"
	icon_state = "incrush"
	attack_verb = list("crushes", "sweeps through")
	animname = "cut"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/spin.ogg')
	chargetime = 5
	chargedrain = 2
	penfactor = MAUL_DEFAULT_PENFACTOR
	damfactor = 1.63
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Logarius Wheel base - leap slam. Overhead flat slam into the ground.
/datum/intent/logarius/leapslam
	name = "leap slam"
	icon_state = "insmash"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/land.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.33
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Logarius Wheel transformed - low sweep. Fast horizontal swing from right to left.
/datum/intent/logarius/lowsweep
	name = "low sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "swings")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/logariuswheel/spin.ogg', 'modular/sounds/trickweapons/logariuswheel/slam.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 0.97
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Logarius Wheel transformed - forward thrust. Thrust the spinning wheels forward.
/datum/intent/logarius/fwdthrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "drives")
	animname = "stab"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/spin.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.94
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Logarius Wheel transformed - ground smash. R2 slam with spinning sparks.
/datum/intent/logarius/groundsmash
	name = "ground smash"
	icon_state = "insmash"
	attack_verb = list("smashes", "grinds into")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/land.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.22
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Logarius Wheel transformed - arcane crush. L2-enhanced heavy overhead strike.
/// The wheel channels arcane fury into a single devastating downward blow.
/datum/intent/logarius/arcanerevolve
	name = "arcane crush"
	icon_state = "incrush"
	attack_verb = list("crushes", "arcane-smashes")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/logariuswheel/spirit.ogg', 'modular/sounds/trickweapons/logariuswheel/slam.ogg')
	chargetime = 6
	chargedrain = 3
	penfactor = 40
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	no_early_release = TRUE
	misscost = 8
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

// ===================== LOGARIUS WHEEL =====================
// Base: Heavy mace/club. Standard blunt strikes.
// Transformed: Spinning wheel mode. Fast, grinding multi-hit style.
// The wheel's spinning is simulated via rapid low-CD strikes.

/obj/item/rogueweapon/trickweapon/logariuswheel
	name = "penitent's wheel"
	desc = "A trick weapon once used by the Otavan Inquisition's Ordinators to extract confession and dispense judgment. In its inert form, a heavy iron-bound wheel affixed to a stout handle, serving as a brutal bludgeon. When activated, the wheel spins with Psydonic fury, grinding against flesh with the force of divine sentence. The Ordinators sought to punish the heretical, and this wheel was their verdict."
	icon_state = "funnywheel"
	item_state = "funnywheel"
	force = 22
	force_wielded = 28
	possible_item_intents = list(/datum/intent/logarius/wheelstrike, /datum/intent/logarius/horizsweep, /datum/intent/logarius/leapslam)
	gripped_intents = list(/datum/intent/logarius/wheelstrike, /datum/intent/logarius/horizsweep, /datum/intent/logarius/chargedsweep, /datum/intent/logarius/leapslam)
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_LONG
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
	transform_sound = 'modular/sounds/trickweapons/logariuswheel/spin.ogg'
	untransform_sound = 'modular/sounds/trickweapons/logariuswheel/land.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_BLUNT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	hudshrink = 0.5 // The wheel is large
	// --- Transformed state: Spinning Wheel ---
	transformed_name = "penitent's wheel"
	transformed_desc = "The penitent's wheel, now spinning with terrible Psydonic force. The iron-bound rim grinds ceaselessly, eager to exact its punishment upon whatever it touches. Each revolution carries the weight of Otavan judgment."
	transformed_icon_state = "funnywheel_t"
	transformed_item_state = "funnywheel_t"
	transformed_force = 18
	transformed_force_wielded = 24
	transformed_intents = list(/datum/intent/logarius/lowsweep, /datum/intent/logarius/fwdthrust, /datum/intent/logarius/groundsmash)
	transformed_gripped_intents = list(/datum/intent/logarius/lowsweep, /datum/intent/logarius/fwdthrust, /datum/intent/logarius/groundsmash, /datum/intent/logarius/arcanerevolve)
	transformed_swingsound = BLUNTWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/logarius_wheel_crush
	transformed_special = /datum/special_intent/logarius_wheel_grind

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/logariuswheel/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,"sx" = -9,"sy" = -7,"nx" = 9,"ny" = -3,"wx" = -2,"wy" = -3,"ex" = -5,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 174,"sturn" = 137,"wturn" = 0,"eturn" = 0,"nflip" = 1,"sflip" = 1,"wflip" = 0,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.4,"sx" = 0,"sy" = -7,"nx" = -1,"ny" = -4,"wx" = 1,"wy" = -9,"ex" = 6,"ey" = -6,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 20,"sturn" = 0,"wturn" = 35,"eturn" = -53,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,"sx" = -8,"sy" = -6,"nx" = 8,"ny" = -5,"wx" = 1,"wy" = -3,"ex" = -2,"ey" = -6,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 236,"sturn" = 205,"wturn" = 180,"eturn" = -7,"nflip" = 1,"sflip" = 1,"wflip" = 0,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.4,"sx" = -1,"sy" = -7,"nx" = -1,"ny" = -6,"wx" = 2,"wy" = -9,"ex" = 6,"ey" = -7,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 253,"sturn" = -100,"wturn" = -96,"eturn" = -111,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
