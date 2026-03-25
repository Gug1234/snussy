// Backend for consolidated ERP Preferences Menu (tgui)
// Requires: #include "erp_toggle_defs.dm" in this or a parent file

#include "erp_toggle_defs.dm"

/client/proc/open_erp_preferences_menu()
	if(!prefs)
		to_chat(src, span_warning("Preferences not loaded."))
		return

	var/list/toggles = list()
	#define _ERP_TOGGLE_ENTRY(key, name, desc) \
		var/enabled = prefs[key]; \
		toggles += list(list( \
			"key" = key, \
			"name" = name, \
			"description" = desc, \
			"enabled" = enabled \
		))
	#define _ERP_TOGGLE_LOOP \
		_ERP_TOGGLE_ENTRY("sexable", "Allow ERP Panel", "Allow others to use the ERP panel on you.") \
		_ERP_TOGGLE_ENTRY("chastenable", "Chastity Content", "Show and interact with chastity device content.") \
		_ERP_TOGGLE_ENTRY("chastity_hardmode", "Permanent Chastity Binding", "Enables permanent chastity device binding. Only the device's unique key can unlock it. Disabling requires a special prayer.") \
		_ERP_TOGGLE_ENTRY("extreme_erp", "Extreme ERP Content", "Enable extreme content (gore, ryona, etc.) in the ERP panel.") \
		_ERP_TOGGLE_ENTRY("edging", "Edging Content", "Enable edging content in the ERP panel.")

	_ERP_TOGGLE_LOOP

	#undef _ERP_TOGGLE_ENTRY
	#undef _ERP_TOGGLE_LOOP

	new /datum/tgui(src.mob, src, "ErpPreferences", "ERP Preferences")
		.ui_data = proc/ui_data_erp_preferences
		.ui_act = proc/ui_act_erp_preferences
		.open()

// Data sent to tgui
/client/proc/ui_data_erp_preferences(user)
	var/list/toggles = list()
	#define _ERP_TOGGLE_ENTRY(key, name, desc) \
		toggles += list(list( \
			"key" = key, \
			"name" = name, \
			"description" = desc, \
			"enabled" = prefs[key] \
		))
	_ERP_TOGGLE_LOOP
	#undef _ERP_TOGGLE_ENTRY
	#undef _ERP_TOGGLE_LOOP
	return list("toggles" = toggles)

// Handle tgui actions
/client/proc/ui_act_erp_preferences(act_type, payload, tgui, state)
	if(act_type == "save")
		var/changed = FALSE
		#define _ERP_TOGGLE_ENTRY(key, name, desc) \
			if(payload[key] != null && prefs[key] != payload[key]) { \
				if(key == "chastity_hardmode" && payload[key] == 0 && prefs[key] == 1) { \
					to_chat(src, span_warning("Permanent binding can only be disabled via the special prayer in the normal menu.")); \
					continue; \
				} \
				prefs[key] = payload[key]; \
				changed = TRUE; \
			}
		_ERP_TOGGLE_LOOP
		#undef _ERP_TOGGLE_ENTRY
		#undef _ERP_TOGGLE_LOOP
		if(changed)
			prefs.save_preferences()
		to_chat(src, span_notice("ERP preferences updated."))
		return TRUE
	if(act_type == "cancel")
		return TRUE
	return FALSE

/client/verb/erp_preferences()
	set name = "ERP Preferences"
	set category = "Options"
	set desc = "Open the consolidated ERP preferences menu."
	open_erp_preferences_menu()
