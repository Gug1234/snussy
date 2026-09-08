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
 * Transformation is triggered via rmb_self or the space bar (right-click while held).
 * The base class caches the "other" state's data and swaps everything
 * on transform, then calls update_a_intents() to refresh the HUD.
 *
 * Subtypes MUST set the `transformed_*` vars for the second state.
 */
/obj/item/rogueweapon/trickweapon
	name = "trick weapon base DO NOT MAP, DO NOT SPAWN"
	desc = "This is a base class for trick weapons. If you're seeing this, something went wrong with the inheritance. Notify a maintainer."
	icon = 'modular/icons/obj/trickweapons/trickweapons.dmi'
	icon_state = "base_trickweapon"
	item_state = "base_trickweapon"
	lefthand_file = 'icons/mob/inhands/weapons/rogue_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/rogue_righthand.dmi'
	anvilrepair = /datum/skill/craft/weaponsmithing
	smeltresult = /obj/item/ingot/steel
	flags_1 = CONDUCT_1
	resistance_flags = FIRE_PROOF
	obj_flags = CAN_BE_HIT | UNIQUE_RENAME
	dropshrink = 0.7
	hudshrink = 0
	gripsprite = FALSE

	/// Whether the weapon is currently in its transformed state.
	var/transformed = FALSE

	// --- Transformed state vars (set by subtypes) ---
	/// Name when transformed.
	var/transformed_name = "transformed name not set. Change the transformed_name var in the item's code to fix this."
	/// Description when transformed.
	var/transformed_desc = "Transformed description not set. Change the transformed_desc var in the item's code to fix this."
	/// Icon state when transformed.
	var/transformed_icon_state = "base_trickweapon_t"
	/// Item state when transformed.
	var/transformed_item_state = "base_trickweapon_t"
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

	// --- Transformation sound vars ---
	/// Sound played when transforming from base to transformed state.
	/// Override in subtypes with weapon-specific sounds from modular/sounds/trickweapons/.
	var/transform_sound = 'sound/combat/clash_draw.ogg'
	/// Sound played when reverting from transformed back to base state.
	/// If null, falls back to transform_sound.
	var/untransform_sound

	// --- Serrated damage system vars ---
	/// Whether this weapon currently has a serrated edge that deals bonus damage to beasts and anthromorphs.
	var/serrated = FALSE
	/// Bonus damage multiplier applied to force_dynamic against qualifying targets. 0.2 = 20% extra.
	var/serrated_bonus = 0.2
	/// Cached base form serrated state (populated on Initialize from initial serrated value).
	var/base_serrated
	/// Serrated state when transformed. Null = same as base. Set explicitly for per-form toggling.
	var/transformed_serrated

	// --- Dual Wielder trait scaling vars ---
	/// Bonus force added to force_dynamic when the wielder has TRAIT_DUALWIELDER. 0 = no bonus.
	var/dualwielder_force_bonus = 0
	/// Bonus wdefense added to wdefense_dynamic when the wielder has TRAIT_DUALWIELDER. 0 = no bonus.
	var/dualwielder_wdefense_bonus = 0

	// --- Anti-trick weapon defense vars ---
	/// Bonus dodge chance when defending against an attacker using a trick weapon. 0 = no bonus.
	var/anti_trickweapon_dodge_bonus = 0
	/// Bonus parry chance when defending against an attacker using a trick weapon. 0 = no bonus.
	var/anti_trickweapon_parry_bonus = 0

	// --- Combo system tracking (v3 — true combo sequences) ---
	/// Ring buffer of combo_id strings from recent attacks. Max length = combo_buffer_max.
	var/list/combo_buffer
	/// Max entries in the combo buffer before oldest are dropped.
	var/combo_buffer_max = 8
	/// Current position in a same-intent combo chain (0-indexed).
	var/combo_index = 0
	/// world.time of the last attack. Used for combo window timeout.
	var/last_attack_time = 0
	/// Type path of the intent used on the last attack.
	var/last_intent_type
	/// Cached reference to the last intent datum instance.
	var/datum/intent/last_intent_ref
	/// Weakref to the last mob attacked. Combo resets on target switch.
	var/datum/weakref/combo_target
	/// List of /datum/trickweapon_combo defined for this weapon. Set by subtypes.
	var/list/defined_combos

	// --- Zone tracking ---
	/// Parent zones hit this combo chain.
	var/list/combo_zones_hit
	/// Running wound severity bonus from zone diversity.
	var/combo_zone_bonus = 0

	// --- Impact FX system ---
	/// Master toggle for the variable hit sound + VFX system.
	var/impact_fx_enabled = TRUE
	/// Cached last matched combo from process_combo, used by play_impact_vfx for finisher escalation.
	var/datum/trickweapon_combo/last_matched_combo

	// --- Transform attack tracking ---
	/// Is the transform keybind currently held down?
	var/transform_key_held = FALSE
	/// Was the last action in the chain a transform (Space tap)?
	var/last_was_transform = FALSE

	// --- Transform attack intents ---
	/// 1H intents for base→transformed transform attack. list() of type paths.
	var/list/transform_attack_intents
	/// 2H intents for base→transformed transform attack.
	var/list/transform_attack_gripped_intents
	/// 1H intents for transformed→base untransform attack.
	var/list/untransform_attack_intents
	/// 2H intents for transformed→base untransform attack.
	var/list/untransform_attack_gripped_intents

	// --- Running attack intents (auto-selected when on run intent + LMB) ---
	/// Running attack intent for base 1H. Type path.
	var/running_intent_base
	/// Running attack intent for base 2H.
	var/running_intent_base_grip
	/// Running attack intent for transformed 1H.
	var/running_intent_tfm
	/// Running attack intent for transformed 2H.
	var/running_intent_tfm_grip

	// --- Running transform attack intents ---
	/// Running base→transformed transform attack intent (run + hold Space + LMB).
	var/running_transform_intent
	/// Running transformed→base untransform attack intent.
	var/running_untransform_intent

	// --- Lunge attack intents (jump intent + MMB on mob) ---
	/// Lunge intent for base 1H. Type path.
	var/lunge_intent_base
	/// Lunge intent for base 2H.
	var/lunge_intent_base_grip
	/// Lunge intent for transformed 1H.
	var/lunge_intent_tfm
	/// Lunge intent for transformed 2H.
	var/lunge_intent_tfm_grip

	// --- Extra intent cache (running/transform/lunge intents that aren't in HUD lists) ---
	/// Assoc list mapping "[type_path]" → instantiated /datum/intent. Lazily populated by find_intent_on_weapon().
	var/list/cached_extra_intents

	// --- Lunge execution flag ---
	/// TRUE while a lunge attack is being executed. Prevents resolve_attack_intent from overriding the lunge intent.
	var/executing_lunge = FALSE

	// --- Transform cooldown ---
	/// Cooldown timer to prevent keyboard-repeat double-fires on the Space keybinding.
	COOLDOWN_DECLARE(transform_cd)

	// --- Transform spam detection vars ---
	/// Number of transforms recorded in the current rolling window.
	var/transform_spam_count = 0
	/// world.time when the rolling window started. Resets after TRANSFORM_SPAM_WINDOW elapses.
	var/transform_spam_window_start = 0
	/// Whether admins have already been alerted for the current spam burst (prevents alert flood).
	var/transform_spam_alerted = FALSE

	// --- Firearm hybrid system vars (for gun-weapons like Reiterpallasch, Rifle Spear) ---
	/// The ammo type this weapon consumes for shot intents. Null = no shot capability.
	var/shot_ammo_type
	/// Damage dealt by the shot intent (overrides normal force calculation).
	var/shot_damage = 0
	/// Armor penetration for the shot intent.
	var/shot_ap = 0

	// --- Per-form weapon special vars ---
	/// Weapon special (strong intent right-click ability) for the transformed state.
	/// Set as a path on the subtype; instantiated on Initialize.
	/// Null = no special in that form. Each form can have a different special or none.
	var/datum/special_intent/transformed_special
	/// Cached base form weapon special (populated on Initialize from the inherited `special` var).
	var/datum/special_intent/base_special

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

	// Cache the base form special (already instantiated by parent Initialize)
	base_special = special
	// Instantiate the transformed special if set as a path
	if(ispath(transformed_special))
		transformed_special = new transformed_special()

	// Cache the initial serrated state as the base form value
	base_serrated = serrated
	// If transformed_serrated was never set, default it to match base
	if(isnull(transformed_serrated))
		transformed_serrated = serrated

	// Register serrated bonus signal if this weapon starts serrated
	update_serrated_signal()

