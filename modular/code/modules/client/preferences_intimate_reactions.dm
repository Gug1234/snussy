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

/// Allows partner-facing custom reaction text where supported.
/datum/preferences/var/intimate_reaction_share_with_partner = FALSE

/**
 * Per-character custom intimate reaction text pool.
 *
 * Structure (associative list):
	 *   "movement"     → list("string1", "string2", ...),
	 *   "sex_received" → list(...),
	 *
 * Null when the player has not configured any custom strings.
 * Serialized to JSON for sidecar persistence by save_character().
 */
/datum/preferences/var/list/custom_intimate_reactions = null

/// Returns TRUE when an intimate reaction audience mode is recognized.
/proc/is_valid_intimate_reaction_audience(audience)
	return istext(audience) && (audience in INTIMATE_AUDIENCE_OPTIONS)

/// Returns the sidecar key used for per-category audience metadata.
/proc/get_intimate_reaction_audience_key(category)
	if(!istext(category) || !length(category))
		return null
	return "[INTIMATE_REACTION_AUDIENCE_PREFIX][category]"

/// Returns the sidecar key used for per-category enabled/disabled metadata.
/proc/get_intimate_reaction_disabled_key(category)
	if(!istext(category) || !length(category))
		return null
	return "[INTIMATE_REACTION_DISABLED_PREFIX][category]"

/**
 * Validates and sanitizes custom_intimate_reactions after loading from the savefile.
 *
 * Enforces:
 *   - Category keys must be one of the valid keys from all bank definitions.
 *   - String lists are trimmed to INTIMATE_REACTION_MAX_STRINGS entries.
 *   - Individual strings are clamped to INTIMATE_REACTION_MAX_LENGTH characters.
 *
 * Sets custom_intimate_reactions to null if nothing valid remains after cleaning.
 */
/datum/preferences/proc/validate_custom_intimate_reactions()
	if(!islist(custom_intimate_reactions))
		custom_intimate_reactions = null
		return

	var/list/valid_cats = get_all_intimate_reaction_categories()
	var/list/validated = list()
	for(var/category in custom_intimate_reactions)
		// Handle audience keys - "audience_<category>" is per-category visibility metadata.
		if(copytext(category, 1, length(INTIMATE_REACTION_AUDIENCE_PREFIX) + 1) == INTIMATE_REACTION_AUDIENCE_PREFIX)
			var/audience_base_cat = copytext(category, length(INTIMATE_REACTION_AUDIENCE_PREFIX) + 1)
			if(audience_base_cat in valid_cats)
				var/audience = custom_intimate_reactions[category]
				if(is_valid_intimate_reaction_audience(audience))
					validated[category] = audience
			continue
		// Handle disabled keys - "disabled_<category>" is sparse per-category off metadata.
		if(copytext(category, 1, length(INTIMATE_REACTION_DISABLED_PREFIX) + 1) == INTIMATE_REACTION_DISABLED_PREFIX)
			var/disabled_base_cat = copytext(category, length(INTIMATE_REACTION_DISABLED_PREFIX) + 1)
			if(disabled_base_cat in valid_cats)
				if(custom_intimate_reactions[category])
					validated[category] = TRUE
			continue
		// Handle weight keys - "weight_<category>" is a parallel list of numbers.
		if(copytext(category, 1, 8) == "weight_")
			var/base_cat = copytext(category, 8)
			if(base_cat in valid_cats)
				var/list/weights = custom_intimate_reactions[category]
				if(islist(weights) && weights.len)
					var/list/valid_weights = list()
					for(var/w in weights)
						valid_weights += clamp(round(w), 0, 100)
						if(valid_weights.len >= INTIMATE_REACTION_MAX_STRINGS)
							break
					if(valid_weights.len)
						validated[category] = valid_weights
			continue
		if(!(category in valid_cats))
			continue
		var/list/strings = custom_intimate_reactions[category]
		if(!islist(strings) || !strings.len)
			continue

		var/list/valid_strings = list()
		for(var/str in strings)
			if(!istext(str) || !length(str))
				continue
			// html_decode() repairs legacy strings that were double-encoded
			// by old sanitize() calls; strip_html_simple() prevents HTML
			// injection at runtime without encoding entities for TGUI.
			valid_strings += strip_html_simple(sanitize_simple(html_decode(copytext(str, 1, INTIMATE_REACTION_MAX_LENGTH + 1))))
			if(valid_strings.len >= INTIMATE_REACTION_MAX_STRINGS)
				break

		if(valid_strings.len)
			validated[category] = valid_strings

	custom_intimate_reactions = validated.len ? validated : null

