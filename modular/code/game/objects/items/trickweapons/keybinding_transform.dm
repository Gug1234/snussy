/**
 * Keybinding: Transform Trick Weapon (Space)
 *
 * Hold-to-prime system for transform attacks:
 *   - TAP (press + release within TRANSFORM_HOLD_WINDOW): Normal transform.
 *   - HOLD (press, then LMB before release): Transform attack — transforms
 *     AND attacks in one action using transform_attack_intents.
 *
 * down() sets transform_key_held = TRUE and starts a fallback timer.
 * up() clears the flag. If no attack fired during the hold, performs
 * the normal transform on up() (or when the timer expires).
 */
/datum/keybinding/living/trick_transform
	hotkey_keys = list("Space")
	name = "trick_transform"
	full_name = "Transform Trick Weapon"
	description = "Transforms the trick weapon in your active hand. Hold + LMB for a transform attack."
	category = CATEGORY_HUMAN

/datum/keybinding/living/trick_transform/down(client/user)
	var/mob/living/L = user.mob
	if(!isliving(L))
		return FALSE
	var/obj/item/rogueweapon/trickweapon/TW = L.get_active_held_item()
	if(!istype(TW))
		return FALSE

	// Set held flag — the attack() override checks this for transform attacks
	TW.transform_key_held = TRUE

	// Start a fallback timer: if the player doesn't attack or release within
	// the hold window, treat it as a tap (normal transform).
	addtimer(CALLBACK(TW, TYPE_PROC_REF(/obj/item/rogueweapon/trickweapon, transform_hold_timeout), L), TRANSFORM_HOLD_WINDOW)
	return TRUE

/datum/keybinding/living/trick_transform/up(client/user)
	var/mob/living/L = user.mob
	if(!isliving(L))
		return FALSE
	var/obj/item/rogueweapon/trickweapon/TW = L.get_active_held_item()
	if(!istype(TW))
		return FALSE

	if(TW.transform_key_held)
		// Key released without an attack firing — do normal transform
		TW.transform_key_held = FALSE
		TW.transform_weapon(L)
	return TRUE

