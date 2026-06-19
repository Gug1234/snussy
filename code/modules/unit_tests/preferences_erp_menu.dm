/datum/preferences/unit_test_character_sheet_erp_menu_entries/New(client/C)
	return

/datum/preferences/unit_test_intimate_accessory_lobby_anatomy/New(client/C)
	return

/datum/unit_test/preferences_character_sheet_erp_menu_entries

/datum/unit_test/preferences_character_sheet_erp_menu_entries/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_character_sheet_erp_menu_entries(null)
	if(!hascall(prefs, "get_character_sheet_erp_menu_entries"))
		qdel(prefs)
		return Fail("Character preferences do not expose ERP menu entries.")
	if(!hascall(prefs, "get_character_sheet_slot_io_menu_entries"))
		qdel(prefs)
		return Fail("Character preferences do not expose slot import/export menu entries.")

	var/list/entries = call(prefs, "get_character_sheet_erp_menu_entries")()
	var/list/slot_io_entries = call(prefs, "get_character_sheet_slot_io_menu_entries")()

	TEST_ASSERT(islist(entries), "character sheet ERP menu entries must be a list")
	TEST_ASSERT(islist(slot_io_entries), "character sheet slot IO menu entries must be a list")

	var/list/entry_preferences = list()
	for(var/list/entry as anything in entries)
		var/preference = entry["preference"]
		if(istext(preference))
			entry_preferences[preference] = TRUE

	var/list/expected_preferences = list(
		"chastity_menu",
		"cursed_collar_menu",
		"intimate_accessories_menu",
		"custom_sex_editor",
		"intimate_reactions_editor",
	)
	for(var/expected_preference in expected_preferences)
		TEST_ASSERT(entry_preferences[expected_preference], "missing character sheet ERP menu entry: [expected_preference]")

	TEST_ASSERT(!entry_preferences["export_character_slot"], "character slot export should not live under ERP menu entries")
	TEST_ASSERT(!entry_preferences["import_character_slot"], "character slot import should not live under ERP menu entries")

	var/list/slot_io_preferences = list()
	for(var/list/entry as anything in slot_io_entries)
		var/preference = entry["preference"]
		if(istext(preference))
			slot_io_preferences[preference] = TRUE

	qdel(prefs)
	TEST_ASSERT(slot_io_preferences["character_slot_io"], "missing top-left character slot import/export launcher")

/datum/unit_test/intimate_accessory_lobby_anatomy_filters
	priority = TEST_PRE

/datum/unit_test/intimate_accessory_lobby_anatomy_filters/proc/make_organ_entry(choice_type)
	var/datum/customizer_entry/entry = new /datum/customizer_entry()
	entry.customizer_choice_type = choice_type
	entry.disabled = FALSE
	allocated += entry
	return entry

/datum/unit_test/intimate_accessory_lobby_anatomy_filters/proc/options_include(list/options, option_name)
	return (option_name in options)

/datum/unit_test/intimate_accessory_lobby_anatomy_filters/proc/find_row_by_key(list/rows, row_key)
	for(var/list/row as anything in rows)
		if(row["key"] == row_key)
			return row
	return null

/datum/unit_test/intimate_accessory_lobby_anatomy_filters/proc/find_option_by_key(list/options, option_key)
	for(var/list/option as anything in options)
		if(option["key"] == option_key)
			return option
	return null

