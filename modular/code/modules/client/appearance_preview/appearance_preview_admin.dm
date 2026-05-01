/**
 * Admin recovery surface for the appearance preview asset bundle.
 *
 * The runtime `mount_bundle()` path is fail-closed: any failure (missing
 * PNG, malformed manifest, iconforge error) leaves `assets` empty for the
 * rest of the round with only a server-log diagnostic. Before this verb
 * existed, a restart was the only remedy. The verb below lets an admin
 * re-attempt the mount in place and surfaces the structured failure reason
 * from `mount_bundle` directly in chat, so the fix path is:
 *
 *   1. Ship the missing PNG (or fix the upstream build).
 *   2. An admin runs `admin_rebuild_appearance_preview_bundle`.
 *   3. Chat reports either "bundle mounted" or "mount failed: <reason>".
 *
 * The verb is gated by `R_ADMIN`; there is no `/client/verb` auto-attach,
 * so it is invoked via the callproc admin tool (or added to an admin-verb
 * list in a follow-up). Keeping it as a /client/proc instead of /client/verb
 * avoids exposing the verb to non-admin clients in the built-in verb panel.
 */

/client/proc/admin_rebuild_appearance_preview_bundle()
	set name = "Rebuild Appearance Preview Bundle"
	set category = "Debug"
	set desc = "Re-run appearance preview asset mount without restarting the server."

	if(!check_rights(R_ADMIN))
		return

	var/datum/asset/simple/appearance_preview/preview_asset = get_asset_datum(/datum/asset/simple/appearance_preview)
	if(!istype(preview_asset))
		to_chat(usr, span_warning("appearance_preview: asset datum unavailable; cannot rebuild."))
		return

	// `mount_bundle()` populates `assets` on success and leaves it empty on
	// failure. It also clears + re-sets `last_mount_failure_reason` per run,
	// so reading it after the call gives the admin the exact reason for the
	// current attempt — not a stale one from a prior mount.
	var/ok = preview_asset.mount_bundle()
	if(ok)
		to_chat(usr, span_notice("appearance_preview: bundle mounted ([length(preview_asset.assets)] assets registered)."))
		log_admin("[key_name(usr)] rebuilt the appearance preview asset bundle successfully.")
		message_admins("[key_name_admin(usr)] rebuilt the appearance preview asset bundle.")
		return

	var/reason = preview_asset.last_mount_failure_reason
	if(!reason)
		reason = "unspecified failure; see server log for details."
	to_chat(usr, span_warning("appearance_preview: bundle mount FAILED — [reason]"))
	log_admin("[key_name(usr)] attempted appearance preview rebuild; failed: [reason]")
	message_admins("[key_name_admin(usr)] attempted appearance preview rebuild; failed: [reason]")
