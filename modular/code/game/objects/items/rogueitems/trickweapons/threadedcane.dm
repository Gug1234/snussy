// ===================== THREADED CANE INTENTS =====================

/// Threaded Cane base - horizontal slash. R1 alternating slashes.
/datum/intent/threadedcane/slash
	name = "cane slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_crack1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_crack2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Threaded Cane base - cane thrust. R2 straight lunge.
/datum/intent/threadedcane/thrust
	name = "cane thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "lunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_crack1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_crack2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.35
	clickcd = CLICK_CD_CHARGED
	swingdelay = 4
	item_d_type = "stab"

/// Threaded Cane base - charged thrust. Charged R2, identical motion with more power.
/datum/intent/threadedcane/chargedthrust
	name = "charged thrust"
	icon_state = "instab"
	attack_verb = list("drives into", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_crack1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_land.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 45
	damfactor = 1.9
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "stab"

/// Threaded Cane base - overhead slash. Dash R1 downward strike.
/datum/intent/threadedcane/overheadslash
	name = "overhead slash"
	icon_state = "inchop"
	attack_verb = list("chops", "slashes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_crack1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_crack2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	item_d_type = "slash"

/// Threaded Cane transformed - whip slash. R1 alternating whip swings, reach 2.
/datum/intent/threadedcane/whipslash
	name = "whip slash"
	icon_state = "incut"
	attack_verb = list("lashes", "whips")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_swing1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_hit.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.02
	clickcd = CLICK_CD_MELEE
	reach = 2
	item_d_type = "slash"

/// Threaded Cane transformed - whip thrust. Backstep R1 lash-stab with the tip.
/datum/intent/threadedcane/whipthrust
	name = "whip thrust"
	icon_state = "instab"
	attack_verb = list("stabs", "lashes")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_swing2.ogg', 'modular/sounds/trickweapons/threadedcane/whip_hit.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.07
	clickcd = CLICK_CD_MELEE
	reach = 2
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Threaded Cane transformed - wide sweep. R2 overhead horizontal loop with reach.
/datum/intent/threadedcane/widesweep
	name = "wide sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "lashes")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_swing1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_swing2.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 15
	damfactor = 1.34
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	reach = 2
	item_d_type = "slash"

/// Threaded Cane transformed - overhead lash. Dash R2 vertical whip strike.
/datum/intent/threadedcane/overheadlash
	name = "overhead lash"
	icon_state = "inchop"
	attack_verb = list("lashes down", "cracks upon")
	animname = "chop"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/threadedcane/whip_swing1.ogg', 'modular/sounds/trickweapons/threadedcane/whip_hit.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.39
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	reach = 2
	item_d_type = "slash"

// ===================== THREADED CANE =====================
// Base: Slender sword. Quick cuts and precise thrusts. Can be two-handed.
// Transformed: Bladed whip. Lashing and cracking at range. 1H ONLY.

/obj/item/rogueweapon/trickweapon/threadedcane
	name = "threaded cane"
	desc = "One of the trick weapons of the Artificer's Guild, a refined and elegant instrument favored by Hawthorne aristocrats. In its base form it serves as a slender blade concealed within a gentleman's cane. Transformed, the blade splits apart into a barbed, segmented whip of terrible reach."
	icon_state = "threadedcane"
	item_state = "threadedcane"
	force = 20
	force_wielded = 23
	possible_item_intents = list(/datum/intent/threadedcane/slash, /datum/intent/threadedcane/thrust, /datum/intent/threadedcane/overheadslash)
	gripped_intents = list(/datum/intent/threadedcane/slash, /datum/intent/threadedcane/thrust, /datum/intent/threadedcane/chargedthrust, /datum/intent/threadedcane/overheadslash)
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_SWIFT
	wdefense = 6
	wdefense_wbonus = 0
	minstr = 5
	max_blade_int = 180
	max_integrity = 150
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	throwforce = 8
	thrown_bclass = BCLASS_CUT
	sellprice = 45
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Bladed Whip ---
	transformed_name = "threaded cane"
	transformed_desc = "The threaded cane, now unraveled into its whip form. Segmented blades lash outward in sweeping arcs, flaying Rot-bloated flesh at a distance no sword could reach."
	transformed_icon_state = "threadedcane_t"
	transformed_item_state = "threadedcane_t"
	transformed_force = 19
	transformed_force_wielded = 0
	transformed_intents = list(/datum/intent/threadedcane/whipslash, /datum/intent/threadedcane/whipthrust)
	transformed_gripped_intents = list(/datum/intent/threadedcane/whipslash, /datum/intent/threadedcane/whipthrust, /datum/intent/threadedcane/widesweep, /datum/intent/threadedcane/overheadlash)
	transformed_swingsound = BLADEWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 2 // Hard to parry with a whip
	transformed_wdefense_wbonus = 0
	transformed_minstr = 5
	transformed_associated_skill = /datum/skill/combat/whipsflails
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_NORMAL

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/threadedcane/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.7,"sx" = 5,"sy" = -3,"nx" = -5,"ny" = -2,"wx" = -5,"wy" = -1,"ex" = 3,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 7,"sturn" = -7,"wturn" = 16,"eturn" = -22,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)