/// Returns TRUE when a category is allowed to emit for this preference slot.
/datum/preferences/proc/intimate_reaction_category_enabled(category)
	if(!istext(category) || !(category in get_all_intimate_reaction_categories()))
		return TRUE
	if(!islist(custom_intimate_reactions))
		return TRUE
	var/disabled_key = get_intimate_reaction_disabled_key(category)
	return !custom_intimate_reactions[disabled_key]

/// Stores a per-category enabled toggle. Disabled state is stored sparsely.
/datum/preferences/proc/set_intimate_reaction_category_enabled(category, enabled)
	if(!istext(category) || !(category in get_all_intimate_reaction_categories()))
		return FALSE
	if(!islist(custom_intimate_reactions))
		custom_intimate_reactions = list()
	var/disabled_key = get_intimate_reaction_disabled_key(category)
	if(enabled)
		custom_intimate_reactions.Remove(disabled_key)
	else
		custom_intimate_reactions[disabled_key] = TRUE
	if(!length(custom_intimate_reactions))
		custom_intimate_reactions = null
	return TRUE

/// Returns TRUE when this preference slot permits a source to emit a reaction.
/datum/preferences/proc/can_emit_intimate_reaction_category(category, content_flags = 0, require_accessory_free = FALSE, require_intimate_accessories = FALSE)
	if(!intimate_reaction_enabled)
		return FALSE
	if(!intimate_reaction_category_enabled(category))
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

/// Returns the configured audience for a category, falling back to default_audience.
/datum/preferences/proc/get_intimate_reaction_audience(category, default_audience = INTIMATE_AUDIENCE_SELF)
	if(!is_valid_intimate_reaction_audience(default_audience))
		default_audience = INTIMATE_AUDIENCE_SELF
	if(!istext(category) || !length(category))
		return default_audience
	if(!islist(custom_intimate_reactions))
		return default_audience
	var/audience_key = get_intimate_reaction_audience_key(category)
	var/audience = custom_intimate_reactions[audience_key]
	if(is_valid_intimate_reaction_audience(audience))
		return audience
	return default_audience

/// Stores a per-category audience override. Passing the default removes the override.
/datum/preferences/proc/set_intimate_reaction_audience(category, audience, default_audience = INTIMATE_AUDIENCE_SELF)
	if(!istext(category) || !(category in get_all_intimate_reaction_categories()))
		return FALSE
	if(!is_valid_intimate_reaction_audience(audience))
		return FALSE
	if(!is_valid_intimate_reaction_audience(default_audience))
		default_audience = INTIMATE_AUDIENCE_SELF
	if(!islist(custom_intimate_reactions))
		custom_intimate_reactions = list()
	var/audience_key = get_intimate_reaction_audience_key(category)
	if(audience == default_audience)
		custom_intimate_reactions.Remove(audience_key)
	else
		custom_intimate_reactions[audience_key] = audience
	if(!length(custom_intimate_reactions))
		custom_intimate_reactions = null
	return TRUE

/// Returns TRUE when category is an accessory-free character flavor category.
/datum/preferences/proc/is_character_flavor_reaction_category(category)
	if(!istext(category) || !length(category))
		return FALSE
	if(category in list(INTIMATE_CONTEXT_MOVEMENT, INTIMATE_CONTEXT_SEX_RECEIVED, INTIMATE_CONTEXT_ANAL_SEX_RECEIVED))
		return TRUE
	for(var/tier in INTIMATE_TIER_LIST)
		if(category == "[tier]_[INTIMATE_CONTEXT_MOVEMENT]")
			return TRUE
		if(category == "[tier]_[INTIMATE_CONTEXT_SEX_RECEIVED]")
			return TRUE
		if(category == "[tier]_[INTIMATE_CONTEXT_ANAL_SEX_RECEIVED]")
			return TRUE
	return FALSE

