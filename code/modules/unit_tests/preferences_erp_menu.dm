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
