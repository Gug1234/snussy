/**
 * ui_act_rate_limiter.dm — Shared rolling-window rate limiter for TGUI editor
 * Topic() floods.
 *
 * The taur genital offset editor, custom piercing editor and
 * all future TGUI editors with drag-heavy input are vulnerable to Topic() floods that can
 * lag or crash the server if abused. To mitigate this, we want to put in place a
 * the same flood-protection shape: a rolling window of call timestamps,
 * a per-window cap, a short soft-block on overage, and a throttled admin
 * notification. This datum centralises that logic so both editors (and any
 * future ones with drag-heavy input) can just compose one of these.
 *
 * Usage:
 *   var/datum/ui_act_rate_limiter/rate_limiter
 *
 *   /datum/my_editor/New()
 *     rate_limiter = new("my editor")
 *
 *   /datum/my_editor/ui_act(action, list/params)
 *     . = ..()
 *     if(.)
 *       return
 *     if(rate_limiter.check_blocked(usr))
 *       return FALSE
 *     // ...normal handling...
 */

/datum/ui_act_rate_limiter
	/// Cap on ui_act() calls inside one `window_ds` window before a soft
	/// block kicks in. 25/sec matches the drag-throttled frontend budget
	/// with headroom.
	var/max_per_window = 25
	/// Rolling window length in deciseconds. 10 ds = 1 second, so the default
	/// cap effectively reads as "25 calls per second".
	var/window_ds = 10
	/// Minimum deciseconds between admin flood notifications for this
	/// limiter instance, to keep the admin channel quiet during long floods.
	var/notify_cooldown_ds = 300
	/// Human-readable label used in admin notifications.
	var/editor_label = "editor"
	/// world.time stamps of recent ui_act() calls, trimmed to the window.
	var/list/recent_act_times
	/// world.time at which we last notified admins about this user abusing
	/// the editor, throttled by `notify_cooldown_ds`.
	var/last_abuse_notify_time = 0
	/// world.time until which further ui_act() calls are dropped silently.
	var/blocked_until = 0

/datum/ui_act_rate_limiter/New(label, max_per_win = 25, win_ds = 10, notify_ds = 300)
	if(istext(label))
		editor_label = label
	if(isnum(max_per_win) && max_per_win > 0)
		max_per_window = max_per_win
	if(isnum(win_ds) && win_ds > 0)
		window_ds = win_ds
	if(isnum(notify_ds) && notify_ds >= 0)
		notify_cooldown_ds = notify_ds

/**
 * Records one ui_act() call and returns TRUE if the call should be dropped
 * because the user is over budget. On the overage transition an admin
 * notification is emitted (throttled by `notify_cooldown_ds`).
 */
/datum/ui_act_rate_limiter/proc/check_blocked(mob/user)
	var/now = world.time
	if(blocked_until && now < blocked_until)
		return TRUE
	if(!islist(recent_act_times))
		recent_act_times = list()
	var/cutoff = now - window_ds
	while(length(recent_act_times) && recent_act_times[1] < cutoff)
		recent_act_times.Cut(1, 2)
	recent_act_times += now
	if(length(recent_act_times) <= max_per_window)
		return FALSE
	blocked_until = now + window_ds
	recent_act_times.Cut()
	if(now - last_abuse_notify_time >= notify_cooldown_ds)
		last_abuse_notify_time = now
		var/key_str = user ? key_name(user) : "UNKNOWN"
		var/msg = "[editor_label]: [key_str] exceeded [max_per_window] Topic() calls/[window_ds / 10]s; blocking their edits for [window_ds / 10]s, check for potential abuse."
		log_admin(msg)
		message_admins(span_adminnotice(msg))
	return TRUE
