// ===================== LUDWIG'S HOLY BLADE INTENTS =====================
// Base (silver longsword): Quick diagonal slashes, forward thrusts, pommel strikes.
// Transformed (greatsword): Devastating 2H sweeps, overhead slams, charged thrusts.
// Sounds: modular/sounds/trickweapons/ludwigblade/

// --- Base mode: Silver longsword ---

/// Fast diagonal slash â€” the R1 combo opener. Quick right-to-left cut.
/datum/intent/ludwig/diagslash
	name = "diagonal slash"
	icon_state = "incut"
	attack_verb = list("slashes", "cuts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/ludwigblade/sword_hit1.ogg', 'modular/sounds/trickweapons/ludwigblade/sword_hit2.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.0
	clickcd = 10
	swingdelay = 0
	item_d_type = "slash"

/// Forward thrust â€” R2 attack. Short windup, direct stab.
/datum/intent/ludwig/thrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "stabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/ludwigblade/stab.ogg')
	chargetime = 0
	penfactor = 25
	damfactor = 1.0
	clickcd = CLICK_CD_MELEE
	swingdelay = 2
	item_d_type = "stab"

/// Pommel strike â€” blunt utility bash with the crossguard.
/datum/intent/ludwig/pommel
	name = "pommel strike"
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

/// Charged violent thrust â€” gripped R2 charged. Extended windup, blade driven upward.
/datum/intent/ludwig/chargedthrust
	name = "violent thrust"
	icon_state = "inthrust"
	attack_verb = list("drives", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/ludwigblade/stab.ogg')
	chargetime = 3
	penfactor = 30
	damfactor = 1.2
	clickcd = CLICK_CD_HEAVY
	swingdelay = 4
	no_early_release = TRUE
	item_d_type = "stab"

// --- Transformed mode: Greatsword ---

/// Heavy overhead chop â€” 1H only. Weak without two-handed leverage.
/datum/intent/ludwig/heavychop
	name = "heavy chop"
	icon_state = "inchop"
	attack_verb = list("chops", "hacks")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/ludwigblade/greatsword_slash1.ogg', 'modular/sounds/trickweapons/ludwigblade/greatsword_slash2.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 0.9
	clickcd = 14
	swingdelay = 8
	item_d_type = "slash"

/// Flat-blade push â€” 1H blunt bash, shield-like shove with the broad side.
/datum/intent/ludwig/greatstrike
	name = "flat strike"
	icon_state = "instrike"
	attack_verb = list("shoves", "bashes")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('sound/combat/hits/blunt/metalblunt (1).ogg', 'sound/combat/hits/blunt/metalblunt (2).ogg', 'sound/combat/hits/blunt/metalblunt (3).ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	swingdelay = 0
	damfactor = 0.7
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR

/// Wide horizontal sweep â€” 2H R1 combo. Sweeping cut from right to left.
/datum/intent/ludwig/greatsweep
	name = "greatsword sweep"
	icon_state = "incut"
	attack_verb = list("sweeps", "cleaves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/ludwigblade/greatsword_slash1.ogg', 'modular/sounds/trickweapons/ludwigblade/greatsword_slash2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1.1
	clickcd = CLICK_CD_MELEE
	swingdelay = 4
	item_d_type = "slash"

/// Vertical overhead slam â€” 2H R2. Sword raised and brought crashing down.
/datum/intent/ludwig/verticalslam
	name = "vertical slam"
	icon_state = "insmash"
	attack_verb = list("slams", "crushes")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/ludwigblade/greatsword_slash1.ogg', 'modular/sounds/trickweapons/ludwigblade/greatsword_slash2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.25
	clickcd = 14
	swingdelay = 8
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Devastating charged thrust â€” 2H charged R2. Massive windup, blade driven forward and up.
/datum/intent/ludwig/greatthrust
	name = "devastating thrust"
	icon_state = "instab"
	attack_verb = list("drives", "impales", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/ludwigblade/stab.ogg')
	chargetime = 5
	penfactor = 40
	damfactor = 1.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	no_early_release = TRUE
	item_d_type = "stab"

// ===================== LUDWIG'S HOLY BLADE =====================
// Base: One-handed silver longsword. Quick cuts, thrusts, pommel strikes.
// Transformed: Massive greatsword. Devastating 2H sweeps and charged thrusts.
// 2H FOCUSED in transformed state - weak 1H, powerful 2H.

/obj/item/rogueweapon/trickweapon/ludwigblade
	name = "pontifex blade"
	desc = "A trick weapon forged for the warrior-priests of the Psydonic faith. In its sheathed form, a silver longsword of reliable make. When drawn from its scabbard-like greatsword shell, the blade locks into the larger frame to form a single weapon of staggering size and weight. The Pontifexes wielded these to devastating effect against deadites and werewolves alike."
	icon_state = "ludwigsword"
	item_state = "ludwigsword"
	force = 22
	force_wielded = 25
	possible_item_intents = list(/datum/intent/ludwig/diagslash, /datum/intent/ludwig/thrust, /datum/intent/ludwig/pommel)
	gripped_intents = list(/datum/intent/ludwig/diagslash, /datum/intent/ludwig/thrust, /datum/intent/ludwig/pommel, /datum/intent/ludwig/chargedthrust)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_NORMAL
	wdefense = 5
	wdefense_wbonus = 3
	minstr = 8
	max_blade_int = 250
	max_integrity = 250
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_MED
	parrysound = list('sound/combat/parry/bladed/bladedmedium (1).ogg', 'sound/combat/parry/bladed/bladedmedium (2).ogg', 'sound/combat/parry/bladed/bladedmedium (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge1.ogg'
	transform_sound = 'modular/sounds/trickweapons/ludwigblade/activate.ogg'
	throwforce = 10
	thrown_bclass = BCLASS_CUT
	sellprice = 60
	grid_width = 32
	grid_height = 64
	is_silver = TRUE
	// --- Transformed state: Greatsword ---
	transformed_name = "pontifex blade"
	transformed_desc = "The pontifex blade, now assembled into its full greatsword form. The silver longsword locks into the massive shell, creating a single weapon of immense reach and crushing weight. Each swing carries the conviction of the Psydonic faithful."
	transformed_icon_state = "ludwigsword_t"
	transformed_item_state = "ludwigsword_t"
	transformed_force = 14 // Weak 1H - designed for 2H use
	transformed_force_wielded = 30 // Massive 2H bonus
	transformed_intents = list(/datum/intent/ludwig/heavychop, /datum/intent/ludwig/greatstrike)
	transformed_gripped_intents = list(/datum/intent/ludwig/greatsweep, /datum/intent/ludwig/verticalslam, /datum/intent/ludwig/greatthrust, /datum/intent/ludwig/greatstrike)
	transformed_swingsound = BLADEWOOSH_HUGE
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 5
	transformed_wdefense_wbonus = 5
	transformed_minstr = 11
	transformed_associated_skill = /datum/skill/combat/swords
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/ludwigs_silver_flash
	transformed_special = /datum/special_intent/ludwigs_holy_slam

/// Mob render properties for one-handed and wielded display.
/obj/item/rogueweapon/trickweapon/ludwigblade/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.6,"sx" = -8,"sy" = 13,"nx" = 20,"ny" = -11,"wx" = 4,"wy" = 11,"ex" = -7,"ey" = 10,"northabove" = 1,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 70,"sturn" = -52,"wturn" = -17,"eturn" = 17,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = -4)
				if("wielded")
					return list("shrink" = 0.6,"sx" = 9,"sy" = 0,"nx" = -9,"ny" = 0,"wx" = 10,"wy" = -11,"ex" = 11,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -9,"sturn" = 9,"wturn" = 51,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.5,"sx" = -14,"sy" = -12,"nx" = 14,"ny" = -8,"wx" = -11,"wy" = -7,"ex" = 4,"ey" = -7,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = -20,"sturn" = 0,"wturn" = 18,"eturn" = -25,"nflip" = 1,"sflip" = -1,"wflip" = -1,"eflip" = 1)
				if("wielded")
					return list("shrink" = 0.6,"sx" = 6,"sy" = -3,"nx" = -6,"ny" = -2,"wx" = 9,"wy" = -8,"ex" = 9,"ey" = -3,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 0,"sturn" = 0,"wturn" = 27,"eturn" = 0,"nflip" = 4,"sflip" = 0,"wflip" = 0,"eflip" = 0)

