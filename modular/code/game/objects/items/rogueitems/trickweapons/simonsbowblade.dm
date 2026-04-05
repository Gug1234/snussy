// ===================== SIMON'S BOWBLADE INTENTS =====================

/// Simon's Bowblade base - diagonal slash. R1 alternating curved sword slashes.
/datum/intent/bowblade/diagslash
	name = "diagonal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/simonsbowblade/bow_shot1.ogg', 'modular/sounds/trickweapons/generic/swing_sword1.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Simon's Bowblade base - forward thrust. R2 straight lunge with the blade.
/datum/intent/bowblade/thrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "lunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/generic/iron_stab_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.3
	clickcd = CLICK_CD_CHARGED
	swingdelay = 4
	item_d_type = "stab"

/// Simon's Bowblade base - backhand swipe. Backstep R1 quick reverse slash.
/datum/intent/bowblade/backswipe
	name = "backhand swipe"
	icon_state = "inslash"
	attack_verb = list("swipes", "backhands")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/swing_sword1.ogg', 'modular/sounds/trickweapons/generic/swing_sword2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Simon's Bowblade base - spinning swipe. Charged R2 full-body spin slash.
/datum/intent/bowblade/spinswipe
	name = "spinning swipe"
	icon_state = "incrush"
	attack_verb = list("spins through", "whirls into")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/generic/swing_sword_charge.ogg', 'modular/sounds/trickweapons/generic/swing_sword1.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 25
	damfactor = 1.7
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "slash"

/// Simon's Bowblade transformed - bow swipe. Close-range melee with the bow frame.
/datum/intent/bowblade/bowswipe
	name = "bow swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "strikes")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/simonsbowblade/bow_shot1.ogg', 'modular/sounds/trickweapons/simonsbowblade/bow_shot2.ogg')
	chargetime = 0
	penfactor = 5
	damfactor = 0.7
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Simon's Bowblade transformed - piercing shot. R1 arrow shot at range.
/// Long reach represents the arrow travelling across tiles.
/datum/intent/bowblade/piercingshot
	name = "piercing shot"
	icon_state = "instrike"
	attack_verb = list("pierces", "shoots")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/simonsbowblade/shot.ogg', 'modular/sounds/trickweapons/simonsbowblade/bow_shot3.ogg')
	chargetime = 0
	penfactor = 40
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	reach = 3
	item_d_type = "stab"
	effective_range = 3
	effective_range_type = EFF_RANGE_EXACT

