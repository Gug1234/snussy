// ===================== KOS PARASITE INTENTS =====================

/// Kos Parasite base - bludgeon bash. Simple blunt hit with the calcified shell.
/datum/intent/kosparasite/bash
	name = "bludgeon bash"
	icon_state = "instrike"
	attack_verb = list("bashes", "clubs")
	animname = "strike"
	blade_class = BCLASS_BLUNT
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_hit2.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit2.ogg')
	chargetime = 0
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1
	clickcd = CLICK_CD_MELEE
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_WEAK

/// Kos Parasite base - cartilage thrust. Jabbing the hardened tip forward.
/datum/intent/kosparasite/thrust
	name = "cartilage thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "jabs")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_impact1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_impact2.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit3.ogg')
	chargetime = 0
	penfactor = 20
	damfactor = 0.9
	clickcd = CLICK_CD_FAST
	item_d_type = "stab"

/// Kos Parasite base - headbutt. Charged heavy blow, smashing with the shell.
/datum/intent/kosparasite/headbutt
	name = "leaping headbutt"
	icon_state = "insmash"
	attack_verb = list("headbutts", "rams")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kosparasite/lobe_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit2.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit3.ogg', 'modular/sounds/trickweapons/kosparasite/blood_splat1.ogg')
	chargetime = 4
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.5
	clickcd = CLICK_CD_HEAVY
	swingdelay = 6
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

/// Kos Parasite transformed - dual tentacle swipe. Fast lashing at range.
/// Layered whip crack + wet flesh slap for the characteristic tendril lash.
/datum/intent/kosparasite/dualswipe
	name = "dual tentacle swipe"
	icon_state = "incut"
	attack_verb = list("swipes", "lashes")
	animname = "cut"
	blade_class = BCLASS_LASHING
	hitsound = list('modular/sounds/trickweapons/kosparasite/tendril_land.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_slap1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_slap2.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit1.ogg')
	chargetime = 0
	penfactor = 10
	damfactor = 1.1
	clickcd = CLICK_CD_FAST
	reach = 2
	item_d_type = "blunt"

/// Kos Parasite transformed - dual tentacle thrust. Charged reach 2 piercing stab.
/// Wet skewering sound on hit — tendril punching through flesh.
/datum/intent/kosparasite/dualthrust
	name = "dual tentacle thrust"
	icon_state = "instab"
	attack_verb = list("thrusts", "skewers")
	animname = "stab"
	blade_class = BCLASS_STAB
	hitsound = list('modular/sounds/trickweapons/kosparasite/flesh_impact1.ogg', 'modular/sounds/trickweapons/kosparasite/flesh_impact2.ogg', 'modular/sounds/trickweapons/kosparasite/blood_splat1.ogg', 'modular/sounds/trickweapons/kosparasite/blood_splat2.ogg')
	chargetime = 3
	chargedrain = 1
	penfactor = 35
	damfactor = 1.2
	clickcd = CLICK_CD_CHARGED
	reach = 2
	item_d_type = "stab"
	effective_range = 2
	effective_range_type = EFF_RANGE_EXACT

/// Kos Parasite transformed - tendril slam. Heavy charged overhead, alien tendrils crushing down.
/// A focused single-target slam channeling the parasite's mass.
/// Uses the tendril_land + lobe sounds for a wet, devastating impact.
/datum/intent/kosparasite/arcaneburst
	name = "tendril slam"
	icon_state = "incrush"
	attack_verb = list("slams", "bashes")
	animname = "strike"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kosparasite/tendril_land.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit2.ogg')
	chargetime = 8
	chargedrain = 3
	penfactor = 50
	damfactor = 2
	clickcd = CLICK_CD_HEAVY
	swingdelay = 8
	no_early_release = TRUE
	misscost = 10
	item_d_type = "blunt"
	intent_intdamage_factor = 1.5
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_ABSURD

/// Kos Parasite transformed - leaping slam. Fast gap-closer style attack.
/// Heavy wet impact — tendrils crashing down.
/datum/intent/kosparasite/leapslam
	name = "leaping slam"
	icon_state = "insmash"
	attack_verb = list("slams", "crashes into")
	animname = "chop"
	blade_class = BCLASS_SMASH
	hitsound = list('modular/sounds/trickweapons/kosparasite/tendril_land.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit1.ogg', 'modular/sounds/trickweapons/kosparasite/lobe_hit2.ogg', 'modular/sounds/trickweapons/kosparasite/blood_splat2.ogg')
	chargetime = 2
	chargedrain = 1
	penfactor = BLUNT_DEFAULT_PENFACTOR
	damfactor = 1.3
	clickcd = CLICK_CD_CHARGED
	item_d_type = "blunt"
	intent_intdamage_factor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	blunt_chipping = TRUE
	blunt_chip_strength = BLUNT_CHIP_STRONG

