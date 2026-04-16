// ===================== IMPACT VFX DEFINITIONS =====================
// Temp visual effects spawned on hit by the Impact FX system.
//
// ICON FILES (separate DMIs per effect family):
//   modular/icons/effects/impact_fx.dmi       -- 32x32 small FX (sparks, dust, small splashes)
//   modular/icons/effects/impact_fx_blood.dmi  -- 194x194 blood spatters (from Aseprite exports)
//
// VARIETY SYSTEM:
//   Each subtype has a `variants` list of icon_state names.
//   On spawn, Initialize() picks a random variant from the list.
//   If variants is null/empty, falls back to the default icon_state.
//
// DIRECTION SYSTEM:
//   play_impact_vfx() passes attack direction (attacker->target).
//   Subtypes with `use_attack_dir = TRUE` will face that direction.
//   The DMI states should have 4 directional frames (N/S/E/W) for
//   directional effects. Non-directional effects ignore this.
//
// DMI NAMING CONVENTION:
//   [category]_[N]   e.g. blood_splash_1, blood_splash_2, ...
//   Add/remove entries from the variants lists as you add states to the DMI.
// =================================================================

/obj/effect/temp_visual/impact_fx
	icon = 'modular/icons/effects/impact_fx.dmi'
	icon_state = "blood_splash"
	duration = 4 // 0.4 seconds
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = 0
	pixel_y = 8 // Center on chest area
	/// List of icon_state variant names to randomly pick from on spawn. Null = use default icon_state.
	var/list/variants
	/// If TRUE, Initialize() sets dir from the passed attack direction.
	var/use_attack_dir = FALSE

/obj/effect/temp_visual/impact_fx/Initialize(mapload, attack_dir)
	. = ..()
	if(use_attack_dir && attack_dir)
		setDir(attack_dir)
	if(LAZYLEN(variants))
		icon_state = pick(variants)
	flick(icon_state, src)

// ---- 32x32 FX (impact_fx.dmi) ----

/obj/effect/temp_visual/impact_fx/blood_splash
	icon_state = "blood_splash"
	duration = 5
	variants = list(\
		"blood_splash_1",\
		"blood_splash_2",\
		"blood_splash_3",\
		"blood_splash_4",\
		"blood_splash_5",\
		"blood_splash_6",\
		"blood_splash_7",\
		"blood_splash_8",\
		"blood_splash_9",\
	)

/obj/effect/temp_visual/impact_fx/hit_spark
	icon_state = "hit_spark"
	duration = 3
	variants = list(\
		"hit_spark_1",\
		"hit_spark_2",\
		"hit_spark_3",\
		"hit_spark_4",\
		"hit_spark_5",\
	)

/obj/effect/temp_visual/impact_fx/metal_clang
	icon_state = "metal_clang"
	duration = 4
	variants = list(\
		"metal_clang_1",\
		"metal_clang_2",\
		"metal_clang_3",\
		"metal_clang_4",\
	)

/obj/effect/temp_visual/impact_fx/slash_arc
	icon_state = "slash_arc"
	duration = 3
	use_attack_dir = TRUE
	variants = list(\
		"slash_arc_1",\
		"slash_arc_2",\
		"slash_arc_3",\
		"slash_arc_4",\
		"slash_arc_5",\
		"slash_arc_6",\
	)

/obj/effect/temp_visual/impact_fx/dust_puff
	icon_state = "dust_puff"
	duration = 5
	pixel_y = 0 // Ground level
	variants = list(\
		"dust_puff_1",\
		"dust_puff_2",\
		"dust_puff_3",\
		"dust_puff_4",\
		"dust_puff_5",\
	)

// ---- 194x194 blood spatters (impact_fx_blood.dmi) ----
// Exported from Aseprite at native 194x194 canvas size. All blood states
// (large/medium/small) share the same DMI — visual size differences are
// baked into the art. Size picked by resolve_impact_fx() based on
// combo finisher (large), normal combo hit (medium), or basic attack (small).

/obj/effect/temp_visual/impact_fx/blood_spatter
	icon = 'modular/icons/effects/impact_fx_blood.dmi'
	icon_state = "spatter_medium"
	duration = 7
	pixel_y = 0 // Larger sprites — no chest offset needed
	use_attack_dir = TRUE

/obj/effect/temp_visual/impact_fx/blood_spatter/large
	icon_state = "spatter_large"
	duration = 8

/obj/effect/temp_visual/impact_fx/blood_spatter/medium
	icon_state = "spatter_medium"
	duration = 7

/obj/effect/temp_visual/impact_fx/blood_spatter/small
	icon_state = "spatter_small"
	duration = 5
