// ===================== AMYGDALAN ARM INTENTS =====================

/// Amygdalan Arm base - overhead ground slam. Heavy blunt impact.
/datum/intent/amygdala/slam
	name = "ground slam"
	icon_state = "insmash"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/flesh_hit1.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_hit2.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Amygdalan Arm base - quick jab with the calcified limb.
/datum/intent/amygdala/jab
	name = "arm jab"
	icon_state = "instrike"
	attack_verb = list("jabs", "bashes")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/flesh_impact1.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_impact2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Amygdalan Arm base - wide horizontal sweep with the club.
/datum/intent/amygdala/sweep
	name = "wide sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "swings")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/flesh_hit1.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Amygdalan Arm base - overhead crush. 2H only, charged maul-like slam.
/datum/intent/amygdala/crush
	name = "overhead crush"
	icon_state = "incrush"
	attack_verb = list("crushes", "hammers")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/flesh_hit1.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_impact1.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = MAUL_DEFAULT_PENFACTOR
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Amygdalan Arm transformed - tentacle lash. Fast whip-like strike at range.
/datum/intent/amygdala/lash
	name = "tentacle lash"
	icon_state = "inlash"
	attack_verb = list("lashes", "whips")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/whip_crack.ogg', 'modular/sounds/trickweapons/amygdalanarm/whip_land.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	reach = 2
	item_d_type = "blunt"

/// Amygdalan Arm transformed - extended sweep. Wide arc at range 2.
/datum/intent/amygdala/tendsweep
	name = "extended sweep"
	icon_state = "insweep"
	attack_verb = list("sweeps", "swipes")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/whip_crack.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_impact1.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Amygdalan Arm transformed - rotating thrust. Charged reach 2 stab.
/datum/intent/amygdala/rotthrust
	name = "rotating thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "drives")
	animname = "stab"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/whip_crack.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_impact2.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = 30
	damfactor = 1.3
	clickcd = CLICK_CD_HEAVY
	reach = 2
	item_d_type = "blunt"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Amygdalan Arm transformed - eldritch slam. Heavy charged ground pound at range.
/datum/intent/amygdala/eldritchslam
	name = "eldritch slam"
	icon_state = "inslam"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/amygdalanarm/flesh_hit1.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_hit2.ogg', 'modular/sounds/trickweapons/amygdalanarm/flesh_impact1.ogg')
	chargetime = 6
	chargedrain = 2
	penfactor = MAUL_DEFAULT_PENFACTOR
	damfactor = 1.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	reach = 2
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

// ===================== AMYGDALAN ARM =====================
// Base: Heavy club. A massive alien limb used as a bludgeon.
// Transformed: The arm unfurls into a long, whip-like scythe
// with tremendous reach. Heavy sweeping attacks.
// In Bloodborne, the Amygdalan Arm is literally a limb torn
// from one of the lesser Amygdala. It extends when transformed.

/obj/item/rogueweapon/trickweapon/amygdalanarm
	name = "abyssal arm"
	desc = "A trick weapon fashioned from the severed limb of a deep-sea leviathan, dredged from waters where Abyssor's dreams bleed into reality. In its compact form, a grotesque but effective club of calcified alien flesh and bone. When commanded, the arm unfurls to its full terrible length, sweeping through the air with the reach of the creature it once belonged to. Those who gaze upon it too long often feel watched in return."
	icon_state = "dreamfiendarm"
	item_state = "dreamfiendarm"
	force = 24
	force_wielded = 28
	possible_item_intents = list(/datum/intent/amygdala/jab, /datum/intent/amygdala/sweep, /datum/intent/amygdala/slam)
	gripped_intents = list(/datum/intent/amygdala/jab, /datum/intent/amygdala/sweep, /datum/intent/amygdala/slam, /datum/intent/amygdala/crush)
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_HEAVY
	wdefense = 3
	wdefense_wbonus = 2
	minstr = 10
	max_blade_int = 300
	max_integrity = 300
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLUNTWOOSH_MED
	parrysound = list('sound/combat/parry/parrygen.ogg')
	pickup_sound = 'sound/foley/equip/swordlarge2.ogg'
	transform_sound = 'modular/sounds/trickweapons/amygdalanarm/arm_transform.ogg'
	untransform_sound = 'modular/sounds/trickweapons/amygdalanarm/arm_untransform.ogg'
	throwforce = 12
	thrown_bclass = BCLASS_BLUNT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Extended whip-scythe ---
	transformed_name = "abyssal arm"
	transformed_desc = "The abyssal arm, now fully extended. The alien limb unfurls to its true length, its clawed fingers splayed wide, sweeping through the air with terrible reach. Each lash carries the weight and malice of Abyssor's dreaming grasp."
	transformed_icon_state = "dreamfiendarm_t"
	transformed_item_state = "dreamfiendarm_t"
	transformed_force = 14 // Weak 1H - designed for 2H range
	transformed_force_wielded = 28
	transformed_intents = list(/datum/intent/amygdala/lash, /datum/intent/amygdala/tendsweep)
	transformed_gripped_intents = list(/datum/intent/amygdala/lash, /datum/intent/amygdala/tendsweep, /datum/intent/amygdala/rotthrust, /datum/intent/amygdala/eldritchslam)
	transformed_swingsound = BLUNTWOOSH_MED
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/amygdalan_bash
	transformed_special = /datum/special_intent/amygdalan_smash

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/amygdalanarm/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.55,"sx" = -12,"sy" = -8,"nx" = 11,"ny" = -9,"wx" = 1,"wy" = 6,"ex" = -5,"ey" = 4,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 180,"wturn" = -20,"eturn" = -67,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.6,"sx" = 6,"sy" = 2,"nx" = 1,"ny" = 6,"wx" = -4,"wy" = 7,"ex" = 2,"ey" = 6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = -30,"sturn" = 12,"wturn" = 180,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 1,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.45,"sx" = -16,"sy" = -10,"nx" = 9,"ny" = -8,"wx" = -12,"wy" = -8,"ex" = 0,"ey" = -8,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 90,"wturn" = 100,"eturn" = 0,"nflip" = 1,"sflip" = 1,"wflip" = 1,"eflip" = 1)
				if("wielded")
					return list("shrink" = 0.5,"sx" = 6,"sy" = 1,"nx" = -10,"ny" = 2,"wx" = 8,"wy" = -2,"ex" = 7,"ey" = 6,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 180,"sturn" = 0,"wturn" = 18,"eturn" = -27,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