// ===================== KOS PARASITIC CLOTHING =====================
// When a host infests themselves with the Kos Parasite, these items
// permanently replace the head and glove slots.
// Inventory HUD sprites: "koshead" / "kosarms" from kosclothing.dmi
// On-mob overlay sprites: "koshead" / "kosarms" from kosparasiteonmob.dmi

/// Parasitic crest — calcified growth that fuses to the host's skull.
/// Replaces the helmet slot permanently. Cannot be removed once bonded.
/// Chitin armor: excellent vs slash/stab, moderate vs blunt, weak vs piercing/fire.
/obj/item/clothing/head/roguetown/koshead
	name = "parasitic crest"
	desc = "A grotesque crown of calcified flesh and chitinous shell, fused directly to the skull. Where it ends and the host begins is impossible to tell."
	icon = 'modular/icons/obj/trickweapons/kosclothing.dmi'
	mob_overlay_icon = 'modular/icons/obj/trickweapons/kosparasiteonmob.dmi'
	icon_state = "koshead"
	item_state = "koshead"
	flags_inv = HIDEEARS|HIDEHAIR|HIDEFACIALHAIR
	body_parts_covered = HEAD|HAIR
	slot_flags = ITEM_SLOT_HEAD
	dynamic_hair_suffix = ""
	clothing_flags = SNUG_FIT
	attachment_component = null
	sellprice = 0
	resistance_flags = FIRE_PROOF
	max_integrity = ARMOR_INT_HELMET_ANTAG
	armor = list("blunt" = 40, "slash" = 100, "stab" = 90, "piercing" = 50, "fire" = 0, "acid" = 0)
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_TWIST)
	blocksound = SOFTHIT
	anvilrepair = null
	sewrepair = FALSE

/obj/item/clothing/head/roguetown/koshead/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "kos_parasite")

/// Parasitic tendrils — alien appendages fused to the host's forearms and hands.
/// Replaces the glove slot permanently. Cannot be removed once bonded.
/// Same chitin armor profile as the crest.
/obj/item/clothing/gloves/roguetown/kosarms
	name = "parasitic tendrils"
	desc = "Thick, rope-like tendrils of alien flesh wrapped around and fused with the host's forearms. They pulse with a faint, sickly warmth."
	icon = 'modular/icons/obj/trickweapons/kosclothing.dmi'
	mob_overlay_icon = 'modular/icons/obj/trickweapons/kosparasiteonmob.dmi'
	icon_state = "kosarms"
	item_state = "kosarms"
	body_parts_covered = HANDS
	slot_flags = ITEM_SLOT_GLOVES
	sellprice = 0
	resistance_flags = FIRE_PROOF
	max_integrity = ARMOR_INT_SIDE_ANTAG
	armor = list("blunt" = 40, "slash" = 100, "stab" = 90, "piercing" = 50, "fire" = 0, "acid" = 0)
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_TWIST)
	blocksound = SOFTHIT
	anvilrepair = null
	sewrepair = FALSE

/obj/item/clothing/gloves/roguetown/kosarms/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "kos_parasite")

// ===================== KOS DEPLOY ACTION =====================
// Innate toggle action granted to the host upon infestation.
// Deploys or retracts the parasite weapon from the host's hands.
// Persists independently of the weapon's location (survives nullspace stow).

/datum/action/innate/kos_deploy
	name = "Deploy Parasite"
	desc = "Deploy or retract the Parasite from your flesh."
	icon_icon = 'modular/icons/obj/trickweapons/trickweapons.dmi'
	button_icon_state = "abyssorparasite"
	/// Reference to the bonded parasite weapon.
	var/obj/item/rogueweapon/trickweapon/kosparasite/weapon

/datum/action/innate/kos_deploy/Activate()
	if(!weapon || !owner || !isliving(owner))
		return
	var/mob/living/L = owner
	if(!L.put_in_hands(weapon))
		to_chat(L, span_warning("My hands are full!"))
		active = FALSE
		return
	ADD_TRAIT(weapon, TRAIT_NODROP, "kos_parasite")
	active = TRUE
	to_chat(L, span_notice("The parasite stirs to life, unfurling from my flesh..."))
	playsound(L, 'modular/sounds/trickweapons/kosparasite/parasite_birth.ogg', 50, TRUE)

