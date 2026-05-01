/**
 * custom_piercing_post_render.dm — Render hook for custom piercing slots
 * that have no legacy sprite_accessory pipeline of their own.
 *
 * This covers:
 *   * The freeform slots (custom_upper / custom_lower) — no item required.
 *   * Item-gated slots without a legacy overlay (nose / belly / tongue /
 *     rear piercing / insertable_genital). The composer's equip check
 *     still gates them so nothing renders unless the item is present.
 *
 * Slots that already wire through adjust_appearance_list (ear / breast /
 * genital / pintle / chastity / insertable_rear) are NOT handled here to
 * avoid double-rendering; they stay on the legacy body-offset pipeline.
 *
 * ## Single-refresh contract (Step 12)
 *
 * `_rebuild_custom_piercing_post_overlays` is the sole point at which
 * post-pass custom piercing overlays are recomputed on a mob. It is driven
 * exclusively from `/mob/living/carbon/human/update_body_parts`, so one
 * update_body_parts call produces exactly one cut-then-add pass. The
 * appearance preview commit pipeline refreshes the lobby mannequin via
 * `prefs.update_preview_icon` once per successful commit, which indirectly
 * triggers this rebuild once per commit. Do not call this proc from any
 * other site — adding a second invocation would break the single-refresh
 * guarantee the commit contract depends on.
 *
 * Appearances are tracked in `_custom_piercing_post_overlays` so they can
 * be cut cleanly on the next body refresh.
 */

/mob/living/carbon/human
	/// Appearances currently applied for post-pass custom piercings.
	var/list/_custom_piercing_post_overlays
	/// Last key used to build `_custom_piercing_post_overlays`.
	var/tmp/custom_piercing_post_overlay_key
	/// Copied preferences-side version for custom piercing render-relevant state.
	var/tmp/custom_piercings_version = 0
	/// TRUE when preview-only paths intentionally suppress post-render custom piercing overlays.
	var/tmp/custom_piercing_post_render_suppressed = FALSE
	/// Preview-only `slot:index` target hidden from the DM dummy while TGUI overlays that selected entry.
	var/tmp/custom_piercing_preview_suppressed_target_key = null

/mob/living/carbon/human/update_body_parts(redraw = FALSE)
	. = ..()
	_rebuild_custom_piercing_post_overlays()

/mob/living/carbon/human/proc/generate_custom_piercing_post_overlay_key()
	var/preview_target_key = istext(custom_piercing_preview_suppressed_target_key) ? custom_piercing_preview_suppressed_target_key : ""
	return md5("[dir]|[obscured_flags]|[custom_piercings_version]|[custom_piercing_post_render_suppressed ? 1 : 0]|[preview_target_key]")

/mob/living/carbon/human/proc/_rebuild_custom_piercing_post_overlays()
	var/new_key = generate_custom_piercing_post_overlay_key()
	if(custom_piercing_post_overlay_key == new_key)
		return
	custom_piercing_post_overlay_key = new_key

	if(length(_custom_piercing_post_overlays))
		cut_overlay(_custom_piercing_post_overlays)
		_custom_piercing_post_overlays = null
	if(custom_piercing_post_render_suppressed || !length(custom_piercings))
		return
	if(!GLOB.custom_piercing_post_render_slots)
		return
	var/list/new_appearances = list()
	for(var/slot_key in GLOB.custom_piercing_post_render_slots)
		var/category = custom_piercing_slot_manifest_category(slot_key)
		if(!category)
			continue
		var/list/slot_appearances = compose_custom_piercing_slot_appearances(src, slot_key)
		if(!(slot_key in GLOB.custom_piercing_freeform_slots))
			apply_custom_piercing_slot_props(slot_appearances, src, slot_key)
		new_appearances += slot_appearances
	if(!length(new_appearances))
		return
	_custom_piercing_post_overlays = new_appearances
	add_overlay(new_appearances)
