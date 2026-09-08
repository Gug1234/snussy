// ===================== BLADES OF MERCY INTENTS =====================

/// Blades of Mercy base - horizontal slash. R1 combo of alternating horizontal slashes.
/// Quick and consistent with minimal stamina cost.
/datum/intent/mercy/horizslash
	name = "horizontal slash"
	icon_state = "inslash"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/hit1.ogg', 'modular/sounds/trickweapons/bladesofmercy/hit2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Blades of Mercy base - quick slash. Quickstep R1 forward hop and slash.
/// Fast gap-closer with a quick forward lunge.
/datum/intent/mercy/quickslash
	name = "quick slash"
	icon_state = "incut"
	attack_verb = list("dashes into", "quick-slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/flash1.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Blades of Mercy base - reverse slash. R2 reverse grip slash from behind the body.
/// The hunter reverses grip and slashes forward right to left.
/datum/intent/mercy/reverseslash
	name = "reverse slash"
	icon_state = "inchop"
	attack_verb = list("reverse-slashes", "backhands")
	animname = "chop"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/hit1.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash1.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.25
	clickcd = CLICK_CD_CHARGED
	swingdelay = 4
	item_d_type = "slash"

/// Blades of Mercy base - charged uppercut. Charged R2 reverse grip uppercut.
/// Drags the blade behind, then brings it up in a devastating uppercut.
/datum/intent/mercy/chargeduppercut
	name = "charged uppercut"
	icon_state = "inuppercut"
	attack_verb = list("uppercuts", "rips upward into")
	animname = "chop"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/flash1.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash2.ogg')
	chargetime = 6
	chargedrain = 2
	penfactor = 30
	damfactor = 2
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "slash"

/// Blades of Mercy transformed - flurry. R1 rapid alternating dual dagger strikes.
/// A relentless barrage of cuts with both blades. Low per-hit damage,
/// extremely fast. Speeds up dramatically after the first few hits.
/datum/intent/mercy/flurry
	name = "flurry"
	icon_state = "influrry"
	attack_verb = list("slashes with both blades", "flurries into", "rakes with twin daggers")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/flash1.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash2.ogg', 'modular/sounds/trickweapons/bladesofmercy/hit1.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 0.9
	clickcd = CLICK_CD_RAPID
	item_d_type = "slash"

/// Blades of Mercy transformed - dual thrust. Quickstep R1 lunging dual stab.
/// Both blades are brought forward in a rapid thrusting motion.
/datum/intent/mercy/dualthrust
	name = "dual thrust"
	icon_state = "instab"
	attack_verb = list("thrusts with both blades", "lunges into", "double-stabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/flash1.ogg', 'modular/sounds/trickweapons/bladesofmercy/hit2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.4
	clickcd = CLICK_CD_MELEE
	item_d_type = "stab"

/// Blades of Mercy transformed - cross slash. R2 dual cross-slash combo.
/// Both blades brought to the side and slashed across each other.
/datum/intent/mercy/crossslash
	name = "cross slash"
	icon_state = "incrush"
	attack_verb = list("cross-slashes", "scissors into")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/hit1.ogg', 'modular/sounds/trickweapons/bladesofmercy/hit2.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash1.ogg')
	chargetime = 3
	chargedrain = 2
	penfactor = 25
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "slash"

/// Blades of Mercy transformed - scissor slash. L2 overhead X-slash with backward hop.
/// Both blades raised overhead and brought down and out in an X pattern.
/// Well-suited as a finisher after an R1 flurry, creating distance.
/datum/intent/mercy/scissorslash
	name = "scissor slash"
	icon_state = "inslash"
	attack_verb = list("scissor-slashes", "carves an X into")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/bladesofmercy/hit1.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash1.ogg', 'modular/sounds/trickweapons/bladesofmercy/flash2.ogg')
	chargetime = 4
	chargedrain = 2
	penfactor = 20
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 5
	item_d_type = "slash"

// ===================== BLADES OF MERCY =====================
// Base: A single curved dagger, once part of a pair. Fast horizontal
// slashes and quick thrusts with arcane-infused steel.
// Transformed: The blade separates into twin daggers, one in each hand.
// Devastating flurry attacks that sacrifice per-hit damage for
// overwhelming speed. The signature weapon of the Hunters of Hunters.

/obj/item/rogueweapon/trickweapon/bladesofmercy
	name = "blade of mercy"
	desc = "A trick weapon favored by those who hunt other hunters â€” bounty-killers and Inquisition executors alike. In its combined form, a single curved dagger of arcyne-infused siderite. When separated, the blade splits into twin daggers, allowing for an overwhelmingly fast dual-wielding style that leaves no opening for retaliation."
	icon_state = "bladesofmercy"
	item_state = "bladesofmercy"
	force = 18
	force_wielded = 21
	possible_item_intents = list(/datum/intent/mercy/horizslash, /datum/intent/mercy/quickslash, /datum/intent/mercy/reverseslash)
	gripped_intents = list(/datum/intent/mercy/horizslash, /datum/intent/mercy/quickslash, /datum/intent/mercy/reverseslash, /datum/intent/mercy/chargeduppercut)
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_SMALL
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_SWIFT
	wdefense = 4
	wdefense_wbonus = 2
	minstr = 5
	max_blade_int = 180
	max_integrity = 160
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/knives
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedsmall (1).ogg', 'sound/combat/parry/bladed/bladedsmall (2).ogg', 'sound/combat/parry/bladed/bladedsmall (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall2.ogg'
	transform_sound = 'modular/sounds/trickweapons/bladesofmercy/bom_transform.ogg'
	untransform_sound = 'modular/sounds/trickweapons/bladesofmercy/bom_untransform.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 50
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Twin Daggers ---
	transformed_name = "blades of mercy"
	transformed_desc = "The blades of mercy, now separated into their twin-dagger form. One in each hand, they weave a relentless storm of cuts and thrusts. Inquisition executors used this form to overwhelm their quarry with speed, leaving no chance of escape."
	transformed_icon_state = "bladesofmercy_t"
	transformed_item_state = "bladesofmercy_t"
	transformed_force = 14 // Lower per-hit, but much faster attacks
	transformed_force_wielded = 18
	transformed_intents = list(/datum/intent/mercy/flurry, /datum/intent/mercy/dualthrust, /datum/intent/mercy/crossslash)
	transformed_gripped_intents = list(/datum/intent/mercy/flurry, /datum/intent/mercy/dualthrust, /datum/intent/mercy/crossslash, /datum/intent/mercy/scissorslash)
	transformed_swingsound = BLADEWOOSH_SMALL
	transformed_wlength = WLENGTH_NORMAL
	transformed_wbalance = WBALANCE_SWIFT
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 1
	transformed_minstr = 5
	transformed_associated_skill = /datum/skill/combat/knives
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_SMALL
	special = /datum/special_intent/blades_of_mercy_quick
	transformed_special = /datum/special_intent/blades_of_mercy_flurry
	/// Separate icon file for transformed on-mob rendering (dual daggers).
	var/inhand_icon = 'modular/icons/obj/trickweapons/rakuyo_and_bladesofmercy_onmob.dmi'
	// --- Dual wielder scaling: rewards TRAIT_DUALWIELDER users ---
	dualwielder_force_bonus = 3
	dualwielder_wdefense_bonus = 2
	// --- Anti-trick weapon defense: hunter-killer specialization ---
	anti_trickweapon_dodge_bonus = 15
	anti_trickweapon_parry_bonus = 15

/// Override generateonmob to pull from the dual-wield on-mob DMI when transformed.
/// Base form uses normal weapon on-mob behavior.
/obj/item/rogueweapon/trickweapon/bladesofmercy/generateonmob(tag, prop, behind = FALSE, mirrored = FALSE, used_index = null)
	if(!transformed)
		return ..(tag, prop, behind, mirrored, used_index)
	var/cached_icon = icon
	icon = inhand_icon
	var/onmob_state = wielded ? "bladesofmercyonmob_twohands" : "bladesofmercyonmob_onehands"
	. = ..(tag, prop, behind, mirrored, onmob_state)
	icon = cached_icon

/// Mob render properties — small dagger (base), full dual-dagger overlay (transformed).
/obj/item/rogueweapon/trickweapon/bladesofmercy/getonmobprop(tag)
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
					return list("shrink" = 0.35,"sx" = -15,"sy" = -11,"nx" = 12,"ny" = -10,"wx" = -10,"wy" = -10,"ex" = 6,"ey" = -11,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 180,"wturn" = 90,"eturn" = 0,"nflip" = 1,"sflip" = 0,"wflip" = 1,"eflip" = 1)
				if("wielded")
					return list("shrink" = 0.45,"sx" = 3,"sy" = 1,"nx" = -5,"ny" = 2,"wx" = 7,"wy" = -3,"ex" = 8,"ey" = 3,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 180,"sturn" = 0,"wturn" = 30,"eturn" = -6,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)