/datum/action/innate/kos_deploy/Deactivate()
	if(!weapon || !owner || !isliving(owner))
		return
	var/mob/living/L = owner
	if(weapon.wielded || weapon.altgripped)
		weapon.ungrip(L)
	REMOVE_TRAIT(weapon, TRAIT_NODROP, "kos_parasite")
	L.temporarilyRemoveItemFromInventory(weapon, TRUE)
	weapon.moveToNullspace()
	active = FALSE
	to_chat(L, span_notice("The parasite retracts, burrowing back beneath my skin..."))
	playsound(L, 'modular/sounds/trickweapons/kosparasite/tendril_land.ogg', 50, TRUE)

// ===================== KOS PARASITE WEAPON =====================
// An eldritch implant weapon. Before infestation it behaves like a normal
// item that can be carried. Using it on yourself (attack_self) triggers
// permanent bonding: head and gloves are replaced with parasitic growths,
// and the weapon becomes deployable via an action button.
//
// Icon state conventions for GIF animation control:
//   kosparasite    — static first frame (unwielded base)
//   kosparasite1   — animated GIF (wielded base)
//   kosparasite_t  — static first frame (unwielded transformed)
//   kosparasite_t1 — animated GIF (wielded transformed)
// The trick weapon base automatically appends "1" on wield and strips
// it on unwield, so no extra animation code is needed.

/obj/item/rogueweapon/trickweapon/kosparasite
	name = "abyssal parasite"
	desc = "A trick weapon dredged from the depths of Abyssor's domain, found tangled in the nets of a doomed fishing vessel. In its dormant state, a grotesque appendage of hardened cartilage and calcified flesh, useful only as a crude bludgeon. When awakened, the parasite unfurls into writhing tentacles that lash out with otherworldly malice. To wield it is to invite communion with the dreams of a slumbering god."
	icon_state = "abyssorparasite"
	item_state = "abyssorparasite"
	/// Separate icon file for in-hand (on-mob) rendering, since generateonmob
	/// reads from `icon` which points at the inventory sprite sheet.
	var/inhand_icon = 'modular/icons/obj/trickweapons/kosparasiteonmob.dmi'
	/// On-mob icon state for the base form (maps inventory state to on-mob state).
	var/inhand_base_state = "kosparasite"
	/// On-mob icon state for the transformed form.
	var/inhand_transformed_state = "kosparasite_t"
	force = 18
	force_wielded = 22
	possible_item_intents = list(/datum/intent/kosparasite/bash, /datum/intent/kosparasite/thrust)
	gripped_intents = list(/datum/intent/kosparasite/bash, /datum/intent/kosparasite/thrust, /datum/intent/kosparasite/headbutt)
	slot_flags = ITEM_SLOT_HIP | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_NORMAL
	wlength = WLENGTH_SHORT
	wbalance = WBALANCE_NORMAL
	wdefense = 2
	wdefense_wbonus = 1
	minstr = 6
	max_blade_int = 200
	max_integrity = 200
	sharpness = IS_BLUNT
	associated_skill = /datum/skill/combat/maces
	swingsound = BLUNTWOOSH_SMALL
	parrysound = list('sound/combat/parry/parrygen.ogg')
	pickup_sound = 'sound/foley/equip/swordsmall1.ogg'
	transform_sound = 'modular/sounds/trickweapons/kosparasite/parasite_attack.ogg'
	untransform_sound = 'modular/sounds/trickweapons/kosparasite/parasite_birth.ogg'
	dropshrink = 0.3
	throwforce = 0
	thrown_bclass = null
	sellprice = 0
	grid_width = 32
	grid_height = 64
	// --- Transformed state: Awakened Tentacles ---
	transformed_name = "abyssal parasite"
	transformed_desc = "The abyssal parasite, now fully awakened. Writhing tentacles extend from the calcified shell, lashing out with a mind of their own. Each strike carries the spectral intelligence of Abyssor's dreaming will, reaching further than any natural limb should."
	transformed_icon_state = "abyssorparasite_t"
	transformed_item_state = "abyssorparasite_t"
	transformed_force = 16
	transformed_force_wielded = 24
	transformed_intents = list(/datum/intent/kosparasite/dualswipe, /datum/intent/kosparasite/leapslam)
	transformed_gripped_intents = list(/datum/intent/kosparasite/dualswipe, /datum/intent/kosparasite/dualthrust, /datum/intent/kosparasite/arcaneburst, /datum/intent/kosparasite/leapslam)
	transformed_swingsound = list('modular/sounds/trickweapons/kosparasite/koshit1.ogg', 'modular/sounds/trickweapons/kosparasite/koshit2.ogg', 'modular/sounds/trickweapons/kosparasite/koshit3.ogg')
	transformed_wlength = WLENGTH_LONG // tendrils are long
	transformed_wbalance = WBALANCE_NORMAL
	transformed_wdefense = 2
	transformed_wdefense_wbonus = 2
	transformed_minstr = 7
	transformed_associated_skill = /datum/skill/combat/maces
	transformed_sharpness = IS_BLUNT
	transformed_w_class = WEIGHT_CLASS_BULKY
	special = /datum/special_intent/kos_parasite_bash
	transformed_special = /datum/special_intent/kos_parasite_burst
	/// The mob this parasite has permanently bonded to. Null before infestation.
	var/mob/living/host
	/// Whether this parasite has permanently bonded to a host.
	var/infested = FALSE
	/// The action button for deploying/retracting the weapon.
	var/datum/action/innate/kos_deploy/deploy_action