/// Transforms within the rolling window before a warning is issued to the player.
#define TRANSFORM_SPAM_WARN_THRESHOLD 10
/// Transforms within the rolling window before the weapon explodes and dismembers the holding arm.
#define TRANSFORM_SPAM_EXPLODE_THRESHOLD 30
/// Rolling window duration in deciseconds (10 seconds).
#define TRANSFORM_SPAM_WINDOW (10 SECONDS)

/**
 * Core transformation proc. Ungrips if needed, swaps all state vars
 * between base and transformed, updates visuals, and refreshes intents.
 *
 * Includes a multi-stage rolling-window spam penalty:
 *   - 10 transforms: IC warning to the player + admin alert
 *   - 30 transforms: weapon explodes, dismembers holding arm, painscream,
 *     bold visible_message, and admin log
 */
/obj/item/rogueweapon/trickweapon/proc/transform_weapon(mob/living/user)
	// --- Transform cooldown (prevents keyboard-repeat double-fires) ---
	if(!COOLDOWN_FINISHED(src, transform_cd))
		return
	COOLDOWN_START(src, transform_cd, 3) // 0.3 seconds

	// --- Transform spam detection ---
	var/now = world.time
	if(now - transform_spam_window_start > TRANSFORM_SPAM_WINDOW)
		// Window expired — reset counter
		transform_spam_count = 0
		transform_spam_window_start = now
		transform_spam_alerted = FALSE
	transform_spam_count++

	// Stage 1: Warning at 10 transforms
	if(transform_spam_count >= TRANSFORM_SPAM_WARN_THRESHOLD && !transform_spam_alerted)
		transform_spam_alerted = TRUE
		to_chat(user, span_userdanger("[src] begins to grow unstable from the rapid transformations. It'd probably be a good idea to stop..."))
		message_admins("TRICK WEAPON SPAM: [ADMIN_LOOKUPFLW(user)] transformed [src] [transform_spam_count] times in [TRANSFORM_SPAM_WINDOW / 10] seconds.")
		log_game("TRICK WEAPON SPAM: [key_name(user)] transformed [src] [transform_spam_count] times in [TRANSFORM_SPAM_WINDOW / 10] seconds at [AREACOORD(user)].")

	// Stage 2: Explosion at 30 transforms — dismember arm, destroy weapon
	if(transform_spam_count >= TRANSFORM_SPAM_EXPLODE_THRESHOLD)
		transform_spam_explode(user)
		return

	// Remember grip state so we can restore it after the swap
	var/was_wielded = wielded
	var/was_altgripped = altgripped

	// Ungrip before swapping vars to avoid stale state
	if(wielded || altgripped)
		ungrip(user, show_message = FALSE)

	transformed = !transformed

	if(transformed)
		apply_transformed_state()
	else
		apply_base_state()

	// Invalidate the cached onmob property data so update_inv_hands()
	// fetches fresh offsets from getonmobprop() for the new form.
	onprop = null

	// Update the visual and combat state
	update_icon()
	update_force_dynamic()
	update_wdefense_dynamic()
	var/active_sound = transformed ? transform_sound : (untransform_sound || transform_sound)
	playsound(loc, active_sound, 100, TRUE)
	do_sparks(3, FALSE, src)
	to_chat(user, span_notice("I transform [src]."))

	// Restore grip state — weapon stays two-handed across transformations
	if(was_wielded && !was_altgripped)
		wield(user, show_message = FALSE)
	else if(was_altgripped)
		altgrip(user)

	if(user.get_active_held_item() == src)
		user.update_a_intents()
		user.update_inv_hands()

/**
 * Timer callback for transform hold-to-prime. If the flag is still set
 * when the timer fires, the player held Space but didn't attack —
 * treat as a tap and do normal transform.
 */
/obj/item/rogueweapon/trickweapon/proc/transform_hold_timeout(mob/living/user)
	if(!transform_key_held)
		return // Already consumed by attack or up()
	transform_key_held = FALSE
	transform_weapon(user)


/**
 * Punishment proc for extreme transform spam. The weapon explodes violently,
 * dismembering whichever arm was holding it, forces a painscream, broadcasts
 * a bold message to nearby players, and logs the event.
 */
