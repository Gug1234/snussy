// ===================== BLOODLETTER INTENTS =====================
// Base form: One-handed mace â€” compact blunt strikes.
// Transformed: Two-handed blood flail â€” massive, sweeping blood-infused attacks.

/// Bloodletter base - overhand. Downward overhead strike with the mace head.
/datum/intent/bloodletter/overhand
	name = "overhand"
	icon_state = "insmash"
	attack_verb = list("bashes", "hammers")
	animname = "chop"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_hit1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.0
	clickcd = CLICK_CD_MELEE
	swingdelay = 0
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Bloodletter base - sweep. Backhand horizontal sweep from left to right.
/datum/intent/bloodletter/sweep
	name = "sweep"
	icon_state = "instrike"
	attack_verb = list("sweeps", "swipes")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_hit1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 0.95
	clickcd = CLICK_CD_MELEE
	swingdelay = 0
	item_d_type = "blunt"

/// Bloodletter base - thrust. Forward thrust with the mace head.
/datum/intent/bloodletter/thrust
	name = "thrust"
	icon_state = "inthrust"
	attack_verb = list("thrusts", "jabs")
	animname = "thrust"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_hit1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "blunt"

/// Bloodletter base - slam. Heavy overhead slam, fully charged.
/datum/intent/bloodletter/slam
	name = "slam"
	icon_state = "incrush"
	attack_verb = list("slams", "crushes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_hit1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_hit2.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Bloodletter transformed - blood sweep. Wide backhanded sweep with the blood flail.
/datum/intent/bloodletter/bloodsweep
	name = "blood sweep"
	icon_state = "insweep"
	attack_verb = list("lashes", "rends")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_combo1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo2.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.05
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Bloodletter transformed - blood smash. Overhead slam with the blood-engorged head.
/datum/intent/bloodletter/bloodsmash
	name = "blood smash"
	icon_state = "insmash"
	attack_verb = list("smashes", "pulverizes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_combo1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo2.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo3.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_MELEE
	swingdelay = 4
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Bloodletter transformed - blood thrust. Two-handed forward thrust with the spiked head.
/datum/intent/bloodletter/bloodthrust
	name = "blood thrust"
	icon_state = "inthrust"
	attack_verb = list("impales", "gores")
	animname = "thrust"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_combo1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo2.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "blunt"

/// Bloodletter transformed - blood slam. Devastating two-handed overhead ground slam.
/datum/intent/bloodletter/bloodslam
	name = "blood slam"
	icon_state = "incrush"
	attack_verb = list("devastates", "blood-crushes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/bloodletter/blood_combo1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo2.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo3.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG



// ===================== BLOODLETTER =====================
// Base: One-handed mace â€” simple blunt strikes (maces skill).
// Transformed: Two-handed blood flail â€” devastating sweeps and slams.
// A weapon steeped in Graggar's cruelty â€” its wielder feeds it with their
// own blood, and it rewards them with terrible, indiscriminate violence.
//
// Unique mechanics:
//   1. Transformation COSTS HP (the wielder stabs themselves to draw blood).
//   2. Base is one-handed (bigboy = FALSE), transformed is two-handed (bigboy = TRUE).
//      apply_transformed_state/apply_base_state overridden to toggle bigboy.

/obj/item/rogueweapon/trickweapon/bloodletter
	name = "bloodletter"
	desc = "A trick weapon steeped in Graggar's cruelty. In its base form, a sturdy one-handed mace with an iron head designed for crushing blows. But the weapon's true nature is far more sinister â€” driven into one's own flesh, it drinks deep and unfurls into a terrible blood-soaked flail. Those who wield it say they can hear the Conqueror's laughter."
	icon_state = "bloodletter"
	item_state = "bloodletter"
	force = 21
	force_wielded = 24
	possible_item_intents = list(/datum/intent/bloodletter/overhand, /datum/intent/bloodletter/sweep, /datum/intent/bloodletter/thrust, /datum/intent/bloodletter/slam)
	gripped_intents = list(/datum/intent/bloodletter/overhand, /datum/intent/bloodletter/sweep, /datum/intent/bloodletter/thrust, /datum/intent/bloodletter/slam)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_NORMAL
	wdefense = 4
	wdefense_wbonus = 0
	minstr = 7
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall2.ogg'
	transform_sound = 'modular/sounds/trickweapons/bloodletter/bloodletter_transform.ogg'
	untransform_sound = 'modular/sounds/trickweapons/bloodletter/bloodletter_untransform.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_BLUNT
	smeltresult = /obj/item/ingot/iron
	sellprice = 55
	grid_width = 32
	grid_height = 64
	/// HP cost when transforming into the blood flail (one-time stab).
	var/transform_hp_cost = 10
	// --- Transformed state: Two-handed blood flail ---
	transformed_name = "bloodletter"
	transformed_desc = "The bloodletter, now a grotesque flail of congealed blood and iron. The wielder's own vitality animates the weapon, its chain-like tendrils of hardened blood lashing out with terrible force. Graggar's cruelty made manifest â€” every transformation demands a tithe of flesh."
	transformed_icon_state = "bloodletter_t"
	transformed_item_state = "bloodletter_t"
	transformed_force = 25
	transformed_force_wielded = 30
	transformed_intents = list(/datum/intent/bloodletter/bloodsweep, /datum/intent/bloodletter/bloodsmash, /datum/intent/bloodletter/bloodthrust, /datum/intent/bloodletter/bloodslam)
	transformed_gripped_intents = list(/datum/intent/bloodletter/bloodsweep, /datum/intent/bloodletter/bloodsmash, /datum/intent/bloodletter/bloodthrust, /datum/intent/bloodletter/bloodslam)
	transformed_swingsound = BLADEWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 0
	transformed_minstr = 9
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/bloodletter_crush
	transformed_special = /datum/special_intent/bloodletter_eruption

/// Mob render properties for one-handed and wielded display (mace-sized).
/obj/item/rogueweapon/trickweapon/bloodletter/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.75,"sx" = -3,"sy" = 4,"nx" = 1,"ny" = 5,"wx" = 1,"wy" = 5,"ex" = -3,"ey" = 3,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 200,"sturn" = -24,"wturn" = -24,"eturn" = 297,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
				if("wielded")
					return list("shrink" = 1,"sx" = 2,"sy" = -3,"nx" = -5,"ny" = -4,"wx" = 3,"wy" = -4,"ex" = 1,"ey" = -4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 211,"sturn" = 11,"wturn" = 34,"eturn" = -3,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.3,"sx" = -13,"sy" = -9,"nx" = 9,"ny" = -6,"wx" = -7,"wy" = -6,"ex" = 2,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 180,"wturn" = 90,"eturn" = 90,"nflip" = 1,"sflip" = 0,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.4,"sx" = 0,"sy" = -1,"nx" = -5,"ny" = -1,"wx" = 1,"wy" = -3,"ex" = 0,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 175,"sturn" = 0,"wturn" = 42,"eturn" = 0,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)

/**
 * Override transform_weapon to apply HP cost when transforming INTO
 * the blood flail. The wielder stabs themselves to draw blood.
 * Reverting to base form has no cost.
 */
/obj/item/rogueweapon/trickweapon/bloodletter/transform_weapon(mob/living/user)
	// Only charge HP when going FROM base TO transformed
	if(!transformed)
		user.adjustBruteLoss(transform_hp_cost)
		to_chat(user, span_danger("You drive [src] into your own flesh, feeding it with blood!"))
		playsound(loc, 'sound/combat/hits/blunt/genblunt (3).ogg', 80, TRUE)
	..()

/**
 * Override apply_transformed_state to also set bigboy = TRUE,
 * making the blood flail require two hands to wield effectively.
 */
/obj/item/rogueweapon/trickweapon/bloodletter/apply_transformed_state()
	..()
	bigboy = TRUE

/**
 * Override apply_base_state to restore bigboy = FALSE,
 * returning the weapon to one-handed mace mode.
 */
/obj/item/rogueweapon/trickweapon/bloodletter/apply_base_state()
	..()
	bigboy = FALSE



