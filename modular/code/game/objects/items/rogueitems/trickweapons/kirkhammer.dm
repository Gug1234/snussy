// ===================== KIRKHAMMER INTENTS =====================

/// Kirkhammer base - diagonal slash. R1 combo alternating diagonal slashes.
/datum/intent/kirkhammer/diagslash
	name = "diagonal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/kirkhammer/sword_hit1.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Kirkhammer base - upward slash. Rolling R1, scrapes the blade upward.
/datum/intent/kirkhammer/upslash
	name = "upward slash"
	icon_state = "incut"
	attack_verb = list("uppercuts", "slashes upward")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/kirkhammer/sword_hit1.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Kirkhammer base - forward thrust. R2 direct thrust forward.
/datum/intent/kirkhammer/thrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/iron_stab_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.4
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "stab"

/// Kirkhammer base - charged thrust. Charged R2 powerful thrust with upward path.
/datum/intent/kirkhammer/chargedthrust
	name = "charged thrust"
	icon_state = "inthrust"
	attack_verb = list("drives into", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/swing_stab_charge.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat1.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 40
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "stab"

/// Kirkhammer transformed - diagonal slam. R1 alternating overhead diagonal slams.
/datum/intent/kirkhammer/diagslam
	name = "diagonal slam"
	icon_state = "insmash"
	attack_verb = list("slams", "smashes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kirkhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/kirkhammer/hammer_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.4
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Kirkhammer transformed - shield push. Backstep/dash R1, lunging the hammer forward like a battering ram.
/datum/intent/kirkhammer/shieldpush
	name = "shield push"
	icon_state = "instrike"
	attack_verb = list("shoves", "pushes")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/kirkhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/kirkhammer/hammer_swing.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 0.6
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Kirkhammer transformed - overhead slam. R2 vertical overhead ground pound.
/datum/intent/kirkhammer/overheadslam
	name = "overhead slam"
	icon_state = "inslam"
	attack_verb = list("pounds", "slams")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kirkhammer/hammer_hit2.ogg', 'modular/sounds/trickweapons/kirkhammer/hammer_hit1.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = MAUL_DEFAULT_PENFACTOR
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Kirkhammer transformed - charged devastation. Charged R2, the signature full-body twist slam.
/// The hammer is brought down with such force the hunter's leg lifts off the ground.
/datum/intent/kirkhammer/chargeddev
	name = "charged devastation"
	icon_state = "incrush"
	attack_verb = list("devastates", "obliterates")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kirkhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/kirkhammer/hammer_swing.ogg')
	chargetime = 6
	chargedrain = 3
	penfactor = 50
	damfactor = 3.1
	clickcd = CLICK_CD_HEAVY
	swingdelay = 12
	no_early_release = TRUE
	misscost = 12
	item_d_type = "blunt"
	intent_intdamage_factor = 2
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

// ===================== KIRKHAMMER =====================
// Base: One-handed silver straight sword. Quick cuts and thrusts.
// Transformed: Giant stone hammer. Devastating 2H blunt damage.
// 2H FOCUSED in transformed state - weak 1H, powerful 2H.

/obj/item/rogueweapon/trickweapon/kirkhammer
	name = "psydonic hammer"
	desc = "A trick weapon issued to Pontifexes of the Psydonic faith. On the one side, an easily handled silver sword. On the other, a giant obtuse stone weapon, characterized by a blunt strike and extreme force of impact. The Otavan Inquisition takes a heavy-handed, merciless stance toward the deadite horde, an irony not lost upon the wielders of this most symbolic weapon."
	icon_state = "kirkhammer"
	item_state = "kirkhammer"
	force = 21
	force_wielded = 24
	possible_item_intents = list(/datum/intent/kirkhammer/diagslash, /datum/intent/kirkhammer/upslash, /datum/intent/kirkhammer/thrust)
	gripped_intents = list(/datum/intent/kirkhammer/diagslash, /datum/intent/kirkhammer/upslash, /datum/intent/kirkhammer/thrust, /datum/intent/kirkhammer/chargedthrust)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_NORMAL
	wdefense = 5
	wdefense_wbonus = 3
	minstr = 8
	max_blade_int = 200
	max_integrity = 250
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/kirkhammer/transform.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	is_silver = TRUE
	// --- Transformed state: Stone Hammer ---
	transformed_name = "psydonic hammer"
	transformed_desc = "The psydonic hammer, now in its full hammer form. The silver sword slots into the massive stone head as a handle, creating a weapon of staggering weight and crushing force. Each blow lands with the finality of an Otavan decree."
	transformed_icon_state = "kirkhammer_t"
	transformed_item_state = "kirkhammer_t"
	transformed_force = 14 // Weak 1H - designed for 2H use
	transformed_force_wielded = 30 // Massive 2H bonus
	transformed_intents = list(/datum/intent/kirkhammer/diagslam, /datum/intent/kirkhammer/shieldpush)
	transformed_gripped_intents = list(/datum/intent/kirkhammer/diagslam, /datum/intent/kirkhammer/shieldpush, /datum/intent/kirkhammer/overheadslam, /datum/intent/kirkhammer/chargeddev)
	transformed_swingsound = BLUNTWOOSH_HUGE
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 4
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/kirkhammer/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)

