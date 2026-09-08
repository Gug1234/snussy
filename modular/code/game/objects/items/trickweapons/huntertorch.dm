// ===================== HUNTER TORCH INTENTS =====================
// The swing sounds are Yharnamite villager voice lines. Every swing, it screams.

/// Hunter Torch base - torch sweep. Horizontal fire sweep at chest level.
/datum/intent/huntertorch/sweep
	name = "torch sweep"
	icon_state = "incut"
	attack_verb = list("scorches", "sweeps")
	animname = "cut"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Hunter Torch base - torch swing. Upward fire swing from the hip.
/datum/intent/huntertorch/swing
	name = "torch swing"
	icon_state = "inuppercut"
	attack_verb = list("swings", "sears")
	animname = "cut"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Hunter Torch base - torch thrust. Jabbing the lit end forward into the target.
/datum/intent/huntertorch/thrust
	name = "torch thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Hunter Torch base - overhead smash. Slamming the torch down with both the weight of the wood
/// and the fury of the mob. Slow, heavy, blunt. The long dramatic shouts.
/datum/intent/huntertorch/smash
	name = "overhead smash"
	icon_state = "insmash"
	attack_verb = list("smashes", "slams down on")
	animname = "chop"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	swingsound = list('modular/sounds/trickweapons/huntertorch/burn1.ogg', 'modular/sounds/trickweapons/huntertorch/dieee.ogg', 'modular/sounds/trickweapons/huntertorch/mash_brain.ogg', 'modular/sounds/trickweapons/huntertorch/plague_rat.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.3
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

// ===================== HUNTER TORCH TRANSFORMED INTENTS =====================
// The mob's rage intensifies. Beast roars mix in with the screaming.

/// Hunter Torch transformed - frenzied sweep. Fast, wild horizontal fire arc.
/datum/intent/huntertorch/frenzy
	name = "frenzied sweep"
	icon_state = "incut"
	attack_verb = list("sears", "scorches")
	animname = "cut"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Hunter Torch transformed - wild swing. Upward fire arc, fast and reckless.
/datum/intent/huntertorch/wild
	name = "wild swing"
	icon_state = "inuppercut"
	attack_verb = list("swings wildly at", "sears")
	animname = "cut"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.95
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Hunter Torch transformed - burning jab. Forward fire thrust, angrier.
/datum/intent/huntertorch/burnjab
	name = "burning jab"
	icon_state = "instab"
	attack_verb = list("burns into", "jabs")
	animname = "stab"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"

/// Hunter Torch transformed - immolation. Charged overhead fire slam.
/// The mob's fury reaches its peak. Beast roars and primal screaming.
/datum/intent/huntertorch/immolate
	name = "immolation"
	icon_state = "incrush"
	attack_verb = list("immolates", "engulfs")
	animname = "chop"
	blade_class = BCLASS_BURN
	hitsound = list('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/ignite.ogg')
	swingsound = list('modular/sounds/trickweapons/huntertorch/beast_roar1.ogg', 'modular/sounds/trickweapons/huntertorch/beast_roar2.ogg', 'modular/sounds/trickweapons/huntertorch/dieee.ogg', 'modular/sounds/trickweapons/huntertorch/burn1.ogg')
	chargetime = 8
	chargedrain = 2
	penfactor = 30
	damfactor = 1.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

// ===================== HUNTER TORCH =====================
// Base: A crude torch from the streets of Yharnam. Screams when you swing it.
// Transformed: The fire intensifies and the screaming gets worse.
// 1H ONLY. Low damage, high comedy value.

/obj/item/rogueweapon/trickweapon/huntertorch
	name = "hunter's torch"
	desc = "A crude torch carried by desperate hunters of beasts. The wood is soaked in something foul-smelling. When swung, it screams. Not metaphorically. It literally screams obscenities at your target. 'AWAY! AWAY!' it shrieks, unprompted."
	icon_state = "huntertorch"
	item_state = "huntertorch"
	force = 12
	force_wielded = 0
	possible_item_intents = list(/datum/intent/huntertorch/sweep, /datum/intent/huntertorch/swing, /datum/intent/huntertorch/thrust, /datum/intent/huntertorch/smash)
	gripped_intents = null
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_SWIFT
	wdefense = 1
	wdefense_wbonus = 0
	minstr = 6
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = list(\
		'modular/sounds/trickweapons/huntertorch/die.ogg',\
		'modular/sounds/trickweapons/huntertorch/fiend.ogg',\
		'modular/sounds/trickweapons/huntertorch/kill.ogg',\
		'modular/sounds/trickweapons/huntertorch/burn2.ogg',\
		'modular/sounds/trickweapons/huntertorch/cursed_beast.ogg',\
		'modular/sounds/trickweapons/huntertorch/vile_beast.ogg',\
		'modular/sounds/trickweapons/huntertorch/death_upon_ya.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away1.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away2.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away3.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away4.ogg',\
		'modular/sounds/trickweapons/huntertorch/foul_beast.ogg',\
		'modular/sounds/trickweapons/huntertorch/not_wanted.ogg',\
		'modular/sounds/trickweapons/huntertorch/your_fault.ogg',\
		'modular/sounds/trickweapons/huntertorch/better_off_dead.ogg')
	parrysound = list('sound/combat/parry/pugilism/unarmparry (1).ogg', 'sound/combat/parry/pugilism/unarmparry (2).ogg', 'sound/combat/parry/pugilism/unarmparry (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall2.ogg'
	transform_sound = 'modular/sounds/trickweapons/huntertorch/beast_roar1.ogg'
	throwforce = 5
	thrown_bclass = BCLASS_BLUNT
	sellprice = 10
	grid_width = 32
	grid_height = 32
	// --- Transformed state: Enraged Torch ---
	transformed_name = "hunter's torch"
	transformed_desc = "The torch burns with renewed fury. The screaming is louder now, more guttural. Something between a man's rage and a beast's howl."
	transformed_icon_state = "huntertorch_t"
	transformed_item_state = "huntertorch_t"
	transformed_force = 18
	transformed_force_wielded = 0
	transformed_intents = list(/datum/intent/huntertorch/frenzy, /datum/intent/huntertorch/wild, /datum/intent/huntertorch/burnjab, /datum/intent/huntertorch/immolate)
	transformed_gripped_intents = null
	transformed_swingsound = list(\
		'modular/sounds/trickweapons/huntertorch/dieee.ogg',\
		'modular/sounds/trickweapons/huntertorch/burn1.ogg',\
		'modular/sounds/trickweapons/huntertorch/burn2.ogg',\
		'modular/sounds/trickweapons/huntertorch/beast_roar1.ogg',\
		'modular/sounds/trickweapons/huntertorch/beast_roar2.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away1.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away2.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away3.ogg',\
		'modular/sounds/trickweapons/huntertorch/away_away4.ogg',\
		'modular/sounds/trickweapons/huntertorch/plague_rat.ogg',\
		'modular/sounds/trickweapons/huntertorch/mash_brain.ogg',\
		'modular/sounds/trickweapons/huntertorch/not_wanted.ogg')
	transformed_wlength = WLENGTH_SHORT
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 1
	transformed_wdefense_wbonus = 0
	transformed_minstr = 6
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_NORMAL

/obj/item/rogueweapon/trickweapon/huntertorch/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -7,"sy" = 1,"nx" = 5,"ny" = 1,"wx" = -2,"wy" = 0,"ex" = -1,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = -38,"sturn" = 38,"wturn" = 38,"eturn" = -38,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
