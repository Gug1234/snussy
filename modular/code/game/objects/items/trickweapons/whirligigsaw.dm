// ===================== WHIRLIGIG SAW INTENTS =====================

/// Whirligig Saw base - diagonal slash. Standard R1 combo starter.
/datum/intent/whirligig/slash
	name = "diagonal slash"
	icon_state = "instrike"
	attack_verb = list("slashes", "swipes")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Whirligig Saw base - backstep thrust. Quick jabbing motion.
/datum/intent/whirligig/thrust
	name = "backstep thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "blunt"
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Whirligig Saw base - overhead slam. Charged R2 slam downward.
/datum/intent/whirligig/slam
	name = "overhead slam"
	icon_state = "insmash"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.4
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Whirligig Saw base - power sweep. Wide charged horizontal swing.
/datum/intent/whirligig/powersweep
	name = "power sweep"
	icon_state = "inchop"
	attack_verb = list("sweeps", "swings")
	animname = "cut"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit2.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_hit3.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_HEAVY
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Whirligig Saw transformed - grinding sweep. Fast sawing slash.
/datum/intent/whirligig/grindingsweep
	name = "grinding sweep"
	icon_state = "incut"
	attack_verb = list("grinds into", "saws")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Whirligig Saw transformed - grinding thrust. Drilling stab.
/datum/intent/whirligig/grindingthrust
	name = "grinding thrust"
	icon_state = "instab"
	attack_verb = list("drills into", "grinds")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 2
	chargedrain = 1
	chargedloop = /datum/looping_sound/whirligig_saw
	penfactor = 40
	damfactor = 1.1
	clickcd = CLICK_CD_CHARGED
	item_d_type = "stab"

/// How often the sustained spinning saw aura ticks, in deciseconds (0.5s).
#define SPINNING_SAW_TICK_RATE 5
/// Damage multiplier per sustained grind tick (fraction of force_dynamic).
#define SPINNING_SAW_TICK_DAMFACTOR 0.5

/// Whirligig Saw transformed - spinning saw (L2). Sustained grinding attack.
/// Click and hold to rev the saw. Once fully charged, the spinning disc
/// damages any living mob on the tile the wielder is facing (1 tile forward).
/// Face your target and hold — anything that steps in front gets ground up.
/// High stamina drain while active. Uses chargedloop for saw spin sound.
/datum/intent/whirligig/spinningsaw
	name = "spinning saw"
	icon_state = "inrend"
	attack_verb = list("grinds through", "shreds")
	animname = "strike"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 1
	chargedrain = 1
	chargedloop = /datum/looping_sound/whirligig_saw
	no_early_release = TRUE
	keep_looping = TRUE
	penfactor = 25
	damfactor = 0.7
	clickcd = CLICK_CD_RAPID
	releasedrain = 1
	item_d_type = "slash"
	/// Timer ID for the sustained grinding damage loop.
	var/saw_grind_timer

/// Start the grinding damage aura timer when the charge begins.
/// The tick proc checks for full charge before dealing damage.
/datum/intent/whirligig/spinningsaw/on_charge_start()
	..()
	saw_grind_timer = addtimer(CALLBACK(src, PROC_REF(saw_grind_tick)), SPINNING_SAW_TICK_RATE, TIMER_STOPPABLE | TIMER_LOOP)

/// Stop the grinding damage aura when the mouse is released.
/datum/intent/whirligig/spinningsaw/on_mouse_up()
	if(saw_grind_timer)
		deltimer(saw_grind_timer)
		saw_grind_timer = null
	..()

/**
 * Sustained damage tick for the spinning saw.
 * Fires every SPINNING_SAW_TICK_RATE ds while held. Only applies damage
 * once the charge is complete (chargedprog >= 100). Targets the single
 * tile the wielder is facing — hold the saw out in a direction and
 * anything standing there gets ground up.
 */
/datum/intent/whirligig/spinningsaw/proc/saw_grind_tick()
	// Safety: stop if mob or weapon is gone
	if(!mastermob || QDELETED(mastermob) || !masteritem || QDELETED(masteritem))
		if(saw_grind_timer)
			deltimer(saw_grind_timer)
			saw_grind_timer = null
		return
	// Only deal damage once fully charged
	if(!mastermob.client || mastermob.client.chargedprog < 100)
		return
	// Must still be holding the weapon
	if(mastermob.get_active_held_item() != masteritem)
		if(saw_grind_timer)
			deltimer(saw_grind_timer)
			saw_grind_timer = null
		return
	// Can't grind while incapacitated
	if(mastermob.incapacitated())
		return

	// Get the tile the wielder is facing
	var/turf/target_turf = get_step(mastermob, mastermob.dir)
	if(!target_turf)
		return

	var/grind_damage = max(1, round(masteritem.force_dynamic * SPINNING_SAW_TICK_DAMFACTOR))

	for(var/mob/living/L in target_turf)
		if(L.stat == DEAD)
			continue
		// Apply grinding damage
		var/target_limb = L.simple_limb_hit(mastermob.zone_selected)
		L.apply_damage(grind_damage, BRUTE, def_zone = target_limb)
		// --- On-hit feedback: meaty cut sound + saw grind layered ---
		playsound(L, pick('modular/sounds/trickweapons/generic/iron_cut_meat1.ogg', 'modular/sounds/trickweapons/generic/iron_cut_meat2.ogg'), 65, TRUE)
		playsound(L, pick(hitsound), 50, TRUE)
		// --- VFX: sparks + blood ---
		do_sparks(2, FALSE, L)
		L.add_splatter_floor()
		to_chat(L, span_userdanger("[mastermob]'s spinning saw grinds into you!"))
		to_chat(mastermob, span_warning("The spinning saw grinds into [L]!"))