/// Returns TRUE when this preference slot has player-authored accessory-free character flavor.
/datum/preferences/proc/has_custom_character_flavor_reactions()
	if(!islist(custom_intimate_reactions))
		return FALSE
	for(var/category in custom_intimate_reactions)
		if(!is_character_flavor_reaction_category(category))
			continue
		var/list/strings = custom_intimate_reactions[category]
		if(islist(strings) && length(strings))
			return TRUE
	return FALSE

/**
 * Resolves anatomy-aware tokens in intimate reaction text strings.
 *
 * Replaces placeholder tokens with contextual values derived from the user and
 * (optionally) a target mob. Designed for lightweight inline use inside signal
 * handlers and component procs — avoids regex in favour of simple replacetext()
 * chains for BYOND performance.
 *
 * Supported tokens:
 *   [USER]        — user's visible name
 *   [TARGET]      — target's visible name (or "someone" if null)
 *   [THEY]        — user's subject pronoun  (he/she/they/it)
 *   [THEM]        — user's object pronoun   (him/her/them/it)
 *   [THEIR]       — user's possessive       (his/her/their/its)
 *   [TTHEY]       — target's subject pronoun
 *   [TTHEM]       — target's object pronoun
 *   [TTHEIR]      — target's possessive
 *   [PENIS_TYPE]  — descriptive penis type name (knotted/equine/plain/etc) or "none"
 *   [CUPSIZE]     — breast size label from GLOB.named_breast_sizes (Flat–Obscene) or "none"
 *   [TAUR]        — taur bodypart name if present, otherwise "none"
 *   [SHEATH]      — sheath descriptor (none/sheath/genital slit)
 *   [GENITAL_DESC]— contextual genital descriptor combining organ type + state
 *
 * Arguments:
 *   text   — the raw string containing tokens.
 *   user   — the mob whose anatomy supplies [USER]/[THEY]/etc and genital data.
 *   target — (optional) a second mob for [TARGET]/[TTHEY]/etc. May be null.
 *
 * Returns the resolved string with all recognised tokens replaced.
 */