/obj/item/rogueweapon/trickweapon/proc/transform_spam_explode(mob/living/carbon/human/user)
	if(!istype(user))
		return

	// Determine which arm is holding the weapon
	var/held_idx = user.get_held_index_of_item(src)
	if(isnull(held_idx))
		held_idx = user.active_hand_index || 1 // Fall back to active hand, then left
	var/arm_zone = (held_idx % 2) ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM // Odd = left, Even = right

	// Drop and destroy the weapon
	var/weapon_name = name
	user.dropItemToGround(src, force = TRUE)
	visible_message(span_boldwarning("[src] violently explodes in a shower of shrapnel!"))
	playsound(user, 'sound/misc/explode/bomb.ogg', 100, TRUE)
	new /obj/effect/temp_visual/explosion/fast(get_turf(user))
	qdel(src)

	// Dismember the arm that was holding the weapon (admin_dismember bypasses armor)
	var/obj/item/bodypart/arm = user.get_bodypart(arm_zone)
	if(arm)
		arm.admin_dismember(BRUTE, BCLASS_BLUNT)

	// Force a painscream
	user.emote("painscream")

	// Bold message to everyone nearby explaining what happened
	user.visible_message(span_boldwarning("[user] blew [user.p_their()] own arm off by spamming [weapon_name]'s transformation mechanism!"), \
		span_userdanger("The rapid transformations overloaded [weapon_name] — it explodes, taking my arm with it!"))

	// Log to admins
	message_admins("TRICK WEAPON EXPLOSION: [ADMIN_LOOKUPFLW(user)] hit [TRANSFORM_SPAM_EXPLODE_THRESHOLD] transforms in [TRANSFORM_SPAM_WINDOW / 10]s — [weapon_name] exploded and dismembered their [arm_zone == BODY_ZONE_L_ARM ? "left" : "right"] arm.")
	log_game("TRICK WEAPON EXPLOSION: [key_name(user)] hit [TRANSFORM_SPAM_EXPLODE_THRESHOLD] transforms in [TRANSFORM_SPAM_WINDOW / 10]s — [weapon_name] exploded and dismembered their [arm_zone == BODY_ZONE_L_ARM ? "left" : "right"] arm at [AREACOORD(user)].")

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
	special = transformed_special
	serrated = transformed_serrated
	update_serrated_signal()

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
	special = base_special
	serrated = base_serrated
	update_serrated_signal()

// ===================== FIREARM HYBRID SYSTEM =====================
// For gun-weapons (Reiterpallasch, Rifle Spear) that have shot intents
// requiring ammo consumption. Shot intents are identified by having
// a `requires_ammo` var set to TRUE on the intent datum.

/// consume_ammo return: ammo found and consumed successfully.
#define AMMO_RESULT_CONSUMED 1
/// consume_ammo return: no ammo of any kind found.
#define AMMO_RESULT_NONE 2
/// consume_ammo return: ammo found, but wrong type for this weapon.
#define AMMO_RESULT_WRONG_TYPE 3

/**
 * Searches the user's inventory for one unit of the weapon's shot_ammo_type.
 * Checks hands first, then all carried items (including quiver/bullet pouches
 * which store ammo in their `arrows` list rather than `contents`).
 *
 * Returns AMMO_RESULT_CONSUMED on success, AMMO_RESULT_NONE or
 * AMMO_RESULT_WRONG_TYPE on failure. This single-pass approach avoids
 * calling get_contents() twice when the failure path needs wrong-ammo info.
 */
/obj/item/rogueweapon/trickweapon/proc/consume_ammo(mob/living/user)
	if(!shot_ammo_type)
		return AMMO_RESULT_NONE

	var/found_wrong_ammo = FALSE

	// Check hands first
	for(var/obj/item/I in user.held_items)
		if(I == src)
			continue
		if(istype(I, shot_ammo_type))
			qdel(I)
			return AMMO_RESULT_CONSUMED
		if(istype(I, /obj/item/ammo_casing))
			found_wrong_ammo = TRUE

	// Check all carried items, including inside quiver/bullet pouches
	for(var/obj/item/carried in user.get_contents())
		// Direct ammo in inventory
		if(istype(carried, shot_ammo_type))
			qdel(carried)
			return AMMO_RESULT_CONSUMED
		if(istype(carried, /obj/item/ammo_casing))
			found_wrong_ammo = TRUE
		// Ammo stored in bullet pouches (uses `arrows` list, not `contents`)
		if(istype(carried, /obj/item/quiver/bullet))
			var/obj/item/quiver/bullet/pouch = carried
			for(var/obj/item/ammo in pouch.arrows)
				if(istype(ammo, shot_ammo_type))
					pouch.arrows -= ammo
					qdel(ammo)
					pouch.update_icon()
					return AMMO_RESULT_CONSUMED
			if(length(pouch.arrows))
				found_wrong_ammo = TRUE

	return found_wrong_ammo ? AMMO_RESULT_WRONG_TYPE : AMMO_RESULT_NONE

/**
 * Pre-attack hook for gun-trick weapons. If the user's current intent
 * has `requires_ammo = TRUE`, attempt to consume ammo. On failure,
 * produce a dry-fire click and cancel the attack chain.
 */
/obj/item/rogueweapon/trickweapon/pre_attack(atom/A, mob/living/user, params)
	if(shot_ammo_type && user.used_intent)
		var/datum/intent/I = user.used_intent
		if(intent_requires_ammo(I))
			var/ammo_result = consume_ammo(user)
			if(ammo_result != AMMO_RESULT_CONSUMED)
				if(ammo_result == AMMO_RESULT_WRONG_TYPE)
					var/obj/item/ammo_type_ref = shot_ammo_type
					to_chat(user, span_warning("[src] clicks — wrong ammunition! It requires [initial(ammo_type_ref.name)]."))
				else
					to_chat(user, span_warning("[src] clicks — no ammunition!"))
				playsound(loc, 'sound/combat/parry/bladed/bladedthin (1).ogg', 50, TRUE)
				user.changeNext_move(CLICK_CD_MELEE)
				return TRUE
	return ..()

/**
 * Returns TRUE if the given intent datum has a requires_ammo var set to TRUE.
 * Used by pre_attack to determine whether to consume ammo for firearm intents.
 * Checks via istype against known gun-intent subtypes rather than var reflection.
 */
/obj/item/rogueweapon/trickweapon/proc/intent_requires_ammo(datum/intent/I)
	if(istype(I, /datum/intent/riflespear/rifleblast))
		return TRUE
	if(istype(I, /datum/intent/reiter/pistolshot))
		return TRUE
	return FALSE

/**
 * Override update_force_dynamic to inject the dual wielder force bonus.
 * Checks if the holder has TRAIT_DUALWIELDER and adds the bonus on top
 * of the base force_dynamic calculation.
 */
