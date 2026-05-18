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
	TEST_ASSERT_EQUAL(options["Gilded Chastity"], CURSED_ROUNDSTART_GILDED_CHASTITY, "missing gilded chastity option")

	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_COLLAR), "collar selection should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_COLLAR, "collar selection was not stored")
	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_GILDED_CHASTITY), "gilded chastity selection should be accepted")
	TEST_ASSERT(prefs.uses_cursed_roundstart_chastity(), "gilded chastity should use the cursed chastity equip path")
	TEST_ASSERT(!prefs.set_cursed_roundstart_device("bad-device"), "invalid cursed device should be rejected")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_GILDED_CHASTITY, "invalid device should not overwrite selection")

	TEST_ASSERT_EQUAL(prefs.pref_gilded_chastity_recipient, GILDED_CHASTITY_RECIPIENT_MASTER, "gilded recipient should default to master")
	TEST_ASSERT(prefs.set_gilded_chastity_recipient(GILDED_CHASTITY_RECIPIENT_TREASURY), "treasury recipient should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_gilded_chastity_recipient, GILDED_CHASTITY_RECIPIENT_TREASURY, "treasury recipient should be stored")
	TEST_ASSERT(!prefs.set_gilded_chastity_recipient("bad-recipient"), "invalid gilded recipient should be rejected")
	TEST_ASSERT_EQUAL(prefs.pref_gilded_chastity_recipient, GILDED_CHASTITY_RECIPIENT_TREASURY, "invalid recipient should not overwrite selection")

	TEST_ASSERT(prefs.set_cursed_roundstart_master_name("Alice North"), "valid master name should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "Alice North", "master name was not stored")

	prefs.pref_cursed_self_master = TRUE
	var/datum/cursed_collar_lobby_menu/menu = new(prefs)
	TEST_ASSERT(menu.ui_act("set_master_name", list("master_name" = "Bob East"), null), "lobby menu should accept explicit master_name payloads")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "Bob East", "lobby menu master name action should store typed external master names")
	TEST_ASSERT(!prefs.pref_cursed_self_master, "setting an external master should clear self-master")
	qdel(menu)

	prefs.pref_cursed_self_master = TRUE
	prefs.pref_gilded_chastity_recipient = GILDED_CHASTITY_RECIPIENT_MASTER
	TEST_ASSERT(prefs.set_gilded_chastity_recipient(GILDED_CHASTITY_RECIPIENT_MASTER), "self-master master recipient selection should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_gilded_chastity_recipient, GILDED_CHASTITY_RECIPIENT_TREASURY, "self-master gilded recipient should default to Keep Treasury")

	prefs.reset_intimate_accessory_preferences()
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_NONE, "reset should clear cursed device")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "", "reset should clear cursed master name")
	TEST_ASSERT(!prefs.pref_cursed_self_master, "reset should clear self-master flag")
	TEST_ASSERT_EQUAL(prefs.pref_gilded_chastity_recipient, GILDED_CHASTITY_RECIPIENT_MASTER, "reset should restore gilded recipient default")

	qdel(prefs)

/datum/unit_test/gilded_chastity_device_contract/proc/setup_test_mind(mob/living/carbon/human/H, character_name)
	H.name = character_name
	H.real_name = character_name
	var/datum/mind/M = new /datum/mind(null)
	allocated += M
	M.name = character_name
	M.transfer_to(H)
	return M

