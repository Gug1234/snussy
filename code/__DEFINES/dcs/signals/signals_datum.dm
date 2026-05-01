/// from datum ui_act (usr, action)
#define COMSIG_UI_ACT "COMSIG_UI_ACT"

/// Emitted on a /datum/preferences after its character_preview_view has run
/// update_body(). Used by the lobby 3x3 HUD observer to re-copy the shared
/// dummy's appearance onto its cardinal holders without owning its own dummy.
/// No args.
#define COMSIG_PREFS_PREVIEW_UPDATED "prefs_preview_updated"
