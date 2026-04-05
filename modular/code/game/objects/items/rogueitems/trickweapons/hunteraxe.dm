// ===================== HUNTER AXE INTENTS =====================
// Base (one-handed axe): Diagonal cuts, overhead chops, handle bashes.
// Transformed (greataxe/halberd): Wide sweeps, overhead slams, 360-degree spin.
// Sounds: modular/sounds/trickweapons/hunteraxe/

// --- Base mode: One-handed axe ---

/// Diagonal downward cut â€” R1 combo opener. Quick right-to-left axe swing.
/datum/intent/hunteraxe/diagcut
	name = "diagonal cut"
	icon_state = "incut"
	attack_verb = list("cuts", "hacks")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hunteraxe/axe_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/axe_hit2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.0
	clickcd = 10
	swingdelay = 0
	item_d_type = "slash"

/// Overhead chop â€” standard R2 axe strike. Brings the head straight down.
/datum/intent/hunteraxe/chop
	name = "overhead chop"
	icon_state = "inchop"
	attack_verb = list("chops", "cleaves")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/hunteraxe/axe_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/axe_hit2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "slash"

/// Handle bash â€” blunt utility strike with the axe haft.
/datum/intent/hunteraxe/bash
	name = "handle bash"
	icon_state = "instrike"
	attack_verb = list("bashes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('sound/combat/hits/blunt/metalblunt (1).ogg', 'sound/combat/hits/blunt/metalblunt (2).ogg', 'sound/combat/hits/blunt/metalblunt (3).ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	swingdelay = 0
	damfactor = NONBLUNT_BLUNT_DAMFACTOR
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR

/// Charged overhead chop â€” gripped R2 charged. Full-body swing driving the axe deep.
/datum/intent/hunteraxe/chargedchop
	name = "cleaving chop"
	icon_state = "incrush"
	attack_verb = list("cleaves", "splits")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/hunteraxe/axe_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/axe_hit2.ogg')
	chargetime = 3
	penfactor = 30
	damfactor = 1.3
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	no_early_release = TRUE
	item_d_type = "slash"

// --- Transformed mode: Greataxe/Halberd ---

/// Wide horizontal sweep â€” 2H R1 combo. Long sweeping arc.
/datum/intent/hunteraxe/greatsweep
	name = "wide sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "cleaves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hunteraxe/pole_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/pole_hit2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 4
	item_d_type = "slash"

/// Overhead slam â€” powerful overhead axe blow with the extended haft.
/datum/intent/hunteraxe/overheadslam
	name = "overhead slam"
	icon_state = "inchop"
	attack_verb = list("slams", "crushes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/hunteraxe/pole_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/pole_hit2.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.2
	clickcd = 14
	swingdelay = 6
	item_d_type = "slash"

/// Haft thrust â€” forward thrust with the butt end of the extended pole.
/datum/intent/hunteraxe/haftthrust
	name = "haft thrust"
	icon_state = "instab"
	attack_verb = list("jabs", "thrusts")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/hunteraxe/thrust1.ogg', 'modular/sounds/trickweapons/hunteraxe/thrust_deep.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 0.9
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "stab"

/// 360-degree spin â€” the signature Hunter Axe charged R2. Full rotation greataxe sweep.
/datum/intent/hunteraxe/spin
	name = "360 spin"
	icon_state = "insweep"
	attack_verb = list("reaps", "scythes", "carves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/hunteraxe/pole_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/pole_hit2.ogg')
	chargetime = 6
	penfactor = 20
	damfactor = 2.0
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	no_early_release = TRUE
	item_d_type = "slash"

// ===================== HUNTER AXE =====================
// Base: One-handed axe. Diagonal cuts, overhead chops, handle bashes.
// Transformed: Extended greataxe/halberd. Wide sweeps, thrusts, 360 spin.
// 2H FOCUSED in transformed state.

/obj/item/rogueweapon/trickweapon/hunteraxe
	name = "hunter axe"
	desc = "A trick weapon of the Artificer's Guild, favored by hunters who prefer raw strength over finesse. In its compact form, a sturdy one-handed axe. When extended, the handle telescopes outward, transforming it into a long-hafted greataxe capable of sweeping, devastating blows against the deadite horde."
	icon_state = "hunteraxe"
	item_state = "hunteraxe"
	force = 21
	force_wielded = 25
	possible_item_intents = list(/datum/intent/hunteraxe/diagcut, /datum/intent/hunteraxe/chop, /datum/intent/hunteraxe/bash)
	gripped_intents = list(/datum/intent/hunteraxe/diagcut, /datum/intent/hunteraxe/chop, /datum/intent/hunteraxe/bash, /datum/intent/hunteraxe/chargedchop)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_NORMAL
	wdefense = 4
	wdefense_wbonus = 2
	minstr = 8
	max_blade_int = 250
	max_integrity = 250
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/axes
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/hunteraxe/transform.ogg'
	throwforce = 12
	thrown_bclass = BCLASS_CHOP
	sellprice = 45
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Greataxe ---
	transformed_name = "hunter axe"
	transformed_desc = "The hunter axe, now fully extended. The long haft provides tremendous leverage, allowing for sweeping cuts that cleave through hordes of deadites. A brutal weapon for brutal work."
	transformed_icon_state = "hunteraxe_t"
	transformed_item_state = "hunteraxe_t"
	transformed_force = 15 // Weak 1H
	transformed_force_wielded = 30 // Strong 2H
	transformed_intents = list(/datum/intent/hunteraxe/greatsweep, /datum/intent/hunteraxe/haftthrust)
	transformed_gripped_intents = list(/datum/intent/hunteraxe/greatsweep, /datum/intent/hunteraxe/overheadslam, /datum/intent/hunteraxe/haftthrust, /datum/intent/hunteraxe/spin)
	transformed_swingsound = BLADEWOOSH_HUGE
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 3
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/axes
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/hunteraxe/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				if(transformed) // --- Transformed (halberd) one-handed ---
					return list("shrink" = 0.6,"sx" = -4,"sy" = -1,"nx" = 0,"ny" = 0,"wx" = 3,"wy" = -6,"ex" = -6,"ey" = -6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 78,"sturn" = -88,"wturn" = -46,"eturn" = 46,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
				// --- Base (axe) one-handed ---
				return list("shrink" = 0.5,"sx" = -7,"sy" = -5,"nx" = 6,"ny" = -5,"wx" = -2,"wy" = -6,"ex" = -6,"ey" = -6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 78,"sturn" = -88,"wturn" = -46,"eturn" = 46,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				if(transformed) // --- Transformed (halberd) two-handed ---
					return list("shrink" = 0.8,"sx" = 0,"sy" = 0,"nx" = 0,"ny" = 0,"wx" = 0,"wy" = 0,"ex" = 0,"ey" = 1,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = -171,"eturn" = -20,"nflip" = 4,"sflip" = 0,"wflip" = 1,"eflip" = 0)
				// --- Base (axe) two-handed ---
				return list("shrink" = 0.5,"sx" = 4,"sy" = 0,"nx" = -6,"ny" = 0,"wx" = -6,"wy" = 0,"ex" = 6,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 4,"eflip" = 0)

