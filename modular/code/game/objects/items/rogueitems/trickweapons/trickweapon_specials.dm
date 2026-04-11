// ====================================================================
// TRICK WEAPON SPECIALS - Bloodborne-faithful weapon arts
// ====================================================================
// Each special is designed around the weapon's most iconic attack from
// its Bloodborne moveset. Specials use the /datum/special_intent API
// and are assigned to trick weapons via base_special/transformed_special.
// ====================================================================

// ====================================================================
// PRESSURED — Trick weapon combo debuff
// ====================================================================
// A weaker alternative to Exposed, exclusive to trick weapon specials.
// Exposed fully disables parry and dodge — Pressured gives a 50%
// chance to fail those checks instead. This keeps Exposed reserved
// for feint and generic weapon specials while giving trick weapons
// their own combo ecosystem.
// ====================================================================
/atom/movable/screen/alert/status_effect/debuff/pressured
	name = "Pressured"
	desc = "I'm under heavy pressure! My defenses are unreliable."
	icon_state = "exposed"

/datum/status_effect/debuff/pressured
	id = "pressured"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/pressured
	duration = 5 SECONDS
	mob_effect_icon = 'icons/mob/mob_effects.dmi'
	mob_effect_icon_state = "eff_exposed"
	mob_effect_layer = MOB_EFFECT_LAYER_EXPOSED

/datum/status_effect/debuff/pressured/on_creation(mob/living/new_owner, new_dur)
	if(new_dur)
		duration = new_dur
	return ..()

// =====================================================================
// SAW CLEAVER — "Transformation Rend"
// The saw cleaver's iconic L1 transformation combo: a vicious serrated
// rending slash that tears into beasts. Fast, aggressive, forward.
// =====================================================================
/datum/special_intent/saw_cleaver_rend
	name = "Transformation Rend"
	desc = "A vicious serrated slash forward, tearing through flesh. Fast and brutal."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/sawcleaver/saw_special.ogg'
	delay = 0.5 SECONDS
	cooldown = 15 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/saw_cleaver_rend/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/saw_cleaver_rend/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// KIRKHAMMER — "Hammer Quake"
// The Kirkhammer's transformed mode produces shockwaves on every hit.
// Its charged R2 is a devastating 2.30x overhead with Massive impact.
// This special recreates the ground-shaking AoE hammer slam.
// =====================================================================
/datum/special_intent/kirkhammer_quake
	name = "Hammer Quake"
	desc = "Slams the massive hammer into the ground, sending a shockwave radiating outward. Knocks foes off-balance."
	tile_coordinates = list(
		list(0,0),
		list(1,0, 0.15 SECONDS), list(-1,0, 0.15 SECONDS), list(0,1, 0.15 SECONDS), list(0,-1, 0.15 SECONDS),
		list(1,1, 0.3 SECONDS), list(-1,1, 0.3 SECONDS), list(1,-1, 0.3 SECONDS), list(-1,-1, 0.3 SECONDS)
		)
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	respect_adjacency = TRUE
	delay = 1 SECONDS
	cooldown = 25 SECONDS
	stamcost = 25
	var/dam
	var/self_immob = 1.2 SECONDS

/datum/special_intent/kirkhammer_quake/on_create()
	. = ..()
	howner.Immobilize(self_immob)
	playsound(howner, 'modular/sounds/trickweapons/kirkhammer/hammer_swing.ogg', 100, TRUE)

/datum/special_intent/kirkhammer_quake/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5) + 40
	. = ..()

/datum/special_intent/kirkhammer_quake/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			if(L.IsOffBalanced())
				L.Knockdown(2 SECONDS)
			else
				L.OffBalance(4 SECONDS)
			L.Slowdown(3)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
	var/sfx = pick('modular/sounds/trickweapons/kirkhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/kirkhammer/hammer_hit2.ogg')
	playsound(T, sfx, 100, TRUE)
	..()

// =====================================================================
// THREADED CANE — "Whip Sweep"
// In transformed whip mode, the Threaded Cane has deceptive range and
// excels at counter-hits. The backstep R2 has amazing range. This
// special is a wide-arc whip lash at range, catching multiple foes.
// =====================================================================
/datum/special_intent/threaded_cane_sweep
	name = "Whip Sweep"
	desc = "Lashes the whip in a wide arc at range, catching anyone in the sweep. Slows and exposes struck targets."
	tile_coordinates = list(list(-1,0), list(0,0), list(1,0))
	post_icon_state = "strike"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/threadedcane/whip_swing1.ogg'
	respect_adjacency = FALSE
	use_clickloc = TRUE
	delay = 0.4 SECONDS
	cooldown = 17 SECONDS
	range = 3
	stamcost = 20
	var/dam

/datum/special_intent/threaded_cane_sweep/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/threaded_cane_sweep/apply_hit(turf/T)
	var/whiffed = TRUE
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Slowdown(4)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 5 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_LASHING)
			whiffed = FALSE
	if(!whiffed)
		playsound(T, 'modular/sounds/trickweapons/threadedcane/whip_hit.ogg', 100, TRUE)
	else
		playsound(T, 'modular/sounds/trickweapons/threadedcane/whip_crack1.ogg', 100, TRUE)
	..()

// =====================================================================
// HUNTER AXE — "Rally Spin"
// The Hunter Axe's transformed L2 is its most iconic attack: a massive
// 360-degree spinning sweep. In-game it has great rally potential
// and is the quintessential crowd-control move for strength builds.
// =====================================================================
/datum/special_intent/hunter_axe_spin
	name = "Rally Spin"
	desc = "Spins the extended axe in a full circle, striking everything around you. Knocks lighter foes aside."
	tile_coordinates = list(list(0,0), list(1,0), list(1,-1), list(1,-2), list(0,-2), list(-1,-2), list(-1,-1), list(-1,0))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/hunteraxe/transform.ogg'
	use_doafter = TRUE
	respect_adjacency = FALSE
	delay = 0.8 SECONDS
	cooldown = 22 SECONDS
	stamcost = 25
	var/dam
	var/self_immob = 0.9 SECONDS

/datum/special_intent/hunter_axe_spin/on_create()
	. = ..()
	howner.Immobilize(self_immob)

/datum/special_intent/hunter_axe_spin/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/hunter_axe_spin/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			L.Slowdown(3)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CHOP)
	var/sfx = pick('modular/sounds/trickweapons/hunteraxe/axe_hit1.ogg', 'modular/sounds/trickweapons/hunteraxe/axe_hit2.ogg')
	playsound(T, sfx, 100, TRUE)
	..()

