/// Church Pick - penetrating overhead strike. High pen for armored targets.
/datum/intent/pick/strike
	name = "overhead strike"
	icon_state = "instrike"
	attack_verb = list("strikes", "drives")
	animname = "chop"
	blade_class = BCLASS_PICK
	hitsound = list('modular/sounds/trickweapons/churchpick/pick_hit1.ogg', 'modular/sounds/trickweapons/churchpick/pick_hit2.ogg', 'modular/sounds/trickweapons/churchpick/pick_iron.ogg')
	penfactor = 55
	swingdelay = 6
	damfactor = 1
	clickcd = 14
	item_d_type = "piercing"

/// Church Pick - heavy penetrating thrust, 2H focused.
/datum/intent/pick/thrust
	name = "piercing thrust"
	icon_state = "instab"
	attack_verb = list("pierces", "impales")
	animname = "stab"
	blade_class = BCLASS_PICK
	hitsound = list('modular/sounds/trickweapons/churchpick/pick_hit1.ogg', 'modular/sounds/trickweapons/churchpick/pick_hit2.ogg', 'modular/sounds/trickweapons/churchpick/pick_iron.ogg')
	penfactor = 60
	swingdelay = 4
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	item_d_type = "piercing"

// ===================== CHURCH PICK INTENTS =====================

/// Church Pick base - quick thrust. R1 combo opener, straight thrust forward.
/datum/intent/churchpick/quickthrust
	name = "quick thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/churchpick/pick_hit1.ogg', 'modular/sounds/trickweapons/churchpick/pick_hit2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "stab"

/// Church Pick base - horizontal sweep. R1 combo and backstep R1.
/datum/intent/churchpick/horizsweep
	name = "horizontal sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/churchpick/slash_hit1.ogg', 'modular/sounds/trickweapons/churchpick/slash_hit2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.03
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Church Pick base - forceful thrust. R2 powerful thrust forward.
/datum/intent/churchpick/forcethrust
	name = "forceful thrust"
	icon_state = "instab"
	attack_verb = list("drives into", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/churchpick/pick_hit1.ogg', 'modular/sounds/trickweapons/churchpick/pick_iron.ogg')
	chargetime = 0
	penfactor = 35
	damfactor = 1.37
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "stab"

/// Church Pick base - arching uppercut. Charged R2 wide uppercut from foot to shoulder.
/datum/intent/churchpick/uppercut
	name = "arching uppercut"
	icon_state = "incut"
	attack_verb = list("uppercuts", "arcs through")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/churchpick/slash_hit1.ogg', 'modular/sounds/trickweapons/churchpick/slash_hit2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 30
	damfactor = 1.79
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "slash"

/// Church Pick transformed - overhead slam. R1 combo overhand downward strikes.
/datum/intent/churchpick/overheadslam
	name = "overhead slam"
	icon_state = "inchop"
	attack_verb = list("slams", "drives down")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/churchpick/pick_hit2.ogg', 'modular/sounds/trickweapons/churchpick/pick_iron.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	item_d_type = "slash"

/// Church Pick transformed - wide sweep. R1 combo horizontal sweeps at extended range.
/datum/intent/churchpick/widesweep
	name = "wide sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "rakes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/churchpick/slash_hit1.ogg', 'modular/sounds/trickweapons/churchpick/pick_hit1.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.05
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Church Pick transformed - charged double slam. Charged R2, fake-out sweep into overhead slam.
/datum/intent/churchpick/chargeddouble
	name = "charged double slam"
	icon_state = "insmash"
	attack_verb = list("crushes", "pounds")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/churchpick/pick_hit1.ogg', 'modular/sounds/trickweapons/churchpick/pick_hit2.ogg')
	chargetime = 6
	chargedrain = 2
	penfactor = 40
	damfactor = 2.21
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	no_early_release = TRUE
	misscost = 10
	item_d_type = "slash"

/// Church Pick transformed - quick swipe. L2 shortened backhand horizontal swipe.
/// Same animation regardless of movement state; fast but weak.
/datum/intent/churchpick/quickswipe
	name = "quick swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "flicks")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/churchpick/slash_hit2.ogg', 'modular/sounds/trickweapons/churchpick/pick_hit1.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.53
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

// ===================== CHURCH PICK =====================
// Base: Broadsword. Standard sword cuts, thrusts, and chops.
// Transformed: Warpick. Penetrating overhead strikes and thrusts.
// 2H GREATLY benefits pick mode - high pen scaling.

/obj/item/rogueweapon/trickweapon/churchpick
	name = "inquisitor's pick"
	desc = "A trick weapon commissioned by the Otavan Inquisition for its Ordinators. In its compact form, it serves as a sturdy broadsword suited to general combat. When transformed, the blade folds outward into a savage warpick designed to puncture deadite hides and Rot-hardened bone."
	icon_state = "churchpick"
	item_state = "churchpick"
	force = 22
	force_wielded = 26
	possible_item_intents = list(/datum/intent/churchpick/quickthrust, /datum/intent/churchpick/horizsweep, /datum/intent/churchpick/forcethrust)
	gripped_intents = list(/datum/intent/churchpick/quickthrust, /datum/intent/churchpick/horizsweep, /datum/intent/churchpick/forcethrust, /datum/intent/churchpick/uppercut)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_NORMAL
	wdefense = 5
	wdefense_wbonus = 3
	minstr = 8
	max_blade_int = 250
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 50
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Warpick ---
	transformed_name = "inquisitor's pick"
	transformed_desc = "The inquisitor's pick, unfolded into its warpick form. The cruel, narrow point concentrates immense force into a tiny area, punching through avantyne armor and werewolf bone with equal ease. Best wielded with both hands."
	transformed_icon_state = "churchpick_t"
	transformed_item_state = "churchpick_t"
	transformed_force = 18 // Weak 1H - designed for 2H use
	transformed_force_wielded = 30 // Massive 2H bonus
	transformed_intents = list(/datum/intent/churchpick/overheadslam, /datum/intent/churchpick/widesweep)
	transformed_gripped_intents = list(/datum/intent/churchpick/overheadslam, /datum/intent/churchpick/widesweep, /datum/intent/churchpick/chargeddouble, /datum/intent/churchpick/quickswipe)
	transformed_swingsound = BLADEWOOSH_LARGE
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 4
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/axes
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/churchpick/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)

