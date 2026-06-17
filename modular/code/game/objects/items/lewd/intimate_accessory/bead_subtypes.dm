// ── Additional Anal Bead Subtypes ────────────────────────────────────────────
// Each subtype overrides get_max_beads() and get_bead_length(); the parent
// update_item_visuals() uses get_bead_length() to derive icon_state
// ("rear_bead_item_[length]"), the matching gem overlay, and handles the
// blue_pearled (abyssor) branch. Subtypes only override update_item_visuals()
// when their visuals genuinely diverge (glass: unique overlay; spiked: no
// pearl/gem branches; mixed12: icon prefix "mixedbeads_12" != length "mixed_12").
// Unsocketable types override attackby() to reject all socket attempts.
// Gem-only types use the same base attackby but reject special cross sockets.

// ════════════════════════════════════════════════════════════════════════════
// GLASS BEADS — VERY EVIL BEADS!!!!!!
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/glass
	name = "glass anal beads"
	desc = "A set of four delicate glass beads. Beautiful, fragile, and profoundly unwise to wear while climbing."
	default_desc = "A set of four delicate glass beads. Beautiful, fragile, and profoundly unwise to wear while climbing."
	icon_state = "glass_main"
	item_state = "glass_main"
	bead_count = "glass"
	intimate_flags = INTIMATE_FLAG_INSERTABLE
	intimate_metal_name = "glass"
	sellprice = 3
	resistance_flags = NONE
	/// Whether we've registered our z-fall listener.
	var/fall_registered = FALSE

/obj/item/intimate_accessory/rear/plug/analbeads/glass/get_max_beads()
	return 4

/obj/item/intimate_accessory/rear/plug/analbeads/glass/get_bead_length()
	return "glass"

/obj/item/intimate_accessory/rear/plug/analbeads/glass/update_item_visuals()
	cut_overlays()
	icon_state = "glass_main"
	item_state = "glass_main"
	// Tint the base layer (metal caps) with the crafting metal color.
	apply_intimate_item_tint()
	// Glass overlay sits on top, untinted.
	var/mutable_appearance/overlay = mutable_appearance(icon, "glass_overlay")
	overlay.color = null
	add_overlay(overlay)
	update_icon()
/// Glass ripcord — violent ripcord shatters them inside.
/obj/item/intimate_accessory/rear/plug/analbeads/glass/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] grabs the pull ring and rips the glass beads out of [who] with a savage yank — one of them doesn't make it out intact. There's a muffled crack from inside [who], followed by a scream."
	return "[user] carefully draws the glass beads from [who] one by one, each fragile sphere emerging slick and unbroken."


/obj/item/intimate_accessory/rear/plug/analbeads/glass/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 55, TRUE, ignore_walls = FALSE)
	if(violent)
		// Violent ripcord shatters a bead inside — same consequence as z-fall
		playsound(target, 'sound/foley/glassbreak.ogg', 60, TRUE)
		target.emote("scream", forced = TRUE)
		var/obj/item/bodypart/groin = target.get_bodypart(check_zone(BODY_ZONE_PRECISE_GROIN))
		if(groin)
			groin.add_wound(/datum/wound/slash/large)
			groin.add_wound(/datum/wound/slash/large)
		send_extreme_content_visible_message(target, span_userdanger("Bloody glass shards fall from between [target]'s legs along with the remaining beads."))
		target.Knockdown(30)
		// Destroy the beads — they're shattered
		remove_intimate_accessory(target)
		if(!QDELETED(src))
			qdel(src)
		return
	// Gentle ripcord — just an orgasm
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)

/// Gate behind extreme ERP — shattering glass inside someone is violent content.
/obj/item/intimate_accessory/rear/plug/analbeads/glass/can_attach_to_intimate_slot(mob/living/carbon/human/H, mob/user, slot, silent = FALSE, require_open_slot = TRUE)
	. = ..()
	if(!.)
		return FALSE
	if(!user?.client?.prefs?.extreme_erp)
		if(!silent)
			to_chat(user, span_warning("You need extreme content enabled to use this."))
		return FALSE
	if(H != user && !H?.client?.prefs?.extreme_erp)
		if(!silent)
			to_chat(user, span_warning("[H] does not have extreme content enabled."))
		return FALSE
	return TRUE

/// Block ALL socketing — glass has no sockets.
/obj/item/intimate_accessory/rear/plug/analbeads/glass/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/roguegem) || istype(I, /obj/item/pearl/blue) || istype(I, /obj/item/riddleofsteel) || src.is_psydonic_socket_item(I) || src.is_zizite_socket_item(I))
		to_chat(user, span_warning("Glass beads have no sockets."))
		return TRUE
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel))
		to_chat(user, span_warning("There is nothing socketed in these glass beads."))
		return TRUE
	return ..()

/obj/item/intimate_accessory/rear/plug/analbeads/glass/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	if(H && !fall_registered)
		RegisterSignal(H, COMSIG_HUMAN_Z_IMPACT_DAMAGE, PROC_REF(on_z_impact))
		fall_registered = TRUE

/obj/item/intimate_accessory/rear/plug/analbeads/glass/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && fall_registered)
		UnregisterSignal(H, COMSIG_HUMAN_Z_IMPACT_DAMAGE)
		fall_registered = FALSE
	return ..()

/// When the wearer falls a z-level, the glass beads shatter inside them.
/obj/item/intimate_accessory/rear/plug/analbeads/glass/proc/on_z_impact(mob/living/carbon/human/victim, turf/T, levels)
	SIGNAL_HANDLER
	if(QDELETED(src) || QDELETED(victim) || QDELETED(wearer) || src.wearer != victim)
		return
	// Shatter the beads
	send_extreme_content_visible_message(
		victim,
		span_userdanger("The glass beads inside [victim] shatter on impact, jagged shards ripping through [victim]'s insides!"),
		span_userdanger("WHITE-HOT AGONY — the glass beads inside you shatter, shards tearing through your guts!")
	)
	playsound(victim, 'sound/foley/glassbreak.ogg', 60, TRUE)

	// Apply a grievous slash wound to the groin
	var/obj/item/bodypart/groin = victim.get_bodypart(check_zone(BODY_ZONE_PRECISE_GROIN))
	if(groin)
		groin.add_wound(/datum/wound/slash/large)
		groin.add_wound(/datum/wound/slash/large)

	// Remove and destroy the beads
	beads_inserted = 0
	remove_intimate_accessory(victim)
	if(!QDELETED(src))
		send_extreme_content_visible_message(victim, span_warning("Bloody glass shards fall from between [victim]'s legs."))
		qdel(src)