/proc/resolve_intimate_reaction_tokens(text, mob/living/carbon/human/user, mob/living/carbon/human/target, user_is_viewer = FALSE, target_is_viewer = FALSE)
	if(!text || !user)
		return text

	// --- Name tokens ---
	var/user_name = user_is_viewer ? "you" : user.name
	var/user_possessive = user_is_viewer ? "your" : _intimate_reaction_possessive_name(user.name)
	text = replacetext(text, "\[USERPOS]", user_possessive)
	text = replacetext(text, "\[USER]", user_name)
	if(target)
		text = replacetext(text, "\[TARGET]", target_is_viewer ? "you" : target.name)
	else
		text = replacetext(text, "\[TARGET]", "someone")

	// --- User pronoun tokens (leverage existing mob procs which respect disguises & pronoun prefs) ---
	text = replacetext(text, "\[THEY]", user_is_viewer ? "you" : user.p_they())
	text = replacetext(text, "\[THEM]", user_is_viewer ? "you" : user.p_them())
	text = replacetext(text, "\[THEIR_CAP]", user_is_viewer ? "Your" : capitalize(user.p_their()))
	text = replacetext(text, "\[THEIR]", user_is_viewer ? "your" : user.p_their())

	// --- Target pronoun tokens ---
	if(target)
		text = replacetext(text, "\[TTHEY]", target_is_viewer ? "you" : target.p_they())
		text = replacetext(text, "\[TTHEM]", target_is_viewer ? "you" : target.p_them())
		text = replacetext(text, "\[TTHEIR]", target_is_viewer ? "your" : target.p_their())
	else
		text = replacetext(text, "\[TTHEY]", "they")
		text = replacetext(text, "\[TTHEM]", "them")
		text = replacetext(text, "\[TTHEIR]", "their")

	// --- Penis type token ---
	var/penis_type_label = "none"
	var/obj/item/organ/penis/user_penis = user.getorganslot(ORGAN_SLOT_PENIS)
	if(user_penis)
		penis_type_label = get_penis_type_label(user_penis.penis_type)
	var/custom_penis_type_label = resolve_custom_anatomy_token(user, "cock", CUSTOM_ANATOMY_TOKEN_BARE, penis_type_label)
	text = replacetext(text, "\[PENIS_TYPE]", custom_penis_type_label)

	// --- Penis size descriptor token ---
	// [COCKSIZE] resolves to a visceral, shame/lust-coded descriptor based on penis_size.
	var/cocksize_label = "none"
	if(user_penis)
		cocksize_label = _penis_size_descriptor(user_penis.penis_size)
	text = replacetext(text, "\[COCKSIZE]", cocksize_label)

	// --- Short penis-size adjective ---
	// [SIZEADJ] resolves to a single word: "pitiful", "modest", or "massive".
	// Designed to precede nouns: "[THEIR] [SIZEADJ] [PENIS_TYPE]".
	var/sizeadj_label = "none"
	if(user_penis)
		sizeadj_label = _penis_size_adjective(user_penis.penis_size)
	text = replacetext(text, "\[SIZEADJ]", sizeadj_label)

	// --- Sheath token ---
	var/sheath_label = "none"
	if(user_penis)
		switch(user_penis.sheath_type)
			if(SHEATH_TYPE_NORMAL)
				sheath_label = "sheath"
			if(SHEATH_TYPE_SLIT)
				sheath_label = "genital slit"
	text = replacetext(text, "\[SHEATH]", sheath_label)

	// --- Cup size token ---
	// [CUPSIZE] resolves to a fantasy-appropriate descriptor comparing breast size
	// to common objects found in Ratwood (fruits, produce, etc.).
	// cup_short_label is kept for [GENITAL_DESC] where brevity matters.
	var/cup_label = "none"
	var/cup_short_label = "none"
	var/obj/item/organ/breasts/user_breasts = user.getorganslot(ORGAN_SLOT_BREASTS)
	if(user_breasts)
		cup_label = _breast_size_descriptor(user_breasts.breast_size)
		cup_short_label = find_key_by_value(GLOB.named_breast_sizes, user_breasts.breast_size)
		if(!cup_short_label)
			cup_short_label = "unknown"
	var/custom_cup_label = resolve_custom_anatomy_token(user, "cup_size", CUSTOM_ANATOMY_TOKEN_BARE, cup_label)
	text = replacetext(text, "\[CUPSIZE]", custom_cup_label)

	// --- Short breast-size adjective ---
	// [CUPADJ] resolves to a single word: "flat", "small", "modest", "generous", "heavy", "obscene".
	// Designed to slot before nouns: "[THEIR] [CUPADJ] breasts" / "[CUPADJ] chest".
	var/cupadj_label = "none"
	if(user_breasts)
		cupadj_label = _breast_size_adjective(user_breasts.breast_size)
	text = replacetext(text, "\[CUPADJ]", cupadj_label)

	// --- Breast type token ---
	// [BREASTTYPE] resolves to a descriptive phrase aware of pair/quad/sextuple
	// arrangement and the current breast_size, with unique text for multi-breast bodies.
	var/breast_type_label = "none"
	if(user_breasts)
		breast_type_label = _breast_type_descriptor(user_breasts.accessory_type, user_breasts.breast_size)
	var/custom_breast_type_label = resolve_custom_anatomy_token(user, "breast_type", CUSTOM_ANATOMY_TOKEN_BARE, breast_type_label)
	text = replacetext(text, "\[BREASTTYPE]", custom_breast_type_label)

	// --- Vagina type token ---
	// [VAGTYPE] resolves to a visceral descriptor based on the vagina's sprite accessory type.
	var/vagtype_label = "none"
	var/obj/item/organ/vagina/user_vagina = user.getorganslot(ORGAN_SLOT_VAGINA)
	if(user_vagina)
		vagtype_label = _vagina_type_descriptor(user_vagina.accessory_type)
	var/custom_vagtype_label = resolve_custom_anatomy_token(user, "vag", CUSTOM_ANATOMY_TOKEN_BARE, vagtype_label)
	text = replacetext(text, "\[VAGTYPE]", custom_vagtype_label)

	// --- Short vagina-type adjective ---
	// [VAGADJ] resolves to a single word: "smooth", "hairy", "trimmed", "spaded", "furred", "gaping", "cloacal".
	// Designed for: "[THEIR] [VAGADJ] cunt" / "the [VAGADJ] slit".
	var/vagadj_label = "none"
	if(user_vagina)
		vagadj_label = _vagina_type_adjective(user_vagina.accessory_type)
	text = replacetext(text, "\[VAGADJ]", vagadj_label)

	// --- Taur token ---
	var/taur_label = "none"
	var/obj/item/bodypart/taur/user_taur = user.get_taur_tail()
	if(user_taur)
		taur_label = user_taur.name
	text = replacetext(text, "\[TAUR]", taur_label)

	// --- Contextual genital descriptor ---
	// Builds a short phrase summarising the user's primary genital state.
	var/genital_desc = "smooth groin"
	if(user_penis && user_breasts)
		genital_desc = "[penis_type_label] and [cup_short_label] chest"
	else if(user_penis)
		genital_desc = "[penis_type_label]"
	else if(user_vagina)
		if(user_breasts)
			genital_desc = "slit and [cup_short_label] chest"
		else
			genital_desc = "slit"
	else if(user_breasts)
		genital_desc = "[cup_short_label] chest"
	text = replacetext(text, "\[GENITAL_DESC]", genital_desc)

	return text