/obj/item/rogueweapon/trickweapon/kosparasite/Initialize(mapload)
	. = ..()
	deploy_action = new()
	deploy_action.weapon = src

/obj/item/rogueweapon/trickweapon/kosparasite/Destroy()
	if(host)
		UnregisterSignal(host, COMSIG_MOB_ATE_FOOD)
	if(deploy_action)
		QDEL_NULL(deploy_action)
	host = null
	return ..()

/// Clicking the weapon while held and un-infested triggers the bonding process.
/// After infestation, attack_self does nothing (transform is via rmb_self).
/obj/item/rogueweapon/trickweapon/kosparasite/attack_self(mob/user)
	if(!infested)
		infest(user)
		return
	return ..()

/**
 * Permanently bonds the parasite to the host.
 * Replaces head/glove slots with parasitic growths, locks the weapon
 * with TRAIT_NODROP, and grants the deploy/retract action button.
 * This process is irreversible.
 */
/obj/item/rogueweapon/trickweapon/kosparasite/proc/infest(mob/living/carbon/human/user, force = FALSE)
	if(!ishuman(user) || infested)
		return
	// Constructs lack flesh for the parasite to bond with; revenants are weird and I don't wanna deal with their stupid dumb head mechanics.
	if(isconstruct(user) || isdullahan(user))
		to_chat(user, span_warning("The parasite writhes against my form but finds no living flesh to bond with."))
		return
	if(!force)
		if(tgui_alert(user, "Allow the parasite to bond with your flesh? This cannot be undone.", "Abyssal Communion", list("Yes", "No")) != "Yes")
			return
		if(QDELETED(src) || QDELETED(user) || user.get_active_held_item() != src)
			return
	// Strip existing headgear and gloves
	var/obj/item/old_head = user.get_item_by_slot(SLOT_HEAD)
	if(old_head)
		user.dropItemToGround(old_head, force = TRUE)
	var/obj/item/old_gloves = user.get_item_by_slot(SLOT_GLOVES)
	if(old_gloves)
		user.dropItemToGround(old_gloves, force = TRUE)
	// Force-equip parasitic gear
	user.equip_to_slot_or_del(new /obj/item/clothing/head/roguetown/koshead(user), SLOT_HEAD)
	user.equip_to_slot_or_del(new /obj/item/clothing/gloves/roguetown/kosarms(user), SLOT_GLOVES)
	// Bond the weapon
	infested = TRUE
	host = user
	// Swap inventory sprite to the tendril arms instead of the dormant parasite
	icon = 'modular/icons/obj/trickweapons/kosclothing.dmi'
	icon_state = "kosarms"
	item_state = "kosarms"
	slot_flags = null
	ADD_TRAIT(src, TRAIT_NODROP, "kos_parasite")
	// Parasitic biology overrides the host's — immune to zombie infection and lycanthropy
	// Mostly a failsafe to prevent edgecases where zombie transformation tries to remove the unremoveable headgear
	ADD_TRAIT(user, TRAIT_ZOMBIE_IMMUNE, "kos_parasite")
	ADD_TRAIT(user, TRAIT_SILVER_BLESSED, "kos_parasite")
	// So the user can repair the weapon without puking
	ADD_TRAIT(user, TRAIT_WILD_EATER, "kos_parasite")
	// Listen for the host eating raw fish to trigger self-repair
	RegisterSignal(user, COMSIG_MOB_ATE_FOOD, PROC_REF(on_host_ate))
	// Grant deploy action — weapon is already in hand
	deploy_action.Grant(user)
	deploy_action.active = TRUE
	to_chat(user, span_userdanger("The parasite burrows into my flesh! Calcified growths erupt from my skull as tendrils wrap around my arms. There is no going back."))
	playsound(user, 'modular/sounds/trickweapons/kosparasite/parasite_birth.ogg', 80, TRUE)
	user.emote("painscream")

