/datum/preferences/unit_test_cursed_collar_preferences/New(client/C)
	return

/datum/unit_test/chastity_preview_preferences_do_not_spawn_keys
	priority = TEST_PRE

/datum/unit_test/chastity_preview_preferences_do_not_spawn_keys/proc/make_organ_entry(choice_type)
	var/datum/customizer_entry/entry = new /datum/customizer_entry()
	entry.customizer_choice_type = choice_type
	entry.disabled = FALSE
	allocated += entry
	return entry

/datum/unit_test/chastity_preview_preferences_do_not_spawn_keys/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_cursed_collar_preferences(null)
	prefs.chastenable = TRUE
	prefs.pref_chastity_enabled = TRUE
	prefs.pref_chastity_spawn_key = TRUE
	prefs.customizer_entries = list(make_organ_entry(/datum/customizer_choice/organ/penis/human))

	var/mob/living/carbon/human/dummy/preview = allocate(/mob/living/carbon/human/dummy, null)
	var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
	penis.Insert(preview)

	prefs.apply_chastity_preferences(preview)

	TEST_ASSERT_NOTNULL(preview.chastity_device, "preview should still receive a visual chastity device")
	TEST_ASSERT_NULL(preview.chastity_device.generated_key, "preview chastity application must not spawn a physical key")

	qdel(prefs)

/datum/unit_test/cursed_collar_preferences_contract

/datum/unit_test/cursed_collar_preferences_contract/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_cursed_collar_preferences(null)

	var/list/options = prefs.get_cursed_roundstart_device_options()
	TEST_ASSERT(islist(options), "cursed round-start device options must be a list")
	TEST_ASSERT_EQUAL(options["None"], CURSED_ROUNDSTART_NONE, "missing none option")
	TEST_ASSERT_EQUAL(options["Cursed Collar"], CURSED_ROUNDSTART_COLLAR, "missing collar option")
	TEST_ASSERT_EQUAL(options["Cursed Chastity"], CURSED_ROUNDSTART_CHASTITY, "missing cursed chastity option")

	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_COLLAR), "collar selection should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_COLLAR, "collar selection was not stored")
	TEST_ASSERT(!prefs.set_cursed_roundstart_device("bad-device"), "invalid cursed device should be rejected")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_COLLAR, "invalid device should not overwrite selection")

	TEST_ASSERT(prefs.set_cursed_roundstart_master_name("Alice North"), "valid master name should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "Alice North", "master name was not stored")

	prefs.pref_cursed_self_master = TRUE
	var/datum/cursed_collar_lobby_menu/menu = new(prefs)
	TEST_ASSERT(menu.ui_act("set_master_name", list("master_name" = "Bob East"), null), "lobby menu should accept explicit master_name payloads")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "Bob East", "lobby menu master name action should store typed external master names")
	TEST_ASSERT(!prefs.pref_cursed_self_master, "setting an external master should clear self-master")
	qdel(menu)

	prefs.pref_cursed_self_master = TRUE
	prefs.reset_intimate_accessory_preferences()
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_NONE, "reset should clear cursed device")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "", "reset should clear cursed master name")
	TEST_ASSERT(!prefs.pref_cursed_self_master, "reset should clear self-master flag")

	qdel(prefs)