/// Returns the viewer-appropriate version of an intimate reaction token string.
/proc/resolve_intimate_reaction_tokens_for_viewer(text, mob/living/carbon/human/user, mob/living/carbon/human/target, mob/viewer)
	return resolve_intimate_reaction_tokens(text, user, target, viewer && viewer == user, viewer && viewer == target)

/// Returns a visible-name possessive for third-person token output.
/proc/_intimate_reaction_possessive_name(name)
	if(!istext(name) || !length(name))
		return "someone's"
	return "[name]'s"

/**
 * Maps a PENIS_TYPE_* define to a human-readable label for token resolution.
 *
 * Kept as a dedicated proc so the mapping lives in one place and can be
 * extended without touching the token resolver itself.
 */
/proc/get_penis_type_label(penis_type)
	switch(penis_type)
		if(PENIS_TYPE_PLAIN)
			return "cock"
		if(PENIS_TYPE_KNOTTED)
			return "knotted cock"
		if(PENIS_TYPE_EQUINE)
			return "equine cock"
		if(PENIS_TYPE_EQUINE_KNOTTED)
			return "equine knotted cock"
		if(PENIS_TYPE_TAPERED)
			return "tapered cock"
		if(PENIS_TYPE_TAPERED_DOUBLE)
			return "tapered double cock"
		if(PENIS_TYPE_TAPERED_DOUBLE_KNOTTED)
			return "tapered double knotted cock"
		if(PENIS_TYPE_TAPERED_KNOTTED)
			return "tapered knotted cock"
		if(PENIS_TYPE_BARBED)
			return "barbed cock"
		if(PENIS_TYPE_BARBED_KNOTTED)
			return "barbed knotted cock"
		if(PENIS_TYPE_TENTACLE)
			return "tentacle cock"
	return "cock"

/**
 * Maps a numeric breast_size (0–9) to a descriptor
 * Designed to read naturally as both a standalone noun-phrase ("[CUPSIZE] breasts")
 * and as an adjective in compound descriptors ("[CUPSIZE] chest").
 *
 * Arguments:
 *   size — the integer breast_size value from the organ (0 = Flat, 9 = Obscene).
 *
 * Returns a lowercase descriptive string.
 */
/proc/_breast_size_descriptor(size)
	switch(size)
		if(0) // Flat
			return "flat"
		if(1) // Slight
			return "barely-there, like two ripe cherries"
		if(2) // Small
			return "small, each about the size of a lemon"
		if(3) // Moderate
			return "modest, like a pair of apples"
		if(4) // Large
			return "full and heavy, like ripe pears"
		if(5) // Generous
			return "generous, each like a fat pomegranate"
		if(6) // Heavy
			return "heavy, like two overfull wineskins"
		if(7) // Massive
			return "massive, each the size of a prize melon"
		if(8) // Heaping
			return "heaping, like two sacks of grain straining at the seams"
		if(9) // Obscene
			return "obscene, each rivaling a pumpkin"
	return "unknown"

/**
 * Maps a numeric penis_size (1–3) to a descriptor.
 * Small sizes are disparaged with shaming language; large sizes are described
 * with lurid, hefty reverence.
 *
 * Arguments:
 *   size — the integer penis_size value from the organ (1 = Small, 2 = Average, 3 = Large).
 *
 * Returns a lowercase descriptive string.
 */