// ════════════════════════════════════════════════════════════════════════════
// SMALL 12-BEAD — A long chain of 12 small beads. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/small12
	name = "small anal beads"
	desc = "A lengthy string of twelve small beads, each barely larger than a marble. What they lack in girth they make up for in number."
	default_desc = "A lengthy string of twelve small beads, each barely larger than a marble. What they lack in girth they make up for in number."
	icon_state = "rear_bead_item_12"
	item_state = "rear_bead_item_12"
	bead_count = "12small"
	rear_accessory_noun = "small anal beads"
	sellprice = 15

/obj/item/intimate_accessory/rear/plug/analbeads/small12/get_max_beads()
	return 12

/obj/item/intimate_accessory/rear/plug/analbeads/small12/get_bead_length()
	return "12"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Small 12-bead ripcord — twelve rapid pops in a row.
/obj/item/intimate_accessory/rear/plug/analbeads/small12/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] grabs the pull ring and rips all twelve beads from [who] in one savage yank — the small spheres rattle out in a machine-gun chain of wet pops, so fast that [who]'s rim barely has time to register each one before the next tears through."
	return "[user] draws the long chain of twelve small beads from [who] in one slow, continuous pull — each marble popping free in a gentle, rhythmic sequence."

/obj/item/intimate_accessory/rear/plug/analbeads/small12/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 60, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	// 12 rapid pops — fucked stupid from sheer stimulation
	target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
	if(violent)
		target.apply_status_effect(/datum/status_effect/knot_gaped)
		target.Knockdown(15)


// ════════════════════════════════════════════════════════════════════════════
// MEDIUM PYRAMID — 5 beads graduating small to large. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium
	name = "medium pyramid anal beads"
	desc = "A graduated string of five beads, each one larger than the last — a gentle escalation from marble-sized to fist-clenching."
	default_desc = "A graduated string of five beads, each one larger than the last — a gentle escalation from marble-sized to fist-clenching."
	icon_state = "rear_bead_item_pyramid_medium"
	item_state = "rear_bead_item_pyramid_medium"
	bead_count = "pyramid_medium"
	rear_accessory_noun = "medium pyramid anal beads"
	sellprice = 18

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium/get_max_beads()
	return 5

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium/get_bead_length()
	return "pyramid_medium"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for medium pyramid beads — a measured escalation.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "The smallest bead slides into [who] with ease, a gentle beginning that promises nothing about what follows."
		if(2)
			return "The second bead is larger — [who]'s rim stretches just enough to notice, the growing size a gentle warning."
		if(3)
			return "The middle bead marks the tipping point. [who] feels genuine stretch now, the graduated girth pulling a low sound from [who]'s throat as the rim slowly gives."
		if(4)
			return "[who]'s breath catches. The fourth bead is large, requiring [user] to push firmly, [who]'s body fighting the escalation even as the smaller beads are dragged deeper by the cord."
		if(5)
			return "The final bead is the largest — [who] has to be worked open around it, the rim straining before it crests and pops inside with a wet sound. The full graduated chain sits heavy inside, smallest to largest."

/// Bespoke removal messages for medium pyramid beads.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(5)
			return "[user] pulls on the cord and the largest bead stretches [who]'s rim wide, the relief palpable as the biggest sphere finally slides free."
		if(4)
			return "The fourth bead exits more easily, the decreasing girth a merciful contrast. [who]'s body starts to relax."
		if(3)
			return "The middle bead pops free without fanfare, the graduated descent making each extraction gentler than the last."
		if(2)
			return "The second bead is small enough to barely register, slipping past [who]'s well-stretched rim without effort."
		if(1)
			return "The final marble-sized bead tumbles free, and [who]'s hole finally empties. The graduated stretch leaves [who]'s rim tender but intact."

/// Medium pyramid ripcord — five graduating beads yanked largest-first.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] grabs the cord and rips all five beads from [who] in one savage pull — the largest first, then each smaller one in rapid succession, the graduated chain hammering [who]'s rim five times in a descending cascade."
	return "[user] draws the graduated chain from [who] in one continuous motion, the largest bead stretching the rim before each successively smaller one follows — a diminishing wave from challenge to nothing."

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 55, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	if(violent)
		target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
		target.Knockdown(12)


// ════════════════════════════════════════════════════════════════════════════
// INFLEXIBLE — Stiff rod of 4 bulbous beads. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/inflexible
	name = "inflexible anal beads"
	desc = "A rigid rod of four bulbous beads fused to an unyielding spine. It does not bend. You do."
	default_desc = "A rigid rod of four bulbous beads fused to an unyielding spine. It does not bend. You do."
	icon_state = "rear_bead_item_inflexible"
	item_state = "rear_bead_item_inflexible"
	bead_count = "inflexible"
	rear_accessory_noun = "inflexible anal beads"
	sellprice = 20

/obj/item/intimate_accessory/rear/plug/analbeads/inflexible/get_max_beads()
	return 4

/obj/item/intimate_accessory/rear/plug/analbeads/inflexible/get_bead_length()
	return "inflexible"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for inflexible beads — the rod doesn't bend, the body must.
/obj/item/intimate_accessory/rear/plug/analbeads/inflexible/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "[user] lines up the rigid rod with [who]'s rear and pushes. The first bulb crests the rim with an unyielding firmness — the rod does not curve to match [who]'s body. [who]'s body curves to match the rod."
		if(2)
			return "The second bulb forces [who]'s insides to straighten around the rigid spine, the inflexible shaft pressing against curves that were never meant to be straight. [who] can feel the rod's path like a ramrod."
		if(3)
			return "[who] groans as the third bulb is driven in, the rod now deep enough that [who]'s guts have to rearrange around its unyielding length. Every slight movement makes the entire shaft shift as one solid piece."
		if(4)
			return "The final bulb pops past [who]'s rim and the rod bottoms out, perfectly straight inside a body that is anything but. [who] can feel it pressing against the front of [target.p_their()] abdomen, a rigid presence that dominates every sensation."

