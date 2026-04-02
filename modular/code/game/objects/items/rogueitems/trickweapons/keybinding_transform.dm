/**
 * Keybinding: Transform Trick Weapon (Space)
 *
 * Allows the player to transform their held trick weapon by pressing Space.
 * Only fires when the active held item is a trick weapon.
 */
/datum/keybinding/living/trick_transform
	hotkey_keys = list("Space")
	name = "trick_transform"
	full_name = "Transform Trick Weapon"
	description = "Transforms the trick weapon in your active hand."
	category = CATEGORY_HUMAN

/datum/keybinding/living/trick_transform/down(client/user)
	var/mob/living/L = user.mob
	if(!isliving(L))
		return FALSE
	var/obj/item/rogueweapon/trickweapon/TW = L.get_active_held_item()
	if(!istype(TW))
		return FALSE
	TW.transform_weapon(L)
	return TRUE