// =====================================================================
// LUDWIG'S HOLY BLADE — "Holy Greatsword Slam"
// Ludwig's transformed charged R2 (2.20x multiplier, Thrust, Heavy)
// is a devastating overhead with incredible power. The follow-up R2
// (1.56x, Massive) demolishes staggered foes. Blocking stance is
// another unique identity. This special captures the charged R2 power.
// =====================================================================
/datum/special_intent/ludwigs_holy_slam
	name = "Holy Greatsword Slam"
	desc = "Brings the massive greatsword crashing down with tremendous force. Devastating against staggered foes."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "fx_trap_long"
	respect_adjacency = TRUE
	delay = 1.3 SECONDS
	cooldown = 28 SECONDS
	stamcost = 25
	var/dam
	var/self_immob = 1.5 SECONDS

/datum/special_intent/ludwigs_holy_slam/on_create()
	. = ..()
	howner.Immobilize(self_immob)
	playsound(howner, 'modular/sounds/trickweapons/ludwigblade/activate.ogg', 100, TRUE)

/datum/special_intent/ludwigs_holy_slam/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STAPER - 10)) / 10)), 0.5)
	. = ..()

/datum/special_intent/ludwigs_holy_slam/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			var/hitdmg = dam
			if(L.has_status_effect(/datum/status_effect/debuff/pressured))
				hitdmg *= 2
				L.Knockdown(2.5 SECONDS)
				playsound(howner, 'sound/combat/tf2crit.ogg', 100, TRUE)
			else
				L.OffBalance(4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, hitdmg, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	playsound(T, pick('modular/sounds/trickweapons/ludwigblade/greatsword_slash1.ogg', 'modular/sounds/trickweapons/ludwigblade/greatsword_slash2.ogg'), 100, TRUE)
	..()

// =====================================================================
// WHIRLIGIG SAW — "Sawblade Burst"
// The Whirligig's L2 hold is its signature: a sustained grinding loop.
// That bespoke mechanic lives in the intent system. The special is
// instead a short, punishing forward slam — revving the saw to max
// and crashing it down in a wide arc.
// =====================================================================
/datum/special_intent/whirligig_grind
	name = "Sawblade Burst"
	desc = "Revs the saw to maximum speed and slams it forward, shredding everything in a wide arc."
	tile_coordinates = list(list(-1,0), list(0,0), list(1,0), list(0,1))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/whirligigsaw/saw_spin_loop_start.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 22 SECONDS
	stamcost = 25
	var/dam
	var/self_immob = 0.8 SECONDS

/datum/special_intent/whirligig_grind/on_create()
	. = ..()
	howner.Immobilize(self_immob)

/datum/special_intent/whirligig_grind/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/whirligig_grind/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	playsound(T, pick('modular/sounds/trickweapons/whirligigsaw/saw_spin_hit1.ogg', 'modular/sounds/trickweapons/whirligigsaw/saw_spin_hit2.ogg'), 100, TRUE)
	..()

// =====================================================================
// BURIAL BLADE — "Gehrman's Harvest"
// The Burial Blade's transformed charged R2 (1.90x, Heavy) has
// incredible range. Its L2 chain strikes vertically with great super
// armor damage. This wide scythe arc captures its sweeping identity.
// =====================================================================
/datum/special_intent/burial_blade_harvest
	name = "Gehrman's Harvest"
	desc = "Sweeps the scythe in a wide arc, reaping all in its path. A dirge of farewell."
	tile_coordinates = list(
		list(-1,0), list(0,0), list(1,0),
		list(-1,1, 0.2 SECONDS), list(0,1, 0.2 SECONDS), list(1,1, 0.2 SECONDS)
		)
	post_icon_state = "sweep_fx"
	pre_icon_state = "fx_trap_long"
	sfx_pre_delay = 'modular/sounds/trickweapons/burialblade/scythe_swing1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 22 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/burial_blade_harvest/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/burial_blade_harvest/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 5 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	playsound(T, pick('modular/sounds/trickweapons/burialblade/blade_hit1.ogg', 'modular/sounds/trickweapons/burialblade/blade_hit2.ogg'), 100, TRUE)
	..()

// =====================================================================
// BLADES OF MERCY — "Mercy's Flurry"
// The BoM's transformed mode has rapid alternating dual strikes and
// the highest speed in the game. Their L2 combo insertions deal burst
// damage. This special captures the rapid dual-slash aggression.
// =====================================================================
/datum/special_intent/blades_of_mercy_flurry
	name = "Mercy's Flurry"
	desc = "A rapid dash forward with twin blades, striking twice in quick succession. Speed is the weapon of choice."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/bladesofmercy/hit1.ogg'
	respect_adjacency = FALSE
	delay = 0.3 SECONDS
	cooldown = 12 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/blades_of_mercy_flurry/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	var/throwtarget = get_edge_target_turf(howner, howner.dir)
	howner.safe_throw_at(throwtarget, 1, 2, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
	. = ..()

/datum/special_intent/blades_of_mercy_flurry/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
				apply_generic_weapon_damage(L, dam * 0.7, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// =====================================================================
// RAKUYO — "Whirlwind Dance"
// The Rakuyo's transformed L2 is a gorgeous 360-degree double spin
// (0.95+1.00x then 1.05+1.10x), hitting all around the user twice.
// Lady Maria's signature weapon demands elegance and crowd control.
// =====================================================================
/datum/special_intent/rakuyo_whirlwind
	name = "Whirlwind Dance"
	desc = "Spins with dual blades, slashing everything around you twice in an elegant whirlwind."
	tile_coordinates = list(
		list(0,0), list(1,0), list(1,-1), list(1,-2), list(0,-2), list(-1,-2), list(-1,-1), list(-1,0),
		list(0,0, 0.4 SECONDS), list(1,0, 0.4 SECONDS), list(1,-1, 0.4 SECONDS), list(1,-2, 0.4 SECONDS), list(0,-2, 0.4 SECONDS), list(-1,-2, 0.4 SECONDS), list(-1,-1, 0.4 SECONDS), list(-1,0, 0.4 SECONDS)
		)
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/rakuyo/spin.ogg'
	respect_adjacency = FALSE
	delay = 0.4 SECONDS
	cooldown = 20 SECONDS
	stamcost = 25
	var/dam
	var/hitcount = 0

/datum/special_intent/rakuyo_whirlwind/_reset()
	hitcount = initial(hitcount)
	. = ..()

/datum/special_intent/rakuyo_whirlwind/_process_grid(list/turfs, newdelay)
	hitcount++
	. = ..()

/datum/special_intent/rakuyo_whirlwind/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASPD - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/rakuyo_whirlwind/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			var/hitdmg = hitcount >= 2 ? (dam * 1.15) : dam
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, hitdmg, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	playsound(T, pick('modular/sounds/trickweapons/rakuyo/slash1.ogg', 'modular/sounds/trickweapons/rakuyo/slash2.ogg'), 100, TRUE)
	..()

// =====================================================================
// STAKE DRIVER — "Pile Bunker"
// The most iconic attack in all of Bloodborne: the transformed charged
// R2 at 3.55x — an explosive AoE punch that obliterates anything it
// hits. Extremely slow charge, massive risk and reward.
// =====================================================================
/datum/special_intent/stake_driver_explosion
	name = "Pile Bunker"
	desc = "Charges the stake mechanism to its limit, then detonates in a devastating explosion. Extremely slow, extremely deadly."
	tile_coordinates = list(list(0,0), list(1,0), list(-1,0), list(0,1), list(0,-1))
	post_icon_state = "kick_fx"
	pre_icon_state = "fx_trap_long"
	respect_adjacency = TRUE
	delay = 2 SECONDS
	cooldown = 35 SECONDS
	stamcost = 30
	var/dam
	var/self_immob = 2.5 SECONDS
	var/self_expose = 3 SECONDS

/datum/special_intent/stake_driver_explosion/on_create()
	. = ..()
	howner.Immobilize(self_immob)
	howner.apply_status_effect(/datum/status_effect/debuff/exposed, self_expose)
	playsound(howner, 'modular/sounds/trickweapons/stakedriver/combo1.ogg', 100, TRUE)

/datum/special_intent/stake_driver_explosion/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 8)), 0.5) + 60
	. = ..()