/// Bespoke removal messages for inflexible beads.
/obj/item/intimate_accessory/rear/plug/analbeads/inflexible/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(4)
			return "[user] grips the base and pulls. The entire rigid rod shifts as one piece, [who]'s insides forced to straighten again as the deepest bulb begins its retreat, dragging across every nerve."
		if(3)
			return "The rod slides back another notch, the third bulb cresting [who]'s rim. [who]'s guts gratefully relax back into their natural curves as the unyielding shaft withdraws."
		if(2)
			return "Two down. The rod's rigidity means the extraction is smooth but relentless — no give, no flex, just a straight pull that [who]'s body has to accommodate."
		if(1)
			return "The final bulb pops free and the rod exits [who] entirely, leaving behind a strange hollowness — [who]'s insides slowly remembering how to be soft."

/// Inflexible ripcord — a rigid rod ripped out like a ramrod.
/obj/item/intimate_accessory/rear/plug/analbeads/inflexible/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] grabs the base of the rigid rod and rips it out of [who] in one straight pull — the four bulbs dragging across every nerve on the way out, the inflexible spine refusing to follow any curve, forcing [who]'s guts to straighten one final, brutal time."
	return "[user] grips the base and slowly withdraws the rigid rod from [who], the four bulbs sliding out one by one, [who]'s insides gratefully collapsing back into their natural curves as the unyielding spine retreats."

/obj/item/intimate_accessory/rear/plug/analbeads/inflexible/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 60, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	if(violent)
		// The rigid rod doesn't flex — violent removal forces the body to accommodate
		target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
		target.Knockdown(15)

// ════════════════════════════════════════════════════════════════════════════
// SMALL PYRAMID — 4 beads graduating small to large. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small
	name = "small pyramid anal beads"
	desc = "A short string of four graduating beads, starting from a pinprick and ending at something that makes you wince."
	default_desc = "A short string of four graduating beads, starting from a pinprick and ending at something that makes you wince."
	icon_state = "rear_bead_item_pyramid_small"
	item_state = "rear_bead_item_pyramid_small"
	bead_count = "pyramid_small"
	rear_accessory_noun = "small pyramid anal beads"
	sellprice = 12

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small/get_max_beads()
	return 4

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small/get_bead_length()
	return "pyramid_small"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for small pyramid beads — short but escalating.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "The first bead is tiny — it slips inside [who] almost unnoticed, a harmless little marble that settles deep."
		if(2)
			return "The second bead is larger, enough that [who]'s rim has to give a little. The cord pulls the first one deeper as it enters."
		if(3)
			return "[who] feels the stretch now — the third bead is considerably bigger, and [who]'s body has to work to accept it. The graduated pressure from within is unmistakable."
		if(4)
			return "The final bead is a genuine challenge, large enough to make [who] gasp as it forces past the rim. All four sit in a neat graduated stack inside, the smallest pressed deepest."

/// Bespoke removal messages for small pyramid beads.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(4)
			return "[user] tugs the cord and the largest bead stretches [who]'s rim wide on the way out, the relief immediate as the biggest sphere pops free."
		if(3)
			return "The next bead is noticeably easier, the shrinking size a welcome mercy after the first extraction."
		if(2)
			return "The second-to-last bead slides free with barely a whisper of resistance."
		if(1)
			return "The tiny final bead practically falls out on its own, leaving [who]'s hole twitching in the quiet aftermath."

/// Small pyramid ripcord — short but the size graduation makes it punchy.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] yanks the cord and all four beads rip out of [who] largest-first — the biggest one stretching [who]'s rim wide before the three smaller ones follow in a rapid-fire chain of pops."
	return "[user] pulls the short chain free in one smooth motion — the largest bead cresting [who]'s rim before the three smaller ones follow in quick succession, a brief but intense extraction."

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 55, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	if(violent)
		target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
		target.Knockdown(10)


// ════════════════════════════════════════════════════════════════════════════
// MIXED SMALL+MEDIUM 12 — Alternating small and medium, 12 total. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/mixed12
	name = "mixed small-medium anal beads"
	desc = "A lengthy string of twelve beads alternating between small and medium in a rhythm designed to massage every inch of the way in."
	default_desc = "A lengthy string of twelve beads alternating between small and medium in a rhythm designed to massage every inch of the way in."
	icon_state = "rear_bead_item_mixedbeads_12"
	item_state = "rear_bead_item_mixedbeads_12"
	bead_count = "mixed_12"
	rear_accessory_noun = "mixed small-medium anal beads"
	sellprice = 20

/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/get_max_beads()
	return 12

/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/get_bead_length()
	return "mixed_12"

/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/update_item_visuals()
	cut_overlays()
	if(src.blue_pearled)
		color = initial(color)
		item_state = "rear_bead_item_abyssor"
		icon_state = "rear_bead_item_abyssor"
		update_icon()
		return
	apply_intimate_item_tint()
	icon_state = "rear_bead_item_mixedbeads_12"
	item_state = "rear_bead_item_mixedbeads_12"
	var/special_overlay_state = get_special_rear_item_state("rear_bead_item", "mixedbeads_12")
	if(special_overlay_state)
		add_overlay(mutable_appearance(icon, special_overlay_state))
	else if(has_socketed_insert())
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, "rear_bead_item_mixedbeads_12_gem")
		if(intimate_gem_color)
			gem_overlay.color = intimate_gem_color
		add_overlay(gem_overlay)
	update_icon()

/// Bespoke insertion messages for mixed small+medium beads — a gentle but relentless cadence.
/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "The first small bead slips past [who]'s rim like nothing — a tiny marble that barely registers. Twelve to go."
		if(2)
			return "A medium bead follows immediately, just large enough to make [who]'s rim notice the difference. Small, then medium — the pattern announces itself."
		if(3, 4)
			return "Small, medium. The alternating sizes settle into a massage-like rhythm, each small bead a moment of ease before the medium stretches [who]'s rim just a little wider."
		if(5, 6)
			return "The beads keep coming in their gentle alternation. [who]'s body has found the rhythm now — accept, stretch, accept, stretch — the cord disappearing bead by bead."
		if(7, 8)
			return "Seven, eight. The fullness is building — each new pair pushes everything deeper, the small beads slipping between the mediums already inside like a rosary threading through [who]'s guts."
		if(9, 10)
			return "[who]'s stuffed. The alternating beads pack tight, small ones nestling in the gaps between mediums. Every new insertion shifts the entire chain deeper, and [who] can feel each individual sphere."
		if(11)
			return "Eleven. The penultimate small bead slides in easily, but there's barely any room left. [who] feels the cord go taut against the packed chain within."
		if(12)
			return "The final medium bead pops past [who]'s well-worked rim. All twelve sit inside in their alternating chain, packed tight from entrance to depth — a rosary of flesh and metal."