/obj/item/rogueweapon/trickweapon/update_force_dynamic()
	..()
	if(dualwielder_force_bonus && isliving(loc) && HAS_TRAIT(loc, TRAIT_DUALWIELDER))
		force_dynamic += dualwielder_force_bonus

/**
 * Calculates and sets wdefense_dynamic, including the dual wielder bonus.
 * Mirrors the base game logic: unwielded = wdefense, wielded = wdefense + wdefense_wbonus.
 * Adds dualwielder_wdefense_bonus on top when the holder has TRAIT_DUALWIELDER.
 */
/obj/item/rogueweapon/trickweapon/proc/update_wdefense_dynamic()
	if(wielded || altgripped)
		wdefense_dynamic = wdefense + wdefense_wbonus
	else
		wdefense_dynamic = wdefense
	if(dualwielder_wdefense_bonus && isliving(loc) && HAS_TRAIT(loc, TRAIT_DUALWIELDER))
		wdefense_dynamic += dualwielder_wdefense_bonus

/**
 * Override wield to swap to 64x64 two-handed sprites.
 * Appends "1" to icon_state and item_state so generateonmob picks
 * up the correct wielded sprite (e.g. "sawcleaver" -> "sawcleaver1").
 * Also recalculates wdefense_dynamic with dual wielder bonus.
 */
/obj/item/rogueweapon/trickweapon/wield(mob/living/carbon/user, show_message = TRUE)
	. = ..()
	if(!wielded)
		return
	update_wdefense_dynamic()
	icon_state = "[icon_state]1"
	item_state = "[item_state]1"
	user.update_inv_hands()

/**
 * Override ungrip to restore the correct icon_state before the parent
 * calls update_transform() and update_inv_hands(). Strips the "1"
 * suffix by restoring the current form's cached icon_state.
 * Also recalculates wdefense_dynamic with dual wielder bonus.
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
	update_wdefense_dynamic()

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

// ===================== SERRATED DAMAGE SYSTEM =====================
// Serrated trick weapons deal bonus brute damage against beasts and
// beast-adjacent species. Full bonus vs animals, monsters, werewolves,
// wildkin, lupians, venardines, and wildshape forms. Half bonus vs
// halfkin, lamia, and harpies who have partial beast heritage.
//
// The bonus is applied via COMSIG_ITEM_ATTACK_SUCCESS, which fires
// after defense checks pass but before attacked_by deals base damage.
// This keeps the serrated logic decoupled from the core attack flow.

/// Static list of species IDs that receive FULL serrated bonus damage.
/// Includes beast-kin, anthromorphs, werewolves, and druidic wildshapes.
GLOBAL_LIST_INIT(serrated_full_species, list(
	"werewolf",
	"anthromorph",
	"anthromorphsmall",
	"lupian",
	"vulpkanin",
	"tabaxi",
	"akula",
	"dracon",
	"lizardfolk",
	"kobold",
	"gnoll",
	"shapebear",
	"shapewolf",
	"shapecat",
	"shapefox",
	"shapecabbit",
	"shapespider",
	"shapesaiga",
))

/// Static list of species IDs that receive HALF serrated bonus damage.
/// These species have partial beast heritage but are more humanoid.
GLOBAL_LIST_INIT(serrated_half_species, list(
	"demihuman",
	"lamia",
	"harpy",
))

/**
 * Returns the serrated damage multiplier for the given target.
 * 1.0 = full bonus (beasts, anthromorphs, wildshapes)
 * 0.5 = half bonus (halfkin, lamia, harpies)
 * 0   = no bonus (humanoids, undead, etc.)
 *
 * Checks mob_biotypes first (MOB_BEAST for simple animals/monsters),
 * then falls back to species ID for carbon humanoids.
 */
/obj/item/rogueweapon/trickweapon/proc/get_serrated_multiplier(mob/living/target)
	// Simple animals and monsters with MOB_BEAST biotype get full bonus
	if(target.mob_biotypes & MOB_BEAST)
		return 1

	// Check species ID for humanoid carbon mobs
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.dna?.species)
			var/species_id = H.dna.species.id
			if(species_id in GLOB.serrated_full_species)
				return 1
			if(species_id in GLOB.serrated_half_species)
				return 0.5

	return 0

/**
 * Registers or unregisters the serrated bonus signal handler based on
 * the current value of `serrated`. Called during Initialize and on
 * each form swap to keep the signal in sync with the active form.
 */
/obj/item/rogueweapon/trickweapon/proc/update_serrated_signal()
	UnregisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS)
	if(serrated)
		RegisterSignal(src, COMSIG_ITEM_ATTACK_SUCCESS, PROC_REF(apply_serrated_bonus))

/**
 * Signal handler for COMSIG_ITEM_ATTACK_SUCCESS.
 * Applies bonus serrated brute damage to qualifying beast targets
 * after defense checks have passed. The bonus bypasses armor —
 * serrated edges are designed to rip through hide and flesh.
 */
