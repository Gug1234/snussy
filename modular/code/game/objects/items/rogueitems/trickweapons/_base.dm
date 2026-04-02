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
 * Punishment proc for extreme transform spam. The weapon explodes violently,
 * dismembering whichever arm was holding it, forces a painscream, broadcasts
 * a bold message to nearby players, and logs the event.
 */
/obj/item/rogueweapon/trickweapon/proc/transform_spam_explode(mob/living/carbon/human/user)
	if(!istype(user))
		return

	// Determine which arm is holding the weapon
	var/held_idx = user.get_held_index_of_item(src)
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
	serrated = base_serrated
	update_serrated_signal()

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