/proc/_penis_size_descriptor(size)
	switch(size)
		if(1) // Small
			return pick(\
				"pitiful, barely a thumb's worth of meat",\
				"pathetically small, more clit than cock",\
				"laughably undersized, a bobbing ornament")
		if(2) // Average
			return pick(\
				"unremarkable, a serviceable handful",\
				"middling, a fine enough member",\
				"average, the sort that does the job without fanfare")
		if(3) // Large
			return pick(\
				"fat and heavy, the kind that might cause rips",\
				"brutishly thick, a gut-churning slab of cock",\
				"monstrous, veined and weighty enough to slap bruises into skin")
	return "unremarkable"

/**
 * Returns a descriptive phrase for the character's breast arrangement,
 * aware of pair, quad, and sextuple types. Adjusts language for multi-breast
 * bodies with unique text that acknowledges the unusual anatomy.
 *
 * Arguments:
 *   accessory_type — the breasts organ's accessory_type path.
 *   breast_size    — the integer breast_size value (0–9).
 *
 * Returns a lowercase descriptive string.
 */
/proc/_breast_type_descriptor(accessory_type, breast_size)
	var/size_word = "modest"
	switch(breast_size)
		if(0)
			size_word = "flat"
		if(1, 2)
			size_word = "small"
		if(3)
			size_word = "modest"
		if(4, 5)
			size_word = "generous"
		if(6, 7)
			size_word = "heavy"
		if(8, 9)
			size_word = "obscene"
	if(ispath(accessory_type, /datum/sprite_accessory/breasts/sextuple))
		switch(breast_size)
			if(0, 1, 2)
				return "six [size_word] breasts, stacked in three rows like an animal's teats"
			if(3, 4, 5)
				return "six [size_word] breasts arranged in neat rows, each pair swaying with its own weight"
			if(6, 7)
				return "six [size_word] breasts crowding her torso, heavy enough to rest against one another"
			if(8, 9)
				return "six [size_word] udders crammed against each other, a grotesque wall of tit-flesh"
		return "six [size_word] breasts, stacked in rows down her torso"
	if(ispath(accessory_type, /datum/sprite_accessory/breasts/quad))
		switch(breast_size)
			if(0, 1, 2)
				return "four [size_word] breasts, a second pair sitting snugly beneath the first"
			if(3, 4, 5)
				return "four [size_word] breasts, the lower pair squished against the upper, all of them full"
			if(6, 7)
				return "four [size_word] breasts fighting for space, each pair heavy enough to sag under its own heft"
			if(8, 9)
				return "four [size_word] mounds of breast, the sheer mass of them making her torso a landscape of cleavage"
		return "four [size_word] breasts, a second pair beneath the first"
	// Standard pair
	switch(breast_size)
		if(0)
			return "a flat chest, a pathetically slim washboard"
		if(1, 2)
			return "a pair of [size_word] breasts, perky and unassuming"
		if(3, 4)
			return "a pair of [size_word] breasts, capped with soft nipples"
		if(5, 6)
			return "[size_word] breasts that strain against fabric, nipples perpetually pushing at cloth"
		if(7)
			return "[size_word] breasts that sway and slap with every step, impossible to ignore"
		if(8, 9)
			return "[size_word] breasts, each a ridiculous mass of flesh that defies posture and decency"
	return "a pair of [size_word] breasts"

/**
 * Maps a vagina sprite accessory type path to a descriptor.
 *
 * Arguments:
 *   accessory_type — the vagina organ's accessory_type path.
 *
 * Returns a lowercase descriptive string.
 */
