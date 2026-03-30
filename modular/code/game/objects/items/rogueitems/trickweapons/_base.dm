// ====================================================================
// TRICK WEAPON SYSTEM - Bloodborne-style transforming weapons
// ====================================================================
// Each trick weapon has two distinct states with unique intents, stats,
// and visual profiles. Transformation is triggered via RMB on the held
// weapon (rmb_self). The base class caches both states and swaps them
// on transform, calling update_a_intents() to refresh the combat HUD.
// ====================================================================

// ===================== BASE TRICK WEAPON CLASS =====================

/**
 * /obj/item/rogueweapon/trickweapon
 *
 * Base class for Bloodborne-style transforming weapons. Each subtype
 * defines two states (base and transformed) with separate names, descs,
 * icon_states, forces, intents, and sound profiles.
 *
 * Transformation is triggered via rmb_self (right-click while held).
 * The base class caches the "other" state's data and swaps everything
 * on transform, then calls update_a_intents() to refresh the HUD.
 *
 * Subtypes MUST set the `transformed_*` vars for the second state.
 */
/obj/item/rogueweapon/trickweapon
	icon = 'modular/icons/obj/trickweapons/trickweapons.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/rogue_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/rogue_righthand.dmi'
	anvilrepair = /datum/skill/craft/weaponsmithing
	smeltresult = /obj/item/ingot/steel
	flags_1 = CONDUCT_1
	resistance_flags = FIRE_PROOF
	obj_flags = CAN_BE_HIT | UNIQUE_RENAME
	dropshrink = 0.5
	gripsprite = FALSE

	/// Whether the weapon is currently in its transformed state.
	var/transformed = FALSE

	// --- Transformed state vars (set by subtypes) ---
	/// Name when transformed.
	var/transformed_name
	/// Description when transformed.
	var/transformed_desc
	/// Icon state when transformed.
	var/transformed_icon_state
	/// Item state when transformed.
	var/transformed_item_state
	/// Force when transformed (1H).
	var/transformed_force = 0
	/// Force when transformed (2H wielded).
	var/transformed_force_wielded = 0
	/// 1H intents for the transformed state.
	var/list/transformed_intents
	/// 2H intents for the transformed state.
	var/list/transformed_gripped_intents
	/// Swing sound when transformed.
	var/transformed_swingsound
	/// Weapon length when transformed.
	var/transformed_wlength
	/// Weapon balance when transformed.
	var/transformed_wbalance
	/// Weapon defense when transformed.
	var/transformed_wdefense
	/// Weapon defense wielding bonus when transformed.
	var/transformed_wdefense_wbonus
	/// Minimum STR when transformed.
	var/transformed_minstr
	/// Associated skill when transformed.
	var/transformed_associated_skill
	/// Sharpness when transformed.
	var/transformed_sharpness
	/// Weight class when transformed.
	var/transformed_w_class

	// --- Firearm hybrid system vars (for gun-weapons like Reiterpallasch, Rifle Spear) ---
	/// The ammo type this weapon consumes for shot intents. Null = no shot capability.
	var/shot_ammo_type
	/// Damage dealt by the shot intent (overrides normal force calculation).
	var/shot_damage = 0
	/// Armor penetration for the shot intent.
	var/shot_ap = 0

	// --- Cached base state vars (populated on Initialize) ---
	var/base_name
	var/base_desc
	var/base_icon_state
	var/base_item_state
	var/base_force
	var/base_force_wielded
	var/list/base_intents
	var/list/base_gripped_intents
	var/base_swingsound
	var/base_wlength
	var/base_wbalance
	var/base_wdefense
	var/base_wdefense_wbonus
	var/base_minstr
	var/base_associated_skill
	var/base_sharpness
	var/base_w_class

/// Disable blood decals on trick weapons to prevent visual artifacts with custom sprites.
/obj/item/rogueweapon/trickweapon/add_blood_DNA(list/dna)
	return FALSE

/obj/item/rogueweapon/trickweapon/Initialize(mapload)
	. = ..()
	// Cache base state from initial values
	base_name = name
	base_desc = desc
	base_icon_state = icon_state
	base_item_state = item_state
	base_force = force
	base_force_wielded = force_wielded
	base_intents = possible_item_intents
	base_gripped_intents = gripped_intents
	base_swingsound = swingsound
	base_wlength = wlength
	base_wbalance = wbalance
	base_wdefense = wdefense
	base_wdefense_wbonus = wdefense_wbonus
	base_minstr = minstr
	base_associated_skill = associated_skill
	base_sharpness = sharpness
	base_w_class = w_class

/**
 * Core transformation proc. Ungrips if needed, swaps all state vars
 * between base and transformed, updates visuals, and refreshes intents.
 */
/obj/item/rogueweapon/trickweapon/proc/transform_weapon(mob/living/user)
	// Ungrip before transforming to avoid stale wielded state
	if(wielded || altgripped)
		ungrip(user, show_message = FALSE)

	transformed = !transformed

	if(transformed)
		apply_transformed_state()
	else
		apply_base_state()

	// Update the visual and combat state
	update_icon()
	update_force_dynamic()
	wdefense_dynamic = wdefense
	playsound(loc, 'sound/combat/clash_draw.ogg', 100, TRUE)
	to_chat(user, span_notice("I transform [src]."))
	if(user.get_active_held_item() == src)
		user.update_a_intents()
		user.update_inv_hands()