/// Bespoke removal messages for mixed small+medium beads.
/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(12, 11)
			return "[user] tugs the cord and the beads begin their exit — medium, small, medium, small — each one popping free in the same gentle rhythm they went in."
		if(10, 9)
			return "The alternating pops continue, [who]'s rim twitching with each extraction. The fullness eases bead by bead, the packed chain loosening inside."
		if(8, 7)
			return "Halfway out. The rhythm is almost soothing now — [who]'s body has memorized the cadence, each small bead a reprieve, each medium a soft stretch."
		if(6, 5)
			return "Six left, then five. The chain unspools from [who]'s insides in its gentle alternation, each bead dragging a little less than the last."
		if(4, 3)
			return "The last few pairs come easily, [who]'s well-stretched rim barely registering the small beads and only faintly noting the mediums."
		if(2)
			return "The second-to-last bead — a medium — slips free with a soft pop, leaving just one tiny marble inside."
		if(1)
			return "The final small bead tumbles out on its own, the twelve-bead rosary complete. [who]'s rim pulses gently, still echoing the alternating rhythm."

/// Mixed small+medium ripcord — twelve rapid-fire pops.
/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] seizes the cord and yanks — all twelve beads rip out of [who] in a rapid-fire chain of pops, the alternating small-medium cadence hammering [who]'s rim twelve times in the space of a heartbeat."
	return "[user] draws the cord steadily, twelve beads sliding free in their gentle alternation — small, medium, small, medium — the full rosary unspooling from [who] in one continuous, tingling chain."

/obj/item/intimate_accessory/rear/plug/analbeads/mixed12/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 60, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	// 12 rapid pops — overwhelming stimulation
	target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
	if(violent)
		target.apply_status_effect(/datum/status_effect/knot_gaped)
		target.Knockdown(15)

// ════════════════════════════════════════════════════════════════════════════
// MIXED MEDIUM+LARGE 8 — Alternating medium and large, 8 total. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/mixed8
	name = "mixed medium-large anal beads"
	desc = "Eight beads in alternating medium and large, each one a fresh challenge on the way in. The rhythm of relief and stretch makes every insertion its own ordeal."
	default_desc = "Eight beads in alternating medium and large, each one a fresh challenge on the way in. The rhythm of relief and stretch makes every insertion its own ordeal."
	icon_state = "rear_bead_item_mixed_8"
	item_state = "rear_bead_item_mixed_8"
	bead_count = "mixed_8"
	rear_accessory_noun = "mixed medium-large anal beads"
	sellprice = 25

/obj/item/intimate_accessory/rear/plug/analbeads/mixed8/get_max_beads()
	return 8

/obj/item/intimate_accessory/rear/plug/analbeads/mixed8/get_bead_length()
	return "mixed_8"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for mixed medium+large beads — the rhythm of relief and stretch.
/obj/item/intimate_accessory/rear/plug/analbeads/mixed8/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "The first bead — a medium — pushes past [who]'s rim with a firm pop. Manageable. A false sense of security."
		if(2)
			return "Then the large one. [who]'s rim has to stretch wide to swallow it, and just as [who] adjusts to the girth, the cord pulls the medium bead deeper. The rhythm begins."
		if(3)
			return "Medium again — the relief is immediate, almost dizzying after the large one. [who]'s body gratefully accepts the smaller sphere, not yet wise to the pattern."
		if(4)
			return "Large. [who] knew it was coming and it doesn't help. The stretch after the brief mercy of the medium makes it feel even bigger, [who]'s rim aching as it crests."
		if(5)
			return "Medium. The reprieve is shorter each time — [who]'s body barely has time to relax before the next bead is already pressing in."
		if(6)
			return "Large again. [who]'s abused rim has learned the cadence now but can't do anything about it, stretching obediently around the bigger sphere while dreading the next false mercy."
		if(7)
			return "The penultimate medium slides in almost gently, but [who] knows what follows. The anticipation is its own torment."
		if(8)
			return "The final large bead forces its way home. All eight sit inside in their cruel alternation, [who]'s guts packed with a rhythm of stretch and relief that pulses with every breath."

/// Bespoke removal messages for mixed medium+large beads.
/obj/item/intimate_accessory/rear/plug/analbeads/mixed8/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(8)
			return "[user] pulls and the final large bead stretches [who]'s rim wide on the way out, the alternating pattern beginning its reversal."
		if(7)
			return "A medium follows — the smaller size slipping free easily, a breath of relief between the heavier extractions."
		if(6, 5)
			return "Large, then medium. The rhythm plays out in reverse, each large bead making [who]'s rim ache before the medium grants a moment's mercy."
		if(4, 3)
			return "The pattern continues — stretch, relief, stretch, relief — [who]'s body twitching in Pavlovian anticipation of which size comes next."
		if(2)
			return "The second bead — a large one — drags free, leaving only the smallest medium behind."
		if(1)
			return "The final medium bead pops free almost anticlimactically, the alternating ordeal over. [who]'s hole gapes, still clenching in phantom rhythm."

/// Mixed medium+large ripcord — the alternating sizes make the rapid extraction punishing.
/obj/item/intimate_accessory/rear/plug/analbeads/mixed8/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] grabs the cord and rips all eight beads from [who] in one vicious yank — medium-large-medium-large — the alternating sizes battering [who]'s rim in a staccato of wet, brutal pops, each large bead hitting like a fist on the way out."
	return "[user] draws the alternating chain steadily from [who], the rhythm of medium-large-medium-large playing out in reverse — each large bead a fresh stretch, each medium a brief mercy."