/proc/_vagina_type_descriptor(accessory_type)
	switch(accessory_type)
		if(/datum/sprite_accessory/vagina/human)
			return pick(\
				"a plain, humanoid slit with soft pink lips",\
				"a neat little cunt, lips flush and unadorned",\
				"a smooth-lipped pussy, warm and slick to the touch")
		if(/datum/sprite_accessory/vagina/hairy)
			return pick(\
				"a bush-framed cunt, dark curls matted with wet",\
				"a wild, hairy mound hiding plump lips beneath coarse pubes",\
				"a thickly bushy pussy, the scent of musk trapped in the tangle")
		if(/datum/sprite_accessory/vagina/trimmed)
			return pick(\
				"a neatly trimmed slit, a thin strip of hair crowning plump lips",\
				"a tidy cunt with a well-kept landing strip above it",\
				"a manicured pussy, pruned to a modest patch above soft folds")
		if(/datum/sprite_accessory/vagina/spade)
			return pick(\
				"a spade-shaped cunt, its lips darkened, puffy, and slightly round",\
				"an cookie-shaped slit, flushed and hot, its spaded lips radiating musky warmth",\
				"an canine pussy shaped like a spade, drooling heat from its thickly puffed folds")
		if(/datum/sprite_accessory/vagina/furred)
			return pick(\
				"a furred cunt, soft animal pelt framing plump, slick lips",\
				"a bestial slit ringed in downy fur, wet and twitching",\
				"a fur-lined pussy, its animal warmth palpable even before contact")
		if(/datum/sprite_accessory/vagina/gaping)
			return pick(\
				"a loose cunt, well-used lips open in an well-worn gape",\
				"a gaping, cavernous pussy that barely closes, its pink insides freely exposed",\
				"a ruined slit, stretched and gaping, wetness freely drooling from the opening")
		if(/datum/sprite_accessory/vagina/cloaca)
			return pick(\
				"a tight cloaca, a singular slit serving double duty between pressed thighs",\
				"an exotic vent, its opening deceptively narrow and slick with mucosal wet",\
				"a cloacal opening, warm and pulsing, its muscular walls rippling on contact")
	return "a nondescript slit"

/**
 * Returns a single-word adjective for penis size, suitable for pre-noun use:
 *   "[THEIR] [SIZEADJ] [PENIS_TYPE]" → "their pitiful knotted"
 */
/proc/_penis_size_adjective(size)
	switch(size)
		if(1)
			return pick("pitiful", "meager", "puny")
		if(2)
			return pick("modest", "average", "unremarkable")
		if(3)
			return pick("massive", "monstrous", "brutish")
	return "unremarkable"

/**
 * Returns a single-word adjective for breast size, suitable for pre-noun use:
 *   "[THEIR] [CUPADJ] breasts" → "their generous breasts"
 */
/proc/_breast_size_adjective(size)
	switch(size)
		if(0)
			return "flat"
		if(1)
			return "slight"
		if(2)
			return "small"
		if(3)
			return "modest"
		if(4)
			return "full"
		if(5)
			return "generous"
		if(6)
			return "heavy"
		if(7)
			return "massive"
		if(8)
			return "heaping"
		if(9)
			return "obscene"
	return "modest"

/**
 * Returns a single-word adjective for vagina sprite type, suitable for pre-noun use:
 *   "[THEIR] [VAGADJ] cunt" → "their furred cunt"
 */
/proc/_vagina_type_adjective(accessory_type)
	switch(accessory_type)
		if(/datum/sprite_accessory/vagina/human)
			return "smooth"
		if(/datum/sprite_accessory/vagina/hairy)
			return "hairy"
		if(/datum/sprite_accessory/vagina/trimmed)
			return "trimmed"
		if(/datum/sprite_accessory/vagina/spade)
			return "spaded"
		if(/datum/sprite_accessory/vagina/furred)
			return "furred"
		if(/datum/sprite_accessory/vagina/gaping)
			return "gaping"
		if(/datum/sprite_accessory/vagina/cloaca)
			return "cloacal"
	return "smooth"

/**
 * Syncs the character_flavor component for accessory-free movement and
 * sex-action flavor text. Removes any existing instance first to avoid
 * duplicates on re-apply (e.g., body swap, preference reload).
 *
 * The component only exists when the player has written character flavor
 * strings. There is no built-in accessory-free fallback bank.
 */
/datum/preferences/proc/apply_character_flavor_component(mob/living/carbon/human/H)
	if(!istype(H))
		return
	// Remove any pre-existing character flavor component to avoid dupes.
	var/datum/component/intimate_reaction/character_flavor/existing = H.GetComponent(/datum/component/intimate_reaction/character_flavor)
	if(existing)
		qdel(existing)
	if(!intimate_reaction_enabled || !has_custom_character_flavor_reactions())
		return
	H.AddComponent(/datum/component/intimate_reaction/character_flavor, src)
