// ===================== KOS PARASITE INTENTS =====================

/// Kos Parasite base - bludgeon bash. Simple blunt hit with the calcified shell.
/datum/intent/kosparasite/bash
	name = "bludgeon bash"
	icon_state = "instrike"
	attack_verb = list("bashes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Kos Parasite base - cartilage thrust. Jabbing the hardened tip forward.
/datum/intent/kosparasite/thrust
	name = "cartilage thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_impact1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_impact2.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_impact3.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

/// Kos Parasite base - headbutt. Charged heavy blow, smashing with the shell.
/datum/intent/kosparasite/headbutt
	name = "leaping headbutt"
	icon_state = "insmash"
	attack_verb = list("headbutts", "rams")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_hit2.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_slap1.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Kos Parasite transformed - dual tentacle swipe. Fast lashing at range.
/datum/intent/kosparasite/dualswipe
	name = "dual tentacle swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "lashes")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_slap1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_slap2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.1
	clickcd = CLICK_CD_FAST
	reach = 2
	item_d_type = "blunt"

/// Kos Parasite transformed - dual tentacle thrust. Charged reach 2 piercing stab.
/datum/intent/kosparasite/dualthrust
	name = "dual tentacle thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_impact1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_impact2.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 35
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Kos Parasite transformed - arcane burst. Heavy charged smash, eldritch energy.
/// Simulates the L2 AOE burst from Bloodborne. High cost, high reward.
/datum/intent/kosparasite/arcaneburst
	name = "arcane burst"
	icon_state = "incrush"
	attack_verb = list("bursts into", "erupts upon")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_hit2.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_impact3.ogg')
	chargetime = 8
	chargedrain = 3
	penfactor = 50
	damfactor = 2
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	no_early_release = TRUE
	misscost = 10
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Kos Parasite transformed - leaping slam. Fast gap-closer style attack.
/datum/intent/kosparasite/leapslam
	name = "leaping slam"
	icon_state = "insmash"
	attack_verb = list("slams", "crashes into")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_slap1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_slap2.ogg')
	chargetime = 2
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_CHARGED
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

// ===================== KOS PARASITE =====================
// Base: An eldritch relic. In its dormant form, a strange club-like
// appendage. Blunt, unremarkable strikes.
// Transformed: The parasite awakens. Tentacle-like lashing attacks
// with extended reach and alien ferocity.
// In Bloodborne, the Kos Parasite transforms the hunter's bare
// hands into tentacle attacks when combined with a specific rune.
// Here it is implemented as a physical weapon that changes form.

/obj/item/rogueweapon/trickweapon/kosparasite
	name = "abyssal parasite"
	desc = "A trick weapon dredged from the depths of Abyssor's domain, found tangled in the nets of a doomed fishing vessel. In its dormant state, a grotesque appendage of hardened cartilage and calcified flesh, useful only as a crude bludgeon. When awakened, the parasite unfurls into writhing tentacles that lash out with otherworldly malice. To wield it is to invite communion with the dreams of a slumbering god."
	icon_state = "kosparasite"
	item_state = "kosparasite"
	force = 18
	force_wielded = 22
	possible_item_intents = list(/datum/intent/kosparasite/bash, /datum/intent/kosparasite/thrust)
	gripped_intents = list(/datum/intent/kosparasite/bash, /datum/intent/kosparasite/thrust, /datum/intent/kosparasite/headbutt)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_NORMAL
	wdefense = 2
	wdefense_wbonus = 1
	minstr = 6
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLUNTWOOSH_SMALL
	parrysound = list('sound/combat/parry/parrygen.ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/kosparasite/flesh_impact1.ogg'
	untransform_sound = 'modular/sounds/trickweapons/kosparasite/flesh_impact2.ogg'
	throwforce = 6
	thrown_bclass = BCLASS_BLUNT
	sellprice = 50
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Awakened Tentacles ---
	transformed_name = "abyssal parasite"
	transformed_desc = "The abyssal parasite, now fully awakened. Writhing tentacles extend from the calcified shell, lashing out with a mind of their own. Each strike carries the spectral intelligence of Abyssor's dreaming will, reaching further than any natural limb should."
	transformed_icon_state = "kosparasite_t"
	transformed_item_state = "kosparasite_t"
	transformed_force = 16
	transformed_force_wielded = 24
	transformed_intents = list(/datum/intent/kosparasite/dualswipe, /datum/intent/kosparasite/leapslam)
	transformed_gripped_intents = list(/datum/intent/kosparasite/dualswipe, /datum/intent/kosparasite/dualthrust, /datum/intent/kosparasite/arcaneburst, /datum/intent/kosparasite/leapslam)
	transformed_swingsound = BLUNTWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 7
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/kosparasite/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)