/obj/item/rogueweapon/trickweapon/proc/apply_serrated_bonus(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	var/multiplier = get_serrated_multiplier(target)
	if(!multiplier)
		return
	var/bonus = round(force_dynamic * serrated_bonus * multiplier)
	if(bonus <= 0)
		return
	target.apply_damage(bonus, BRUTE)

/**
 * Appends serrated examine text when the weapon is inspected.
 */
/obj/item/rogueweapon/trickweapon/examine(mob/user)
	. = ..()
	if(serrated)
		. += span_warning("Its serrated edge is designed to rend beast flesh.")
	if(dualwielder_force_bonus || dualwielder_wdefense_bonus)
		. += span_notice("This weapon rewards a trained dual-wielding style with greater striking power and defensive finesse.")
	if(anti_trickweapon_dodge_bonus || anti_trickweapon_parry_bonus)
		. += span_notice("Designed to counter other trick weapons \u2014 grants an edge when parrying or dodging their strikes.")

// ===================== TRUE COMBO SYSTEM (v3) =====================
// Defined combo sequences with finisher bonuses. Random mashing = floor.
//
// System:
//   Ring buffer tracks the combo_id of each attack.
//   After each attack, check if buffer tail matches any defined combo.
//   Match → finisher bonus on the completing hit + buffer reset.
//   No match → floor damage (intent's raw damfactor).
//
// R1 chains (same intent repeated) ARE the simplest combos.
// Cross-intent sequences provide the big rewards.
// Transform attacks, running attacks, and lunges feed into the buffer.
// ================================================================

// --- Combo category defines (still useful for intent classification) ---
#define COMBO_CAT_LIGHT   "light"
#define COMBO_CAT_HEAVY   "heavy"
#define COMBO_CAT_THRUST  "thrust"
#define COMBO_CAT_BLUNT   "blunt"

/// Combo window multiplier applied to the last intent's clickcd.
#define COMBO_WINDOW_MULT 2.0
/// Wound severity bonus per unique parent zone hit in the combo.
#define COMBO_ZONE_BONUS_PER 0.05
/// Deciseconds for transform hold-to-prime window (tap vs hold detection).
#define TRANSFORM_HOLD_WINDOW 4
/// Lunge attack range in tiles.
#define LUNGE_RANGE 2
/// Lunge attack range when running.
#define LUNGE_RANGE_RUN 3
/// Duration of OffBalance debuff after landing a lunge (deciseconds).
#define LUNGE_OFFBALANCE 20
/// Duration of Immobilize debuff after landing a lunge (deciseconds).
#define LUNGE_IMMOBILIZE 10

// ===================== COMBO DEFINITION DATUM =====================

/**
 * /datum/trickweapon_combo
 *
 * Defines a named combo sequence for a trickweapon. When the combo buffer's
 * tail matches the full sequence, the finisher hit (the last in the sequence)
 * receives bonus damage and speed, and an optional finisher sound plays.
 */
/datum/trickweapon_combo
	/// Display name for the combo (used in future HUD/log).
	var/name = "combo"
	/// Ordered list of combo_id strings that must be executed in sequence.
	var/list/sequence
	/// Damage multiplier applied to the finisher hit (the one completing the combo).
	var/finisher_dam_mult = 1.15
	/// Clickcd speed multiplier applied to the finisher hit (< 1 = faster recovery).
	var/finisher_speed_mult = 1.0
	/// Optional sound list for the finisher hit (overrides normal swing sound).
	var/list/finisher_sound
	/// Optional hit sound override for the combo finisher (played on impact, not swing).
	var/list/finisher_hitsound
	/// VFX scale multiplier for the finisher. > 1 = bigger impact effect.
	var/finisher_vfx_scale = 1.0
	/// Difficulty tier for categorization: 1 = easy, 2 = medium, 3 = hard, 4 = expert.
	var/difficulty = 1

/datum/trickweapon_combo/New(_name, list/_sequence, _dam_mult = 1.15, _speed_mult = 1.0, list/_sound, _difficulty = 1, list/_hitsound, _vfx_scale = 1.0)
	..() 
	name = _name
	sequence = _sequence
	finisher_dam_mult = _dam_mult
	finisher_speed_mult = _speed_mult
	finisher_sound = _sound
	finisher_hitsound = _hitsound
	finisher_vfx_scale = _vfx_scale
	difficulty = _difficulty

/**
 * Helper to add a combo definition to this weapon's defined_combos list.
 */
/obj/item/rogueweapon/trickweapon/proc/add_combo(_name, list/_sequence, _dam_mult = 1.15, _speed_mult = 1.0, list/_sound, _difficulty = 1, list/_hitsound, _vfx_scale = 1.0)
	var/datum/trickweapon_combo/C = new(_name, _sequence, _dam_mult, _speed_mult, _sound, _difficulty, _hitsound, _vfx_scale)
	LAZYADD(defined_combos, C)

// ===================== COMBO BUFFER MANAGEMENT =====================

/**
 * Processes combo state for this attack. Called by the attack() override.
 *
 * 1. Handles timeout/target-switch resets.
 * 2. Advances same-intent chain (combo_index for sounds/damfactors).
 * 3. Appends the attack's combo_id to the ring buffer.
 * 4. Checks for combo sequence matches.
 * 5. Tracks zone diversity.
 *
 * Returns list(combo_sound, dam_mult, speed_mult) for the attack flow.
 */
/obj/item/rogueweapon/trickweapon/proc/process_combo(mob/living/target, mob/living/user, datum/intent/intent)
	var/now = world.time
	var/dam_mult = 1.0
	var/speed_mult = 1.0

	// --- Combo window from last intent's clickcd ---
	var/window = round(intent.clickcd * COMBO_WINDOW_MULT)
	if(last_intent_ref)
		window = round(last_intent_ref.clickcd * COMBO_WINDOW_MULT)

	var/timed_out = last_attack_time && ((now - last_attack_time) > window)
	var/target_switched = combo_target && !IS_WEAKREF_OF(target, combo_target)
	var/same_intent = (intent.type == last_intent_type)

	// --- Full reset conditions ---
	if(timed_out || target_switched || !last_attack_time)
		reset_combo(target)
		same_intent = FALSE // Force fresh start

	// --- Same-intent chain index (for combo_sounds / combo_damfactors) ---
	if(same_intent && intent.combo_max > 0)
		combo_index = (combo_index + 1) % intent.combo_max
	else if(last_intent_type)
		combo_index = 0

	// --- Same-intent chain damage scaling (the floor for R1 chains) ---
	if(intent.combo_damfactors && length(intent.combo_damfactors) > 0 && intent.combo_max > 0)
		var/dam_idx = min(combo_index + 1, length(intent.combo_damfactors))
		dam_mult *= intent.combo_damfactors[dam_idx]

	// --- Append to combo buffer ---
	if(intent.combo_id)
		LAZYADD(combo_buffer, intent.combo_id)
		// Trim to max length
		while(LAZYLEN(combo_buffer) > combo_buffer_max)
			combo_buffer.Cut(1, 2)

	// --- Check for combo finisher ---
	var/datum/trickweapon_combo/matched = check_combo_match()
	if(matched)
		dam_mult *= matched.finisher_dam_mult
		speed_mult *= matched.finisher_speed_mult
		// Reset buffer after consuming a combo
		LAZYCLEARLIST(combo_buffer)

	// Store matched combo for Impact FX (used by attack() for VFX escalation)
	last_matched_combo = matched

	// --- Zone diversity tracking ---
	var/parent_zone = check_zone(user.zone_selected)
	if(!LAZYISIN(combo_zones_hit, parent_zone))
		LAZYADD(combo_zones_hit, parent_zone)
		combo_zone_bonus = (LAZYLEN(combo_zones_hit) - 1) * COMBO_ZONE_BONUS_PER

	// --- Determine sound ---
	var/list/combo_sound
	if(matched?.finisher_sound)
		combo_sound = matched.finisher_sound
	else
		combo_sound = get_combo_sound(intent, combo_index)

	// --- Update tracking state ---
	last_attack_time = now
	last_intent_type = intent.type
	last_intent_ref = intent
	combo_target = WEAKREF(target)

	return list(combo_sound, dam_mult, speed_mult)

/**
 * Checks if the tail of the combo buffer matches any defined combo sequence.
 * Returns the matched /datum/trickweapon_combo, or null if no match.
 * Longest match wins (greedy).
 */
/obj/item/rogueweapon/trickweapon/proc/check_combo_match()
	if(!LAZYLEN(combo_buffer) || !LAZYLEN(defined_combos))
		return null
	var/buf_len = length(combo_buffer)
	var/datum/trickweapon_combo/best_match
	var/best_len = 0
	for(var/datum/trickweapon_combo/combo in defined_combos)
		var/seq_len = length(combo.sequence)
		if(seq_len > buf_len || seq_len <= best_len)
			continue
		// Check if buffer tail matches the sequence
		var/match = TRUE
		for(var/i in 1 to seq_len)
			if(combo_buffer[buf_len - seq_len + i] != combo.sequence[i])
				match = FALSE
				break
		if(match)
			best_match = combo
			best_len = seq_len
	return best_match

/**
 * Returns the appropriate swingsound list for this combo hit.
 * Priority: combo_sounds[index] → intent.swingsound → null (weapon default).
 */
/obj/item/rogueweapon/trickweapon/proc/get_combo_sound(datum/intent/intent, index)
	if(intent.combo_sounds && length(intent.combo_sounds) > 0)
		var/sound_idx = min(index + 1, length(intent.combo_sounds))
		return intent.combo_sounds[sound_idx]
	return intent.swingsound

/**
 * Resets all combo tracking state.
 */
/obj/item/rogueweapon/trickweapon/proc/reset_combo(mob/living/new_target)
	LAZYCLEARLIST(combo_buffer)
	combo_index = 0
	last_attack_time = 0
	last_intent_type = null
	last_intent_ref = null
	LAZYCLEARLIST(combo_zones_hit)
	combo_zone_bonus = 0
	last_was_transform = FALSE
	if(new_target)
		combo_target = WEAKREF(new_target)
	else
		combo_target = null

// Transform preserves the combo buffer (don't wipe it — transform attacks
// feed into combos). Reset combo_index and flag the transform.
/obj/item/rogueweapon/trickweapon/transform_weapon(mob/living/user)
	combo_index = 0
	last_was_transform = TRUE
	return ..()

// ===================== RUNNING ATTACK AUTO-SELECT =====================

/**
 * Resolves the correct intent for this attack, injecting running or
 * transform attack intents when conditions are met.
 *
 * Priority:
 *   1. Running transform attack (run intent + Space held + LMB)
 *   2. Transform attack (Space held + LMB)
 *   3. Running attack (run intent + LMB)
 *   4. Normal attack (HUD-selected intent)
 *
 * Returns list(resolved_intent, is_transform_attack) or null to abort.
 */
/obj/item/rogueweapon/trickweapon/proc/resolve_attack_intent(mob/living/user)
	var/datum/intent/intent = user.used_intent
	var/is_transform_attack = FALSE
	var/is_gripped = (wielded || altgripped)
	var/is_running = (user.m_intent == MOVE_INTENT_RUN)

	// --- Lunge bypass: lunge_on_landing already set the correct intent ---
	if(executing_lunge)
		return list(intent, FALSE)

	// --- Priority 1: Running transform attack (run + Space held) ---
	if(is_running && transform_key_held)
		transform_key_held = FALSE
		var/running_ta_type = transformed ? running_untransform_intent : running_transform_intent
		if(running_ta_type)
			is_transform_attack = TRUE
			transform_weapon(user)
			intent = find_intent_on_weapon(running_ta_type, user)
			if(intent)
				return list(intent, is_transform_attack)
		// Fall through if no running transform intent defined

	// --- Priority 2: Transform attack (Space held, not running) ---
	if(transform_key_held)
		transform_key_held = FALSE
		var/list/ta_intents
		if(transformed)
			ta_intents = is_gripped ? untransform_attack_gripped_intents : untransform_attack_intents
		else
			ta_intents = is_gripped ? transform_attack_gripped_intents : transform_attack_intents
		if(LAZYLEN(ta_intents))
			is_transform_attack = TRUE
			transform_weapon(user)
			intent = find_intent_on_weapon(ta_intents[1], user)
			if(intent)
				return list(intent, is_transform_attack)
		else
			// No transform attack defined — do normal transform, no attack
			transform_weapon(user)
			return null

	// --- Priority 3: Running attack (run intent, no Space) ---
	if(is_running)
		var/running_type
		if(transformed)
			running_type = is_gripped ? running_intent_tfm_grip : running_intent_tfm
		else
			running_type = is_gripped ? running_intent_base_grip : running_intent_base
		if(running_type)
			intent = find_intent_on_weapon(running_type, user)
			if(intent)
				return list(intent, FALSE)

	// --- Priority 4: Normal attack ---
	return list(intent, FALSE)

/**
 * Finds an instantiated intent datum matching the given type path.
 *
 * First checks the mob's possible_a_intents (HUD intents instantiated by
 * update_a_intents). If not found there, lazily creates and caches the
 * intent in cached_extra_intents for running/transform/lunge intents
 * that aren't in the standard HUD lists.
 */
/obj/item/rogueweapon/trickweapon/proc/find_intent_on_weapon(intent_type, mob/living/user)
	if(!ispath(intent_type))
		return null
	// Check mob's instantiated HUD intents first
	if(user)
		for(var/datum/intent/I in user.possible_a_intents)
			if(I.type == intent_type)
				return I
	// Lazily create and cache extra intents (running/transform/lunge)
	if(!cached_extra_intents)
		cached_extra_intents = list()
	var/key = "[intent_type]"
	var/datum/intent/cached = cached_extra_intents[key]
	if(cached)
		// Update mob reference if holder changed
		if(user && cached.mastermob != user)
			cached.mastermob = user
		return cached
	// Create and cache a new instance
	var/datum/intent/new_intent = new intent_type(user, src)
	cached_extra_intents[key] = new_intent
	return new_intent

// ===================== IMPACT FX SYSTEM =====================
// Variable hit sounds + visual impact effects based on target
// armor, blade class, combo state, and weapon-specific overrides.
//
// Integrated into the attack() override via the same temporary-
// mutation pattern used for swing sounds and damfactor.
// No changes to item_attack.dm or species.dm.
// =============================================================

// NOTE: Armor-reactive hit sounds are handled by vanilla's checkarmor() -> get_armor_sound()
// in human_defense.dm. We do NOT duplicate that here. Our resolver only handles:
//   1. Combo finisher hitsounds
//   2. Per-intent combo chain hitsounds
//   3. Weapon flesh override (category-keyed)
//   4. Vanilla fallback (intent.hitsound)

/**
 * Maps a blade_class define to a simplified damage category for armor sound lookup.
 * Returns "slash", "stab", or "blunt".
 */
/obj/item/rogueweapon/trickweapon/proc/get_blade_damage_category(blade_class)
	switch(blade_class)
		if(BCLASS_CUT, BCLASS_CHOP, BCLASS_LASHING)
			return "slash"
		if(BCLASS_STAB, BCLASS_PICK, BCLASS_PIERCE)
			return "stab"
		else
			return "blunt"

/**
 * Resolves what hit sound and VFX category to use for this attack.
 * Priority chain:
 *   1. Combo finisher hitsound (combo.finisher_hitsound)
 *   2. Per-intent combo chain hitsound (intent.combo_hitsounds[combo_index])
 *   3. Vanilla fallback (intent.hitsound via item_attack.dm, no injection needed)
 *
 * Armor hit sounds are handled by vanilla checkarmor() -> get_armor_sound().
 * Intent hitsounds only play when damage gets through armor (spec_attacked_by returns TRUE).
 *
 * Returns list(hitsound_list_or_null, vfx_category, vfx_scale, attack_dir)
 * If hitsound_list is null, the system doesn't inject and vanilla behavior applies.
 */
/obj/item/rogueweapon/trickweapon/proc/resolve_impact_fx(mob/living/target, mob/living/user, datum/intent/intent, datum/trickweapon_combo/combo)
	if(!impact_fx_enabled)
		return list(null, null, 1.0, SOUTH)

	var/list/resolved_hitsound
	var/vfx_category = "blood_spatter_small" // Default for flesh hits
	var/vfx_scale = 1.0
	var/target_ac = ARMOR_CLASS_NONE
	var/attack_dir = get_dir(user, target) || SOUTH // Direction from attacker TO target

	// --- Determine target armor class (for VFX selection only) ---
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		target_ac = H.highest_ac_worn()

	// --- Damage category ---
	var/dmg_cat = get_blade_damage_category(intent.blade_class)

	// --- Set VFX category based on armor + damage type ---
	switch(target_ac)
		if(ARMOR_CLASS_HEAVY)
			vfx_category = "metal_clang"
		if(ARMOR_CLASS_MEDIUM)
			vfx_category = "hit_spark"
		if(ARMOR_CLASS_LIGHT)
			vfx_category = "hit_spark"
		else
			// Unarmored flesh: VFX varies by damage type
			switch(dmg_cat)
				if("slash")
					vfx_category = "slash_arc" // Directional cutting arc
				if("stab")
					vfx_category = "blood_spatter_small" // Puncture spatter
				if("blunt")
					vfx_category = "dust_puff" // Concussion cloud
				else
					vfx_category = "blood_spatter_small"

	// Blunt attacks on armor still get dust puff overlay
	if(dmg_cat == "blunt" && target_ac > ARMOR_CLASS_NONE)
		vfx_category = "dust_puff"

	// --- Spatter size escalation for combos ---
	// Combo finishers = large, mid-combo = medium, basic hit = small
	if(combo?.finisher_hitsound)
		// Combo finisher: upgrade spatter to large
		if(target_ac == ARMOR_CLASS_NONE && dmg_cat != "blunt")
			vfx_category = "blood_spatter_large"
		resolved_hitsound = combo.finisher_hitsound
		vfx_scale = combo.finisher_vfx_scale
		return list(resolved_hitsound, vfx_category, vfx_scale, attack_dir)
	else if(combo_index > 0 && target_ac == ARMOR_CLASS_NONE && dmg_cat != "blunt")
		// Mid-combo on flesh: medium spatter
		vfx_category = "blood_spatter_medium"

	// --- Priority 2: Per-intent combo chain hitsound ---
	if(intent.combo_hitsounds && length(intent.combo_hitsounds) > 0 && combo_index > 0)
		var/hs_idx = min(combo_index + 1, length(intent.combo_hitsounds))
		var/list/chain_hs = intent.combo_hitsounds[hs_idx]
		if(chain_hs && length(chain_hs))
			resolved_hitsound = chain_hs
			return list(resolved_hitsound, vfx_category, vfx_scale, attack_dir)

	// --- Priority 3: Vanilla fallback (null = don't inject, use intent.hitsound as-is) ---
	return list(null, vfx_category, vfx_scale, attack_dir)

/**
 * Spawns a visual impact effect at the target's location.
 * VFX type and scale are determined by resolve_impact_fx().
 * Only called if the attack() return value indicates a successful hit.
 */
/obj/item/rogueweapon/trickweapon/proc/play_impact_vfx(mob/living/target, mob/living/user, vfx_category, vfx_scale, attack_dir)
	if(!target?.loc || !vfx_category)
		return
	var/obj/effect/temp_visual/impact_fx/FX
	switch(vfx_category)
		if("blood_splash")
			FX = new /obj/effect/temp_visual/impact_fx/blood_splash(target.loc, attack_dir)
		if("blood_spatter_large")
			FX = new /obj/effect/temp_visual/impact_fx/blood_spatter/large(target.loc, attack_dir)
		if("blood_spatter_medium")
			FX = new /obj/effect/temp_visual/impact_fx/blood_spatter/medium(target.loc, attack_dir)
		if("blood_spatter_small")
			FX = new /obj/effect/temp_visual/impact_fx/blood_spatter/small(target.loc, attack_dir)
		if("hit_spark")
			FX = new /obj/effect/temp_visual/impact_fx/hit_spark(target.loc, attack_dir)
		if("metal_clang")
			FX = new /obj/effect/temp_visual/impact_fx/metal_clang(target.loc, attack_dir)
		if("slash_arc")
			FX = new /obj/effect/temp_visual/impact_fx/slash_arc(target.loc, attack_dir)
		if("dust_puff")
			FX = new /obj/effect/temp_visual/impact_fx/dust_puff(target.loc, attack_dir)
		else
			return
	if(FX && vfx_scale != 1.0)
		var/matrix/M = matrix()
		M.Scale(vfx_scale)
		FX.transform = M

// ===================== ATTACK OVERRIDE =====================

/**
 * Override attack() to inject the true combo system.
 *
 * 1. Resolves the correct intent (running/transform/normal).
 * 2. Runs combo buffer processing (sequence matching, zone tracking).
 * 3. Temporarily overrides intent vars for the parent attack().
 * 4. Restores originals after.
 */
/obj/item/rogueweapon/trickweapon/attack(mob/living/M, mob/living/user)
	if(!user.used_intent)
		return ..()

	// --- Resolve the correct intent for this attack ---
	var/list/resolution = resolve_attack_intent(user)
	if(!resolution)
		return // Transform consumed the action
	var/datum/intent/intent = resolution[1]

	// --- Process combo buffer and get bonuses ---
	var/list/combo_result = process_combo(M, user, intent)
	var/list/combo_sound = combo_result[1]
	var/dam_mult = combo_result[2]
	var/speed_mult = combo_result[3]

	// --- Resolve Impact FX (hit sounds + VFX) ---
	var/list/impact_result = resolve_impact_fx(M, user, intent, last_matched_combo)
	var/list/fx_hitsound = impact_result[1]
	var/fx_vfx_category = impact_result[2]
	var/fx_vfx_scale = impact_result[3]
	var/fx_attack_dir = impact_result[4]

	// --- Cache originals ---
	var/list/orig_swingsound = intent.swingsound
	var/list/orig_hitsound = intent.hitsound
	var/orig_damfactor = intent.damfactor
	var/datum/intent/orig_used_intent = user.used_intent

	// --- Inject combo-resolved values ---
	if(combo_sound)
		intent.swingsound = combo_sound
	intent.damfactor = orig_damfactor * dam_mult

	// --- Inject impact hit sound ---
	if(fx_hitsound)
		intent.hitsound = fx_hitsound

	// Set used_intent so parent attack() uses the resolved intent
	if(intent != orig_used_intent)
		user.used_intent = intent

	// --- Execute the attack ---
	. = ..()

	// --- Restore originals ---
	intent.swingsound = orig_swingsound
	intent.hitsound = orig_hitsound
	intent.damfactor = orig_damfactor
	if(intent != orig_used_intent)
		user.used_intent = orig_used_intent

	// --- Post-hit effects (only if attack landed) ---
	if(.)
		// Visual impact effect
		play_impact_vfx(M, user, fx_vfx_category, fx_vfx_scale, fx_attack_dir)

	// --- Clear last matched combo ---
	last_matched_combo = null

	// --- Apply speed multiplier ---
	if(speed_mult < 1)
		var/reduced_cd = round(intent.clickcd * speed_mult)
		user.changeNext_move(reduced_cd)

// ===================== LUNGE ATTACK SYSTEM =====================
// When a player on jump intent MMBs a living mob while holding a
// trickweapon, the weapon intercepts the MMB, propels the user
// forward via throw_at, and executes a lunge attack on landing.
//
// Signal registered on equip, unregistered on drop.
// ================================================================

/obj/item/rogueweapon/trickweapon/equipped(mob/user, slot, initial)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_MIDDLECLICKON, PROC_REF(on_owner_mmb))