/datum/special_intent/stake_driver_explosion/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Knockdown(3 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, rand(2, 4), 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, full_pen = TRUE)
	playsound(T, 'modular/sounds/trickweapons/stakedriver/explosion.ogg', 100, TRUE)
	..()

// =====================================================================
// BOOM HAMMER — "Ignition Slam"
// The Boom Hammer's transformed strike is a fire-infused explosive
// hit. Each transformed attack consumes the buff for one big boom.
// This AoE fire slam captures the explosive identity.
// =====================================================================
/datum/special_intent/boom_hammer_ignition
	name = "Ignition Slam"
	desc = "Slams the ignited hammer down, detonating on impact. Fire radiates outward from the strike."
	tile_coordinates = list(list(0,0), list(1,0), list(-1,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	respect_adjacency = TRUE
	delay = 0.8 SECONDS
	cooldown = 22 SECONDS
	stamcost = 20
	var/dam
	var/self_immob = 1 SECONDS

/datum/special_intent/boom_hammer_ignition/on_create()
	. = ..()
	howner.Immobilize(self_immob)
	playsound(howner, 'modular/sounds/trickweapons/boomhammer/ignite.ogg', 80, TRUE)

/datum/special_intent/boom_hammer_ignition/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5) + 30
	. = ..()

/datum/special_intent/boom_hammer_ignition/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
			L.adjust_fire_stacks(2)
			L.ignite_mob()
	playsound(T, pick('modular/sounds/trickweapons/boomhammer/explosion1.ogg', 'modular/sounds/trickweapons/boomhammer/explosion2.ogg'), 100, TRUE)
	..()

// =====================================================================
// TONITRUS — "Arc Discharge"
// The Tonitrus self-buffs with bolt damage on transform. Its identity
// is a crackling electrical burst. This AoE discharge around the user
// stuns and shocks nearby enemies.
// =====================================================================
/datum/special_intent/tonitrus_discharge
	name = "Arc Discharge"
	desc = "Discharges stored electrical energy in a burst around you. Stuns and staggers nearby foes."
	tile_coordinates = list(list(0,0), list(1,0), list(1,-1), list(1,-2), list(0,-2), list(-1,-2), list(-1,-1), list(-1,0))
	post_icon_state = "strike"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/tonitrus/electric_buff.ogg'
	respect_adjacency = FALSE
	delay = 0.5 SECONDS
	cooldown = 20 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/tonitrus_discharge/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/tonitrus_discharge/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Stun(1.5 SECONDS)
			L.Slowdown(4)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
	playsound(T, pick('modular/sounds/trickweapons/tonitrus/mace_hit1.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit2.ogg', 'modular/sounds/trickweapons/tonitrus/mace_hit3.ogg'), 100, TRUE)
	..()

// =====================================================================
// LOGARIUS WHEEL — "Wheel Grind"
// The Logarius Wheel's transformed mode involves wild spinning multi-
// hit attacks. The R1 chain grinds the wheel with escalating damage.
// This multi-hit spin captures the grinding madness of the wheel.
// =====================================================================
/datum/special_intent/logarius_wheel_grind
	name = "Wheel Grind"
	desc = "Spins the accursed wheel wildly, grinding into everything nearby. Each revolution strikes harder."
	tile_coordinates = list(
		list(0,0), list(1,0), list(1,-1), list(1,-2), list(0,-2), list(-1,-2), list(-1,-1), list(-1,0),
		list(0,0, 0.5 SECONDS), list(1,0, 0.5 SECONDS), list(1,-1, 0.5 SECONDS), list(1,-2, 0.5 SECONDS), list(0,-2, 0.5 SECONDS), list(-1,-2, 0.5 SECONDS), list(-1,-1, 0.5 SECONDS), list(-1,0, 0.5 SECONDS)
		)
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/logariuswheel/spin.ogg'
	use_doafter = TRUE
	respect_adjacency = FALSE
	delay = 0.6 SECONDS
	cooldown = 25 SECONDS
	stamcost = 25
	var/dam
	var/hitcount = 0

/datum/special_intent/logarius_wheel_grind/_reset()
	hitcount = initial(hitcount)
	. = ..()

/datum/special_intent/logarius_wheel_grind/_process_grid(list/turfs, newdelay)
	hitcount++
	. = ..()

/datum/special_intent/logarius_wheel_grind/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/logarius_wheel_grind/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			var/hitdmg = hitcount >= 2 ? (dam * 1.4) : dam
			L.OffBalance(3 SECONDS)
			L.Slowdown(2)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, hitdmg, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
	playsound(T, pick('modular/sounds/trickweapons/logariuswheel/slam.ogg', 'modular/sounds/trickweapons/logariuswheel/land.ogg'), 100, TRUE)
	..()

// =====================================================================
// CHIKAGE — "Blood Rend"
// The Chikage's transformed mode drains the wielder's HP for increased
// blood damage. Its charged R2 is devastating. This lunging blood
// slash costs HP but deals vicious damage.
// =====================================================================
/datum/special_intent/chikage_blood_rend
	name = "Blood Rend"
	desc = "Draws upon your own blood to fuel a devastating lunging slash. Costs health, but the damage is immense."
	tile_coordinates = list(list(0,0), list(0,1), list(0,2))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 22 SECONDS
	stamcost = 20
	var/dam
	var/hp_cost = 15

/datum/special_intent/chikage_blood_rend/on_create()
	. = ..()
	howner.adjustBruteLoss(hp_cost)
	to_chat(howner, span_danger("The blood blade bites into your hand!"))

/datum/special_intent/chikage_blood_rend/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 8)), 0.5) + 30
	. = ..()

