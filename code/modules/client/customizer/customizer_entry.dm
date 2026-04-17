/// Customizer entry representing a saved/loaded information about a /datum/customizer_choice and its related information.
/datum/customizer_entry
	/// Used for identification.
	var/customizer_type
	var/customizer_choice_type
	var/accessory_type
	var/accessory_colors
	var/disabled = FALSE
	// Phase 1 additions — per-entry offset + quantized transform. Defaults
	// are no-ops so pre-Phase-1 saves render identically. Render pipeline
	// wiring is Phase 2.
	var/pixel_x = 0
	var/pixel_y = 0
	var/flip_x = FALSE
	var/flip_y = FALSE
	/// Discrete rotation in degrees. Must be one of FEATURE_ROTATION_CHOICES.
	var/rotation = 0
	/// Discrete scale factor. Must be one of FEATURE_SCALE_CHOICES.
	var/scale = 1

	// --- Phase 2 extreme-offset vetting caches ---
	// Recomputed from pixel_x/pixel_y/scale via recompute_extreme_flags().
	// NOT serialized (regenerated on demand; callers mark dirty on mutation).
	/// cache: recomputed, not serialized
	var/is_hard_extreme = FALSE
	/// cache: recomputed, not serialized
	var/is_soft_extreme = FALSE
	/// cache: recomputed, not serialized
	var/extreme_flags = EXTREME_FLAG_NONE
	/// Bitfield of cardinal dirs where this entry renders visibly when flagged.
	/// Phase 2 sets all four dirs when hard-flagged + whole-entry-enabled; Phase 5
	/// will refine to account for per-dir hide once that schema lands.
	/// cache: recomputed, not serialized
	var/flagged_dirs = 0

	// --- Phase 6 composite sub-entries ---
	// Lazy list of /datum/customizer_sub_entry; cap at MAX_SUB_ENTRIES.
	// sub_entries[1] is the primary; its data mirrors back into the parent's
	// legacy fields (accessory_type, accessory_colors, pixel_*, scale,
	// hair_color on hair subtype) so first-match getters keep working
	// without modification. Sub-entries 2..N render as additional overlays.
	var/list/sub_entries
	/// Migration revision for sub_entries. 0 == unmigrated legacy save.
	/// Bumped to SUB_ENTRIES_MIGRATION_VERSION once wrapped.
	var/migrated_v = 0

/// Recomputes the extreme-offset caches from this entry's transform vars.
/// With Phase 6 composites: when sub_entries is populated, aggregate the
/// cached flags across all non-empty sub-entries instead of (only) reading
/// the parent's mirrored primary values. Safe to call any number of times;
/// pure function of current state.
/datum/customizer_entry/proc/recompute_extreme_flags()
	// Phase 6: if composite, recompute each sub-entry first then aggregate.
	if(LAZYLEN(sub_entries))
		extreme_flags = EXTREME_FLAG_NONE
		flagged_dirs = 0
		for(var/datum/customizer_sub_entry/sub as anything in sub_entries)
			if(!istype(sub))
				continue
			sub.recompute_extreme_flags(accessory_type_override = sub.accessory_type)
			extreme_flags |= sub.extreme_flags
			flagged_dirs |= sub.flagged_dirs
		is_hard_extreme = entry_is_hard_flagged(extreme_flags)
		is_soft_extreme = entry_is_soft_flagged(extreme_flags)
		return

	// Legacy / pre-migration path: compute directly from parent fields.
	extreme_flags = compute_entry_extreme_flags(pixel_x, pixel_y, scale)
	is_hard_extreme = entry_is_hard_flagged(extreme_flags)
	is_soft_extreme = entry_is_soft_flagged(extreme_flags)
	// Whole-entry-disabled == accessory_type null (policy carve-out).
	// Per-dir hide is not yet a schema field; Phase 5 refines this.
	if(is_hard_extreme && !isnull(accessory_type))
		// TODO (Phase 5): narrow flagged_dirs using per-dir hide bitfield
		// once that schema field exists on /datum/customizer_entry.
		flagged_dirs = NORTH|SOUTH|EAST|WEST
	else
		flagged_dirs = 0

