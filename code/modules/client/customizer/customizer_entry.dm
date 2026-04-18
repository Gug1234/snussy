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