/datum/unit_test/intimate_accessory_lobby_anatomy_filters/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_intimate_accessory_lobby_anatomy(null)

	var/list/options = prefs.get_intimate_accessory_slot_options("genital_insertable")
	TEST_ASSERT(!options_include(options, "Iron Vaginal Plug"), "vaginal plugs must be hidden without vaginal anatomy")
	TEST_ASSERT(!options_include(options, "Iron Sounding Rod"), "sounding rods must be hidden without penile anatomy")
	TEST_ASSERT(!prefs.set_intimate_accessory_slot_typepath("genital_insertable", /obj/item/intimate_accessory/genital/plug/iron), "vaginal plugs must be rejected without vaginal anatomy")
	TEST_ASSERT(!prefs.set_intimate_accessory_slot_typepath("genital_insertable", /obj/item/intimate_accessory/genital/plug/sounding_rod/iron), "sounding rods must be rejected without penile anatomy")

	prefs.customizer_entries = list(make_organ_entry(/datum/customizer_choice/organ/vagina/human))
	options = prefs.get_intimate_accessory_slot_options("genital_insertable")
	TEST_ASSERT(options_include(options, "Iron Vaginal Plug"), "vaginal plugs must be visible with vaginal anatomy")
	TEST_ASSERT(!options_include(options, "Iron Sounding Rod"), "sounding rods must be hidden without penile anatomy")
	TEST_ASSERT(prefs.set_intimate_accessory_slot_typepath("genital_insertable", /obj/item/intimate_accessory/genital/plug/iron), "vaginal plugs must be accepted with vaginal anatomy")
	TEST_ASSERT(!prefs.set_intimate_accessory_slot_typepath("genital_insertable", /obj/item/intimate_accessory/genital/plug/sounding_rod/iron), "sounding rods must be rejected without penile anatomy")

	prefs.customizer_entries = list(make_organ_entry(/datum/customizer_choice/organ/penis/human))
	options = prefs.get_intimate_accessory_slot_options("genital_insertable")
	TEST_ASSERT(!options_include(options, "Iron Vaginal Plug"), "vaginal plugs must be hidden without vaginal anatomy")
	TEST_ASSERT(options_include(options, "Iron Sounding Rod"), "sounding rods must be visible with penile anatomy")
	TEST_ASSERT(!prefs.set_intimate_accessory_slot_typepath("genital_insertable", /obj/item/intimate_accessory/genital/plug/iron), "vaginal plugs must be rejected without vaginal anatomy")
	TEST_ASSERT(prefs.set_intimate_accessory_slot_typepath("genital_insertable", /obj/item/intimate_accessory/genital/plug/sounding_rod/iron), "sounding rods must be accepted with penile anatomy")

	prefs.pref_intimate_genital_insertable = /obj/item/intimate_accessory/genital/plug/iron
	var/list/rows = prefs.get_intimate_accessory_slot_rows()
	var/list/genital_row = find_row_by_key(rows, "genital_insertable")
	TEST_ASSERT_NOTNULL(genital_row, "genital insertable row must be present")
	TEST_ASSERT_EQUAL("None", genital_row["current"], "invalid saved genital insertables must not show as selected in the lobby menu")

	prefs.customizer_entries = list(
		make_organ_entry(/datum/customizer_choice/organ/vagina/human),
		make_organ_entry(/datum/customizer_choice/organ/penis/human),
	)
	options = prefs.get_intimate_accessory_slot_options("genital_insertable")
	TEST_ASSERT(options_include(options, "Iron Vaginal Plug"), "vaginal plugs must be visible with vaginal anatomy")
	TEST_ASSERT(options_include(options, "Iron Sounding Rod"), "sounding rods must be visible with penile anatomy")

	qdel(prefs)

/datum/unit_test/intimate_accessory_lobby_structured_controls
	priority = TEST_PRE

/datum/unit_test/intimate_accessory_lobby_structured_controls/proc/make_organ_entry(choice_type)
	var/datum/customizer_entry/entry = new /datum/customizer_entry()
	entry.customizer_choice_type = choice_type
	entry.disabled = FALSE
	allocated += entry
	return entry

/datum/unit_test/intimate_accessory_lobby_structured_controls/proc/find_row_by_key(list/rows, row_key)
	for(var/list/row as anything in rows)
		if(row["key"] == row_key)
			return row
	return null

/datum/unit_test/intimate_accessory_lobby_structured_controls/proc/find_option_by_key(list/options, option_key)
	for(var/list/option as anything in options)
		if(option["key"] == option_key)
			return option
	return null

