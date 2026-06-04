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

/// Custom sex action sound course identifiers.
#define CUSTOM_SEX_SOUND_NONE "none"
#define CUSTOM_SEX_SOUND_GENERIC "generic"
#define CUSTOM_SEX_SOUND_SUCKING "sucking"
#define CUSTOM_SEX_SOUND_ORAL "oral"
#define CUSTOM_SEX_SOUND_OUTERCOURSE "outercourse"
#define CUSTOM_SEX_SOUND_OUTERCOURSE_WET "outercourse_wet"
#define CUSTOM_SEX_SOUND_INTERCOURSE "intercourse"
#define CUSTOM_SEX_SOUND_INTERCOURSE_WET "intercourse_wet"
#define CUSTOM_SEX_SOUND_CHASTITY "chastity"
/// Ordered list of valid custom sex action sound course identifiers.
#define CUSTOM_SEX_SOUND_COURSES list(CUSTOM_SEX_SOUND_NONE, CUSTOM_SEX_SOUND_GENERIC, CUSTOM_SEX_SOUND_SUCKING, CUSTOM_SEX_SOUND_ORAL, CUSTOM_SEX_SOUND_OUTERCOURSE, CUSTOM_SEX_SOUND_OUTERCOURSE_WET, CUSTOM_SEX_SOUND_INTERCOURSE, CUSTOM_SEX_SOUND_INTERCOURSE_WET, CUSTOM_SEX_SOUND_CHASTITY)

/// Custom sex action animation identifiers.
#define CUSTOM_SEX_ANIMATION_NONE "none"
#define CUSTOM_SEX_ANIMATION_THRUST "thrust"
#define CUSTOM_SEX_ANIMATION_SOFT_THRUST "soft_thrust"
#define CUSTOM_SEX_ANIMATION_HARD_THRUST "hard_thrust"
/// Ordered list of valid custom sex action animation identifiers.
#define CUSTOM_SEX_ANIMATION_TYPES list(CUSTOM_SEX_ANIMATION_NONE, CUSTOM_SEX_ANIMATION_THRUST, CUSTOM_SEX_ANIMATION_SOFT_THRUST, CUSTOM_SEX_ANIMATION_HARD_THRUST)

/// Shared chunked import/export envelope version for ERP preference payloads.
#define ERP_EXPORT_CONTRACT_VERSION 1
/// Default maximum text length per exported chunk before base64 wrapping.
#define ERP_EXPORT_DEFAULT_CHUNK_SIZE 12000
/// Hard cap for reassembled chunked import payloads.
#define ERP_EXPORT_MAX_PAYLOAD_LENGTH 524288
/// The pasted chunk-envelope text includes base64 JSON wrappers around payload chunks.
#define ERP_EXPORT_MAX_IMPORT_TEXT_LENGTH (ERP_EXPORT_MAX_PAYLOAD_LENGTH * 2)
/// Defensive cap for self-contained TGUI import transfers.
#define ERP_EXPORT_MAX_IMPORT_TRANSFER_CHUNKS 1024

/// Chunked export data kind for complete character-slot exports.
#define ERP_EXPORT_KIND_CHARACTER_SLOT "character_slot"
/// Chunked export data kind for the custom sex menu editor.
#define ERP_EXPORT_KIND_SEX_MENU "sex_menu"
/// Chunked export data kind for the intimate reaction editor.
#define ERP_EXPORT_KIND_REACTIONS "intimate_reactions"

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

// ── Intimate Reaction Arousal Tiers ─────────────────────────────────────────
// String constants identifying each arousal/state tier. Used as category key
// prefixes in preference storage (e.g., "lusty_sex_received") and for runtime
// tier routing in the character_flavor component.

#define INTIMATE_TIER_NEUTRAL     "neutral"
#define INTIMATE_TIER_LUSTY       "lusty"
#define INTIMATE_TIER_BUILDING    "building"
#define INTIMATE_TIER_OVERWHELMED "overwhelmed"
#define INTIMATE_TIER_AFTERGLOW   "afterglow"
#define INTIMATE_TIER_WITHDRAWAL  "withdrawal"
#define INTIMATE_TIER_ROUGHUSE    "roughuse"
#define INTIMATE_TIER_BROKEN      "broken"

/// All tiers in display/priority order (highest → lowest).
#define INTIMATE_TIER_LIST list( \
	INTIMATE_TIER_BROKEN, \
	INTIMATE_TIER_ROUGHUSE, \
	INTIMATE_TIER_OVERWHELMED, \
	INTIMATE_TIER_BUILDING, \
	INTIMATE_TIER_LUSTY, \
	INTIMATE_TIER_NEUTRAL, \
	INTIMATE_TIER_AFTERGLOW, \
	INTIMATE_TIER_WITHDRAWAL \
)