/// Whirligig Saw transformed - grinding slam. Heavy overhead with spinning disc.
/datum/intent/whirligig/grindingslam
	name = "grinding slam"
	icon_state = "insmash"
	attack_verb = list("slams", "crashes")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg')
	chargetime = 5
	chargedrain = 2
	chargedloop = /datum/looping_sound/whirligig_saw
	penfactor = 35
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "slash"

// ---- Whirligig Saw looping sound ----
/// Looping sound for the Whirligig Saw's spinning disc.
/// Plays saw_spin_loop_start on activation, then loops saw_spin_loop while held.
/// mid_length must closely match the audio file duration for a seamless loop —
/// too short causes stop-start stuttering, too long leaves silence gaps.
/datum/looping_sound/whirligig_saw
	start_sound = 'modular/sounds/trickweapons/whirligigsaw/saw_spin_loop_start.ogg'
	start_length = 12
	mid_sounds = list('modular/sounds/trickweapons/whirligigsaw/saw_spin_loop.ogg')
	mid_length = 30
	volume = 80
	extra_range = 3

// ===================== WHIRLIGIG SAW =====================
// Base: Heavy mace. Standard blunt strikes.
// Transformed: "Pizza Cutter" mode. Fast grinding blunt/cut attacks.
// The transformed mode uses rapid low-damage strikes to simulate
// the continuous grinding of the saw wheel.

/obj/item/rogueweapon/trickweapon/whirligigsaw
	name = "whirligig saw"
	desc = "A trick weapon devised by the heretical artificers of an age past. In its dormant form, a heavy mace-like bludgeon with a large serrated disc at its head. When activated, the disc spins at tremendous speed, grinding through Rot-bloated flesh and deadite bone like a millstone through grain. Affectionately dubbed the 'pizza cutter' by those with a dark sense of humor."
	icon_state = "whirligig"
	transformed_serrated = TRUE // Only serrated when the saw disc is spinning
	item_state = "whirligig"
	force = 22
	force_wielded = 26
	possible_item_intents = list(/datum/intent/whirligig/slash, /datum/intent/whirligig/thrust, /datum/intent/whirligig/slam)
	gripped_intents = list(/datum/intent/whirligig/slash, /datum/intent/whirligig/thrust, /datum/intent/whirligig/slam, /datum/intent/whirligig/powersweep)
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_NORMAL
	wbalance = WBALANCE_HEAVY
	wdefense = 3
	wdefense_wbonus = 3
	minstr = 10
	max_blade_int = 300
	max_integrity = 300
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLUNTWOOSH_MED
	parrysound = list('sound/combat/parry/parrygen.ogg')
	pickup_sound = 'sound/foley/equip/swordlarge2.ogg'
	transform_sound = 'modular/sounds/trickweapons/whirligigsaw/saw_spin_loop_start.ogg'
	throwforce = 12
	thrown_bclass = BCLASS_BLUNT
	sellprice = 55
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Pizza Cutter ---
	transformed_name = "whirligig saw"
	transformed_desc = "The whirligig saw, now fully revved. The massive serrated disc spins with terrifying speed, shredding anything it contacts in a storm of sparks and gore. Hold it steady and let the wheel do the work."
	transformed_icon_state = "whirligig_t"
	transformed_item_state = "whirligig_t"
	transformed_force = 20 
	transformed_force_wielded = 28
	transformed_intents = list(/datum/intent/whirligig/grindingsweep, /datum/intent/whirligig/grindingthrust, /datum/intent/whirligig/spinningsaw)
	transformed_gripped_intents = list(/datum/intent/whirligig/grindingsweep, /datum/intent/whirligig/grindingthrust, /datum/intent/whirligig/spinningsaw, /datum/intent/whirligig/grindingslam)
	transformed_swingsound = BLADEWOOSH_LARGE
	transformed_wlength = WLENGTH_LONG
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 10
	transformed_associated_skill = /datum/skill/combat/axes
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/whirligig_crash
	transformed_special = /datum/special_intent/whirligig_grind

/// Mob render properties for one-handed and wielded display.
/// Branches on `transformed` to use different render profiles per form.
/obj/item/rogueweapon/trickweapon/whirligigsaw/getonmobprop(tag)
	. = ..()
	if(tag)
		if(transformed)
			switch(tag)
				if("gen")
					return list("shrink" = 0.7,"sx" = -2,"sy" = 4,"nx" = 0,"ny" = 6,"wx" = 3,"wy" = 3,"ex" = -9,"ey" = 5,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 180,"sturn" = 4,"wturn" = -105,"eturn" = 283,"nflip" = 1,"sflip" = 0,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.85,"sx" = 7,"sy" = 1,"nx" = -15,"ny" = 4,"wx" = 6,"wy" = -1,"ex" = 5,"ey" = 2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = -183,"sturn" = 11,"wturn" = 33,"eturn" = -10,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.5,"sx" = -8,"sy" = -3,"nx" = 8,"ny" = -3,"wx" = -5,"wy" = -2,"ex" = 2,"ey" = -6,"northabove" = 1,"southabove" = 0,"eastabove" = 1,"westabove" = 0,"nturn" = 90,"sturn" = 90,"wturn" = 90,"eturn" = 90,"nflip" = 0,"sflip" = 1,"wflip" = 1,"eflip" = 0)
				if("wielded")
					return list("shrink" = 0.65,"sx" = 4,"sy" = 2,"nx" = -8,"ny" = 2,"wx" = 8,"wy" = -1,"ex" = 6,"ey" = 3,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 1,"nturn" = 171,"sturn" = 4,"wturn" = 24,"eturn" = -4,"nflip" = 1,"sflip" = 0,"wflip" = 0,"eflip" = 0)