/obj/item/intimate_accessory/rear/plug/analbeads/mixed8/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 65, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	target.apply_status_effect(/datum/status_effect/knot_gaped)
	if(violent)
		target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
		target.Knockdown(20)


// ════════════════════════════════════════════════════════════════════════════
// LONG SNAKE — 27 beads, meant to snake deep. Gem-socketable.
// Has bespoke insertion messages given the absurd length.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/snake
	name = "snaking anal beads"
	desc = "Twenty-seven beads on a seemingly endless cord, designed to coil deep into the rectum like a serpent finding its den. The pull ring at the end is your only guarantee of getting them all back."
	default_desc = "Twenty-seven beads on a seemingly endless cord, designed to coil deep into the rectum like a serpent finding its den. The pull ring at the end is your only guarantee of getting them all back."
	icon_state = "rear_bead_item_snake"
	item_state = "rear_bead_item_snake"
	bead_count = "snake"
	rear_accessory_noun = "snaking anal beads"
	sellprice = 35

/obj/item/intimate_accessory/rear/plug/analbeads/snake/get_max_beads()
	return 27

/obj/item/intimate_accessory/rear/plug/analbeads/snake/get_bead_length()
	return "snake"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for snake beads — depth-dependent flavor text.
/obj/item/intimate_accessory/rear/plug/analbeads/snake/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1 to 5)
			return "[user] feeds the first few beads into [who]'s rear — they slide in easily, the cord disappearing bead by bead."
		if(6 to 10)
			return "The beads keep going, each one popping past [who]'s rim with a wet click as the cord snakes deeper, beginning to coil inside."
		if(11 to 15)
			return "[who]'s stomach shifts visibly as the beads wind deeper, the cord tracing the curves of [who]'s guts from the inside. [who] can feel each bead settling into place like vertebrae."
		if(16 to 20)
			return "The cord is absurdly deep now — [who] can feel the beads pressing against organs that have no business being touched, each new insertion sending a full-body shudder up [who]'s spine."
		if(21 to 25)
			return "[who] groans as another bead is forced past the point of reason, the cord coiled so deep it feels like it's behind [who]'s lungs. The pull ring dangles from [who]'s ass like a bell rope."
		if(26 to 27)
			return "The final bead pops in with a wet finality. All twenty-seven are inside now, coiled in [who]'s guts like a rosary swallowed by a serpent. Only the pull ring remains outside, quivering with each of [who]'s ragged breaths."

/// Bespoke removal messages for snake beads.
/obj/item/intimate_accessory/rear/plug/analbeads/snake/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(22 to 27)
			return "[user] tugs the pull ring and the first bead pops free from the deep coil inside [who], dragging what feels like a foot of cord behind it. [who]'s entire body clenches."
		if(16 to 21)
			return "Another bead slides free with a long, slow pull, [who]'s insides reluctantly surrendering each one. The cord unspools from [who]'s guts like a tapeworm being drawn out."
		if(11 to 15)
			return "The beads are coming faster now, each pop making [who]'s rim twitch as the cord slithers through the turns of [who]'s bowels on the way out."
		if(6 to 10)
			return "[user] pulls with a steady hand, bead after bead clicking past [who]'s rim in a wet, rhythmic chain. [who] feels each one drag across every sensitive inch."
		if(2 to 5)
			return "The last few beads slide free easily, [who]'s hole gaping and twitching in the aftermath, slick cord trailing from the swollen rim."
		if(1)
			return "The final bead pops free with a wet, hollow sound, leaving [who]'s ass empty and gaping after hosting the entire serpentine length."



/// Snake ripcord — 27 beads yanked out in one pull. The length is the danger.
/obj/item/intimate_accessory/rear/plug/analbeads/snake/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] wraps the cord around [user.p_their()] fist, plants a foot on [who]'s back, and PULLS. Twenty-seven beads rip through [who]'s guts like a serpent being torn from its burrow — the cord whipping free in a wet, endless chain of pops that goes on and on and on."
	return "[user] pulls the cord hand over hand, drawing the endless chain of twenty-seven beads from [who]'s depths — each one surfacing from deeper inside than the last, the extraction taking an obscene amount of time as the full serpentine length unspools."

/obj/item/intimate_accessory/rear/plug/analbeads/snake/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 70, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	// 27 beads yanked at once — overwhelming
	target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
	target.apply_status_effect(/datum/status_effect/knot_gaped)
	if(violent)
		// Violent ripcord of 27 beads — the sheer friction is destructive
		if(target?.client?.prefs?.extreme_erp && user?.client?.prefs?.extreme_erp)
			var/obj/item/bodypart/chest/chest = target.get_bodypart(BODY_ZONE_CHEST)
			if(chest)
				chest.add_wound(/datum/wound/slash/small)
			send_extreme_content_visible_message(target, span_userdanger("The endless chain of beads drags through [target]'s guts with enough friction to burn — [target] can taste bile."))
		target.Knockdown(25)
// ════════════════════════════════════════════════════════════════════════════
// SPIKED — 6 spiked morningstar balls. Unsocketable. Extreme ERP only.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/spiked
	name = "spiked anal beads"
	desc = "Six steel balls bristling with short, cruel spikes. Less a sex toy, more a string of miniature morningstars. The kind of thing found in an inquisitor's footlocker."
	default_desc = "Six steel balls bristling with short, cruel spikes. Less a sex toy, more a string of miniature morningstars. The kind of thing found in an inquisitor's footlocker."
	icon_state = "rear_bead_item_spiked"
	item_state = "rear_bead_item_spiked"
	bead_count = "spiked"
	intimate_flags = INTIMATE_FLAG_INSERTABLE
	intimate_metal_name = "spiked iron"
	intimate_metal_color = "#4A4A4A"
	rear_accessory_noun = "spiked anal beads"
	sellprice = 30

/obj/item/intimate_accessory/rear/plug/analbeads/spiked/get_max_beads()
	return 6

/obj/item/intimate_accessory/rear/plug/analbeads/spiked/get_bead_length()
	return "spiked"

/obj/item/intimate_accessory/rear/plug/analbeads/spiked/update_item_visuals()
	cut_overlays()
	apply_intimate_item_tint()
	icon_state = "rear_bead_item_spiked"
	item_state = "rear_bead_item_spiked"
	update_icon()

