/**
 * Stupefied — applied by the jelly ear-fuck action.
 * Lowers Intelligence by 2 for 2 minutes. Refreshes on reapplication.
 * Uses the same effectedstats mechanism as mishap_dimwitted, so no
 * manual on_apply / on_remove bookkeeping is needed for the stat penalty.
 */

/atom/movable/screen/alert/status_effect/jelly_stupefied
	name = "Stupefied"
	desc = "Something wriggles deep within my skull... my thoughts are thick and slow."
	icon_state = "mind_control"

/datum/status_effect/debuff/jelly_stupefied
	id = "jelly_stupefied"
	duration = 2 MINUTES
	status_type = STATUS_EFFECT_REFRESH
	effectedstats = list("intelligence" = -2)
	alert_type = /atom/movable/screen/alert/status_effect/jelly_stupefied