/datum/special_intent/chikage_blood_rend/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT, full_pen = TRUE)
	..()

// =====================================================================
// BLOODLETTER — "Blood Eruption"
// On transformation, the wielder impales themselves, spraying blood.
// The L2 is an AoE blood explosion. This costly AoE captures
// the self-destructive nature of the Bloodletter.
// =====================================================================
/datum/special_intent/bloodletter_eruption
	name = "Blood Eruption"
	desc = "Drives the weapon into your own flesh, releasing an explosion of blood that ravages everything around you."
	tile_coordinates = list(list(0,0), list(1,0), list(1,-1), list(1,-2), list(0,-2), list(-1,-2), list(-1,-1), list(-1,0))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	respect_adjacency = FALSE
	delay = 0.7 SECONDS
	cooldown = 25 SECONDS
	stamcost = 20
	var/dam
	var/hp_cost = 20

/datum/special_intent/bloodletter_eruption/on_create()
	. = ..()
	howner.adjustBruteLoss(hp_cost)
	to_chat(howner, span_danger("Blood erupts from your body!"))
	playsound(howner, pick('modular/sounds/trickweapons/bloodletter/blood_combo1.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo2.ogg', 'modular/sounds/trickweapons/bloodletter/blood_combo3.ogg'), 100, TRUE)

/datum/special_intent/bloodletter_eruption/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 8)), 0.5) + 40
	. = ..()

/datum/special_intent/bloodletter_eruption/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Slowdown(4)
			L.OffBalance(3 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 2, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT, no_pen = TRUE)
	..()

// =====================================================================
// AMYGDALAN ARM — "Eldritch Smash"
// The transformed Amygdalan Arm has extreme range (reach 2) and
// overhead slams. This long forward line captures its tentacle
// whip identity with heavy knockdown.
// =====================================================================
/datum/special_intent/amygdalan_smash
	name = "Eldritch Smash"
	desc = "Whips the distended arm forward in a long overhead slam. Extended reach with devastating impact."
	tile_coordinates = list(list(0,0), list(0,1), list(0,2))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/amygdalanarm/flesh_impact1.ogg'
	respect_adjacency = TRUE
	delay = 0.8 SECONDS
	cooldown = 22 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/amygdalan_smash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5) + 20
	. = ..()

/datum/special_intent/amygdalan_smash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			if(L.IsOffBalanced())
				L.Knockdown(2 SECONDS)
			else
				L.OffBalance(4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// CHURCH PICK — "Impaling Thrust"
// All transformed mode attacks are Thrust type. The charged R2 follow-
// up (2.10x, Massive) is the strongest single hit. The Church Pick
// also has a hidden 20% beasthunter bonus on thrusts. This deep
// penetrating thrust captures that righteous impaling identity.
// =====================================================================
/datum/special_intent/church_pick_impale
	name = "Impaling Thrust"
	desc = "Drives the pick deep into the target with a righteous thrust. Pierces through armor with holy fury."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/churchpick/pick_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.7 SECONDS
	cooldown = 20 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/church_pick_impale/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.5) + 20
	. = ..()

/datum/special_intent/church_pick_impale/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 5 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB, full_pen = TRUE)
	..()

// =====================================================================
// HUNTER SAIF — "Closing Dash"
// The Hunter Saif's base mode R1 chain has a unique gap-closing lunge.
// Its closing attacks are its identity — charging forward into enemies.
// This dash+slash captures that aggressive forward pressure.
// =====================================================================
/datum/special_intent/hunter_saif_dash
	name = "Closing Dash"
	desc = "Lunges forward with a cleaving slash, closing the distance instantly. Aggressive and relentless."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/huntersaif/slash_hit1.ogg'
	respect_adjacency = FALSE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/hunter_saif_dash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASPD - 10) / 10)), 0.3)
	var/throwtarget = get_edge_target_turf(howner, howner.dir)
	howner.safe_throw_at(throwtarget, 2, 2, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
	. = ..()

/datum/special_intent/hunter_saif_dash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Slowdown(3)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// SIMON'S BOWBLADE — "Precision Shot"
// In transformed mode, Simon's Bowblade becomes a bow. The R2 charged
// shot has extreme range and precision. This single-target ranged
// special captures the sniper-bow identity.
// =====================================================================
/datum/special_intent/simons_bowblade_shot
	name = "Precision Shot"
	desc = "Draws the bow and fires a precise arrow at the target. Extreme range, pierces armor."
	tile_coordinates = list(list(0,0))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/simonsbowblade/bow_draw1.ogg'
	respect_adjacency = FALSE
	use_clickloc = TRUE
	delay = 0.8 SECONDS
	cooldown = 18 SECONDS
	range = 5
	stamcost = 20
	var/dam

/datum/special_intent/simons_bowblade_shot/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STAPER - 10) / 8)), 0.5) + 20
	. = ..()

/datum/special_intent/simons_bowblade_shot/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Slowdown(4)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB, full_pen = TRUE)
	..()

// =====================================================================
// BEAST CUTTER — "Chain Lash"
// The Beast Cutter's transformed whip mode has heavy, wide sweeps
// with good range. This wide ranged sweep captures the heavy chain
// whip identity, heavier than the Threaded Cane's whip.
// =====================================================================
/datum/special_intent/beast_cutter_lash
	name = "Chain Lash"
	desc = "Lashes the heavy chain whip in a brutal wide sweep, battering anyone caught in its arc."
	tile_coordinates = list(list(-1,0), list(0,0), list(1,0))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/beastcutter/whip_crack1.ogg'
	respect_adjacency = FALSE
	use_clickloc = TRUE
	delay = 0.5 SECONDS
	cooldown = 18 SECONDS
	range = 2
	stamcost = 20
	var/dam

/datum/special_intent/beast_cutter_lash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/beast_cutter_lash/apply_hit(turf/T)
	var/whiffed = TRUE
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			L.Slowdown(3)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_LASHING)
			whiffed = FALSE
	if(!whiffed)
		playsound(T, 'modular/sounds/trickweapons/beastcutter/whip_land.ogg', 100, TRUE)
	else
		playsound(T, 'modular/sounds/trickweapons/beastcutter/whip_crack2.ogg', 100, TRUE)
	..()