// ----------------------------------------------------------------------------
// Phase 6 — Composite sub-entry datum.
// ----------------------------------------------------------------------------
// A sub-entry owns its own accessory + transform; the render pipeline emits
// one overlay per non-empty sub-entry. The primary sub-entry (index 1) also
// mirrors back into the parent's legacy fields via sync_from_primary() so
// existing first-match getters (get_hair_color, wizard mirror, hair dye,
// apply_customizers_to_character, etc.) keep reading the parent and always
// see the primary's values.
/datum/customizer_sub_entry
	var/accessory_type
	var/accessory_colors
	/// Hair-only: per-sub solid hair color. Gradients stay parent-level
	/// (hair sub-entries share parent's natural_gradient / dye_gradient).
	var/hair_color
	var/pixel_x = 0
	var/pixel_y = 0
	var/flip_x = FALSE
	var/flip_y = FALSE
	var/rotation = 0
	var/scale = 1
	/// cache: recomputed, not serialized
	var/is_hard_extreme = FALSE
	/// cache: recomputed, not serialized
	var/is_soft_extreme = FALSE
	/// cache: recomputed, not serialized
	var/extreme_flags = EXTREME_FLAG_NONE
	/// cache: recomputed, not serialized
	var/flagged_dirs = 0

/// Mirror of the parent-level recompute, but keyed on the sub-entry's own
/// transform. `accessory_type_override` lets callers force the whole-entry-
/// disabled carve-out when the sub is empty without copying the field.
/datum/customizer_sub_entry/proc/recompute_extreme_flags(accessory_type_override = null)
	extreme_flags = compute_entry_extreme_flags(pixel_x, pixel_y, scale)
	is_hard_extreme = entry_is_hard_flagged(extreme_flags)
	is_soft_extreme = entry_is_soft_flagged(extreme_flags)
	var/effective_type = isnull(accessory_type_override) ? accessory_type : accessory_type_override
	if(is_hard_extreme && !isnull(effective_type))
		flagged_dirs = NORTH|SOUTH|EAST|WEST
	else
		flagged_dirs = 0

// ----------------------------------------------------------------------------
// Phase 6 — Composite helpers on /datum/customizer_entry.
// ----------------------------------------------------------------------------

/// One-shot migration wrapper. Runs when migrated_v == 0. Takes whatever
/// the parent's legacy fields describe and wraps them into a single
/// primary sub-entry, preserving render identity. Idempotent via the
/// migrated_v guard: running twice on the same entry is a no-op the
/// second time. Called from validate_customizer_entries() post-load.
/datum/customizer_entry/proc/migrate_sub_entries()
	if(migrated_v >= SUB_ENTRIES_MIGRATION_VERSION)
		return
	if(!LAZYLEN(sub_entries))
		var/datum/customizer_sub_entry/primary = new
		primary.accessory_type = accessory_type
		primary.accessory_colors = accessory_colors
		primary.pixel_x = pixel_x
		primary.pixel_y = pixel_y
		primary.flip_x = flip_x
		primary.flip_y = flip_y
		primary.rotation = rotation
		primary.scale = scale
		if(istype(src, /datum/customizer_entry/hair))
			var/datum/customizer_entry/hair/hair_entry = src
			primary.hair_color = hair_entry.hair_color
		primary.recompute_extreme_flags()
		LAZYADD(sub_entries, primary)
	migrated_v = SUB_ENTRIES_MIGRATION_VERSION

/// Copy the primary sub-entry's fields back to the parent's legacy vars.
/// Call after every sub-entry mutation so downstream first-match getters
/// (which read the parent fields directly) always observe the primary's
/// authoritative state. No-op if sub_entries is empty.
/datum/customizer_entry/proc/sync_from_primary()
	var/datum/customizer_sub_entry/primary = LAZYACCESS(sub_entries, 1)
	if(!istype(primary))
		return
	accessory_type = primary.accessory_type
	accessory_colors = primary.accessory_colors
	pixel_x = primary.pixel_x
	pixel_y = primary.pixel_y
	flip_x = primary.flip_x
	flip_y = primary.flip_y
	rotation = primary.rotation
	scale = primary.scale
	if(istype(src, /datum/customizer_entry/hair) && !isnull(primary.hair_color))
		var/datum/customizer_entry/hair/hair_entry = src
		hair_entry.hair_color = primary.hair_color

