// ===================== RAKUYO INTENTS =====================

/// Rakuyo base - horizontal sweep. R1 sweep from right to left.
/datum/intent/rakuyo/horizsweep
	name = "horizontal sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/rakuyo/slash1.ogg', 'modular/sounds/trickweapons/rakuyo/slash2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Rakuyo base - diagonal slash. Backhanded downward slash.
/datum/intent/rakuyo/diagslash
	name = "diagonal slash"
	icon_state = "inchop"
	attack_verb = list("slashes", "rakes")
	animname = "chop"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/rakuyo/slash1.ogg', 'modular/sounds/trickweapons/rakuyo/slash2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.15
	clickcd = CLICK_CD_CHARGED
	item_d_type = "slash"

/// Rakuyo base - forward thrust. Quick lunge stab.
/datum/intent/rakuyo/thrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "lunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/rakuyo/flash1.ogg', 'modular/sounds/trickweapons/rakuyo/flash2.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

/// Rakuyo base - charged dash thrust. R2 charged lunge with full commitment.
/datum/intent/rakuyo/dashthrust
	name = "dash thrust"
	icon_state = "instab"
	attack_verb = list("drives into", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/rakuyo/flash1.ogg', 'modular/sounds/trickweapons/rakuyo/flash2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 40
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "stab"

/// Rakuyo transformed - dual slash. Fast alternating saber+dagger cuts.
/datum/intent/rakuyo/dualslash
	name = "dual slash"
	icon_state = "incut"
	attack_verb = list("slashes", "rakes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/rakuyo/slash1.ogg', 'modular/sounds/trickweapons/rakuyo/slash2.ogg', 'modular/sounds/trickweapons/rakuyo/flash1.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Rakuyo transformed - dagger swipe. Quick backhand dagger strike.
/datum/intent/rakuyo/daggerswipe
	name = "dagger swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "nicks")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/rakuyo/flash1.ogg', 'modular/sounds/trickweapons/rakuyo/flash2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Rakuyo transformed - alternating thrusts. R2 saber+dagger thrust combo.
/datum/intent/rakuyo/altthrusts
	name = "alternating thrusts"
	icon_state = "instab"
	attack_verb = list("thrusts", "pierces")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/rakuyo/flash1.ogg', 'modular/sounds/trickweapons/rakuyo/flash2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 0.95
	clickcd = CLICK_CD_MELEE
	item_d_type = "stab"

/// Rakuyo transformed - spinning dual slash. L2 360-degree dual blade spin.
/// High commitment but devastating in close quarters.
/datum/intent/rakuyo/spinslash
	name = "spinning dual slash"
	icon_state = "incrush"
	attack_verb = list("spins through", "whirls into")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/rakuyo/spin.ogg', 'modular/sounds/trickweapons/rakuyo/slash1.ogg')
	chargetime = 4
	chargedrain = 2
	penfactor = 25
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "slash"

// ===================== RAKUYO =====================
// Base: Elegant twin-blade saber. Fast cuts and thrusts.
// Transformed: Separated saber + dagger. Rapid dual-wielding
// style with dagger-speed thrusts and sabre slashes.
// In Bloodborne, the Rakuyo separates into two weapons held
// in each hand. Here we simulate the dual-wield feel with
// fast mixed sword/dagger intents.

/obj/item/rogueweapon/trickweapon/rakuyo
	name = "rakuyo"
	desc = "A trick weapon of exquisite Ferentian craftsmanship, said to have been commissioned by a noblewoman of Hawthorne. In its combined form, a long elegant saber of peerless balance. When separated, the blade divides into a saber and a shorter dagger, allowing for a devastatingly fast dual-wielding fighting style. Few possess the skill to wield it effectively."
	icon_state = "rakuyo"
	item_state = "rakuyo"
	force = 21
	force_wielded = 25
	possible_item_intents = list(/datum/intent/rakuyo/horizsweep, /datum/intent/rakuyo/diagslash, /datum/intent/rakuyo/thrust)
	gripped_intents = list(/datum/intent/rakuyo/horizsweep, /datum/intent/rakuyo/diagslash, /datum/intent/rakuyo/thrust, /datum/intent/rakuyo/dashthrust)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_LONG
	wbalance = WBALANCE_SWIFT
	wdefense = 6
	wdefense_wbonus = 3
	minstr = 6
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/rakuyo/transform.ogg'
	untransform_sound = 'modular/sounds/trickweapons/rakuyo/transform_grab.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Twin-blade (Saber + Dagger) ---
	transformed_name = "rakuyo"
	transformed_desc = "The rakuyo, now separated into its twin-blade form. The saber in one hand, the dagger in the other â€” together they weave a deadly dance of steel. Capable of overwhelming opponents with a relentless flurry of cuts and thrusts."
	transformed_icon_state = "rakuyo_t"
	transformed_item_state = "rakuyo_t"
	transformed_force = 18 // Lower per-hit, but faster mixed attacks
	transformed_force_wielded = 23
	transformed_intents = list(/datum/intent/rakuyo/dualslash, /datum/intent/rakuyo/daggerswipe, /datum/intent/rakuyo/altthrusts)
	transformed_gripped_intents = list(/datum/intent/rakuyo/dualslash, /datum/intent/rakuyo/daggerswipe, /datum/intent/rakuyo/altthrusts, /datum/intent/rakuyo/spinslash)
	transformed_swingsound = BLADEWOOSH_SMALL
	transformed_wlength = WLENGTH_NORMAL
	transformed_wbalance = WBALANCE_SWIFT
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 2
	transformed_minstr = 6
	transformed_associated_skill = /datum/skill/combat/swords
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_NORMAL

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/rakuyo/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)


