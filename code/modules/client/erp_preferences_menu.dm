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
	// Extra height when the taur genital section is visible.
	var/height = taur_type ? 540 : 440
	user << browse(generate_erp_html(user), "window=erp_prefs;size=580x[height]")

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
		list("sexable",               "Allow ERP Panel",             "Allow others to open the ERP interaction panel on you."),
		list("chastenable",           "Chastity Content",            "Enable visibility and interaction with chastity device content."),
		list("cursed_enabled",        "Cursed Content",              "Allow cursed collars and cursed chastity devices to be equipped on you. Disabling will strip any currently worn cursed items."),
		list("intimate_enabled",      "Intimate Accessories",        "Enable piercings, plugs, and other intimate accessories. Independent of chastity content."),
		list("extreme_erp",           "Extreme ERP Content",         "Enable extreme content (gore, ryona, etc.) within the ERP panel."),
		list("edging",                "Edging Content",              "Enable Psydonite edging and other edging-related content within the ERP panel."),
		list("jelly_controller_enabled", "Jelly Controller Offers",  "Enable strange jelly controller volunteering and future jelly-role prompts. When off, you will not be surfaced for jelly controller content."),
		list("show_intimate_examine", "Show Accessories on Examine", "Allow others to see the 'View intimate accessories' link when examining you."),
		list("intimate_visual_widgets","Accessory Visual Widgets",   "Show detailed paper-doll item visuals inside your intimate accessories panel (reserved for future art assets)."),
		list("intimate_reaction_enabled", "Intimate Reaction Text", "Master toggle: see intimate reaction flavor text (movement descriptions, body exposure, sex-action reactions) from yourself and others."),
		list("intimate_reaction_show_chastity", "  ↳ Chastity Reactions", "Sub-toggle: show chastity device reaction text (jingles, arousal, denial, pain messages)."),
		list("intimate_reaction_show_extreme", "  ↳ Extreme Reactions", "Sub-toggle: show extreme/pain/spike intimate reaction text."),
		list("intimate_reaction_show_accessory_free", "  ↳ Character Flavor", "Sub-toggle: show accessory-free character flavor text (custom movement, body exposure, sex-received).")
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
				overflow-y: auto;
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
			.section-header { font-size: 0.75em; font-weight: bold; color: [T["label"]]; border-bottom: 1px solid [T["border"]]; margin: 10px 0 6px; padding-bottom: 3px; }
			.offset-row {
				display: flex;
				align-items: center;
				background: [T["panel_dark"]];
				border: 1px solid [T["border"]];
				padding: 6px 10px;
				margin-bottom: 4px;
				gap: 8px;
				font-size: 0.78em;
			}
			.offset-label { flex: 1; color: [T["label"]]; }
			.offset-val   { min-width: 28px; text-align: center; font-weight: bold; color: [T["text"]]; }
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

	// --- Taur Genital note — controls moved to character creation for live preview ---
	if(taur_type)
		var/obj/item/bodypart/taur/tt = taur_type
		html += "<div class='section-header'>⬛ Taur Genitals — [tt::name]</div>"
		html += "<p style='font-size:0.62em;color:[T["label"]];margin:0 0 6px;'>Genital layering is now automatic (vaginas overlay the rear, penises/testicles tuck behind). Enable <b>Taur Genital Sprites</b> in the <b>Character Creation</b> menu to use taur-specific sprite variants and pixel offset controls.</p>"

	html += "<div class='section-header'>Jelly Controller Profile</div>"
	html += "<div class='toggle-row'>"
	html += "<div class='toggle-info'><div class='toggle-name'>Volunteer Profile</div><div class='toggle-desc'>Set the descriptive card a jelly wearer will inspect before accepting you.</div></div>"
	html += "<a class='toggle-btn btn-off' href='byond://?src=\ref[src];erp_open=jelly_prefs'>Edit</a>"
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
		if(!(key in list("sexable", "chastenable", "cursed_enabled", "intimate_enabled", "extreme_erp", "edging", "jelly_controller_enabled", "show_intimate_examine", "intimate_visual_widgets", "intimate_reaction_enabled", "intimate_reaction_show_chastity", "intimate_reaction_show_extreme", "intimate_reaction_show_accessory_free")))
			return
		vars[key] = !vars[key]

		// Notify modular hooks that may need to react to a toggle-off
		if(key == "chastenable" && !chastenable)
			if(hascall(usr?.client, "modular_handle_chastity_toggle_disable"))
				call(usr.client, "modular_handle_chastity_toggle_disable")()
		if(key == "cursed_enabled" && !cursed_enabled)
			if(hascall(usr?.client, "modular_handle_cursed_toggle_disable"))
				call(usr.client, "modular_handle_cursed_toggle_disable")()
		if(key == "extreme_erp" && !extreme_erp)
			if(hascall(usr?.client, "modular_handle_extreme_erp_toggle_disable"))
				call(usr.client, "modular_handle_extreme_erp_toggle_disable")()
		if(key == "jelly_controller_enabled" && !jelly_controller_enabled && usr?.client)
			GLOB.jelly_controller_queue -= usr.client
			remove_jelly_controller_client_from_applications(usr.client, "Your jelly controller applications are cleared because role offers were disabled.")


		save_preferences()
		open_erp_preferences_menu(usr)
		return

	if(href_list["erp_open"])
		if(href_list["erp_open"] == "jelly_prefs")
			jelly_prefs?.jelly_show_ui()
		return

	if(href_list["erp_hardmode"])
		if(href_list["erp_hardmode"] != "enable")
			return
		if(chastity_hardmode == CHASTITY_HARDMODE_ENABLED)
			to_chat(usr, span_warning("Permanent binding is already active. Recite the Prayer of Foolish Repentance to Eora to be released."))
			return

		// Mirror the full confirmation flow from /client/verb/toggle_Chastity_Hardmode
		var/confirm = tgui_alert(usr,
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
			list("I accept the binding", "I refuse"))

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
