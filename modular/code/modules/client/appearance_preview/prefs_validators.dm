/*
 * prefs_validators.dm — Value validators for the TGUI preferences menu
 * dispatch framework (Step 3).
 *
 * Scope:
 *   Each validator is a plain /proc that returns TRUE iff the inbound
 *   value from `ui_act("set_pref", {key, value})` is well-formed for the
 *   destination /datum/preferences var. Validators NEVER mutate state
 *   and NEVER call into /datum/preferences — they are side-effect-free
 *   so the dispatcher can safely short-circuit on FALSE without having
 *   to unwind partial writes.
 *
 *   The contract intentionally mirrors what a TGUI payload can carry:
 *     - bool        -> BYOND num 0/1 or text "0"/"1"
 *     - intrange    -> BYOND num inside [min, max]
 *     - enum        -> value appears in an allow-list
 *     - hex color   -> "#RRGGBB" or "RRGGBB"
 *     - string      -> text, length <= cap, printable subset
 *
 * Security note:
 *   Validators are the first gate before GLOB.prefs_setter_table dispatch
 *   reaches a registered setter procpath. Any key whose validator returns
 *   FALSE is dropped silently server-side (with a rate-limited log in the
 *   dispatcher itself — see prefs_set_pref_dispatch.dm).
 */

/**
 * Boolean validator.
 *
 * Accepts BYOND-native FALSE/TRUE (0/1), as well as the text form that
 * TGUI's JSON layer may emit for checkbox state. Rejects everything else.
 *
 * Arguments:
 *   value — the raw payload from ui_act.
 * Returns:
 *   TRUE if the value is 0, 1, "0", or "1"; FALSE otherwise.
 */
/proc/prefs_validate_bool(value)
	if(isnum(value))
		return (value == 0) || (value == 1)
	if(istext(value))
		return (value == "0") || (value == "1")
	return FALSE

/**
 * Integer-range validator factory.
 *
 * Since DM has no first-class closures, this returns a /datum/callback
 * that /datum/prefs_setter can invoke. The returned callback encloses
 * the min/max bounds by value.
 *
 * Arguments:
 *   min — inclusive lower bound.
 *   max — inclusive upper bound.
 * Returns:
 *   /datum/callback bound to prefs_validate_intrange_impl with the
 *   captured bounds.
 */
/proc/prefs_validate_intrange(min, max)
	return CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(prefs_validate_intrange_impl), min, max)

/**
 * Bound target for prefs_validate_intrange. Exported so the callback
 * registry can resolve it at init; not intended for direct use.
 */
/proc/prefs_validate_intrange_impl(min, max, value)
	if(!isnum(value))
		return FALSE
	if(value < min || value > max)
		return FALSE
	// Reject non-integer payloads; BYOND's num covers floats too and
	// the savefile ints need to round-trip cleanly.
	return (round(value) == value)

/**
 * Enum validator factory. Accepts any value present in the supplied
 * allow-list. The list is captured by reference, so callers MUST pass a
 * static/immutable list (populate once at init).
 *
 * Arguments:
 *   allowed — list of permitted values (numbers or strings).
 * Returns:
 *   /datum/callback bound to prefs_validate_enum_impl.
 */
/proc/prefs_validate_enum(list/allowed)
	return CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(prefs_validate_enum_impl), allowed)

/proc/prefs_validate_enum_impl(list/allowed, value)
	if(!islist(allowed) || !length(allowed))
		return FALSE
	return (value in allowed)

/**
 * Hex color validator. Accepts "#RRGGBB" and "RRGGBB" (no alpha). Short
 * form (#RGB) is rejected — we store canonical 6-digit hex to keep
 * sanitize_hexcolor's downstream behavior predictable.
 *
 * Arguments:
 *   value — string payload.
 * Returns:
 *   TRUE if the string matches the 6-digit hex shape.
 */
/proc/prefs_validate_hex(value)
	if(!istext(value))
		return FALSE
	var/len = length(value)
	var/start = 1
	if(len == 7)
		if(copytext(value, 1, 2) != "#")
			return FALSE
		start = 2
	else if(len != 6)
		return FALSE
	for(var/i in start to (start + 5))
		var/c = text2ascii(value, i)
		// 0-9, a-f, A-F
		if((c >= 48 && c <= 57) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102))
			continue
		return FALSE
	return TRUE

/**
 * String validator factory. Enforces a length cap; the cap is small
 * enough that the committed savefile entry never exceeds the 64 KB
 * per-entry ceiling (large text blobs belong in sidecars).
 *
 * Arguments:
 *   max_len — inclusive maximum length in characters.
 * Returns:
 *   /datum/callback bound to prefs_validate_string_impl.
 */
/proc/prefs_validate_string(max_len)
	return CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(prefs_validate_string_impl), max_len)

/proc/prefs_validate_string_impl(max_len, value)
	if(!istext(value))
		return FALSE
	if(length(value) > max_len)
		return FALSE
	return TRUE

/**
 * Permissive validator. Used only by the persist-only sentinel setter
 * (PREF_KEY_PERSIST_ONLY): value content is ignored, the entry exists
 * solely so prefs_apply_commit accepts a flush envelope when the only
 * dirt is from a collection-shaped envelope (loadout, piercings, ...).
 */
/proc/prefs_validate_anything(value)
	return TRUE
