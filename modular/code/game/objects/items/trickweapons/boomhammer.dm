// ===================== BOOM HAMMER INTENTS =====================

/// Boom Hammer base - horizontal swipe. Standard R1 alternating swipe.
/datum/intent/boomhammer/swipe
	name = "horizontal swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "swings")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/boomhammer/hammer_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Boom Hammer base - forward thrust. Backstep R1 style hammer jab.
/datum/intent/boomhammer/thrust
	name = "hammer thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/boomhammer/hammer_hit2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Boom Hammer base - uppercut sweep. R2 diagonal swing from foot to shoulder.
/datum/intent/boomhammer/uppercut
	name = "uppercut sweep"
	icon_state = "inuppercut"
	attack_verb = list("uppercuts", "sweeps")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/boomhammer/hammer_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.35
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Boom Hammer base - overhead slam. Charged R2 ground slam.
/datum/intent/boomhammer/slam
	name = "overhead slam"
	icon_state = "insmash"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/boomhammer/hammer_hit2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = MAUL_DEFAULT_PENFACTOR
	damfactor = 1.9
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Boom Hammer transformed - fiery swipe. Ignited R1, fire-enhanced horizontal hit.
/datum/intent/boomhammer/fieryswipe
	name = "fiery swipe"
	icon_state = "incut"
	attack_verb = list("scorches", "sears")
	animname = "cut"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"

/// Boom Hammer transformed - fiery thrust. Ignited backstep jab with fire.
/datum/intent/boomhammer/fierythrust
	name = "fiery thrust"
	icon_state = "instab"
	attack_verb = list("burns into", "sears")
	animname = "stab"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Boom Hammer transformed - fiery uppercut. Ignited R2 diagonal fire swing.
/datum/intent/boomhammer/fieryuppercut
	name = "fiery uppercut"
	icon_state = "inuppercut"
	attack_verb = list("ignites", "sears through")
	animname = "cut"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.3
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"

/// Boom Hammer transformed - crushing overhead. Charged R2 overhead blow with the full weight of the hammer.
/// A brutal single-target overhead slam that crushes armor.
/datum/intent/boomhammer/explosiveslam
	name = "crushing overhead"
	icon_state = "incrush"
	attack_verb = list("crushes", "smashes down upon")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/boomhammer/hammer_hit2.ogg')
	chargetime = 6
	chargedrain = 2
	penfactor = 50
	damfactor = 1.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	no_early_release = TRUE
	misscost = 10
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

// ===================== BOOM HAMMER =====================
// Base: Heavy hammer/mace. Standard blunt strikes.
// Transformed: Ignited hammer. Fire-infused blunt attacks.
// The transformation "primes" the hammer's igniter for the next strike.

/obj/item/rogueweapon/trickweapon/boomhammer
	name = "boom hammer"
	desc = "A trick weapon born from the forges of Malum's most daring artificers â€” engineers who favored explosive force over elegant mechanism. The hammer's head contains a small furnace and igniter. When primed, the next swing detonates on impact with devastating force. Subtle it is not, but Malum's children never cared much for subtlety."
	icon_state = "boomhammer"
	item_state = "boomhammer"
	force = 24
	force_wielded = 28
	possible_item_intents = list(/datum/intent/boomhammer/swipe, /datum/intent/boomhammer/thrust, /datum/intent/boomhammer/uppercut)
	gripped_intents = list(/datum/intent/boomhammer/swipe, /datum/intent/boomhammer/thrust, /datum/intent/boomhammer/uppercut, /datum/intent/boomhammer/slam)
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
	transform_sound = list('modular/sounds/trickweapons/boomhammer/boom_transform1.ogg', 'modular/sounds/trickweapons/boomhammer/boom_transform2.ogg')
	throwforce = 12
	thrown_bclass = BCLASS_BLUNT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Ignited Hammer ---
	transformed_name = "boom hammer"
	transformed_desc = "The boom hammer, now primed and glowing with contained fury. The furnace within the hammerhead roars to life, wreathing the striking face in superheated flame. Malum's ingenuity made manifest â€” the next impact will be catastrophic."
	transformed_icon_state = "boomhammer_t"
	transformed_item_state = "boomhammer_t"
	transformed_force = 26
	transformed_force_wielded = 32
	transformed_intents = list(/datum/intent/boomhammer/fieryswipe, /datum/intent/boomhammer/fierythrust, /datum/intent/boomhammer/fieryuppercut)
	transformed_gripped_intents = list(/datum/intent/boomhammer/fieryswipe, /datum/intent/boomhammer/fierythrust, /datum/intent/boomhammer/fieryuppercut, /datum/intent/boomhammer/explosiveslam)
	transformed_swingsound = BLUNTWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 3
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/boom_hammer_strike
	transformed_special = /datum/special_intent/boom_hammer_ignition

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/boomhammer/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -8,"sy" = -4,"nx" = 6,"ny" = -3,"wx" = 0,"wy" = 3,"ex" = -2,"ey" = 0,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 90,"wturn" = 250,"eturn" = -55,"nflip" = 0,"sflip" = 1,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.7,"sx" = 7,"sy" = -2,"nx" = -8,"ny" = -2,"wx" = 5,"wy" = -5,"ex" = 7,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 180,"sturn" = 0,"wturn" = 20,"eturn" = -8,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -8,"sy" = -4,"nx" = 6,"ny" = -3,"wx" = -2,"wy" = 1,"ex" = -2,"ey" = 0,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 90,"wturn" = 250,"eturn" = -55,"nflip" = 0,"sflip" = 1,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.65,"sx" = 2,"sy" = 1,"nx" = -7,"ny" = 2,"wx" = 4,"wy" = -1,"ex" = 5,"ey" = 1,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 180,"sturn" = 0,"wturn" = 30,"eturn" = 0,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
/obj/item/rogueweapon/trickweapon/boomhammer/transform_weapon(mob/living/user)
	. = ..()
	if(transformed)
		set_light(2, 1, l_color = "#e87430")
	else
		set_light(0)