/obj/item/rogueweapon/trickweapon/dropped(mob/user)
	UnregisterSignal(user, COMSIG_MOB_MIDDLECLICKON)
	cached_extra_intents = null
	. = ..()

/**
 * Signal handler for COMSIG_MOB_MIDDLECLICKON on the wielding mob.
 * Intercepts MMB when conditions are met for a lunge attack.
 */
/obj/item/rogueweapon/trickweapon/proc/on_owner_mmb(mob/living/user, atom/target)
	SIGNAL_HANDLER

	// Only fire when: jump intent, target is living mob, this weapon is in active hand
	if(!istype(user.mmb_intent, /datum/intent/jump))
		return
	if(!isliving(target))
		return
	if(user.get_active_held_item() != src)
		return

	// Determine the lunge intent for current form + grip
	var/is_gripped = (wielded || altgripped)
	var/lunge_type
	if(transformed)
		lunge_type = is_gripped ? lunge_intent_tfm_grip : lunge_intent_tfm
	else
		lunge_type = is_gripped ? lunge_intent_base_grip : lunge_intent_base
	if(!lunge_type)
		return // No lunge intent defined — let normal jump proceed

	var/datum/intent/lunge_intent = find_intent_on_weapon(lunge_type, user)
	if(!lunge_intent)
		return

	// Cancel normal MMB handling (prevents jump from also firing)
	INVOKE_ASYNC(src, PROC_REF(execute_lunge), user, target, lunge_intent)
	return COMSIG_MOB_CANCEL_CLICKON

