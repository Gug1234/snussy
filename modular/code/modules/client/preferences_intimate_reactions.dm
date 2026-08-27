/**
 * preferences_intimate_reactions.dm — Modular extension to /datum/preferences.
 *
 * Adds per-character custom intimate reaction string storage and validation.
 * Large reaction data is serialized through the ERP sidecar owned by
 * save_character(); only compact account-level toggles live in preferences.
 *
 * Shared constants live in modular/code/__DEFINES/roguetown/sexcon_modular.dm
 * so they are available to all consumers regardless of DME include order.
 */

// Preference vars are full-path declarations so static analysis resolves them before modular procs use them.
/// Master switch for custom intimate reaction text emitted by modular hooks.
/datum/preferences/var/intimate_reaction_enabled = TRUE

/// Allows custom reaction text for chastity-related categories.
/datum/preferences/var/intimate_reaction_show_chastity = TRUE

/// Allows custom reaction text for extreme-content categories.
/datum/preferences/var/intimate_reaction_show_extreme = FALSE

/// Allows custom reaction text when no intimate accessory is equipped.
/datum/preferences/var/intimate_reaction_show_accessory_free = TRUE

/// Returns TRUE when this preference slot permits a source to emit a reaction.
/datum/preferences/proc/can_emit_intimate_reaction_category(category, content_flags = 0, require_accessory_free = FALSE, require_intimate_accessories = FALSE)
	if(!intimate_reaction_enabled)
		return FALSE
	if(require_accessory_free && !intimate_reaction_show_accessory_free)
		return FALSE
	if(require_intimate_accessories && !intimate_enabled)
		return FALSE
	if((content_flags & INTIMATE_CONTENT_CHASTITY) && (!chastenable || !intimate_reaction_show_chastity))
		return FALSE
	if((content_flags & INTIMATE_CONTENT_EXTREME) && (!extreme_erp || !intimate_reaction_show_extreme))
		return FALSE
	return TRUE