/// Phase 6 — opposite direction of sync_from_primary. Writes the parent's
/// legacy fields onto sub_entries[1]. Called after ui_act handlers that
/// mutate parent fields directly (the existing "primary" editor path) so
/// the sub-entry datum stays in lockstep. No-op if sub_entries is empty
/// (pre-migration or dropped).
/datum/customizer_entry/proc/sync_primary_to_sub()
	var/datum/customizer_sub_entry/primary = LAZYACCESS(sub_entries, 1)
	if(!istype(primary))
		return
	primary.accessory_type = accessory_type
	primary.accessory_colors = accessory_colors
	primary.pixel_x = pixel_x
	primary.pixel_y = pixel_y
	primary.flip_x = flip_x
	primary.flip_y = flip_y
	primary.rotation = rotation
	primary.scale = scale
	if(istype(src, /datum/customizer_entry/hair))
		var/datum/customizer_entry/hair/hair_entry = src
		primary.hair_color = hair_entry.hair_color
	primary.recompute_extreme_flags()

// ----------------------------------------------------------------------------
// Phase 7 — absolute transform ceilings (hard clamps).
// ----------------------------------------------------------------------------
// Beyond these ceilings, saves are REJECTED (see _save_gate_allows() in the
// feature customizer editor). Legacy saves that predate the ceilings are
// silently clamped on load via sanitize_clamps() so players never lose their
// entire character to an out-of-bounds value baked into an old savefile.

/// Returns TRUE when `px`, `py`, `scale` are all within the Phase 7 hard
/// ceilings (EXTREME_OFFSET_CLAMP_PX / EXTREME_OFFSET_CLAMP_SCALE). Pure.
/proc/customizer_transform_within_clamps(px, py, scale)
	if(abs(px) > EXTREME_OFFSET_CLAMP_PX)
		return FALSE
	if(abs(py) > EXTREME_OFFSET_CLAMP_PX)
		return FALSE
	if(scale > EXTREME_OFFSET_CLAMP_SCALE)
		return FALSE
	return TRUE

/// Validates the parent transform and every sub-entry transform against the
/// Phase 7 hard ceilings. Returns TRUE if every transform is within bounds,
/// FALSE if any exceeds a ceiling. Used by the save gate to reject outright.
/datum/customizer_entry/proc/validate()
	if(!customizer_transform_within_clamps(pixel_x, pixel_y, scale))
		return FALSE
	if(LAZYLEN(sub_entries))
		for(var/datum/customizer_sub_entry/sub as anything in sub_entries)
			if(!istype(sub))
				continue
			if(!customizer_transform_within_clamps(sub.pixel_x, sub.pixel_y, sub.scale))
				return FALSE
	return TRUE

/// Load-path sanitizer: clamps (does not reject) out-of-bounds transforms on
/// the parent and every sub-entry. Legacy saves with extreme values baked in
/// get silently pulled back to the Phase 7 ceilings so they can still load.
/datum/customizer_entry/proc/sanitize_clamps()
	pixel_x = clamp(pixel_x, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
	pixel_y = clamp(pixel_y, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
	if(scale > EXTREME_OFFSET_CLAMP_SCALE)
		scale = EXTREME_OFFSET_CLAMP_SCALE
	if(LAZYLEN(sub_entries))
		for(var/datum/customizer_sub_entry/sub as anything in sub_entries)
			if(!istype(sub))
				continue
			sub.pixel_x = clamp(sub.pixel_x, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			sub.pixel_y = clamp(sub.pixel_y, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			if(sub.scale > EXTREME_OFFSET_CLAMP_SCALE)
				sub.scale = EXTREME_OFFSET_CLAMP_SCALE