/datum/unit_test/intimate_accessory_lobby_structured_controls/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_intimate_accessory_lobby_anatomy(null)

	TEST_ASSERT(prefs.set_intimate_accessory_slot_typepath("rear_insertable", /obj/item/intimate_accessory/rear/plug/gold), "test setup should select a rear plug")
	TEST_ASSERT(prefs.set_intimate_accessory_slot_socket("rear_insertable", "ruby"), "round-start gem sockets should be accepted for selected rear insertables")

	var/list/rows = prefs.get_intimate_accessory_slot_rows()
	var/list/rear_row = find_row_by_key(rows, "rear_insertable")
	TEST_ASSERT_NOTNULL(rear_row, "rear insertable row must be present")
	TEST_ASSERT(islist(rear_row["type_options"]), "rear insertable rows must send structured type options")
	TEST_ASSERT(islist(rear_row["metal_options"]), "rear insertable rows must send structured metal options")
	TEST_ASSERT(islist(rear_row["socket_options"]), "rear insertable rows must send structured socket options")
	TEST_ASSERT_EQUAL(rear_row["current_type"], "butt_plug", "selected rear plugs should expose the current type key")
	TEST_ASSERT_EQUAL(rear_row["current_metal"], "gold", "selected rear plugs should expose the current metal key")
	TEST_ASSERT_EQUAL(rear_row["current_socket"], "ruby", "selected rear plugs should expose the current socket key")

	var/list/butt_plug_option = find_option_by_key(rear_row["type_options"], "butt_plug")
	TEST_ASSERT_NOTNULL(butt_plug_option, "rear insertable type options should include butt plugs")
	TEST_ASSERT_EQUAL(butt_plug_option["label"], "Butt Plug", "butt plug type option should use a concise label")

	var/list/gold_option = find_option_by_key(rear_row["metal_options"], "gold")
	TEST_ASSERT_NOTNULL(gold_option, "rear insertable metal options should include gold")
	TEST_ASSERT_EQUAL(lowertext(gold_option["color"]), "#c4b651", "metal options should carry swatch colors")

	var/list/ruby_option = find_option_by_key(rear_row["socket_options"], "ruby")
	TEST_ASSERT_NOTNULL(ruby_option, "socket options should include round-start gems")
	TEST_ASSERT_EQUAL(ruby_option["label"], "Rontz", "ruby socket should use the gem display label")
	TEST_ASSERT_EQUAL(lowertext(ruby_option["color"]), "#b4142c", "gem socket options should carry swatch colors")

	var/list/tail_option = find_option_by_key(rear_row["socket_options"], "tail")
	TEST_ASSERT_NOTNULL(tail_option, "rear insertable socket options should include fake tails")
	TEST_ASSERT(!tail_option["disabled"], "tail sockets should be available when the character has no natural tail")

	var/list/tail_plug_option = find_option_by_key(rear_row["type_options"], "tail_plug")
	TEST_ASSERT_NOTNULL(tail_plug_option, "rear insertable type options should expose tail plugs directly")
	TEST_ASSERT_EQUAL(tail_plug_option["label"], "Tail Plug", "tail plug type option should use a concise label")
	var/list/tail_beads_option = find_option_by_key(rear_row["type_options"], "tail_beads")
	TEST_ASSERT_NOTNULL(tail_beads_option, "rear insertable type options should expose tail beads directly")
	TEST_ASSERT_EQUAL(tail_beads_option["label"], "Tail Beads", "tail beads type option should use a concise label")

	TEST_ASSERT(prefs.set_intimate_accessory_slot_design("rear_insertable", type_key = "tail_plug", metal_key = "steel"), "tail plugs should be selectable as their own rear insertable type")
	rows = prefs.get_intimate_accessory_slot_rows()
	rear_row = find_row_by_key(rows, "rear_insertable")
	TEST_ASSERT_EQUAL(rear_row["current_type"], "tail_plug", "tail plug rows should expose a direct tail plug type key")
	TEST_ASSERT_EQUAL(rear_row["current_socket"], "tail", "tail plug type selection should still store the round-start tail socket")
	TEST_ASSERT(!rear_row["show_socket"], "tail plug rows should hide the separate socket selector")
	TEST_ASSERT(rear_row["show_tail_picker"], "tail plug rows should show tail sprite and item icon controls")
	TEST_ASSERT(islist(rear_row["tail_options"]) && length(rear_row["tail_options"]), "tail plug rows should send sprite accessory tail options")
	TEST_ASSERT(islist(rear_row["tail_icon_options"]) && length(rear_row["tail_icon_options"]), "tail plug rows should send item icon shape options")

	TEST_ASSERT(prefs.set_intimate_accessory_slot_design("rear_insertable", type_key = "anal_beads", metal_key = "gold"), "test setup should select anal beads")
	rows = prefs.get_intimate_accessory_slot_rows()
	rear_row = find_row_by_key(rows, "rear_insertable")
	TEST_ASSERT(islist(rear_row["bead_shape_options"]), "anal bead rows should send bead shape options")
	TEST_ASSERT_EQUAL(rear_row["current_bead_shape"], "standard", "standard anal beads should expose the default bead shape key")
	var/list/pyramid_option = find_option_by_key(rear_row["bead_shape_options"], "pyramid_medium")
	TEST_ASSERT_NOTNULL(pyramid_option, "bead shape options should include pyramid beads")
	var/list/glass_option = find_option_by_key(rear_row["bead_shape_options"], "glass")
	TEST_ASSERT_NOTNULL(glass_option, "bead shape options should include glass beads")
	TEST_ASSERT(glass_option["disabled"], "glass beads should be disabled without extreme ERP")
	var/list/spiked_option = find_option_by_key(rear_row["bead_shape_options"], "spiked")
	TEST_ASSERT_NOTNULL(spiked_option, "bead shape options should include spiked beads")
	TEST_ASSERT(spiked_option["disabled"], "spiked beads should be disabled without extreme ERP")
	TEST_ASSERT(!prefs.set_intimate_accessory_rear_bead_shape("glass"), "glass beads should not be selectable without extreme ERP")
	TEST_ASSERT(prefs.set_intimate_accessory_rear_bead_shape("pyramid_medium"), "non-extreme bead shapes should be selectable")

	TEST_ASSERT(prefs.set_intimate_accessory_slot_design("rear_insertable", type_key = "tail_beads", metal_key = "gold"), "tail beads should be selectable as their own rear insertable type")
	rows = prefs.get_intimate_accessory_slot_rows()
	rear_row = find_row_by_key(rows, "rear_insertable")
	TEST_ASSERT_EQUAL(rear_row["current_type"], "tail_beads", "tail bead rows should expose a direct tail bead type key")
	TEST_ASSERT_EQUAL(rear_row["current_socket"], "tail", "tail bead type selection should still store the round-start tail socket")
	TEST_ASSERT_EQUAL(rear_row["current_bead_shape"], "pyramid_medium", "tail bead selection should preserve the chosen bead shape")
	TEST_ASSERT(!rear_row["show_socket"], "tail bead rows should hide the separate socket selector")
	TEST_ASSERT(rear_row["show_tail_picker"], "tail bead rows should show tail sprite and item icon controls")

	TEST_ASSERT(prefs.set_intimate_accessory_slot_design("rear_insertable", type_key = "anal_beads", metal_key = "gold"), "test setup should return to normal anal beads")
	prefs.extreme_erp = TRUE
	TEST_ASSERT(prefs.set_intimate_accessory_rear_bead_shape("glass"), "glass beads should be selectable with extreme ERP enabled")
	rows = prefs.get_intimate_accessory_slot_rows()
	rear_row = find_row_by_key(rows, "rear_insertable")
	TEST_ASSERT_EQUAL(rear_row["current_bead_shape"], "glass", "selected glass beads should be reported as the current bead shape")
	glass_option = find_option_by_key(rear_row["bead_shape_options"], "glass")
	TEST_ASSERT(!glass_option["disabled"], "glass bead option should be enabled with extreme ERP")

	TEST_ASSERT(prefs.set_intimate_accessory_slot_typepath("genital_piercing", /obj/item/intimate_accessory/piercing/genital/bell/gold), "test setup should select a bell genital piercing")
	rows = prefs.get_intimate_accessory_slot_rows()
	var/list/genital_row = find_row_by_key(rows, "genital_piercing")
	TEST_ASSERT_NOTNULL(genital_row, "genital piercing row must be present")
	TEST_ASSERT_EQUAL(genital_row["current_type"], "piercing", "piercing rows should expose the current type key")
	TEST_ASSERT_EQUAL(genital_row["current_metal"], "gold", "piercing rows should expose the current metal key")
	TEST_ASSERT(genital_row["can_bell"], "genital piercings should expose a bell toggle")
	TEST_ASSERT(genital_row["has_bell"], "bell piercing typepaths should set the bell toggle state")
	TEST_ASSERT(genital_row["show_socket"], "socketable piercing rows should show the socket selector")

	TEST_ASSERT(prefs.set_intimate_accessory_slot_design("genital_piercing", type_key = "psydonic", metal_key = "silver"), "test setup should select a fixed psydonic piercing")
	rows = prefs.get_intimate_accessory_slot_rows()
	genital_row = find_row_by_key(rows, "genital_piercing")
	TEST_ASSERT_EQUAL(genital_row["current_type"], "psydonic", "fixed psydonic rows should expose the psydonic type key")
	TEST_ASSERT(!genital_row["show_socket"], "fixed psydonic piercings should hide the socket selector")

	TEST_ASSERT(prefs.set_intimate_accessory_tail_socket("rear_insertable", /datum/sprite_accessory/tail/manticore, "#5BCEFA#F5A9B8#FFFFFF", "catplug"), "tail socket picker should accept valid tail sprite, colors, and item icon")
	TEST_ASSERT(prefs.set_intimate_accessory_slot_socket("rear_insertable", "tail"), "tail sockets should be selectable before the character has a natural tail")

	prefs.customizer_entries = list(make_organ_entry(/datum/customizer_choice/organ/tail/anthro))
	TEST_ASSERT(!prefs.set_intimate_accessory_slot_socket("rear_insertable", "tail"), "natural tail customizers should block selecting a fake-tail round-start socket")
	rows = prefs.get_intimate_accessory_slot_rows()
	rear_row = find_row_by_key(rows, "rear_insertable")
	tail_option = find_option_by_key(rear_row["socket_options"], "tail")
	TEST_ASSERT(tail_option["disabled"], "tail socket options should render disabled when the character already has a tail")

	qdel(prefs)
