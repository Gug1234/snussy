// Defines shared between the sex flavor editor, intimate reaction editor,
// and their corresponding preference storage/validation procs.
// Placed in code\__DEFINES\roguetown\ so Dream Maker's alphabetical sorting
// ensures they are included early, before any files that reference them.

/// Maximum number of custom intimate reaction strings allowed per category.
#define INTIMATE_REACTION_MAX_STRINGS 10
/// Maximum character length of any single custom intimate reaction string.
#define INTIMATE_REACTION_MAX_LENGTH  750
/// Prefix for per-category intimate reaction audience metadata in custom_intimate_reactions.
#define INTIMATE_REACTION_AUDIENCE_PREFIX "audience_"
/// Prefix for per-category intimate reaction disabled metadata in custom_intimate_reactions.
#define INTIMATE_REACTION_DISABLED_PREFIX "disabled_"
/// Intimate reaction output is only sent to the wearer.
#define INTIMATE_AUDIENCE_SELF "self"
/// Intimate reaction output is sent to the wearer and active sex partner when there is one.
#define INTIMATE_AUDIENCE_PARTNER "partner"
/// Intimate reaction output is shown in the immediate 3x3 around the wearer.
#define INTIMATE_AUDIENCE_NEARBY "nearby"
/// Intimate reaction output is shown to anyone in the normal visible-message range.
#define INTIMATE_AUDIENCE_VIEW "view"
/// Ordered list of valid intimate reaction audience modes.
#define INTIMATE_AUDIENCE_OPTIONS list(INTIMATE_AUDIENCE_SELF, INTIMATE_AUDIENCE_PARTNER, INTIMATE_AUDIENCE_NEARBY, INTIMATE_AUDIENCE_VIEW)
/// Vision range for INTIMATE_AUDIENCE_NEARBY.
#define INTIMATE_AUDIENCE_NEARBY_RANGE 1

// The type of action/event that triggered the reaction.

#define INTIMATE_CONTEXT_MOVEMENT           "movement"
#define INTIMATE_CONTEXT_SEX_RECEIVED       "sex_received"
#define INTIMATE_CONTEXT_ANAL_SEX_RECEIVED  "anal_sex_received"

// Bitflags passed to intimate reaction viewer filters so viewer pref filtering
// can be resolved during one audience scan per visible message.

/// Message relates to chastity devices (jingles, arousal, denial, pain).
#define INTIMATE_CONTENT_CHASTITY (1<<0)
/// Message contains extreme/spike/pain content.
#define INTIMATE_CONTENT_EXTREME  (1<<1)

/// Legacy flat category list — kept for backward compatibility with old saves.
/// New code should use tier-prefixed keys (e.g., "neutral_movement").
#define INTIMATE_REACTION_CATEGORIES  list("movement", "sex_received")
