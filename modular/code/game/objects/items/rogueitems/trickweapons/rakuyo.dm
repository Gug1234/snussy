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
	icon_state = "inthrust"
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
	icon_state = "inslash"
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

/// Rakuyo transformed - cross slash. Simultaneous saber and dagger X-pattern cut.
/// An elegant crossing strike with both blades in a single precise motion.
/datum/intent/rakuyo/spinslash
	name = "cross slash"
	icon_state = "incrush"
	attack_verb = list("crosses", "rends")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/rakuyo/slash1.ogg', 'modular/sounds/trickweapons/rakuyo/slash2.ogg')
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
	special = /datum/special_intent/rakuyo_lunge
	transformed_special = /datum/special_intent/rakuyo_whirlwind
	/// Separate icon file for transformed on-mob rendering (saber + dagger).
	var/inhand_icon = 'modular/icons/obj/trickweapons/rakuyo_and_bladesofmercy_onmob.dmi'
	// --- Dual wielder scaling: rewards TRAIT_DUALWIELDER users ---
	dualwielder_force_bonus = 3
	dualwielder_wdefense_bonus = 2

/// Override generateonmob to pull from the dual-wield on-mob DMI when transformed.
/// Base form uses normal weapon on-mob behavior.
/obj/item/rogueweapon/trickweapon/rakuyo/generateonmob(tag, prop, behind = FALSE, mirrored = FALSE, used_index = null)
	if(!transformed)
		return ..(tag, prop, behind, mirrored, used_index)
	var/cached_icon = icon
	icon = inhand_icon
	var/onmob_state = wielded ? "rakuyoonmob_twohands" : "rakuyoonmob_onehands"
	. = ..(tag, prop, behind, mirrored, onmob_state)
	icon = cached_icon

/// Mob render properties — saber (base), full dual-blade overlay (transformed).
/obj/item/rogueweapon/trickweapon/rakuyo/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 1,"sx" = 0,"sy" = 0,"nx" = 0,"ny" = 0,"wx" = 0,"wy" = 0,"ex" = 0,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
				if("wielded")
					return list("shrink" = 1,"sx" = 0,"sy" = 0,"nx" = 0,"ny" = 0,"wx" = 0,"wy" = 0,"ex" = 0,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.7,"sx" = -10,"sy" = -5,"nx" = 9,"ny" = -4,"wx" = -6,"wy" = -5,"ex" = 2,"ey" = -4,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 70,"sturn" = -87,"wturn" = -75,"eturn" = 63,"nflip" = 0,"sflip" = 4,"wflip" = 4,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.8,"sx" = 0,"sy" = 0,"nx" = -3,"ny" = 4,"wx" = 0,"wy" = 0,"ex" = 6,"ey" = 4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 0,"sturn" = 30,"wturn" = 41,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)