/**
 * Executes a lunge attack: propels the user toward the target and attacks on landing.
 */
/obj/item/rogueweapon/trickweapon/proc/execute_lunge(mob/living/user, mob/living/target, datum/intent/lunge_intent)
	if(!user || !target || !lunge_intent)
		return

	var/lunge_range = (user.m_intent == MOVE_INTENT_RUN) ? LUNGE_RANGE_RUN : LUNGE_RANGE

	// Propel the user toward the target
	user.throw_at(target, lunge_range, 1, user, spin = FALSE, callback = CALLBACK(src, PROC_REF(lunge_on_landing), user, target, lunge_intent))

/**
 * Callback after throw_at completes. Executes the lunge attack and applies debuffs.
 * Sets executing_lunge so that the attack() override's resolve_attack_intent()
 * passes through the lunge intent instead of re-resolving to running/normal.
 */
/obj/item/rogueweapon/trickweapon/proc/lunge_on_landing(mob/living/user, mob/living/target, datum/intent/lunge_intent)
	if(QDELETED(user) || QDELETED(target))
		return
	if(!user.Adjacent(target))
		// Missed the target — apply debuffs without attack
		user.OffBalance(LUNGE_OFFBALANCE)
		user.Immobilize(LUNGE_IMMOBILIZE)
		return

	// Set lunge state — attack() override will see this and skip resolve_attack_intent
	executing_lunge = TRUE
	var/datum/intent/orig_intent = user.used_intent
	user.used_intent = lunge_intent

	// Call our attack() override directly. It will:
	// - See executing_lunge=TRUE → resolve_attack_intent returns used_intent as-is
	// - Run process_combo with the lunge intent
	// - Inject combo bonuses into the intent
	// - Call parent attack for damage
	attack(target, user)

	// Restore state
	user.used_intent = orig_intent
	executing_lunge = FALSE

	// Apply post-lunge debuffs (risky commitment)
	user.OffBalance(LUNGE_OFFBALANCE)
	user.Immobilize(LUNGE_IMMOBILIZE)

