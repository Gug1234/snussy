// ===================== RIFLE SPEAR INTENTS =====================
// Base form: Standard spear (polearms skill). Thrusts and sweeps.
// Transformed: Rifle-halberd. Slashing halberd attacks and a rifle blast.

/// Rifle Spear base - thrust. Standard R1 spear thrust forward.
/datum/intent/riflespear/thrust
	name = "thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/swing_stab1.ogg', 'modular/sounds/trickweapons/generic/swing_stab2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "stab"

/// Rifle Spear base - sweep. Sweeping cut with the spearhead.
/datum/intent/riflespear/sweep
	name = "sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/swing_sword1.ogg', 'modular/sounds/trickweapons/generic/swing_sword2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.9
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Rifle Spear base - heavy thrust. Powerful two-handed thrust.
/datum/intent/riflespear/heavythrust
	name = "heavy thrust"
	icon_state = "instab"
	attack_verb = list("drives into", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/swing_stab_charge.ogg', 'modular/sounds/trickweapons/generic/swing_stab1.ogg')
	chargetime = 0
	penfactor = 35
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "stab"

/// Rifle Spear base - charged thrust. R2 fully-charged lancing thrust.
/datum/intent/riflespear/chargedthrust
	name = "charged thrust"
	icon_state = "instab"
	attack_verb = list("impales", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/swing_stab_charge.ogg', 'modular/sounds/trickweapons/generic/swing_stab2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 45
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "stab"

/// Rifle Spear transformed - halberd slash. R1 wide halberd-style slashing cut.
/datum/intent/riflespear/halberdslash
	name = "halberd slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cleaves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/swing_sword1.ogg', 'modular/sounds/trickweapons/generic/swing_sword2.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "slash"

/// Rifle Spear transformed - lunge thrust. Extended reach thrusting attack.
/datum/intent/riflespear/lungethrust
	name = "lunge thrust"
	icon_state = "instab"
	attack_verb = list("lunges into", "thrusts")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/swing_stab1.ogg', 'modular/sounds/trickweapons/generic/swing_stab2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.05
	clickcd = CLICK_CD_CHARGED
	reach = 2
	swingdelay = 4
	item_d_type = "stab"

/// Rifle Spear transformed - rifle blast. Fires grapeshot at melee range.
/// Consumes one grapeshot from inventory. Concussive spread, high pen, long cooldown.
/datum/intent/riflespear/rifleblast
	name = "rifle blast"
	icon_state = "instrike"
	attack_verb = list("blasts", "shoots")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/riflespear/musket_shot1.ogg', 'modular/sounds/trickweapons/riflespear/musket_shot2.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 55
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "blunt"
	/// This intent requires ammo to fire. Checked by trickweapon pre_attack().
	var/requires_ammo = TRUE

/// Rifle Spear transformed - heavy thrust. Powerful extended thrust at range.
/datum/intent/riflespear/t_heavythrust
	name = "heavy thrust"
	icon_state = "instab"
	attack_verb = list("drives through", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/swing_stab_charge.ogg', 'modular/sounds/trickweapons/generic/swing_stab1.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 40
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	reach = 2
	swingdelay = 8
	item_d_type = "stab"


// ===================== RIFLE SPEAR =====================
// Base: A sturdy two-handed spear (polearms skill). Reliable thrusts and sweeps.
// Transformed: Rifle-halberd â€” the spearhead extends and a concealed rifle
// barrel is deployed. Fires a grapeshot spread at melee range.
// A trick weapon crafted by the Artificer's Guild. Designed for
// hunters who prefer to keep a safe distance from their prey.
//
// Two-handed focused: strong force_wielded, weak force (1H).
// Ammo: Consumes /obj/item/ammo_casing/caseless/bullet/grapeshot per rifle blast.
// Skill: Polearms (base + transformed).

/obj/item/rogueweapon/trickweapon/riflespear
	name = "rifle spear"
	desc = "A trick weapon crafted by the Artificer's Guild. In its base form, a sturdy steel spear designed for those who prefer to keep a safe distance from deadites and werewolves. Concealed within the haft is a rifle mechanism â€” for when distance alone is not enough."
	icon_state = "riflespear"
	item_state = "riflespear"
	icon = 'modular/icons/obj/trickweapons/trickweapons.dmi'
	pixel_y = -16
	pixel_x = -16
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	bigboy = TRUE
	gripsprite = TRUE
	force = 15
	force_wielded = 28
	possible_item_intents = list(/datum/intent/riflespear/thrust, /datum/intent/riflespear/sweep)
	gripped_intents = list(/datum/intent/riflespear/thrust, /datum/intent/riflespear/sweep, /datum/intent/riflespear/heavythrust, /datum/intent/riflespear/chargedthrust)
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_GREAT
	wbalance = WBALANCE_NORMAL
	wdefense = 5
	wdefense_wbonus = 3
	minstr = 8
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/polearms
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/generic/iron_cut_iron1.ogg'
	untransform_sound = 'modular/sounds/trickweapons/generic/iron_cut_iron2.ogg'
	throwforce = 15
	thrown_bclass = BCLASS_STAB
	anvilrepair = /datum/skill/craft/weaponsmithing
	smeltresult = /obj/item/ingot/steel
	sellprice = 55
	walking_stick = TRUE
	grid_width = 64
	grid_height = 64
	// --- Ammo system: consumes grapeshot for rifle blast intent ---
	shot_ammo_type = /obj/item/ammo_casing/caseless/bullet/grapeshot
	// --- Transformed state: Rifle-Halberd ---
	transformed_name = "rifle spear"
	transformed_desc = "The rifle spear, now extended into its full rifle-halberd form. The spearhead fans outward into a halberd blade while a concealed rifle barrel deploys along the shaft. A devastating close-range blast of grapeshot can be unleashed at the pull of a trigger."
	transformed_icon_state = "riflespear_t"
	transformed_item_state = "riflespear_t"
	transformed_force = 14
	transformed_force_wielded = 30
	transformed_intents = list(/datum/intent/riflespear/halberdslash, /datum/intent/riflespear/lungethrust)
	transformed_gripped_intents = list(/datum/intent/riflespear/halberdslash, /datum/intent/riflespear/lungethrust, /datum/intent/riflespear/rifleblast, /datum/intent/riflespear/t_heavythrust)
	transformed_swingsound = BLADEWOOSH_LARGE
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 4
	transformed_minstr = 9
	transformed_associated_skill = /datum/skill/combat/polearms
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for polearm-sized 64x64 sprite.
/obj/item/rogueweapon/trickweapon/riflespear/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -6,"sy" = 6,"nx" = 6,"ny" = 7,"wx" = 0,"wy" = 5,"ex" = -1,"ey" = 7,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = -50,"sturn" = 40,"wturn" = 50,"eturn" = -50,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.6,"sx" = 9,"sy" = -4,"nx" = -7,"ny" = 1,"wx" = -9,"wy" = 2,"ex" = 10,"ey" = 2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 5,"sturn" = -190,"wturn" = -170,"eturn" = -10,"nflip" = 8,"sflip" = 8,"wflip" = 1,"eflip" = 0)



