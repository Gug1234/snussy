// ===================== REITERPALLASCH INTENTS =====================
// Base form: Silver rapier (swords skill). Fast thrusts and precise slashes.
// Transformed: Pistol-sword. Retains blade attacks and adds a pistol shot.

/// Reiterpallasch base - quick thrust. R1 combo opener, straight rapier thrust.
/datum/intent/reiter/thrust
	name = "quick thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/iron_stab_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat2.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "stab"

/// Reiterpallasch base - quick slash. R1 alternating slash from left to right.
/datum/intent/reiter/quickslash
	name = "quick slash"
	icon_state = "inslash"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/iron_cut_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_cut_meat2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.95
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Reiterpallasch base - sweep slash. Wide horizontal sweep for crowd control.
/datum/intent/reiter/sweepslash
	name = "sweep slash"
	icon_state = "incut"
	attack_verb = list("sweeps", "slashes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/iron_cut_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_cut_meat2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.05
	clickcd = CLICK_CD_CHARGED
	swingdelay = 4
	item_d_type = "slash"

/// Reiterpallasch base - charged thrust. R2 powerful lunge forward.
/datum/intent/reiter/chargedthrust
	name = "charged thrust"
	icon_state = "inthrust"
	attack_verb = list("drives into", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/iron_stab_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 40
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "stab"

/// Reiterpallasch transformed - quick slash. Fast sword slash in pistol-sword mode.
/datum/intent/reiter/t_quickslash
	name = "quick slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/iron_cut_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_cut_meat2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Reiterpallasch transformed - lunge thrust. Forward-lunging stab with extended reach.
/datum/intent/reiter/lungethrust
	name = "lunge thrust"
	icon_state = "instab"
	attack_verb = list("lunges into", "thrusts")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/iron_stab_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	swingdelay = 4
	item_d_type = "stab"

/// Reiterpallasch transformed - pistol shot. Fires a lead sphere at melee range.
/// Consumes one lead sphere from inventory. High pen, blunt damage, long cooldown.
/datum/intent/reiter/pistolshot
	name = "pistol shot"
	icon_state = "instrike"
	attack_verb = list("shoots", "blasts")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/reiterpallasch/shot.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 50
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	item_d_type = "blunt"
	/// This intent requires ammo to fire. Checked by trickweapon pre_attack().
	var/requires_ammo = TRUE

/// Reiterpallasch transformed - extending thrust. Charged rapier thrust at full extension.
/datum/intent/reiter/extendingthrust
	name = "extending thrust"
	icon_state = "inthrust"
	attack_verb = list("drives through", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/iron_stab_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat2.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 40
	damfactor = 1.45
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "stab"


// ===================== REITERPALLASCH =====================
// Base: Silver rapier â€” a Ferentian noble's dueling blade. Fast, precise thrusts.
// Transformed: Pistol-sword â€” the blade extends and a hidden pistol mechanism
// is revealed. Fires a single lead sphere at melee range.
// A weapon favored by Ferentian aristocrats who value elegance as much as lethality.
//
// Silver property: is_silver = TRUE (effective vs. undead/werewolves).
// Ammo: Consumes /obj/item/ammo_casing/caseless/bullet/lead per pistol shot.
// Skill: Swords (base + transformed).

/obj/item/rogueweapon/trickweapon/reiterpallasch
	name = "reiterpallasch"
	desc = "A trick weapon favored by the dueling aristocracy of Ferentia. In its base form, a slender silver rapier built for precise, lightning-fast thrusts. Attached to it is a firing mechanism that allows for shots amidst the duel."
	icon_state = "reiter"
	item_state = "reiter"
	force = 20
	force_wielded = 23
	possible_item_intents = list(/datum/intent/reiter/thrust, /datum/intent/reiter/quickslash, /datum/intent/reiter/sweepslash, /datum/intent/reiter/chargedthrust)
	gripped_intents = list(/datum/intent/reiter/thrust, /datum/intent/reiter/quickslash, /datum/intent/reiter/sweepslash, /datum/intent/reiter/chargedthrust)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_SWIFT
	wdefense = 7
	wdefense_wbonus = 0
	minstr = 5
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	is_silver = TRUE
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/reiterpallasch/transform1.ogg'
	untransform_sound = 'modular/sounds/trickweapons/reiterpallasch/transform2.ogg'
	throwforce = 8
	thrown_bclass = BCLASS_STAB
	anvilrepair = /datum/skill/craft/weaponsmithing
	smeltresult = /obj/item/ingot/silver
	sellprice = 60
	grid_width = 32
	grid_height = 64
	// --- Ammo system: consumes lead spheres for pistol shot intent ---
	shot_ammo_type = /obj/item/ammo_casing/caseless/bullet/lead
	// --- Transformed state: Pistol-Sword ---
	transformed_name = "reiterpallasch"
	transformed_desc = "The reiterpallasch, now extended into its pistol-sword form. The blade is fully deployed and a hidden firing mechanism is revealed near the hilt. A pull of the trigger fires a lead sphere at point-blank range â€” a lethal surprise mid-duel."
	transformed_icon_state = "reiter_t"
	transformed_item_state = "reiter_t"
	transformed_force = 21
	transformed_force_wielded = 24
	transformed_intents = list(/datum/intent/reiter/t_quickslash, /datum/intent/reiter/lungethrust, /datum/intent/reiter/pistolshot, /datum/intent/reiter/extendingthrust)
	transformed_gripped_intents = list(/datum/intent/reiter/t_quickslash, /datum/intent/reiter/lungethrust, /datum/intent/reiter/pistolshot, /datum/intent/reiter/extendingthrust)
	transformed_swingsound = BLADEWOOSH_SMALL
	transformed_wlength = WLENGTH_NORMAL
	transformed_wbalance = WBALANCE_SWIFT
	transformed_wdefense = 6
	transformed_wdefense_wbonus = 0
	transformed_minstr = 5
	transformed_associated_skill = /datum/skill/combat/swords
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_NORMAL
	special = /datum/special_intent/reiterpallasch_shot
	transformed_special = /datum/special_intent/reiterpallasch_riposte

/// Mob render properties for one-handed and wielded display (rapier-sized).
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/reiterpallasch/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				if(transformed) // --- Transformed (gun-rapier) one-handed ---
					return list("shrink" = 0.6,"sx" = -16,"sy" = -14,"nx" = 16,"ny" = -14,"wx" = -9,"wy" = -9,"ex" = 9,"ey" = -9,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -67,"eturn" = 67,"nflip" = 0,"sflip" = 4,"wflip" = 4,"eflip" = 0)
				// --- Base (rapier) one-handed ---
				return list("shrink" = 0.5,"sx" = -18,"sy" = -14,"nx" = 16,"ny" = -14,"wx" = -9,"wy" = -9,"ex" = 9,"ey" = -9,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -67,"eturn" = 67,"nflip" = 0,"sflip" = 4,"wflip" = 4,"eflip" = 0)
			if("wielded")
				if(transformed) // --- Transformed (gun-rapier) two-handed ---
					return list("shrink" = 0.6,"sx" = 5,"sy" = 3,"nx" = -4,"ny" = 2,"wx" = -11,"wy" = 4,"ex" = 11,"ey" = 4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 12,"sturn" = -12,"wturn" = 13,"eturn" = -13,"nflip" = 4,"sflip" = 0,"wflip" = 4,"eflip" = 0)
				// --- Base (rapier) two-handed ---
				return list("shrink" = 0.6,"sx" = 5,"sy" = 3,"nx" = -4,"ny" = 2,"wx" = -11,"wy" = 4,"ex" = 11,"ey" = 4,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 12,"sturn" = -12,"wturn" = 13,"eturn" = -13,"nflip" = 4,"sflip" = 0,"wflip" = 4,"eflip" = 0)


