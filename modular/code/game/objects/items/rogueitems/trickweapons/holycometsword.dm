// ===================== HOLY COMET SWORD INTENTS =====================

/// Holy Comet Sword base - horizontal swing. R1 combo alternating horizontal slashes.
/datum/intent/holycomet/horizswing
	name = "horizontal swing"
	icon_state = "incut"
	attack_verb = list("slashes", "swings")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/holycomet/hit.ogg', 'modular/sounds/trickweapons/holycomet/swing.ogg')
	chargetime = 0
	penfactor = 15
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Holy Comet Sword base - ground slam. Backstep R1, shortened downward slam.
/datum/intent/holycomet/groundslam
	name = "ground slam"
	icon_state = "inchop"
	attack_verb = list("slams", "pounds")
	animname = "chop"
	blade_class = BCLASS_CHOP
	hitsound = list('modular/sounds/trickweapons/holycomet/hit.ogg', 'modular/sounds/trickweapons/holycomet/swing.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "slash"

/// Holy Comet Sword base - forward thrust. R2 forward lunge.
/datum/intent/holycomet/thrust
	name = "forward thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "lunges")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/holycomet/energy_hit.ogg', 'modular/sounds/trickweapons/holycomet/hit.ogg')
	chargetime = 0
	penfactor = 30
	damfactor = 1.3
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "stab"

/// Holy Comet Sword base - charged thrust. Charged R2 powerful lunge.
/datum/intent/holycomet/chargedthrust
	name = "charged thrust"
	icon_state = "instab"
	attack_verb = list("drives into", "impales")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/holycomet/energy_hit.ogg', 'modular/sounds/trickweapons/holycomet/swing.ogg')
	chargetime = 5
	chargedrain = 1
	penfactor = 45
	damfactor = 1.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "stab"

/// Holy Comet Sword transformed - diagonal swing. R1 alternating diagonal/horizontal arcs.
/// Psycross mode - arcane energy infuses each strike.
/datum/intent/holycomet/diagswing
	name = "diagonal swing"
	icon_state = "incut"
	attack_verb = list("cleaves", "carves")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/holycomet/soul_strike.ogg', 'modular/sounds/trickweapons/holycomet/energy_hit.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "slash"

/// Holy Comet Sword transformed - moonlight sweep. R2 backhand horizontal sweep emitting arcane energy.
/// The signature moonlight wave; high pen represents arcane bypass.
/datum/intent/holycomet/moonlightsweep
	name = "moonlight sweep"
	icon_state = "incrush"
	attack_verb = list("blasts through", "moonlight-sweeps")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/holycomet/activate.ogg', 'modular/sounds/trickweapons/holycomet/soul_strike.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 50
	damfactor = 2.0
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	item_d_type = "slash"

/// Holy Comet Sword transformed - charged moonlight. Charged R2 diagonal sweep with powerful wave.
/datum/intent/holycomet/chargedmoonlight
	name = "charged moonlight"
	icon_state = "incrush"
	attack_verb = list("detonates upon", "moonlight-blasts")
	animname = "cut"
	blade_class = BCLASS_CUT
	hitsound = list('modular/sounds/trickweapons/holycomet/activate.ogg', 'modular/sounds/trickweapons/holycomet/arcane_thrust.ogg')
	chargetime = 6
	chargedrain = 2
	penfactor = 60
	damfactor = 2.8
	clickcd = CLICK_CD_HEAVY
	swingdelay = 10
	no_early_release = TRUE
	misscost = 10
	item_d_type = "slash"

/// Holy Comet Sword transformed - arcane thrust. L2 forward thrust with an arcane flash.
/// Causes knockdown effect in Bloodborne; here represented as high pen + commitment.
/datum/intent/holycomet/arcanethrust
	name = "arcane thrust"
	icon_state = "instab"
	attack_verb = list("pierces with light", "arcane-thrusts")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/holycomet/arcane_thrust.ogg', 'modular/sounds/trickweapons/holycomet/activate.ogg')
	chargetime = 0
	penfactor = 40
	damfactor = 1.5
	clickcd = CLICK_CD_CHARGED
	swingdelay = 6
	item_d_type = "stab"

// ===================== HOLY COMET SWORD =====================
// Base: Greatsword. Heavy 2H cuts, rends, and thrusts.
// Transformed: Psycross. Energy-focused strikes with arcane edge.
// 2H FOCUSED - weak 1H, powerful 2H for both modes.

/obj/item/rogueweapon/trickweapon/holycometsword
	name = "holy comet sword"
	desc = "A greatsword crafted from a fragment of Comet Syon. In its dormant state it serves as a mighty greatsword of surpassing weight. When awakened, the blade splits apart and radiates with pale arcane light, becoming a devastating psycross."
	icon_state = "cometsword"
	item_state = "cometsword"
	icon = 'modular/icons/obj/trickweapons/trickweapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/roguebig_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/roguebig_righthand.dmi'
	force = 14
	force_wielded = 30
	possible_item_intents = list(/datum/intent/holycomet/horizswing, /datum/intent/holycomet/groundslam)
	gripped_intents = list(/datum/intent/holycomet/horizswing, /datum/intent/holycomet/groundslam, /datum/intent/holycomet/thrust, /datum/intent/holycomet/chargedthrust)
	alt_intents = null
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	wlength = WLENGTH_GREAT
	wbalance = WBALANCE_HEAVY
	wdefense = 5
	wdefense_wbonus = 5
	minstr = 12
	max_blade_int = 300
	max_integrity = 300
	sharpness = IS_SHARP
	associated_skill = /datum/skill/combat/swords
	swingsound = BLADEWOOSH_HUGE
	parrysound = list('sound/combat/parry/bladed/bladedlarge (1).ogg', 'sound/combat/parry/bladed/bladedlarge (2).ogg', 'sound/combat/parry/bladed/bladedlarge (3).ogg')
	pickup_sound = 'sound/foley/equip/swordlarge2.ogg'
	transform_sound = 'modular/sounds/trickweapons/holycomet/activate.ogg'
	bigboy = TRUE
	pixel_y = -16
	pixel_x = -16
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	gripsprite = FALSE
	throwforce = 15
	thrown_bclass = BCLASS_CUT
	sellprice = 80
	grid_width = 64
	grid_height = 64
	is_silver = TRUE
	smeltresult = /obj/item/ingot/silver
	// --- Transformed state: Psycross ---
	transformed_name = "holy comet sword"
	transformed_desc = "'Ah... you were at my side all along. My true Lord. My ENDURING comet.' The holy comet sword, now transformed into the psycross. The blade fractures into two prongs of radiant energy, capable of devastating strikes that rend both flesh and spirit."
	transformed_icon_state = "cometsword_t"
	transformed_item_state = "cometsword_t"
	transformed_force = 12 // Even weaker 1H when split open
	transformed_force_wielded = 32 // Slightly stronger 2H than base
	transformed_intents = list(/datum/intent/holycomet/diagswing, /datum/intent/holycomet/arcanethrust)
	transformed_gripped_intents = list(/datum/intent/holycomet/diagswing, /datum/intent/holycomet/moonlightsweep, /datum/intent/holycomet/chargedmoonlight, /datum/intent/holycomet/arcanethrust)
	transformed_swingsound = BLADEWOOSH_HUGE
	transformed_wlength = WLENGTH_GREAT
	transformed_wbalance = WBALANCE_HEAVY
	transformed_wdefense = 4
	transformed_wdefense_wbonus = 5
	transformed_minstr = 12
	transformed_associated_skill = /datum/skill/combat/swords
	transformed_sharpness = IS_SHARP
	transformed_w_class = WEIGHT_CLASS_BULKY
	/// List of spell types granted when transforming into psycross state.
	var/list/psycross_spell_types = list(
		/obj/effect/proc_holder/spell/invoked/projectile/cometbeam,
		/obj/effect/proc_holder/spell/invoked/holy_burst,
		/obj/effect/proc_holder/spell/invoked/psycross_slash
	)

/// Override ComponentInitialize to apply Psydonian blessing by default.
/// The base rogueweapon class would give it a Tennite-type blessing since is_silver = TRUE,
/// but the Holy Comet Sword is inherently blessed by Comet Syon (Psydonian).
/obj/item/rogueweapon/trickweapon/holycometsword/ComponentInitialize()
	AddComponent(\
		/datum/component/silverbless,\
		pre_blessed = BLESSING_PSYDONIAN,\
		silver_type = SILVER_PSYDONIAN,\
		added_force = 0,\
		added_blade_int = 0,\
		added_int = 25,\
		added_def = 2,\
	)

/// Greatsword-style mob render properties for 64x64 sprite visibility.
/obj/item/rogueweapon/trickweapon/holycometsword/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.6,"sx" = -6,"sy" = 6,"nx" = 6,"ny" = 7,"wx" = 0,"wy" = 5,"ex" = -1,"ey" = 7,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = -50,"sturn" = 40,"wturn" = 50,"eturn" = -50,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("wielded")
				return list("shrink" = 0.6,"sx" = 9,"sy" = -4,"nx" = -7,"ny" = 1,"wx" = -9,"wy" = 2,"ex" = 10,"ey" = 2,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 5,"sturn" = -190,"wturn" = -170,"eturn" = -10,"nflip" = 8,"sflip" = 8,"wflip" = 1,"eflip" = 0)
			if("onback")
				return list("shrink" = 0.6,"sx" = -1,"sy" = 2,"nx" = 0,"ny" = 2,"wx" = 2,"wy" = 1,"ex" = 0,"ey" = 1,"nturn" = 0,"sturn" = 0,"wturn" = 70,"eturn" = 15,"nflip" = 1,"sflip" = 1,"wflip" = 1,"eflip" = 1,"northabove" = 1,"southabove" = 0,"eastabove" = 0,"westabove" = 0)

/// Grants psycross spells when transforming into the psycross state.
/obj/item/rogueweapon/trickweapon/holycometsword/apply_transformed_state()
	. = ..()
	var/mob/living/user = loc
	if(!istype(user) || !user.mind)
		return
	for(var/spell_type in psycross_spell_types)
		if(!user.mind.has_spell(spell_type))
			user.mind.AddSpell(new spell_type)

/// Removes psycross spells when reverting to base greatsword state.
/obj/item/rogueweapon/trickweapon/holycometsword/apply_base_state()
	. = ..()
	remove_psycross_spells()

/// Strips psycross spells from the holder's mind, if any.
/obj/item/rogueweapon/trickweapon/holycometsword/proc/remove_psycross_spells()
	var/mob/living/user = loc
	if(!istype(user) || !user.mind)
		return
	for(var/obj/effect/proc_holder/spell/S in user.mind.spell_list)
		if(S.type in psycross_spell_types)
			user.mind.RemoveSpell(S)

/// Cleanup spells if the weapon is dropped while transformed.
/obj/item/rogueweapon/trickweapon/holycometsword/dropped(mob/user)
	if(transformed)
		var/mob/living/L = user
		if(istype(L) && L.mind)
			for(var/obj/effect/proc_holder/spell/S in L.mind.spell_list)
				if(S.type in psycross_spell_types)
					L.mind.RemoveSpell(S)
	return ..()




// ===================== PSYCROSS SPELLS =====================
// Spells granted to the wielder when the Holy Comet Sword is in
// its transformed psycross state. Removed when reverting or dropping.

// ---------- Comet Beam ----------
/// Fires a short-range beam of pale arcane energy from the psycross.
/// Range 4, fully charged before release, moderate cooldown.
/obj/effect/proc_holder/spell/invoked/projectile/cometbeam
	name = "Comet Beam"
	desc = "Channel the radiance of Comet Syon into a searing beam of pale light. Must be fully charged before release."
	clothes_req = FALSE
	range = 4
	projectile_type = /obj/projectile/energy/cometbeam
	overlay_state = "youritem"
	sound = list('sound/magic/churn.ogg')
	active = FALSE
	releasedrain = 30
	chargedrain = 2
	chargetime = 10
	recharge_time = 15 SECONDS
	human_req = TRUE
	warnie = "spellwarning"
	no_early_release = TRUE
	movement_interrupt = FALSE
	charging_slowdown = 3
	chargedloop = /datum/looping_sound/invokegen
	associated_skill = /datum/skill/combat/swords
	invocations = list("")
	invocation_type = "emote"
	cost = 0
	miracle = FALSE
	xp_gain = FALSE

/// Comet beam projectile â€” pale arcane energy, short range, anti-magic blockable.
/// Uses the standard 32x32 divine_blast sprite for reliable trajectory rendering,
/// with the large 64x128 cometbeam sprite attached as a visual-only overlay.
/obj/projectile/energy/cometbeam
	name = "comet beam"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "divine_blast"
	damage = 30
	woundclass = BCLASS_CUT
	nodamage = FALSE
	npc_simple_damage_mult = 1.5
	hitsound = 'sound/magic/churn.ogg'
	speed = 1
	range = 4
	flag = "magic"

/obj/projectile/energy/cometbeam/Initialize()
	. = ..()
	// Attach the large 64x128 cometbeam sprite as a visual overlay.
	// This rides along with the projectile without interfering with
	// the trajectory system's pixel_x/pixel_y animation.
	var/mutable_appearance/beam_overlay = mutable_appearance('modular/icons/obj/trickweapons/effects64x128.dmi', "cometbeam")
	beam_overlay.pixel_x = -16 // center 64px wide on 32px tile
	beam_overlay.pixel_y = -48 // center 128px tall on 32px tile
	beam_overlay.layer = ABOVE_ALL_MOB_LAYER
	add_overlay(beam_overlay)

/obj/projectile/energy/cometbeam/on_hit(target)
	. = ..()
	if(ismob(target))
		var/mob/living/M = target
		if(M.anti_magic_check())
			visible_message(span_warning("[src] dissipates on contact with [target]!"))
			playsound(get_turf(target), 'sound/magic/magic_nulled.ogg', 100)
			qdel(src)
			return BULLET_ACT_BLOCK
		playsound(get_turf(target), 'sound/magic/churn.ogg', 100)

// ---------- Holy Energy Burst ----------
/// AOE burst of holy energy centered on the caster. Damages all adjacent hostiles.
/obj/effect/proc_holder/spell/invoked/holy_burst
	name = "Holy Energy Burst"
	desc = "Release a burst of holy energy from the psycross, searing all nearby foes."
	clothes_req = FALSE
	range = 1
	overlay_state = "youritem"
	sound = list('sound/magic/whiteflame.ogg')
	active = FALSE
	releasedrain = 40
	chargedrain = 2
	chargetime = 8
	recharge_time = 20 SECONDS
	human_req = TRUE
	warnie = "spellwarning"
	no_early_release = TRUE
	movement_interrupt = FALSE
	charging_slowdown = 4
	chargedloop = /datum/looping_sound/invokegen
	associated_skill = /datum/skill/combat/swords
	invocations = list("")
	invocation_type = "emote"
	cost = 0
	miracle = FALSE
	xp_gain = FALSE
	/// Damage dealt to each target in the AOE.
	var/burst_damage = 25
	/// Range of the burst effect in tiles (2 = 5x5 diamond, covers 128x128 sprite area).
	var/burst_range = 2

/obj/effect/proc_holder/spell/invoked/holy_burst/cast(list/targets, mob/user)
	. = ..()
	if(!.)
		return FALSE
	var/turf/center = get_turf(user)
	if(!center)
		return FALSE
	playsound(center, 'sound/magic/whiteflame.ogg', 80, TRUE)
	user.visible_message(span_warning("[user] releases a burst of holy energy!"), span_notice("Holy light erupts from the psycross!"))
	// Spawn the 128x128 AOE visual centered on the caster.
	new /obj/effect/temp_visual/comet_aoe(center)
	for(var/mob/living/M in range(burst_range, center))
		if(M == user)
			continue
		if(M.anti_magic_check())
			to_chat(M, span_warning("The holy energy washes over you harmlessly."))
			continue
		to_chat(M, span_warning("Holy energy sears your flesh!"))
		M.apply_damage(burst_damage, BRUTE, "chest")
		playsound(get_turf(M), 'sound/magic/churn.ogg', 60, TRUE)
	return TRUE

// ---------- Psycross Slash ----------
/// Fires 3 parallel projectiles in the facing direction: a visible center beam
/// carrying the cometslash overlay, and two invisible flanking beams offset
/// 1 tile perpendicular to provide a 3-wide hitbox.
/obj/effect/proc_holder/spell/invoked/psycross_slash
	name = "Psycross Slash"
	desc = "Unleash a wide arc of radiant energy in a line before you, striking all in its path."
	clothes_req = FALSE
	range = 4
	overlay_state = "youritem"
	sound = list('sound/magic/churn.ogg')
	active = FALSE
	releasedrain = 25
	chargedrain = 1
	chargetime = 5
	recharge_time = 12 SECONDS
	human_req = TRUE
	warnie = "spellwarning"
	no_early_release = TRUE
	movement_interrupt = FALSE
	charging_slowdown = 2
	chargedloop = /datum/looping_sound/invokegen
	associated_skill = /datum/skill/combat/swords
	invocations = list("")
	invocation_type = "emote"
	cost = 0
	miracle = FALSE
	xp_gain = FALSE

/obj/effect/proc_holder/spell/invoked/psycross_slash/cast(list/targets, mob/user)
	. = ..()
	if(!.)
		return FALSE
	var/turf/origin = get_turf(user)
	if(!origin)
		return FALSE
	var/dir_facing = user.dir
	playsound(origin, 'sound/magic/churn.ogg', 80, TRUE)
	user.visible_message(span_warning("[user] sweeps the psycross in a wide arc!"), span_notice("Radiant energy lashes outward!"))

	// Determine perpendicular directions for the flanking projectiles.
	var/left_dir
	var/right_dir
	switch(dir_facing)
		if(NORTH, SOUTH)
			left_dir = WEST
			right_dir = EAST
		if(EAST, WEST)
			left_dir = NORTH
			right_dir = SOUTH

	// Calculate a far-forward target turf for aiming all three projectiles.
	var/turf/far_target = origin
	for(var/i in 1 to 4)
		var/turf/next = get_step(far_target, dir_facing)
		if(!next)
			break
		far_target = next

	// --- Center projectile (visible, carries the cometslash overlay) ---
	var/obj/projectile/energy/psycross_slash/center_proj = new(origin)
	center_proj.firer = user
	center_proj.def_zone = user.zone_selected
	center_proj.set_slash_direction(dir_facing)
	center_proj.preparePixelProjectile(far_target, origin)
	center_proj.fire()

	// --- Left flanking projectile (invisible) ---
	var/turf/left_origin = get_step(origin, left_dir)
	if(left_origin)
		var/turf/left_target = get_step(far_target, left_dir)
		if(left_target)
			var/obj/projectile/energy/psycross_slash/flank/left_proj = new(left_origin)
			left_proj.firer = user
			left_proj.def_zone = user.zone_selected
			left_proj.preparePixelProjectile(left_target, left_origin)
			left_proj.fire()

	// --- Right flanking projectile (invisible) ---
	var/turf/right_origin = get_step(origin, right_dir)
	if(right_origin)
		var/turf/right_target = get_step(far_target, right_dir)
		if(right_target)
			var/obj/projectile/energy/psycross_slash/flank/right_proj = new(right_origin)
			right_proj.firer = user
			right_proj.def_zone = user.zone_selected
			right_proj.preparePixelProjectile(right_target, right_origin)
			right_proj.fire()

	return TRUE

// ---------- Psycross Slash Projectiles ----------

/// Center psycross slash projectile â€” visible, carries the 128x64 cometslash overlay.
/// The overlay is rotated to match the travel direction via set_slash_direction().
/obj/projectile/energy/psycross_slash
	name = "psycross slash"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "divine_blast"
	damage = 20
	woundclass = BCLASS_CUT
	nodamage = FALSE
	hitsound = 'sound/magic/churn.ogg'
	speed = 1
	range = 4
	flag = "magic"
	nondirectional_sprite = TRUE // prevent the projectile system from rotating the sprite
	/// Cardinal direction the slash is traveling. Set before fire() to orient the overlay.
	var/slash_dir = NORTH

/// Applies the cometslash overlay rotated to face the given direction.
/// Call this AFTER new() but BEFORE fire().
/// The 128x64 sprite's top-middle edge is treated as the leading edge.
///   NORTH: no rotation (128 wide x 64 tall)
///   SOUTH: 180Â° rotation
///   EAST:  90Â° CW rotation (becomes 64 wide x 128 tall)
///   WEST:  -90Â° rotation (becomes 64 wide x 128 tall)
/obj/projectile/energy/psycross_slash/proc/set_slash_direction(new_dir)
	slash_dir = new_dir
	cut_overlays()
	var/mutable_appearance/slash_overlay = mutable_appearance('modular/icons/obj/trickweapons/effects128x64.dmi', "cometslash")
	slash_overlay.layer = ABOVE_ALL_MOB_LAYER
	switch(slash_dir)
		if(NORTH)
			slash_overlay.pixel_x = -48 // center 128px wide: -(128-32)/2
			slash_overlay.pixel_y = -16 // center 64px tall: -(64-32)/2
		if(SOUTH)
			slash_overlay.pixel_x = -48
			slash_overlay.pixel_y = -16
			var/matrix/M = matrix()
			M.Turn(180)
			slash_overlay.transform = M
		if(EAST)
			slash_overlay.pixel_x = -16 // center 64px (width after rotation)
			slash_overlay.pixel_y = -48 // center 128px (height after rotation)
			var/matrix/M = matrix()
			M.Turn(90)
			slash_overlay.transform = M
		if(WEST)
			slash_overlay.pixel_x = -16
			slash_overlay.pixel_y = -48
			var/matrix/M = matrix()
			M.Turn(-90)
			slash_overlay.transform = M
	add_overlay(slash_overlay)

/obj/projectile/energy/psycross_slash/on_hit(target)
	. = ..()
	if(ismob(target))
		var/mob/living/M = target
		if(M.anti_magic_check())
			visible_message(span_warning("[src] passes through [target] harmlessly!"))
			playsound(get_turf(target), 'sound/magic/magic_nulled.ogg', 100)
			qdel(src)
			return BULLET_ACT_BLOCK
		playsound(get_turf(target), 'sound/magic/churn.ogg', 100)

/// Invisible flanking projectile â€” provides the width for the 3-wide slash hitbox.
/// Has no icon or visual overlay, only deals damage on contact.
/obj/projectile/energy/psycross_slash/flank
	name = "psycross slash"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "divine_blast"
	invisibility = INVISIBILITY_ABSTRACT

/obj/projectile/energy/psycross_slash/flank/Initialize()
	// Skip the parent Initialize overlay attachment â€” this projectile is invisible.
	. = ..()
	cut_overlays()

// --------- Comet Sword Spell Visual Effects ----------

/// 128x128 AOE burst visual centered on caster. Used by Holy Energy Burst.
/obj/effect/temp_visual/comet_aoe
	name = "holy energy burst"
	icon = 'modular/icons/obj/trickweapons/effects128x128.dmi'
	icon_state = "cometaoe"
	pixel_x = -48
	pixel_y = -48
	layer = ABOVE_ALL_MOB_LAYER
	duration = 8
	randomdir = FALSE