/// Fallback chains per tier — when the current tier has no strings, try these in order.
/// Key = starting tier, Value = ordered list of fallback tiers to try.
#define INTIMATE_TIER_FALLBACK list( \
	INTIMATE_TIER_BROKEN      = list(INTIMATE_TIER_ROUGHUSE, INTIMATE_TIER_OVERWHELMED, INTIMATE_TIER_BUILDING, INTIMATE_TIER_LUSTY, INTIMATE_TIER_NEUTRAL), \
	INTIMATE_TIER_ROUGHUSE    = list(INTIMATE_TIER_OVERWHELMED, INTIMATE_TIER_BUILDING, INTIMATE_TIER_LUSTY, INTIMATE_TIER_NEUTRAL), \
	INTIMATE_TIER_OVERWHELMED = list(INTIMATE_TIER_BUILDING, INTIMATE_TIER_LUSTY, INTIMATE_TIER_NEUTRAL), \
	INTIMATE_TIER_BUILDING    = list(INTIMATE_TIER_LUSTY, INTIMATE_TIER_NEUTRAL), \
	INTIMATE_TIER_LUSTY       = list(INTIMATE_TIER_NEUTRAL), \
	INTIMATE_TIER_NEUTRAL     = list(), \
	INTIMATE_TIER_AFTERGLOW   = list(INTIMATE_TIER_OVERWHELMED, INTIMATE_TIER_BUILDING, INTIMATE_TIER_LUSTY, INTIMATE_TIER_NEUTRAL), \
	INTIMATE_TIER_WITHDRAWAL  = list(INTIMATE_TIER_LUSTY, INTIMATE_TIER_NEUTRAL) \
)

// ── Intimate Reaction Contexts ──────────────────────────────────────────────
// The type of action/event that triggered the reaction.

#define INTIMATE_CONTEXT_MOVEMENT           "movement"
#define INTIMATE_CONTEXT_SEX_RECEIVED       "sex_received"
#define INTIMATE_CONTEXT_ANAL_SEX_RECEIVED  "anal_sex_received"

// ── Arousal Thresholds for Tier Routing ─────────────────────────────────────
// These mirror the existing sexcon arousal constants but are named specifically
// for tier routing clarity. Adjust these to tune when tiers kick in.

/// Arousal >= this → lusty tier (matches AROUSAL_HARD_ON_THRESHOLD).
#define INTIMATE_AROUSAL_LUSTY       20
/// Arousal >= this → building tier.
#define INTIMATE_AROUSAL_BUILDING    40
/// Arousal >= this → overwhelmed tier (matches ACTIVE_EJAC_THRESHOLD).
#define INTIMATE_AROUSAL_OVERWHELMED 100

/// Force >= this → roughuse tier overrides arousal-based tier.
#define INTIMATE_FORCE_ROUGHUSE SEX_FORCE_HIGH

/// Duration of the afterglow trait after ejaculation (60 seconds).
#define INTIMATE_AFTERGLOW_DURATION (60 SECONDS)
/// Duration of the withdrawal trait after high arousal drops below building threshold (45 seconds).
#define INTIMATE_WITHDRAWAL_DURATION (45 SECONDS)
/// Arousal must have been at or above this level to trigger withdrawal on drop.
#define INTIMATE_WITHDRAWAL_AROUSAL_PEAK 80

/// Trait source used by temporary intimate reaction mood states.
#define TRAIT_SOURCE_INTIMATE_REACTION "intimate_reaction"
/// Temporary post-climax tier marker used by character-flavor routing.
#define TRAIT_INTIMATE_AFTERGLOW "intimate_afterglow"
/// Temporary high-arousal-drop tier marker used by character-flavor routing.
#define TRAIT_INTIMATE_WITHDRAWAL "intimate_withdrawal"

// ── Intimate Visible Message Content Flags ─────────────────────────────────
// Bitflags passed to get_intimate_excluded_mobs() so viewer pref filtering
// can be resolved in a single hearers pass per visible_message call.

/// Message relates to chastity devices (jingles, arousal, denial, pain).
#define INTIMATE_CONTENT_CHASTITY (1<<0)
/// Message contains extreme/spike/pain content.
#define INTIMATE_CONTENT_EXTREME  (1<<1)

/// Legacy flat category list — kept for backward compatibility with old saves.
/// New code should use tier-prefixed keys (e.g., "neutral_movement").
#define INTIMATE_REACTION_CATEGORIES  list("movement", "sex_received")
