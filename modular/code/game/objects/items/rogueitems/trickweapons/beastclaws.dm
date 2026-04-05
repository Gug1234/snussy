// ===================== BEAST CLAWS INTENTS =====================
// Base (single claw): Fast, aggressive slashes and punches with one claw.
// Transformed (dual claws): Both hands, savage dual swipes and scissoring attacks.
// Skill: Unarmed. Very fast, low stamina cost per hit, low stagger.

// --- Base mode: Single claw ---

/// Quick diagonal swipe from right to left.
/datum/intent/beastclaw/swipe
	name = "claw swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "rakes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_hit1.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit2.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit3.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.0
	clickcd = 8
	swingdelay = 0
	item_d_type = "slash"

/// Forward punch with the claw, quick thrust motion.
/datum/intent/beastclaw/punch
	name = "claw punch"
	icon_state = "inpunch"
	attack_verb = list("punches", "jabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_hit1.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit2.ogg', 'modular/sounds/trickweapons/beastclaws/claw_swing.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 0.98
	clickcd = 8
	swingdelay = 0
	item_d_type = "blunt"

/// Strong overhand swipe â€” deliberate windup, heavier hit.
/datum/intent/beastclaw/overhand
	name = "overhand rake"
	icon_state = "inrake"
	attack_verb = list("rakes", "tears")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_hit1.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit2.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.28
	clickcd = CLICK_CD_MELEE
	swingdelay = 4
	item_d_type = "slash"

/// Charged uppercut â€” extended windup, heavy damage.
/datum/intent/beastclaw/uppercut
	name = "savage uppercut"
	icon_state = "insavage"
	attack_verb = list("uppercuts", "gashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_hit2.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit3.ogg', 'modular/sounds/trickweapons/beastclaws/claw_swing.ogg')
	chargetime = 3
	penfactor = 25
	damfactor = 1.83
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	no_early_release = TRUE
	item_d_type = "slash"

// --- Transformed mode: Dual claws ---

/// Rapid alternating dual swipe â€” both claws from left and right.
/datum/intent/beastclaw/dualswipe
	name = "dual swipe"
	icon_state = "inclaw"
	attack_verb = list("swipes", "rakes", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_double.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit1.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 0.98
	clickcd = 7
	swingdelay = 0
	item_d_type = "slash"

/// Left-hand overhead slam â€” raised and brought down hard.
/datum/intent/beastclaw/dualoverhand
	name = "feral slam"
	icon_state = "incrush"
	attack_verb = list("slams", "mauls", "batters")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_double.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit2.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.38
	clickcd = CLICK_CD_MELEE
	swingdelay = 5
	item_d_type = "slash"

/// Scissoring cross-slash â€” both claws sweep inward in an X pattern.
/datum/intent/beastclaw/scissor
	name = "scissor slash"
	icon_state = "inrend"
	attack_verb = list("scissor-slashes", "rends", "shreds")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_double.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit1.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit3.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.23
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "slash"

/// Massive charged ground slam â€” both claws overhead, slammed into the earth.
/datum/intent/beastclaw/groundslam
	name = "ground slam"
	icon_state = "inslam"
	attack_verb = list("slams", "pounds", "crushes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/beastclaws/claw_double.ogg', 'modular/sounds/trickweapons/beastclaws/claw_hit1.ogg', 'modular/sounds/trickweapons/beastclaws/claw_swing.ogg')
	chargetime = 4
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.93
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	no_early_release = TRUE
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG


// ===================== BEAST CLAWS =====================
// Base: Single claw â€” fast, relentless slashes and punches (unarmed skill).
// Transformed: Dual claws â€” savage dual attacks, scissor slashes, ground slams.
// A primal relic linked to the wildkin â€” Dendor's children.
// Not a weapon against them, but one born of their feral nature.
//
// No special transformation mechanic â€” pure stat/intent swap.
// Very fast attack speed, low damage per hit, rewards aggression.

/obj/item/rogueweapon/trickweapon/beastclaws
	name = "feral claw"
	desc = "A crude gauntlet fitted with wicked iron talons, shaped after the claws of Dendor's wildkin. Worn over the fist and forearm, it turns the wielder's hand into a predator's weapon â€” fast, vicious, and relentless. There are rumours that a second claw is hidden within, waiting to be unleashed."
	icon_state = "beastclaw"
	item_state = "beastclaw"
	force = 18
	force_wielded = 20
	possible_item_intents = list(/datum/intent/beastclaw/swipe, /datum/intent/beastclaw/punch, /datum/intent/beastclaw/overhand, /datum/intent/beastclaw/uppercut)
	gripped_intents = list(/datum/intent/beastclaw/swipe, /datum/intent/beastclaw/punch, /datum/intent/beastclaw/overhand, /datum/intent/beastclaw/uppercut)
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_SMALL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_SWIFT
	wdefense = 3
	wdefense_wbonus = 0
	minstr = 4
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/unarmed
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall2.ogg'
	transform_sound = 'modular/sounds/trickweapons/beastclaws/claw_double.ogg'
	throwforce = 6
	thrown_bclass = BCLASS_CUT
	smeltresult = /obj/item/ingot/iron
	sellprice = 45
	grid_width = 32
	grid_height = 32
	gripsprite = FALSE
	// --- Transformed state: Dual claws ---
	transformed_name = "feral claws"
	transformed_desc = "The feral claws, now fully unfurled. Both hands are sheathed in cruel iron talons, the wielder's movements becoming wild and unpredictable. Each strike is a savage display of primal fury â€” slashing, rending, tearing with bestial abandon."
	transformed_icon_state = "beastclaw_t"
	transformed_item_state = "beastclaw_t"
	transformed_force = 17
	transformed_force_wielded = 19
	transformed_intents = list(/datum/intent/beastclaw/dualswipe, /datum/intent/beastclaw/dualoverhand, /datum/intent/beastclaw/scissor, /datum/intent/beastclaw/groundslam)
	transformed_gripped_intents = list(/datum/intent/beastclaw/dualswipe, /datum/intent/beastclaw/dualoverhand, /datum/intent/beastclaw/scissor, /datum/intent/beastclaw/groundslam)
	transformed_swingsound = BLADEWOOSH_SMALL
	transformed_wlength = WLENGTH_SHORT
	transformed_wbalance = WBALANCE_SWIFT
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 0
	transformed_minstr = 4
	transformed_associated_skill = /datum/skill/combat/unarmed
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_SMALL

/// Mob render properties â€” small claw gauntlet on fist.
/obj/item/rogueweapon/trickweapon/beastclaws/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -7,"sy" = -4,"nx" = 7,"ny" = -4,"wx" = -3,"wy" = -4,"ex" = 1,"ey" = -4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 110,"sturn" = -110,"wturn" = -110,"eturn" = 110,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.5,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)