// =====================================================================
// RIFLE SPEAR — "Rifle Blast"
// The Rifle Spear has a built-in rifle that fires in a line. Its L2
// is a gunshot blast. This forward line of piercing damage captures
// the hybrid gun-spear identity.
// =====================================================================
/datum/special_intent/rifle_spear_blast
	name = "Rifle Blast"
	desc = "Fires the built-in rifle, sending a blast forward in a line. Pierces through armor at range."
	tile_coordinates = list(list(0,0), list(0,1), list(0,2))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/riflespear/musket_shot1.ogg'
	respect_adjacency = FALSE
	delay = 0.5 SECONDS
	cooldown = 20 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/rifle_spear_blast/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STAPER - 10) / 10)), 0.3) + 15
	. = ..()

/datum/special_intent/rifle_spear_blast/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB, full_pen = TRUE)
	playsound(T, 'modular/sounds/trickweapons/riflespear/musket_shot2.ogg', 100, TRUE)
	..()

// =====================================================================
// REITERPALLASCH — "Fencing Riposte"
// The Reiterpallasch is a rapier with a built-in pistol. Its identity
// is precision counter-attacks and fencing ripostes. This quick thrust
// deals bonus damage to exposed/staggered targets.
// =====================================================================
/datum/special_intent/reiterpallasch_riposte
	name = "Fencing Riposte"
	desc = "A swift, precise counter-thrust. Devastates exposed foes with surgical precision."
	tile_coordinates = list(list(0,0))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/reiterpallasch/transform1.ogg'
	respect_adjacency = TRUE
	delay = 0.3 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/reiterpallasch_riposte/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/reiterpallasch_riposte/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			var/hitdmg = dam
			if(L.has_status_effect(/datum/status_effect/debuff/pressured))
				hitdmg *= 2.5
				L.Knockdown(1.5 SECONDS)
				playsound(howner, 'sound/combat/tf2crit.ogg', 100, TRUE)
			else
				L.apply_status_effect(/datum/status_effect/debuff/pressured, 3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, hitdmg, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB, full_pen = TRUE)
	..()

// =====================================================================
// BEAST CLAWS — "Savage Rush"
// The Beast Claws have rapid dual claw attacks. In transformed mode,
// the wielder becomes more bestial with wild, rapid slashing rushes.
// This forward charging multi-claw attack captures that feral identity.
// =====================================================================
/datum/special_intent/beast_claws_rush
	name = "Savage Rush"
	desc = "Charges forward in a feral frenzy, raking claws through anything in your path."
	tile_coordinates = list(list(0,0), list(0,1), list(0,2))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/beastclaws/claw_hit1.ogg'
	respect_adjacency = FALSE
	delay = 0.3 SECONDS
	cooldown = 15 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/beast_claws_rush/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASPD - 10) / 10)), 0.3)
	var/throwtarget = get_edge_target_turf(howner, howner.dir)
	howner.safe_throw_at(throwtarget, 2, 3, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
	. = ..()

/datum/special_intent/beast_claws_rush/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
				apply_generic_weapon_damage(L, dam * 0.6, "slash", pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM), bclass = BCLASS_CUT)
	..()

// =====================================================================
// KOS PARASITE — "Eldritch Burst"
// The Kos Parasite, when used with the Milkweed rune, produces
// arcane tentacle explosions. Its L2 is a devastating AoE burst.
// This ring of eldritch energy captures the cosmic horror identity.
// =====================================================================
/datum/special_intent/kos_parasite_burst
	name = "Eldritch Burst"
	desc = "Channels the parasite's alien power, releasing a pulsating ring of eldritch energy."
	tile_coordinates = list(list(0,0), list(1,0), list(1,-1), list(1,-2), list(0,-2), list(-1,-2), list(-1,-1), list(-1,0))
	post_icon_state = "strike"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/kosparasite/parasite_attack.ogg'
	respect_adjacency = FALSE
	delay = 0.6 SECONDS
	cooldown = 22 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/kos_parasite_burst/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STAPER - 10) / 8)), 0.3) + 20
	. = ..()

/datum/special_intent/kos_parasite_burst/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Slowdown(4)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
	playsound(T, 'modular/sounds/trickweapons/kosparasite/kosexplode.ogg', 100, TRUE)
	..()

// =====================================================================
// HOLY COMET SWORD — "Moonlight Wave"
// A custom weapon in this codebase, always two-handed. Its intents
// already fire beam, cross-slash, and burst AoE on charged afterattack.
// The special is a forward crescent wave — distinct from all three.
// =====================================================================
/datum/special_intent/holy_comet_nova
	name = "Moonlight Wave"
	desc = "Swings the blade overhead, releasing a crescent wave of moonlight energy that crashes forward."
	tile_coordinates = list(
		list(-1,0), list(0,0), list(1,0),
		list(-1,1, 0.2 SECONDS), list(0,1, 0.2 SECONDS), list(1,1, 0.2 SECONDS)
		)
	post_icon_state = "sweep_fx"
	pre_icon_state = "fx_trap_long"
	sfx_pre_delay = 'modular/sounds/trickweapons/holycomet/activate.ogg'
	respect_adjacency = FALSE
	delay = 0.8 SECONDS
	cooldown = 28 SECONDS
	stamcost = 25
	var/dam
	var/self_immob = 1 SECONDS

/datum/special_intent/holy_comet_nova/on_create()
	. = ..()
	howner.Immobilize(self_immob)

/datum/special_intent/holy_comet_nova/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STAPER - 10)) / 10)), 0.5)
	. = ..()

/datum/special_intent/holy_comet_nova/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			L.Slowdown(3)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 2, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
	playsound(T, 'modular/sounds/trickweapons/holycomet/moonlight_hit.ogg', 100, TRUE)
	..()

// =====================================================================
// SAW SPEAR — "Serrated Thrust"
// The Saw Spear's transformed mode is a serrated spear with reach 2.
// Serrated on both forms. Its quick thrusting attacks with serrated
// bonus define it. A reaching serrated poke with expose.
// =====================================================================
/datum/special_intent/saw_spear_thrust
	name = "Serrated Thrust"
	desc = "Thrusts the serrated spear forward with reach, tearing into the target. Exposes them."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/sawspear/spear_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/saw_spear_thrust/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STASPD - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/saw_spear_thrust/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 5 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// ====================================================================
// BASE FORM SPECIALS — Untransformed weapon arts
// ====================================================================
// Base-form specials are precision/power-focused attacks for 1v1
// combat. They complement the transformed specials' crowd-control
// identity by offering surgical, high-damage options in duels.
// ====================================================================