/datum/unit_test/gilded_chastity_device_contract/proc/make_test_human(character_name, add_penis = FALSE)
	var/mob/living/carbon/human/dummy/H = allocate(/mob/living/carbon/human/dummy, null)
	setup_test_mind(H, character_name)
	if(add_penis && !H.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
		penis.Insert(H)
	return H

/datum/unit_test/gilded_chastity_device_contract/Run()
	var/list/old_accounts = SStreasury.bank_accounts
	var/old_treasury_value = SStreasury.treasury_value
	var/old_bandit_contribute = SSmapping?.retainer?.bandit_contribute
	SStreasury.bank_accounts = list()

	var/mob/living/carbon/human/wearer = make_test_human("Gilded Wearer", TRUE)
	var/mob/living/carbon/human/master = make_test_human("Gilded Master")
	var/obj/item/organ/penis/penis = wearer.getorganslot(ORGAN_SLOT_PENIS)
	penis.penis_size = DEFAULT_PENIS_SIZE

	var/obj/item/chastity/cursed/gilded/device = allocate(/obj/item/chastity/cursed/gilded, wearer)
	device.chastity_master = master.mind
	device.gilded_drain_amount = 5

	SStreasury.bank_accounts[wearer] = 3
	SStreasury.bank_accounts[master] = 7
	device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_MASTER
	var/drained = device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 3, "gilded drain should clamp to the wearer's available balance")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 0, "gilded drain should never overdraw the wearer")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[master], 10, "master recipient should receive drained mammon")

	SStreasury.bank_accounts[wearer] = 8
	var/self_master_treasury_before = SStreasury.treasury_value
	device.chastity_master = wearer.mind
	TEST_ASSERT(device.set_gilded_recipient(wearer, GILDED_CHASTITY_RECIPIENT_MASTER), "self-master should accept master recipient requests")
	TEST_ASSERT_EQUAL(device.gilded_recipient, GILDED_CHASTITY_RECIPIENT_TREASURY, "self-master device recipient should default to Keep Treasury")
	drained = device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 5, "self-master gilded drain should still take the configured amount")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 3, "self-master gilded drain should not credit mammon back to the wearer")
	TEST_ASSERT_EQUAL(SStreasury.treasury_value, self_master_treasury_before + 5, "self-master master recipient should default to Keep Treasury")
	device.chastity_master = master.mind

	SStreasury.bank_accounts[wearer] = 4
	var/treasury_recipient_before = SStreasury.treasury_value
	device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_TREASURY
	drained = device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 4, "treasury drain should clamp to the wearer's available balance")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 0, "treasury drain should leave the wearer at zero")
	TEST_ASSERT_EQUAL(SStreasury.treasury_value, treasury_recipient_before + 4, "treasury recipient should receive drained mammon")

	if(SSmapping?.retainer)
		SStreasury.bank_accounts[wearer] = 2
		device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_HOARDMASTER
		drained = device.on_chastity_jingle_triggered(wearer)
		TEST_ASSERT_EQUAL(drained, 2, "hoardmaster drain should clamp to the wearer's available balance")
		TEST_ASSERT_EQUAL(SSmapping.retainer.bandit_contribute, old_bandit_contribute + 2, "hoardmaster recipient should credit bandit contribution")

	penis.penis_size = DEFAULT_PENIS_SIZE
	SStreasury.bank_accounts[wearer] = GILDED_CHASTITY_SHRINK_DRAIN_STEP
	device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_MASTER
	device.gilded_total_drained = GILDED_CHASTITY_SHRINK_DRAIN_STEP - 1
	device.gilded_next_shrink_threshold = GILDED_CHASTITY_SHRINK_DRAIN_STEP
	device.gilded_drain_amount = 1
	drained = device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 1, "threshold jingle should drain the configured amount")
	TEST_ASSERT_EQUAL(penis.penis_size, DEFAULT_PENIS_SIZE - 1, "threshold drain should shrink penis size by one step")

	penis.penis_size = MIN_PENIS_SIZE
	device.apply_gilded_shrink(wearer, TRUE)
	TEST_ASSERT_EQUAL(penis.penis_size, MIN_PENIS_SIZE, "gilded shrink should not reduce below minimum penis size")

	SStreasury.bank_accounts[wearer] = 0
	device.gilded_zero_fund_jingles = 0
	device.gilded_limped = FALSE
	REMOVE_TRAIT(wearer, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
	for(var/i in 1 to GILDED_CHASTITY_ZERO_JINGLES_FOR_LIMP)
		device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT(HAS_TRAIT(wearer, TRAIT_LIMPDICK), "three zero-fund jingles should apply round-only limpness")

	SStreasury.bank_accounts = old_accounts
	SStreasury.treasury_value = old_treasury_value
	if(SSmapping?.retainer)
		SSmapping.retainer.bandit_contribute = old_bandit_contribute