/// Applies the transformed state's vars to the weapon.
/obj/item/rogueweapon/trickweapon/proc/apply_transformed_state()
	name = transformed_name
	desc = transformed_desc
	icon_state = transformed_icon_state
	item_state = transformed_item_state
	force = transformed_force
	force_wielded = transformed_force_wielded
	possible_item_intents = transformed_intents
	gripped_intents = transformed_gripped_intents
	swingsound = transformed_swingsound
	wlength = transformed_wlength
	wbalance = transformed_wbalance
	wdefense = transformed_wdefense
	wdefense_wbonus = transformed_wdefense_wbonus
	minstr = transformed_minstr
	associated_skill = transformed_associated_skill
	sharpness = transformed_sharpness
	w_class = transformed_w_class

/// Restores the base state's vars to the weapon.
/obj/item/rogueweapon/trickweapon/proc/apply_base_state()
	name = base_name
	desc = base_desc
	icon_state = base_icon_state
	item_state = base_item_state
	force = base_force
	force_wielded = base_force_wielded
	possible_item_intents = base_intents
	gripped_intents = base_gripped_intents
	swingsound = base_swingsound
	wlength = base_wlength
	wbalance = base_wbalance
	wdefense = base_wdefense
	wdefense_wbonus = base_wdefense_wbonus
	minstr = base_minstr
	associated_skill = base_associated_skill
	sharpness = base_sharpness
	w_class = base_w_class

// ===================== FIREARM HYBRID SYSTEM =====================
// For gun-weapons (Reiterpallasch, Rifle Spear) that have shot intents
// requiring ammo consumption. Shot intents are identified by having
// a `requires_ammo` var set to TRUE on the intent datum.

/**
 * Searches the user's inventory for one unit of the weapon's shot_ammo_type.
 * Checks hands first, then all carried items (including quiver/bullet pouches
 * which store ammo in their `arrows` list rather than `contents`).
 *
 * Returns TRUE and deletes 1 ammo on success, FALSE on failure.
 */
/obj/item/rogueweapon/trickweapon/proc/consume_ammo(mob/living/user)
	if(!shot_ammo_type)
		return FALSE

	// Check hands first
	for(var/obj/item/I in user.held_items)
		if(I == src)
			continue
		if(istype(I, shot_ammo_type))
			qdel(I)
			return TRUE

	// Check all carried items, including inside quiver/bullet pouches
	for(var/obj/item/carried in user.get_contents())
		// Direct ammo in inventory
		if(istype(carried, shot_ammo_type))
			qdel(carried)
			return TRUE
		// Ammo stored in bullet pouches (uses `arrows` list, not `contents`)
		if(istype(carried, /obj/item/quiver/bullet))
			var/obj/item/quiver/bullet/pouch = carried
			for(var/obj/item/ammo in pouch.arrows)
				if(istype(ammo, shot_ammo_type))
					pouch.arrows -= ammo
					qdel(ammo)
					pouch.update_icon()
					return TRUE

	return FALSE

/**
 * Pre-attack hook for gun-trick weapons. If the user's current intent
 * has `requires_ammo = TRUE`, attempt to consume ammo. On failure,
 * produce a dry-fire click and cancel the attack chain.
 */
/obj/item/rogueweapon/trickweapon/pre_attack(atom/A, mob/living/user, params)
	if(shot_ammo_type && user.used_intent)
		var/datum/intent/I = user.used_intent
		if(I.vars.Find("requires_ammo") && I.vars["requires_ammo"])
			if(!consume_ammo(user))
				to_chat(user, span_warning("[src] clicks — no ammunition!"))
				playsound(loc, 'sound/combat/parry/bladed/bladedthin (1).ogg', 50, TRUE)
				user.changeNext_move(CLICK_CD_MELEE)
				return TRUE
	return ..()

/**
 * Override wield to swap to 64x64 two-handed sprites.
 * Appends "1" to icon_state and item_state so generateonmob picks
 * up the correct wielded sprite (e.g. "sawcleaver" -> "sawcleaver1").
 */
/obj/item/rogueweapon/trickweapon/wield(mob/living/carbon/user, show_message = TRUE)
	. = ..()
	if(!wielded)
		return
	icon_state = "[icon_state]1"
	item_state = "[item_state]1"
	user.update_inv_hands()

/**
 * Override ungrip to restore the correct icon_state before the parent
 * calls update_transform() and update_inv_hands(). Strips the "1"
 * suffix by restoring the current form's cached icon_state.
 */
/obj/item/rogueweapon/trickweapon/ungrip(mob/living/carbon/user, show_message = TRUE)
	if(wielded)
		if(transformed)
			icon_state = transformed_icon_state
			item_state = transformed_item_state
		else
			icon_state = base_icon_state
			item_state = base_item_state
	. = ..()

/**
 * Overrides rmb_self to trigger transformation instead of alt-grip.
 * Trick weapons use their transformation as their right-click action.
 */
/obj/item/rogueweapon/trickweapon/rmb_self(mob/user)
	if(!isliving(user))
		return
	var/mob/living/L = user
	if(L.get_active_held_item() != src)
		return
	transform_weapon(L)

