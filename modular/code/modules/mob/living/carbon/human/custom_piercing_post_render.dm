/**
 * custom_piercing_post_render.dm — Render hook for custom piercing slots
 * that have no legacy sprite_accessory pipeline of their own.
 *
 * This covers:
 *   • The freeform slots (custom_upper / custom_lower) — no item required.
 *   • Item-gated slots without a legacy overlay (nose / belly / tongue /
 *     rear piercing / insertable_genital). The composer's equip check
 *     still gates them so nothing renders unless the item is present.
 *
 * Slots that already wire through adjust_appearance_list (ear / breast /
 * genital / pintle / chastity / insertable_rear) are NOT handled here to
 * avoid double-rendering; they stay on the legacy body-offset pipeline.
 *
 * Appearances are tracked in `_custom_piercing_post_overlays` so they can
 * be cut cleanly on the next body refresh.
 */

/mob/living/carbon/human
	/// Appearances currently applied for post-pass custom piercings.
	var/list/_custom_piercing_post_overlays

/mob/living/carbon/human/update_body_parts(redraw = FALSE)
	. = ..()
	_rebuild_custom_piercing_post_overlays()

/mob/living/carbon/human/proc/_rebuild_custom_piercing_post_overlays()
	if(length(_custom_piercing_post_overlays))
		cut_overlay(_custom_piercing_post_overlays)
		_custom_piercing_post_overlays = null
	if(!GLOB.custom_piercing_post_render_slots)
		return
	var/list/new_appearances = list()
	for(var/slot_key in GLOB.custom_piercing_post_render_slots)
		new_appearances += compose_custom_piercing_slot_appearances(src, slot_key)
	if(!length(new_appearances))
		return
	_custom_piercing_post_overlays = new_appearances
	add_overlay(new_appearances)