/// Bespoke insertion messages for spiked beads — every single one hurts.
/obj/item/intimate_accessory/rear/plug/analbeads/spiked/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "[user] presses the first spiked ball against [who]'s rim. The steel points dimple the flesh before the sphere forces through, each spike dragging a thin line of blood on the way in."
		if(2)
			return "The second morningstar ball follows, the spikes catching on [who]'s already-torn rim. [who] can feel each individual point scraping the raw inner walls."
		if(3)
			return "Blood is running freely now. The third spiked ball grinds past [who]'s entrance, the spikes of the previous beads pressing into soft tissue as everything shifts deeper to accommodate."
		if(4)
			return "[who]'s body convulses around the fourth ball, muscles clenching involuntarily against the spikes — which only drives them deeper into the walls. Every twitch is a fresh puncture."
		if(5)
			return "The fifth spiked sphere is forced in against [who]'s body's screaming protests, the chain of morningstars inside rearranging with audible wet sounds, spikes scoring new furrows."
		if(6)
			return "The final morningstar ball pops past [who]'s shredded rim. All six are inside now, a chain of spiked steel buried in torn flesh. Every breath makes [who] feel the points shift."

/// Bespoke removal messages for spiked beads — coming out is worse.
/obj/item/intimate_accessory/rear/plug/analbeads/spiked/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(6)
			return "[user] yanks the cord. The first spiked ball drags backward through [who]'s guts, every spike that went in smoothly now catching and tearing on the way out. [who] screams."
		if(5)
			return "The second extraction is worse — the spikes have had time to settle into the wounds they made, and pulling them free reopens every single one."
		if(4)
			return "Blood and worse coats the emerging ball. The spikes glisten crimson as [user] pulls steadily, [who]'s body trying to clench around the remaining chain and only impaling itself further."
		if(3)
			return "Three left inside. [who] can feel the remaining spiked balls shifting as the cord goes taut, the points finding fresh flesh to dig into."
		if(2)
			return "The fifth ball rips free with a wet tearing sound. [who]'s rim is barely recognizable, the skin shredded by repeated passage of steel thorns."
		if(1)
			return "The final morningstar ball tears free, dragging a trail of blood behind it. [who]'s hole is a ruin of punctures and lacerations, twitching weakly around nothing."


/// Spiked ripcord — this is a war crime.
/obj/item/intimate_accessory/rear/plug/analbeads/spiked/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] grabs the cord in both hands and RIPS. All six spiked balls tear through [who]'s insides like a chain of morningstars dragged through a wound, every spike catching and shredding flesh on the way out in a spray of blood."
	return "[user] pulls the cord steadily and the six spiked balls grind their way out of [who] one after another, each spike scraping fresh furrows through already-torn tissue."

/obj/item/intimate_accessory/rear/plug/analbeads/spiked/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 65, TRUE, ignore_walls = FALSE)
	// Spiked beads always cause damage — they're spiked
	target.emote("scream", forced = TRUE)
	target.apply_status_effect(/datum/status_effect/knot_gaped)
	// Apply lacerations from the spikes
	var/obj/item/bodypart/chest/chest = target.get_bodypart(BODY_ZONE_CHEST)
	if(chest)
		chest.add_wound(/datum/wound/slash/small)
	if(violent)
		// Violent ripcord with spiked beads — grievous internal damage
		if(chest)
			chest.add_wound(/datum/wound/slash/large)
		var/obj/item/bodypart/groin = target.get_bodypart(check_zone(BODY_ZONE_PRECISE_GROIN))
		if(groin)
			groin.add_wound(/datum/wound/fracture)
		send_extreme_content_visible_message(target, span_userdanger("[target]'s insides are shredded — blood pours from between [target.p_their()] legs as the spiked chain tears free."))
		playsound(target, 'sound/combat/fracture/fracturewet (1).ogg', 55, TRUE)
		target.Knockdown(40)
/// Block ALL socketing — spiked beads have no sockets.
/obj/item/intimate_accessory/rear/plug/analbeads/spiked/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/roguegem) || istype(I, /obj/item/pearl/blue) || istype(I, /obj/item/riddleofsteel) || src.is_psydonic_socket_item(I) || src.is_zizite_socket_item(I))
		to_chat(user, span_warning("The spikes cover every possible socket."))
		return TRUE
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel))
		to_chat(user, span_warning("There is nothing socketed in these spiked beads."))
		return TRUE
	return ..()

/// Gate behind extreme ERP — only allow equipping if both parties consent.
/obj/item/intimate_accessory/rear/plug/analbeads/spiked/can_attach_to_intimate_slot(mob/living/carbon/human/H, mob/user, slot, silent = FALSE, require_open_slot = TRUE)
	. = ..()
	if(!.)
		return FALSE
	if(!user?.client?.prefs?.extreme_erp)
		if(!silent)
			to_chat(user, span_warning("You need extreme content enabled to use this."))
		return FALSE
	if(H != user && !H?.client?.prefs?.extreme_erp)
		if(!silent)
			to_chat(user, span_warning("[H] does not have extreme content enabled."))
		return FALSE
	return TRUE

// ════════════════════════════════════════════════════════════════════════════
// LARGE PYRAMID — 8 beads graduating small to very large. Gem-socketable.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large
	name = "large pyramid anal beads"
	desc = "Eight beads in a merciless graduation from pebble to plum, each step larger than the last. The final bead is the size of a closed fist."
	default_desc = "Eight beads in a merciless graduation from pebble to plum, each step larger than the last. The final bead is the size of a closed fist."
	icon_state = "rear_bead_item_pyramid_large"
	item_state = "rear_bead_item_pyramid_large"
	bead_count = "pyramid_large"
	rear_accessory_noun = "large pyramid anal beads"
	sellprice = 30

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large/get_max_beads()
	return 8

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large/get_bead_length()
	return "pyramid_large"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for large pyramid beads — escalating dread.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "The first bead is barely a pebble — it slips past [who]'s rim without ceremony, a deceptive mercy."
		if(2)
			return "The second bead follows easily, only slightly larger. [who] barely notices the difference. Not yet."
		if(3)
			return "A noticeable step up. [who]'s rim has to stretch to accept the third, a preview of what's coming."
		if(4)
			return "The fourth bead requires a push. [who] feels the graduated girth now, the string pulling the smaller beads deeper as each new one claims the entrance."
		if(5)
			return "[who] winces as the fifth bead forces past the rim, large enough now that [who]'s body instinctively tries to resist. [user] is patient."
		if(6)
			return "The sixth bead is the size of a small egg. [who] has to consciously relax as [user] works it in, the graduated chain below dragging taut inside."
		if(7)
			return "[who] gasps — the seventh bead is unmistakably large, stretching [who]'s rim wide enough to ache as it finally crests and pops inside, displacing everything below it deeper."
		if(8)
			return "The final bead is the size of a closed fist. [user] has to twist and rock it before [who]'s abused rim stretches impossibly wide to swallow it, the entire graduated chain now buried to the hilt."