// =====================================================================
// SAW CLEAVER (base) — "Serrated Charge"
// Base form charged R2 (1.90x in BB) is a powerful overhead saw
// strike. Slower wind-up for higher damage than the transformed
// special, with a balance-breaking impact.
// =====================================================================
/datum/special_intent/saw_cleaver_charge
	name = "Serrated Charge"
	desc = "Winds up a vicious overhead saw strike, breaking through the target's guard."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/sawcleaver/cleaver_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.7 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/saw_cleaver_charge/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/saw_cleaver_charge/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// KIRKHAMMER (base) — "Silver Thrust"
// Base mode is a nimble silver sword. R2 is a 1.0x Thrust with full
// AR. The charged R2 (1.20x, Heavy) is a lunging precision thrust.
// Fast and surgical, contrasting the transformed hammer's brutality.
// =====================================================================
/datum/special_intent/kirkhammer_thrust
	name = "Silver Thrust"
	desc = "A precise lunging thrust with the silver sword. Fast and piercing."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/kirkhammer/sword_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/kirkhammer_thrust/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/kirkhammer_thrust/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// =====================================================================
// THREADED CANE (base) — "Cane Impale"
// Base mode charged R2 (1.90x Thrust) is one of BB's highest single-
// hit multipliers. A devastating cane thrust that punishes exposed
// targets with bonus damage.
// =====================================================================
/datum/special_intent/threaded_cane_impale
	name = "Cane Impale"
	desc = "Drives the rigid cane forward in a devastating thrust. Exposed foes suffer greatly."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/generic/swing_stab_charge.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 16 SECONDS
	stamcost = 16
	var/dam

/datum/special_intent/threaded_cane_impale/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/threaded_cane_impale/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			var/hitdmg = dam
			if(L.has_status_effect(/datum/status_effect/debuff/pressured))
				hitdmg *= 1.8
				playsound(howner, 'sound/combat/tf2crit.ogg', 100, TRUE)
			else
				L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, hitdmg, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// =====================================================================
// HUNTER AXE (base) — "Overhead Cleave"
// Base mode one-handed axe. The charged R2 is a heavy overhead chop.
// A focused forward cleave that breaks guard — the huntsman's bread
// and butter before extending the axe for crowd work.
// =====================================================================
/datum/special_intent/hunter_axe_cleave
	name = "Overhead Cleave"
	desc = "Brings the axe down in a focused overhead cleave. Staggers the target."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/hunteraxe/axe_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/hunter_axe_cleave/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/hunter_axe_cleave/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			if(L.IsOffBalanced())
				L.Knockdown(2 SECONDS)
			else
				L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "chop", BODY_ZONE_CHEST, bclass = BCLASS_CHOP)
	..()

// =====================================================================
// LUDWIG'S HOLY BLADE (base) — "Silver Flash"
// Nearly identical base moveset to Kirkhammer (silver sword). R2 is
// 1.0x Thrust. Quick dashing R2 lunge. A fast thrust that contrasts
// the transformed greatsword's crushing overhead.
// =====================================================================
/datum/special_intent/ludwigs_silver_flash
	name = "Silver Flash"
	desc = "A swift lunging thrust with the holy silver sword. Quick and precise."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/ludwigblade/sword_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/ludwigs_silver_flash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/ludwigs_silver_flash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// =====================================================================
// WHIRLIGIG SAW (base) — "Mace Crash"
// Base mode is a mace with blunt attacks. Forward leap R2 (1.20x,
// Heavy impact). A focused overhead mace slam contrasting the
// transformed mode's wide sawblade burst.
// =====================================================================
/datum/special_intent/whirligig_crash
	name = "Mace Crash"
	desc = "Smashes the mace down in a heavy overhead blow. Breaks the target's balance."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/whirligigsaw/saw_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/whirligig_crash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/whirligig_crash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// BURIAL BLADE (base) — "Reaper's Mark"
// Base curved blade mode. Quick curved slashes, thrusts, overhead
// chop. A swift forward curved slash that marks the target — smaller
// and faster than the transformed scythe's wide harvest sweep.
// =====================================================================
/datum/special_intent/burial_blade_mark
	name = "Reaper's Mark"
	desc = "Tags the target with a swift curved slash, marking them for the reaper."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/burialblade/blade_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/burial_blade_mark/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/burial_blade_mark/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 5 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// BLADES OF MERCY (base) — "Quicksilver Slash"
// Base mode is a single short blade. The fastest weapon in BB. Quick
// horizontal slashes and reverse grip attacks. A single surgical
// strike that punishes exposed targets — precision over the
// transformed mode's frenzied dual-blade flurry.
// =====================================================================
/datum/special_intent/blades_of_mercy_quick
	name = "Quicksilver Slash"
	desc = "A blindingly fast slash with the single blade. Devastates exposed targets."
	tile_coordinates = list(list(0,0))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/bladesofmercy/flash1.ogg'
	respect_adjacency = TRUE
	delay = 0.2 SECONDS
	cooldown = 10 SECONDS
	stamcost = 12
	var/dam

/datum/special_intent/blades_of_mercy_quick/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASPD - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/blades_of_mercy_quick/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			var/hitdmg = dam
			if(L.has_status_effect(/datum/status_effect/debuff/pressured))
				hitdmg *= 2
				playsound(howner, 'sound/combat/tf2crit.ogg', 100, TRUE)
			else
				L.apply_status_effect(/datum/status_effect/debuff/pressured, 3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, hitdmg, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// RAKUYO (base) — "Noble Lunge"
// Base mode saber. The fully charged R2 (1.70x Thrust, Heavy) has
// amazing forward momentum and reach. A precise lunging thrust
// contrasting the transformed dual-wielding whirlwind.
// =====================================================================
/datum/special_intent/rakuyo_lunge
	name = "Noble Lunge"
	desc = "Lunges forward with a precise thrust of the saber. Elegant and deadly."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/rakuyo/slash1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/rakuyo_lunge/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASPD - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/rakuyo_lunge/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// =====================================================================
// STAKE DRIVER (base) — "Piston Strike"
// Base mode is a short blade/fist weapon. Quick slashes, uppercuts,
// forward jabs. The piston mechanism gives punchy impacts. A focused
// compact punch — contrasting the transformed mode's massive
// charged explosion.
// =====================================================================
/datum/special_intent/stake_driver_piston
	name = "Piston Strike"
	desc = "Fires the piston mechanism in a focused punch. Compact, brutal, and disorienting."
	tile_coordinates = list(list(0,0))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/stakedriver/combo1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 16
	var/dam

/datum/special_intent/stake_driver_piston/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STASPD - 10)) / 10)), 0.5)
	. = ..()

/datum/special_intent/stake_driver_piston/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	playsound(T, pick('modular/sounds/trickweapons/stakedriver/punch1.ogg', 'modular/sounds/trickweapons/stakedriver/punch2.ogg', 'modular/sounds/trickweapons/stakedriver/punch3.ogg'), 100, TRUE)
	..()

