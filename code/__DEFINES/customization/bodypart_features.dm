// Bodypart feature transform constraints (Phase 1).
// Per-entry offset/quantized transform on /datum/customizer_entry and the
// live /datum/bodypart_feature. Render pipeline wiring is Phase 2.

#define FEATURE_OFFSET_MIN -64
#define FEATURE_OFFSET_MAX 64
#define FEATURE_ROTATION_CHOICES list(0, 90, 180, 270)
#define FEATURE_SCALE_CHOICES list(1, 2)
#define MAXIMUM_FEATURE_STACK 3