/// Bespoke removal messages for large pyramid beads.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(8)
			return "[user] grips the ring and pulls. The fist-sized bead stretches [who]'s rim wide on the way out, [who]'s body shuddering in relief as the largest sphere finally crests free."
		if(7)
			return "The next bead is noticeably smaller — still large, but the contrast with what just left makes it almost feel like mercy."
		if(6, 5)
			return "Each bead pops free a little easier than the last, the diminishing size a welcome reprieve as [who]'s insides slowly empty."
		if(4, 3)
			return "The middle beads slide out smoothly, [who]'s stretched rim barely registering them after what it endured."
		if(2)
			return "The second-to-last bead is small enough to slip free almost unnoticed, a ghost of the ordeal it was to put them in."
		if(1)
			return "The final pebble-sized bead tumbles out on its own, the string going slack. [who]'s rim twitches, slowly relearning how to close."


// ════════════════════════════════════════════════════════════════════════════
// GIANT — 6 fist-sized balls. Tauric-intended but usable by anyone. Gem-socketable.

/// Large pyramid ripcord — eight graduating beads ripped out largest-first.
/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] seizes the cord and rips the entire graduated chain out of [who] in one savage pull — the fist-sized bead first, then each smaller one in a machine-gun chain of wet pops that makes [who]'s entire body convulse."
	return "[user] steadily draws the graduated chain from [who], the largest bead stretching the rim wide before each successively smaller one slides free, an agonizing countdown from agony to relief."

/obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 65, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
	if(violent)
		target.apply_status_effect(/datum/status_effect/knot_gaped)
		target.Knockdown(20)
// ════════════════════════════════════════════════════════════════════════════

/obj/item/intimate_accessory/rear/plug/analbeads/giant
	name = "giant anal beads"
	desc = "Six fist-sized balls on a thick cord, each one a genuine test of anatomy. Likely intended for tauric bodies with the accommodating biology to match — although nothing is stopping those of smaller build from unwisely attempting the full set."
	default_desc = "Six fist-sized balls on a thick cord, each one a genuine test of anatomy. Likely intended for tauric bodies with the accommodating biology to match — although nothing is stopping those of smaller build from unwisely attempting the full set."
	icon_state = "rear_bead_item_giant"
	item_state = "rear_bead_item_giant"
	bead_count = "giant"
	rear_accessory_noun = "giant anal beads"
	sellprice = 40

/obj/item/intimate_accessory/rear/plug/analbeads/giant/get_max_beads()
	return 6

/obj/item/intimate_accessory/rear/plug/analbeads/giant/get_bead_length()
	return "giant"

// update_item_visuals() inherited from parent — uses get_bead_length() scaffold.

/// Bespoke insertion messages for giant beads — each one is a physical ordeal.
/obj/item/intimate_accessory/rear/plug/analbeads/giant/get_push_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted + 1
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(1)
			return "[user] presses the first fist-sized ball against [who]'s rim. It takes a long, agonizing moment before the hole stretches wide enough to swallow it with a wet pop."
		if(2)
			return "The second ball meets more resistance — [who]'s body clenches against the intrusion, but [user] pushes until the rim surrenders and the sphere disappears inside."
		if(3)
			return "Three down. [who]'s stomach is starting to visibly distend, the outline of the massive balls pressing against [who]'s skin from within."
		if(4)
			return "[who] makes a choked sound as the fourth ball forces its way in, the sheer volume inside making every breath feel shallow. [who]'s guts are running out of room."
		if(5)
			return "The fifth ball has to be worked in slowly, [user] twisting and rocking it as [who]'s body fights the impossible fullness. Something shifts audibly inside to make room."
		if(6)
			return "The final ball pops past [who]'s wrecked rim with a sound like a cork in a wine barrel. All six fist-sized spheres are inside now, and [who]'s belly is round with them."

/// Bespoke removal messages for giant beads.
/obj/item/intimate_accessory/rear/plug/analbeads/giant/get_pull_bead_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/depth = beads_inserted
	var/who = (user == target) ? "[user]" : "[target]"
	switch(depth)
		if(6)
			return "[user] grips the pull ring and heaves. The first ball emerges with glacial slowness, [who]'s rim stretching grotesquely wide around the sphere before it finally pops free."
		if(5)
			return "The second ball drags against [who]'s insides on the way out, the massive sphere pulling an obscene bulge through [who]'s abdomen before cresting the rim."
		if(4)
			return "Three to go. Each extraction makes [who]'s entire body spasm, the void left behind making [who]'s guts lurch and settle in unfamiliar ways."
		if(3)
			return "[user] pulls another free, and the relief is immediate — [who]'s belly deflates visibly, though the remaining balls still shift and press inside."
		if(2)
			return "The fifth ball slides out more easily, [who]'s rim too beaten to resist. The stretch barely registers anymore."
		if(1)
			return "The last ball tumbles free with a hollow, wet sound, leaving [who]'s hole utterly destroyed — gaping, twitching, and struggling to remember how to close."


/// Giant bead ripcord — the body was never meant to pass six fist-sized spheres in rapid succession.
/obj/item/intimate_accessory/rear/plug/analbeads/giant/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	if(violent)
		return "[user] wraps the cord around [user.p_their()] fist and HEAVES. All six fist-sized balls rip out of [who] in a single brutal chain, each one stretching [who]'s rim to its absolute limit before popping free in rapid succession like cannonballs from a breech."
	return "[user] grips the pull ring and begins the long, deliberate extraction — six fist-sized spheres sliding free one after another in an agonizingly slow chain, each one stretching [who]'s hole wide before popping loose."