/**
 * Signal handler for COMSIG_MOB_ATE_FOOD.
 * When the host eats raw fish, the parasite feeds on the biological material
 * and repairs the weapon AND both parasitic clothing pieces (crest + tendrils).
 * Scales repair amount by fish rarity.
 */
/obj/item/rogueweapon/trickweapon/kosparasite/proc/on_host_ate(mob/living/eater, obj/item/reagent_containers/food/snacks/food, mob/living/feeder)
	SIGNAL_HANDLER
	if(!istype(food, /obj/item/reagent_containers/food/snacks/fish))
		return
	var/obj/item/reagent_containers/food/snacks/fish/F = food
	// Scale repair by rarity: common 15, rare 25, ultra-rare 40, legendary 60
	var/repair_amount
	switch(F.rarity_rank)
		if(3) // legendary
			repair_amount = 60
		if(2) // ultra-rare
			repair_amount = 40
		if(1) // rare
			repair_amount = 25
		else  // common
			repair_amount = 15
	// Repair the weapon itself
	var/anything_repaired = FALSE
	if(obj_integrity < max_integrity)
		obj_integrity = min(obj_integrity + repair_amount, max_integrity)
		anything_repaired = TRUE
	// Repair parasitic clothing on the host
	if(ishuman(eater))
		var/mob/living/carbon/human/H = eater
		var/obj/item/clothing/head/roguetown/koshead/crest = H.get_item_by_slot(SLOT_HEAD)
		if(istype(crest) && crest.obj_integrity < crest.max_integrity)
			crest.obj_integrity = min(crest.obj_integrity + repair_amount, crest.max_integrity)
			anything_repaired = TRUE
		var/obj/item/clothing/gloves/roguetown/kosarms/tendrils = H.get_item_by_slot(SLOT_GLOVES)
		if(istype(tendrils) && tendrils.obj_integrity < tendrils.max_integrity)
			tendrils.obj_integrity = min(tendrils.obj_integrity + repair_amount, tendrils.max_integrity)
			anything_repaired = TRUE
	if(!anything_repaired)
		to_chat(eater, span_notice("The parasite savors the raw flesh, but it is already whole."))
		return
	to_chat(eater, span_notice("The parasite shudders with delight as it absorbs the raw fish, knitting its wounds closed."))
	playsound(eater, 'modular/sounds/trickweapons/kosparasite/parasite_birth.ogg', 40, TRUE)

/// Override apply_base_state/apply_transformed_state to force the infested
/// inventory sprite (kosarms from kosclothing.dmi) instead of the dormant parasite.
/obj/item/rogueweapon/trickweapon/kosparasite/apply_base_state()
	. = ..()
	if(infested)
		icon = 'modular/icons/obj/trickweapons/kosclothing.dmi'
		icon_state = "kosarms"
		item_state = "kosarms"

/obj/item/rogueweapon/trickweapon/kosparasite/apply_transformed_state()
	. = ..()
	if(infested)
		icon = 'modular/icons/obj/trickweapons/kosclothing.dmi'
		icon_state = "kosarms"
		item_state = "kosarms"

/// Override generateonmob to pull from kosparasiteonmob.dmi with the correct
/// on-mob icon states. The inventory DMI uses "abyssorparasite" naming while
/// the on-mob DMI uses "kosparasite" naming, and has no "1" suffix states.
/obj/item/rogueweapon/trickweapon/kosparasite/generateonmob(tag, prop, behind = FALSE, mirrored = FALSE, used_index = null)
	var/cached_icon = icon
	icon = inhand_icon
	// Map to the correct on-mob state — the on-mob DMI has no "1" suffixed states
	var/onmob_state = transformed ? inhand_transformed_state : inhand_base_state
	. = ..(tag, prop, behind, mirrored, onmob_state)
	icon = cached_icon

/// Mob render properties for one-handed and wielded display.
/// Sprites in kosparasiteonmob.dmi are handcrafted to align correctly — no offsets needed.
/obj/item/rogueweapon/trickweapon/kosparasite/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 1,"sx" = 0,"sy" = 0,"nx" = 0,"ny" = 0,"wx" = 0,"wy" = 0,"ex" = 0,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
			if("wielded")
				return list("shrink" = 1,"sx" = 0,"sy" = 0,"nx" = 0,"ny" = 0,"wx" = 0,"wy" = 0,"ex" = 0,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