/// Simon's Bowblade transformed - charged shot. Charged R2 powerful arrow with full draw.
/datum/intent/bowblade/chargedshot
	name = "charged shot"
	icon_state = "incrush"
	attack_verb = list("impales", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/simonsbowblade/bow_draw1.ogg', 'modular/sounds/trickweapons/simonsbowblade/bow_shot2.ogg')
	chargetime = 6
	chargedrain = 2
	penfactor = 55
	damfactor = 1.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	no_early_release = TRUE
	reach = 3
	item_d_type = "stab"
	effective_range = 3
	effective_range_type = EFF_RANGE_EXACT

/// Simon's Bowblade transformed - bow thrust. Backstep melee jab with the bow tip.
/datum/intent/bowblade/bowthrust
	name = "bow thrust"
	icon_state = "inthrust"
	attack_verb = list("jabs", "pokes")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/simonsbowblade/bow_shot1.ogg', 'modular/sounds/trickweapons/generic/iron_stab_meat1.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 0.8
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

// ===================== SIMON'S BOWBLADE =====================
// Base: Elegant curved sword. Quick cuts and thrusts.
// Transformed: Bow-like blade. Long-reach thrusting/stabbing attacks
// to simulate the ranged nature of the bow form within melee.
// NOTE: True projectile firing would require a gun-type object.
// This uses long-reach stab intents as a mechanical approximation.

/obj/item/rogueweapon/trickweapon/simonsbowblade
	name = "ranger's bowblade"
	desc = "A trick weapon favored by Ferentian outriders and frontier rangers. In its folded form, a sleek curved sword designed for swift, precise cuts. When unfolded, the blade's halves separate and arc outward, forming a lethal bow-like frame that can strike at considerable distance. A weapon for those who patrol the wilds beyond the duchy walls."
	icon_state = "simonsbowblade"
	item_state = "simonsbowblade"
	force = 20
	force_wielded = 24
	possible_item_intents = list(/datum/intent/bowblade/diagslash, /datum/intent/bowblade/thrust, /datum/intent/bowblade/backswipe)
	gripped_intents = list(/datum/intent/bowblade/diagslash, /datum/intent/bowblade/thrust, /datum/intent/bowblade/backswipe, /datum/intent/bowblade/spinswipe)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_SWIFT
	wdefense = 5
	wdefense_wbonus = 2
	minstr = 6
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_SMALL
	parrysound = list('sound/combat/parry/bladed/bladedthin (1).ogg', 'sound/combat/parry/bladed/bladedthin (2).ogg', 'sound/combat/parry/bladed/bladedthin (3).ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/simonsbowblade/transform1.ogg'
	untransform_sound = 'modular/sounds/trickweapons/simonsbowblade/transform2.ogg'
	throwforce = 8
	thrown_bclass = BCLASS_CUT
	sellprice = 50
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Bow-blade ---
	transformed_name = "ranger's bowblade"
	transformed_desc = "The ranger's bowblade, now unfolded into its bow configuration. The curved halves of the blade arc outward, forming a lethal frame that can lash out at considerable distance with piercing thrusts. A weapon for those who prefer to keep their distance."
	transformed_icon_state = "simonsbowblade_t"
	transformed_item_state = "simonsbowblade_t"
	transformed_force = 12 // Weaker up close
	transformed_force_wielded = 22 // Better at range with 2H
	transformed_intents = list(/datum/intent/bowblade/bowswipe, /datum/intent/bowblade/bowthrust)
	transformed_gripped_intents = list(/datum/intent/bowblade/bowswipe, /datum/intent/bowblade/piercingshot, /datum/intent/bowblade/chargedshot, /datum/intent/bowblade/bowthrust)
	transformed_swingsound = BLADEWOOSH_MED
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 3
	transformed_wdefense_wbonus = 2
	transformed_minstr = 7
	transformed_associated_skill = /datum/skill/combat/polearms
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/simonsbowblade/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				if(transformed) // --- Transformed (bow) one-handed ---
					return list("shrink" = 0.6,"sx" = -3,"sy" = 0,"nx" = 6,"ny" = 2,"wx" = 3,"wy" = 1,"ex" = -4,"ey" = 0,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 75,"sturn" = 0,"wturn" = -23,"eturn" = 23,"nflip" = 0,"sflip" = 4,"wflip" = 4,"eflip" = 0)
				// --- Base (sword) one-handed ---
				return list("shrink" = 0.6,"sx" = -15,"sy" = -12,"nx" = 13,"ny" = -12,"wx" = -11,"wy" = -11,"ex" = 7,"ey" = -11,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = -90,"wturn" = -80,"eturn" = 81,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				if(transformed) // --- Transformed (bow) two-handed ---
					return list("shrink" = 0.7,"sx" = -8,"sy" = -2,"nx" = 10,"ny" = -3,"wx" = 1,"wy" = 0,"ex" = -5,"ey" = -2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 9,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 4,"eflip" = 0)
				// --- Base (sword) two-handed ---
				return list("shrink" = 0.7,"sx" = 5,"sy" = -10,"nx" = -7,"ny" = -1,"wx" = -13,"wy" = 2,"ex" = 10,"ey" = 3,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 12,"sturn" = 29,"wturn" = 23,"eturn" = -26,"nflip" = 8,"sflip" = 0,"wflip" = 8,"eflip" = 0)


