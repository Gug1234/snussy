// ── Modular sexcon constants ─────────────────────────────────────────────────
// Defines shared between the sex flavor editor, intimate reaction editor,
// and their corresponding preference storage/validation procs.
// Placed in code\__DEFINES\roguetown\ so Dream Maker's alphabetical sorting
// ensures they are included early, before any files that reference them.

/// Maximum number of custom flavor strings allowed per action per phase.
#define SEX_FLAVOR_MAX_STRINGS 10
/// Maximum character length of any single custom flavor string.
#define SEX_FLAVOR_MAX_LENGTH  280
/// Ordered list of valid phase keys used by both the editor and the validator.
#define SEX_FLAVOR_PHASES      list("on_start", "on_perform", "on_finish")
/// Maximum number of custom sex action slots a player can define.
#define MAX_CUSTOM_SEX_ACTIONS 5

/// Maximum number of custom intimate reaction strings allowed per category.
#define INTIMATE_REACTION_MAX_STRINGS 10
/// Maximum character length of any single custom intimate reaction string.
#define INTIMATE_REACTION_MAX_LENGTH  280
/// Ordered list of valid category keys used by both the editor and the validator.
#define INTIMATE_REACTION_CATEGORIES  list("movement", "sex_received")

