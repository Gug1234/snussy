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

/// Logarius Wheel transformed - arcane revolve. L2-enhanced heavy spin attack.
/// The wheel spins with arcane fury; high commitment, high reward.
/datum/intent/logarius/arcanerevolve
	name = "arcane revolve"
	icon_state = "incrush"
	attack_verb = list("grinds through", "revolves into")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/logariuswheel/spin.ogg', 'modular/sounds/trickweapons/logariuswheel/spirit.ogg')
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
	icon_state = "logariuswheel"
	item_state = "logariuswheel"
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
	// --- Transformed state: Spinning Wheel ---
	transformed_name = "penitent's wheel"
	transformed_desc = "The penitent's wheel, now spinning with terrible Psydonic force. The iron-bound rim grinds ceaselessly, eager to exact its punishment upon whatever it touches. Each revolution carries the weight of Otavan judgment."
	transformed_icon_state = "logariuswheel_t"
	transformed_item_state = "logariuswheel_t"
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

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/logariuswheel/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)

