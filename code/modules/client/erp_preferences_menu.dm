/**
 * ERP Preferences Menu
 *
 * Consolidated browse-based popup for all ERP-related player preferences.
 * Designed to accommodate future expansion (additional toggles, paper-doll
 * imagery) without structural changes to the menu scaffold.
 *
 * To add a new toggle: append an entry to the `basic_toggles` static list
 * inside generate_erp_html(), then ensure the pref var is whitelisted in the
 * Topic() handler below.
 *
 * Topic callbacks are dispatched through /datum/preferences/Topic().
 * The menu self-refreshes after every toggle click.
 */

/// Opens the ERP preferences popup for the given user.
/datum/preferences/proc/open_erp_preferences_menu(mob/user)
	if(!user?.client)
		return
	user << browse(generate_erp_html(user), "window=erp_prefs;size=580x440")

/// Generates the full HTML document for the ERP preferences popup.
/datum/preferences/proc/generate_erp_html(mob/user)
	// Colour palette shared with the rest of the character UI
	var/list/T = list(
		"bg"          = "#100000",
		"text"        = "#aa8f8f",
		"label"       = "#aa8f8f",
		"border"      = "#7b5353",
		"panel_dark"  = "#00000044",
		"on"          = "rgba(76,175,80,0.25)",
		"on_border"   = "#4CAF50",
		"on_text"     = "#4CAF50",
		"off"         = "rgba(100,40,40,0.25)",
		"lock"        = "rgba(70,60,20,0.3)",
		"lock_border" = "#b8960c",
		"lock_text"   = "#b8960c"
	)

	// Toggle definitions — key / display name / description.
	// Add new boolean prefs here; also whitelist the key in Topic() below.
	var/static/list/basic_toggles = list(
		list("sexable",     "Allow ERP Panel",       "Allow others to open the ERP interaction panel on you."),
		list("chastenable", "Chastity Content",       "Enable visibility and interaction with chastity device content."),
		list("extreme_erp", "Extreme ERP Content",    "Enable extreme content (gore, ryona, etc.) within the ERP panel."),
		list("edging",      "Edging Content",         "Enable edging-related content within the ERP panel.")
	)

	var/html = {"
		<!DOCTYPE html>
		<html lang="en">
		<meta charset='UTF-8'>
		<meta http-equiv='X-UA-Compatible' content='IE=edge,chrome=1'/>
		<style>
			body {
				font-family: Verdana, Arial, sans-serif;
				background: [T["bg"]] url('flowers.png') repeat;
				color: [T["text"]];
				margin: 0; padding: 0;
			}
			.header {
				text-align: center;
				padding: 8px 5px 6px;
				background: [T["panel_dark"]];
				border-bottom: 2px solid [T["border"]];
			}
			.header h1 { margin: 0; color: [T["text"]]; font-size: 1.0em; }
			.header p  { margin: 2px 0; font-size: 0.65em; color: [T["label"]]; }
			.content   { padding: 10px; }
			.toggle-row {
				display: flex;
				align-items: center;
				background: [T["panel_dark"]];
				border: 1px solid [T["border"]];
				padding: 8px 10px;
				margin-bottom: 6px;
				gap: 10px;
			}
			.toggle-info  { flex: 1; }
			.toggle-name  { font-weight: bold; color: [T["text"]]; font-size: 0.8em; margin-bottom: 3px; }
			.toggle-desc  { font-size: 0.65em; color: [T["label"]]; line-height: 1.3; }
			.toggle-btn {
				padding: 4px 12px;
				border: 1px solid [T["border"]];
				background: [T["panel_dark"]];
				color: [T["text"]];
				cursor: pointer;
				font-family: Verdana, Arial, sans-serif;
				font-size: 0.7em;
				text-decoration: none;
				display: inline-block;
				white-space: nowrap;
				min-width: 48px;
				text-align: center;
			}
			.btn-on   { background: [T["on"]];   border-color: [T["on_border"]];   color: [T["on_text"]]; }
			.btn-off  { background: [T["off"]];  border-color: [T["border"]]; }
			.btn-lock { background: [T["lock"]]; border-color: [T["lock_border"]]; color: [T["lock_text"]]; cursor: default; }
			.hardmode-note { font-size: 0.6em; color: [T["lock_text"]]; margin-top: 3px; font-style: italic; }
		</style>
		<body>
			<div class="header">
				<h1>ERP Preferences</h1>
				<p>Settings are saved immediately when toggled.</p>
			</div>
			<div class="content">
	"}

	// --- Standard boolean toggles ---
	for(var/list/entry in basic_toggles)
		var/key   = entry[1]
		var/dname = entry[2]
		var/desc  = entry[3]
		var/is_on = vars[key]

		html += "<div class='toggle-row'>"
		html += "<div class='toggle-info'><div class='toggle-name'>[dname]</div><div class='toggle-desc'>[desc]</div></div>"
		if(is_on)
			html += "<a class='toggle-btn btn-on'  href='byond://?src=\ref[src];erp_toggle=[key]'>ON</a>"
		else
			html += "<a class='toggle-btn btn-off' href='byond://?src=\ref[src];erp_toggle=[key]'>OFF</a>"
		html += "</div>"

	// --- Chastity Hardmode — special handling ---
	// Enabling shows a full confirmation dialog; disabling requires an in-game prayer.
	var/is_hardmode = (chastity_hardmode == CHASTITY_HARDMODE_ENABLED)
	html += "<div class='toggle-row'>"
	html += "<div class='toggle-info'>"
	html += "<div class='toggle-name'>Permanent Chastity Binding</div>"
	html += "<div class='toggle-desc'>Enables permanent chastity device binding. Only the device's unique key can unlock it.</div>"
	if(is_hardmode)
		html += "<div class='hardmode-note'>⚠ Active — to disable, recite the Prayer of Foolish Repentance to Eora in-game.</div>"
	html += "</div>"

	if(is_hardmode)
		html += "<span class='toggle-btn btn-lock'>BOUND</span>"
	else
		html += "<a class='toggle-btn btn-off' href='byond://?src=\ref[src];erp_hardmode=enable'>OFF</a>"
	html += "</div>"

	html += "</div></body></html>"
	return html

/**
 * Topic() extension for ERP preference toggles.
 *
 * Handles two href keys:
 *   erp_toggle  — flips a boolean pref by name (whitelist enforced)
 *   erp_hardmode — triggers the full permanent-binding confirmation flow
 */
/datum/preferences/Topic(href, href_list)
	. = ..()

	if(href_list["erp_toggle"])
		var/key = href_list["erp_toggle"]
		// Whitelist: only allow known safe boolean pref keys
		if(!(key in list("sexable", "chastenable", "extreme_erp", "edging")))
			return
		vars[key] = !vars[key]

		// Notify modular hooks that may need to react to a toggle-off
		if(key == "chastenable" && !chastenable)
			if(hascall(usr?.client, "modular_handle_chastity_toggle_disable"))
				call(usr.client, "modular_handle_chastity_toggle_disable")()
		if(key == "extreme_erp" && !extreme_erp)
			if(hascall(usr?.client, "modular_handle_extreme_erp_toggle_disable"))
				call(usr.client, "modular_handle_extreme_erp_toggle_disable")()

		save_preferences()
		open_erp_preferences_menu(usr)
		return

	if(href_list["erp_hardmode"])
		if(href_list["erp_hardmode"] != "enable")
			return
		if(chastity_hardmode == CHASTITY_HARDMODE_ENABLED)
			to_chat(usr, span_warning("Permanent binding is already active. Recite the Prayer of Foolish Repentance to Eora to be released."))
			return

		// Mirror the full confirmation flow from /client/verb/toggle_Chastity_Hardmode
		var/confirm = alert(usr,
			"PERMANENT CHASTITY BINDING:\n\n\
			• Only the device's unique key can unlock it\n\
			• Keys can be lost, stolen, or destroyed forever\n\
			• Divine intervention will not free you\n\
			• Lockpicks and tools will fail\n\
			• Even the Duke's master key holds no power\n\
			• Physical removal is impossible\n\
			• You will remain bound until the key releases you\n\n\
			Do you accept these terms of permanent binding?",
			"Permanent Chastity Binding",
			"I accept the binding",
			"I refuse")

		if(confirm != "I accept the binding")
			to_chat(usr, span_notice("You decline the permanent binding."))
			open_erp_preferences_menu(usr)
			return

		chastity_hardmode = CHASTITY_HARDMODE_ENABLED
		save_preferences()
		if(ishuman(usr))
			var/mob/living/carbon/human/H = usr
			H.chastity_device?.sync_generated_key_metadata(H, usr)
		to_chat(usr, span_boldwarning("You have accepted the terms of PERMANENT BINDING. Only keys shall grant freedom."))
		log_game("[key_name(usr.client)] enabled permanent chastity binding via ERP preferences menu.")
		message_admins("[key_name_admin(usr.client)] enabled permanent chastity binding via ERP preferences menu.")
		open_erp_preferences_menu(usr)
		return

/// Client verb that opens the ERP preferences menu.
/client/verb/erp_preferences()
	set name = "ERP Preferences"
	set category = "Options"
	set desc = "Open the consolidated ERP preferences menu."
	if(prefs)
		prefs.open_erp_preferences_menu(usr)