/obj/item/intimate_accessory/rear/plug/analbeads/giant/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	playsound(target, 'sound/misc/mat/pop.ogg', 70, TRUE, ignore_walls = FALSE)
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	// Gentle: instant orgasm + gaped
	target.apply_status_effect(/datum/status_effect/knot_gaped)
	target.apply_status_effect(/datum/status_effect/knot_fucked_stupid)
	if(violent)
		// Violent + extreme: pelvic fracture from six fist-sized balls ripping through
		if(target?.client?.prefs?.extreme_erp && user?.client?.prefs?.extreme_erp)
			var/obj/item/bodypart/groin = target.get_bodypart(check_zone(BODY_ZONE_PRECISE_GROIN))
			if(groin)
				groin.add_wound(/datum/wound/fracture)
			send_extreme_content_visible_message(target, span_userdanger("Something cracks inside [target]'s pelvis as the last ball tears free."))
			playsound(target, 'sound/combat/fracture/fracturewet (1).ogg', 50, TRUE)
		target.Knockdown(30)


// ════════════════════════════════════════════════════════════════════════════
// UNFINISHED ANAL BEADS — Crafted at the anvil, used in hand to pick a shape.
// Works like the dildo crafting system: one recipe per metal, shape is chosen
// on use rather than flooding the anvil with every possible subtype.
// ════════════════════════════════════════════════════════════════════════════

/obj/item/unfinished_analbeads
	name = "unfinished anal beads"
	desc = "An unfinished set of anal beads. Use in hand to shape them."
	icon = 'modular/icons/obj/lewd/intimate_accessories.dmi'
	icon_state = "rear_beads_item_short"
	w_class = WEIGHT_CLASS_SMALL
	var/bead_metal_name
	var/bead_metal_color
	var/bead_is_silver = FALSE
	var/base_sell = 10

/obj/item/unfinished_analbeads/Initialize()
	. = ..()
	if(bead_metal_name)
		name = "unfinished [bead_metal_name] anal beads"
	if(bead_metal_color)
		color = bead_metal_color

/obj/item/unfinished_analbeads/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to choose a bead shape.")

/obj/item/unfinished_analbeads/attack_self(mob/living/user)
	. = ..()
	if(!istype(user) || user.incapacitated())
		return
	customize(user)

/obj/item/unfinished_analbeads/proc/customize(mob/living/user)
	var/list/shape_choices = list(
		"Standard (4 beads)",
		"Five Beads (5)",
		"Six Beads (6)",
		"Small (12 beads)",
		"Small Pyramid (4 graduating)",
		"Medium Pyramid (5 graduating)",
		"Large Pyramid (8 graduating)",
		"Inflexible (4 rigid)",
		"Mixed Small+Medium (12)",
		"Mixed Medium+Large (8)",
		"Snake (27 beads)",
		"Giant (6 fist-sized)",
		"Glass (4, fragile)",
		"Spiked (6, extreme)",
	)

	var/choice = tgui_input_list(user, "Choose a shape for the anal beads.", "Anal Bead Shape", shape_choices)
	if(!choice || QDELETED(src) || user.incapacitated() || !in_range(user, src))
		return

	var/bead_type
	switch(choice)
		if("Standard (4 beads)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads
		if("Five Beads (5)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/fivebeads
		if("Six Beads (6)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/sixbeads
		if("Small (12 beads)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/small12
		if("Small Pyramid (4 graduating)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small
		if("Medium Pyramid (5 graduating)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium
		if("Large Pyramid (8 graduating)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large
		if("Inflexible (4 rigid)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/inflexible
		if("Mixed Small+Medium (12)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/mixed12
		if("Mixed Medium+Large (8)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/mixed8
		if("Snake (27 beads)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/snake
		if("Giant (6 fist-sized)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/giant
		if("Glass (4, fragile)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/glass
		if("Spiked (6, extreme)")
			bead_type = /obj/item/intimate_accessory/rear/plug/analbeads/spiked

	if(!bead_type)
		return

	var/obj/item/intimate_accessory/rear/plug/analbeads/new_beads = new bead_type(get_turf(user))

	// Spiked beads have fully hardcoded metal properties — skip transfer.
	// Glass beads keep their own metal name ("glass") but accept the metal color for their caps.
	var/is_spiked = istype(new_beads, /obj/item/intimate_accessory/rear/plug/analbeads/spiked)
	if(!is_spiked)
		if(!istype(new_beads, /obj/item/intimate_accessory/rear/plug/analbeads/glass))
			if(bead_metal_name)
				new_beads.intimate_metal_name = bead_metal_name
		if(bead_metal_color)
			new_beads.intimate_metal_color = bead_metal_color
		new_beads.is_silver = bead_is_silver
	new_beads.sellprice = base_sell
	new_beads.base_sellprice = base_sell
	new_beads.refresh_rear_plug_state()

	to_chat(user, span_notice("You shape the metal into \a [new_beads]."))
	if(!user.put_in_hands(new_beads))
		new_beads.forceMove(get_turf(user))
	qdel(src)

// ── Metal Variants ──────────────────────────────────────────────────────────

/obj/item/unfinished_analbeads/iron
	bead_metal_name = "iron"
	bead_metal_color = "#9EA48E"
	base_sell = 5

/obj/item/unfinished_analbeads/copper
	bead_metal_name = "copper"
	bead_metal_color = "#8C4734"
	base_sell = 5

/obj/item/unfinished_analbeads/steel
	bead_metal_name = "steel"
	bead_metal_color = "#9BADB7"
	base_sell = 10

/obj/item/unfinished_analbeads/bronze
	bead_metal_name = "bronze"
	bead_metal_color = "#CBBF9A"
	base_sell = 12

/obj/item/unfinished_analbeads/silver
	bead_metal_name = "silver"
	bead_metal_color = "#C6D5E1"
	bead_is_silver = TRUE
	base_sell = 30

/obj/item/unfinished_analbeads/gold
	bead_metal_name = "gold"
	bead_metal_color = "#C4B651"
	base_sell = 50

/obj/item/unfinished_analbeads/blacksteel
	bead_metal_name = "blacksteel"
	bead_metal_color = "#A2CBE3"
	base_sell = 150