// =====================================================================
// BOOM HAMMER (base) — "Hammer Strike"
// Base mode is a standard hammer without ignition. Horizontal swipes
// and overhead slams. Pure blunt force without fire, contrasting
// the transformed mode's explosive AoE ignition slam.
// =====================================================================
/datum/special_intent/boom_hammer_strike
	name = "Hammer Strike"
	desc = "A heavy overhead hammer blow without the flames. Pure blunt force."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/boom_hammer_strike/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/boom_hammer_strike/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	playsound(T, pick('modular/sounds/trickweapons/boomhammer/hammer_hit1.ogg', 'modular/sounds/trickweapons/boomhammer/hammer_hit2.ogg'), 100, TRUE)
	..()

// =====================================================================
// TONITRUS (base) — "Focused Strike"
// Base mode is a mace without the bolt buff. Standard strikes,
// overhead, jab. A precise measured bludgeon hit that slows —
// no electrical theatrics yet, contrasting the transformed AoE
// arc discharge.
// =====================================================================
/datum/special_intent/tonitrus_strike
	name = "Focused Strike"
	desc = "A precise, measured blow with the mace. Stalls the target."
	tile_coordinates = list(list(0,0))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/tonitrus/mace_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 14
	var/dam

/datum/special_intent/tonitrus_strike/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/tonitrus_strike/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.Slowdown(4)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// LOGARIUS WHEEL (base) — "Wheel Crush"
// Base mode is a heavy wheel. Wheel strikes, leap slams, horizontal
// sweeps. The forward leap R2 has Heavy impact. A crushing forward
// slam — methodical and grounded vs the transformed arcane grind.
// =====================================================================
/datum/special_intent/logarius_wheel_crush
	name = "Wheel Crush"
	desc = "Crashes the heavy wheel forward into the target. Staggers and flattens."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/logariuswheel/slam.ogg'
	respect_adjacency = TRUE
	delay = 0.7 SECONDS
	cooldown = 16 SECONDS
	stamcost = 20
	var/dam

/datum/special_intent/logarius_wheel_crush/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/logarius_wheel_crush/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			if(L.IsOffBalanced())
				L.Knockdown(2 SECONDS)
			else
				L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT, no_pen = TRUE)
	..()

// =====================================================================
// CHIKAGE (base) — "Quickdraw"
// Base mode katana. The iconic L1→R1 quickdraw (1.32x Blood) is the
// signature Vileblood move: an iaido flash-draw from the sheath.
// Fast and precise, contrasting the transformed blood rend's HP-cost
// carnage.
// =====================================================================
/datum/special_intent/chikage_quickdraw
	name = "Quickdraw"
	desc = "An iaido flash-draw from the sheath. The blade sings scarlet as it leaves."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_pre_delay = 'modular/sounds/trickweapons/chikage/katana_draw1.ogg'
	sfx_post_delay = 'modular/sounds/trickweapons/chikage/katana_iai_strike1.ogg'
	respect_adjacency = TRUE
	delay = 0.3 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/chikage_quickdraw/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/chikage_quickdraw/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// BLOODLETTER (base) — "Mace Crush"
// Base mode is a heavy mace. Overhand, sweep, thrust, slam.
// Standard bludgeon work — contrasting the transformed mode's
// self-destructive blood explosion.
// =====================================================================
/datum/special_intent/bloodletter_crush
	name = "Mace Crush"
	desc = "Crashes the heavy mace down in a crushing overhand blow."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/bloodletter/blood_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/bloodletter_crush/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/bloodletter_crush/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// AMYGDALAN ARM (base) — "Eldritch Bash"
// Base mode is a short arm club. Jab, sweep, slam. Awkward, compact,
// and alien. A focused bludgeon — clumsy but powerful, contrasting
// the transformed tentacle whip's long-range smash.
// =====================================================================
/datum/special_intent/amygdalan_bash
	name = "Eldritch Bash"
	desc = "Slams the compact alien bone down. Clumsy but effective."
	tile_coordinates = list(list(0,0))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/amygdalanarm/flesh_impact1.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 14 SECONDS
	stamcost = 16
	var/dam

/datum/special_intent/amygdalan_bash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/amygdalan_bash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			if(L.IsOffBalanced())
				L.Knockdown(2 SECONDS)
			else
				L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// CHURCH PICK (base) — "Righteous Sweep"
// Base mode is a large sword (NOT the pick form). Mix of Physical
// and Thrust attacks. The backstep R1 has sweeping arc, great for
// crowds. A wide horizontal slash contrasting the transformed pick's
// focused piercing thrust.
// =====================================================================
/datum/special_intent/church_pick_sweep
	name = "Righteous Sweep"
	desc = "Swings the heavy blade in a wide righteous arc. Purges the unclean."
	tile_coordinates = list(list(-1,0), list(0,0), list(1,0))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/churchpick/slash_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/church_pick_sweep/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STASPD - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/church_pick_sweep/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	playsound(T, pick('modular/sounds/trickweapons/churchpick/slash_hit1.ogg', 'modular/sounds/trickweapons/churchpick/slash_hit2.ogg'), 100, TRUE)
	..()

// =====================================================================
// HUNTER SAIF (base) — "Saif Rend"
// Base mode is the extended cleaver form with overhead and diagonal
// sweeps. In BB the extended Saif lunges forward on each swing.
// A forward rending cleave contrasting the transformed mode's
// gap-closing dash.
// =====================================================================
/datum/special_intent/hunter_saif_rend
	name = "Saif Rend"
	desc = "A powerful forward rending cleave with the extended blade. Vicious and relentless."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/huntersaif/slash_hit2.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 15 SECONDS
	stamcost = 16
	var/dam

/datum/special_intent/hunter_saif_rend/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STASPD - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/hunter_saif_rend/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			L.Slowdown(3)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// SIMON'S BOWBLADE (base) — "Arcing Slash"
// Base mode is a curved sword. Diagonal slashes, thrusts, backswipe.
// A forward curving slash contrasting the transformed bow's
// long-range precision shot.
// =====================================================================
/datum/special_intent/simons_arcing_slash
	name = "Arcing Slash"
	desc = "A sweeping curved slash forward. Quick and graceful."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/simonsbowblade/transform1.ogg'
	respect_adjacency = TRUE
	delay = 0.4 SECONDS
	cooldown = 14 SECONDS
	stamcost = 15
	var/dam

