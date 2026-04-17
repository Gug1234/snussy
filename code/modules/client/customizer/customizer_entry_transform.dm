/// Snap a customizer entry's Phase 1 transform fields back to valid defaults.
/// Runs after savefile load so corrupted/out-of-range values can't leak into
/// the render pipeline. BYOND datum serialization handles missing fields on
/// pre-Phase-1 saves by populating defaults, so no migration is required.
/proc/sanitize_customizer_entry_transform(datum/customizer_entry/entry)
	if(!entry)
		return
	entry.pixel_x = clamp(entry.pixel_x, FEATURE_OFFSET_MIN, FEATURE_OFFSET_MAX)
	entry.pixel_y = clamp(entry.pixel_y, FEATURE_OFFSET_MIN, FEATURE_OFFSET_MAX)
	if(!(entry.rotation in FEATURE_ROTATION_CHOICES))
		entry.rotation = 0
	if(!(entry.scale in FEATURE_SCALE_CHOICES))
		entry.scale = 1
	entry.flip_x = !!entry.flip_x
	entry.flip_y = !!entry.flip_y

/// Returns TRUE if the entry has any non-default Phase 1 transform state.
/proc/customizer_entry_has_transform(datum/customizer_entry/entry)
	if(!entry)
		return FALSE
	return entry.pixel_x || entry.pixel_y || entry.flip_x || entry.flip_y || entry.rotation || entry.scale != 1
