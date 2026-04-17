#define MAXIMUM_MARKINGS_PER_LIMB 3

/// Per-entry pixel offset clamps for the body marking editor (±64, matching
/// the custom piercing / taur genital editors). Entries outside this range
/// are clamped silently on render.
#define BODY_MARKING_OFFSET_MIN -64
#define BODY_MARKING_OFFSET_MAX 64

//Some defines for sprite accessories
// Which color source we're using when the accessory is added
#define DEFAULT_PRIMARY		1
#define DEFAULT_SECONDARY	2
#define DEFAULT_TERTIARY	3
#define DEFAULT_MATRIXED	4 //uses all three colors for a matrix
#define DEFAULT_SKIN_OR_PRIMARY	5 //Uses skin tone color if the character uses one, otherwise primary