/datum/special_intent/simons_arcing_slash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASPD - 10) + (howner.STAPER - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/simons_arcing_slash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	..()

// =====================================================================
// BEAST CUTTER (base) — "Crushing Blow"
// Base mode is a thick iron cleaver/club. Blunt attacks with the
// charged R2 (1.90x, Heavy) being the standout. A heavy overhead
// contrasting the transformed chain whip's ranged crowd-control.
// =====================================================================
/datum/special_intent/beast_cutter_crush
	name = "Crushing Blow"
	desc = "Brings the thick cleaver crashing down in a devastating overhead. Raw brute force."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/beastcutter/chain1.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/beast_cutter_crush/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/beast_cutter_crush/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			var/throwtarget = get_edge_target_turf(howner, get_dir(howner, get_step_away(L, howner)))
			L.safe_throw_at(throwtarget, 1, 1, howner, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// SAW SPEAR (base) — "Serrated Swipe"
// Base mode is a serrated short sword. Diagonal and horizontal
// slashes. A wide horizontal serrated sweep contrasting the
// transformed spear's focused forward thrust.
// =====================================================================
/datum/special_intent/saw_spear_swipe
	name = "Serrated Swipe"
	desc = "Sweeps the serrated blade in a wide horizontal arc, tearing through nearby targets."
	tile_coordinates = list(list(-1,0), list(0,0), list(1,0))
	post_icon_state = "sweep_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/sawspear/saw_hit1.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 15 SECONDS
	stamcost = 16
	var/dam

/datum/special_intent/saw_spear_swipe/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STASPD - 10)) / 10)), 0.3)
	. = ..()

/datum/special_intent/saw_spear_swipe/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	playsound(T, pick('modular/sounds/trickweapons/sawspear/saw_hit1.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit2.ogg', 'modular/sounds/trickweapons/sawspear/saw_hit3.ogg'), 100, TRUE)
	..()

// =====================================================================
// RIFLE SPEAR (base) — "Impaling Thrust"
// Base mode is a spear with thrusts and sweeps. The charged R2
// (1.90x Thrust, Heavy) is a devastating forward lunge. A deep
// piercing thrust contrasting the transformed rifle blast.
// =====================================================================
/datum/special_intent/rifle_spear_thrust
	name = "Impaling Thrust"
	desc = "Drives the spear forward in a deep, armor-piercing lunge."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/generic/swing_stab_charge.ogg'
	respect_adjacency = TRUE
	delay = 0.6 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/rifle_spear_thrust/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.5)
	. = ..()

/datum/special_intent/rifle_spear_thrust/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB, full_pen = TRUE)
	..()

// =====================================================================
// REITERPALLASCH (base) — "Pistol Shot"
// Base mode rapier has a built-in pistol (L2). A ranged shot that
// exposes the target — setting up the transformed mode's devastating
// close-range fencing riposte.
// =====================================================================
/datum/special_intent/reiterpallasch_shot
	name = "Pistol Shot"
	desc = "Fires the rapier's built-in pistol. Opens the target to follow-up attacks."
	tile_coordinates = list(list(0,0))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/reiterpallasch/shot.ogg'
	respect_adjacency = FALSE
	use_clickloc = TRUE
	delay = 0.3 SECONDS
	cooldown = 16 SECONDS
	range = 3
	stamcost = 14
	var/dam

/datum/special_intent/reiterpallasch_shot/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STAPER - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/reiterpallasch_shot/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 5 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "stab", BODY_ZONE_CHEST, bclass = BCLASS_STAB)
	..()

// =====================================================================
// BEAST CLAWS (base) — "Feral Rake"
// Base mode is a single claw gauntlet. Swipes, punches, overhand
// rakes. A quick double-rip that shreds — compact vs the transformed
// bestial forward rush.
// =====================================================================
/datum/special_intent/beast_claws_rake
	name = "Feral Rake"
	desc = "Rakes the claw through the target twice in rapid succession. Feral and vicious."
	tile_coordinates = list(list(0,0))
	post_icon_state = "stab"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/beastclaws/claw_double.ogg'
	respect_adjacency = TRUE
	delay = 0.2 SECONDS
	cooldown = 12 SECONDS
	stamcost = 14
	var/dam

/datum/special_intent/beast_claws_rake/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASPD - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/beast_claws_rake/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
				apply_generic_weapon_damage(L, dam * 0.6, "slash", pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM), bclass = BCLASS_CUT)
	..()

// =====================================================================
// KOS PARASITE (base) — "Calcified Bash"
// Without the Milkweed rune, base form is an empty shell used as a
// bludgeon. Deliberately modest — reflecting its lore uselessness
// outside arcane builds. Contrasts the transformed eldritch burst.
// =====================================================================
/datum/special_intent/kos_parasite_bash
	name = "Calcified Bash"
	desc = "Clubs the target with the calcified shell. Awkward, but it gets the job done."
	tile_coordinates = list(list(0,0))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/kosparasite/flesh_impact1.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 14 SECONDS
	stamcost = 14
	var/dam

/datum/special_intent/kos_parasite_bash/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + ((howner.STASTR - 10) / 10)), 0.3)
	. = ..()

/datum/special_intent/kos_parasite_bash/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.OffBalance(3 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "blunt", BODY_ZONE_CHEST, bclass = BCLASS_BLUNT)
	..()

// =====================================================================
// HOLY COMET SWORD (base) — "Holy Smite"
// Base mode one-handed holy sword. Horizontal swings and ground
// slams. A focused divine strike that marks the target — a prayer
// before the transformed crescent moonlight wave.
// =====================================================================
/datum/special_intent/holy_comet_smite
	name = "Holy Smite"
	desc = "Brings the holy blade down in a focused divine strike. Marks the target for judgment."
	tile_coordinates = list(list(0,0), list(0,1))
	post_icon_state = "kick_fx"
	pre_icon_state = "trap"
	sfx_post_delay = 'modular/sounds/trickweapons/holycomet/hit.ogg'
	respect_adjacency = TRUE
	delay = 0.5 SECONDS
	cooldown = 16 SECONDS
	stamcost = 18
	var/dam

/datum/special_intent/holy_comet_smite/process_attack()
	var/obj/item/rogueweapon/W = iparent
	dam = W.force_dynamic * max((1 + (((howner.STASTR - 10) + (howner.STAPER - 10)) / 10)), 0.5)
	. = ..()

/datum/special_intent/holy_comet_smite/apply_hit(turf/T)
	for(var/mob/living/L in get_hearers_in_view(0, T))
		if(L != howner)
			L.apply_status_effect(/datum/status_effect/debuff/pressured, 4 SECONDS)
			if(L.mobility_flags & MOBILITY_STAND)
				apply_generic_weapon_damage(L, dam, "slash", BODY_ZONE_CHEST, bclass = BCLASS_CUT)
	playsound(T, 'modular/sounds/trickweapons/holycomet/soul_strike.ogg', 100, TRUE)
	..()
