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

/datum/unit_test/cursed_collar_preferences_contract/proc/setup_test_mind(mob/living/carbon/human/H, character_name)
	H.name = character_name
	H.real_name = character_name
	var/datum/mind/M = new /datum/mind(null)
	allocated += M
	M.name = character_name
	M.transfer_to(H)
	return M

/datum/unit_test/cursed_collar_preferences_contract/proc/make_test_human(character_name)
	var/mob/living/carbon/human/consistent/H = allocate(/mob/living/carbon/human/consistent, null)
	setup_test_mind(H, character_name)
	return H

/datum/unit_test/cursed_collar_preferences_contract/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_cursed_collar_preferences(null)

	var/list/options = prefs.get_cursed_roundstart_device_options()
	TEST_ASSERT(islist(options), "cursed round-start device options must be a list")
	TEST_ASSERT_EQUAL(options["None"], CURSED_ROUNDSTART_NONE, "missing none option")
	TEST_ASSERT_EQUAL(options["Cursed Collar"], CURSED_ROUNDSTART_COLLAR, "missing collar option")
	TEST_ASSERT_EQUAL(options["Cursed Chastity"], CURSED_ROUNDSTART_CHASTITY, "missing cursed chastity option")
	TEST_ASSERT_EQUAL(options["Gilded Chastity"], CURSED_ROUNDSTART_GILDED_CHASTITY, "missing gilded chastity option")
	TEST_ASSERT_EQUAL(options["Cursed Piercing"], CURSED_ROUNDSTART_PIERCING, "missing cursed piercing option")

	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_COLLAR), "collar selection should be accepted")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_COLLAR, "collar selection was not stored")
	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_GILDED_CHASTITY), "gilded chastity selection should be accepted")
	TEST_ASSERT(prefs.uses_cursed_roundstart_chastity(), "gilded chastity should use the cursed chastity equip path")
	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_PIERCING), "cursed piercing selection should be accepted")
	TEST_ASSERT(!prefs.uses_cursed_roundstart_chastity(), "cursed piercing should not use the cursed chastity equip path")
	TEST_ASSERT(!prefs.set_cursed_roundstart_device("bad-device"), "invalid cursed device should be rejected")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_PIERCING, "invalid device should not overwrite selection")

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

	prefs.cursed_enabled = TRUE
	prefs.intimate_enabled = TRUE
	prefs.pref_cursed_self_master = TRUE
	TEST_ASSERT(prefs.set_cursed_roundstart_device(CURSED_ROUNDSTART_PIERCING), "round-start cursed piercing selection should be accepted")
	var/mob/living/carbon/human/wearer = make_test_human("Roundstart Piercing Wearer")
	TEST_ASSERT(prefs.apply_cursed_collar_preferences(wearer), "round-start cursed piercing should apply when cursed and intimate content are enabled")
	var/obj/item/intimate_accessory/piercing/cursed/piercing = wearer.intimate_genital_piercing
	TEST_ASSERT_NOTNULL(piercing, "round-start cursed piercing should occupy the default genital piercing slot")
	TEST_ASSERT_EQUAL(piercing.cursed_piercing_master, wearer.mind, "self-master round-start cursed piercing should bind to the wearer's mind")
	TEST_ASSERT(piercing.roundstart_self_master_binding, "self-master round-start cursed piercing should record self-master binding")
	var/datum/component/collar_master/CM = wearer.mind.GetComponent(/datum/component/collar_master)
	TEST_ASSERT_NOTNULL(CM, "round-start cursed piercing should create a collar master component")
	TEST_ASSERT(wearer in CM.my_pets, "round-start cursed piercing should register the wearer as a controlled pet")

	var/mob/living/carbon/human/overlap_wearer = make_test_human("Roundstart Piercing Overwrite Wearer")
	prefs.pref_intimate_genital_piercing = /obj/item/intimate_accessory/piercing/genital/iron
	prefs.apply_intimate_preferences(overlap_wearer)
	var/obj/item/intimate_accessory/piercing/normal_genital_piercing = overlap_wearer.intimate_genital_piercing
	TEST_ASSERT_NOTNULL(normal_genital_piercing, "test setup should equip a normal genital piercing first")
	TEST_ASSERT(prefs.apply_cursed_collar_preferences(overlap_wearer), "round-start cursed piercing should overwrite a normal piercing in its starting slot")
	var/obj/item/intimate_accessory/piercing/cursed/overwriting_piercing = overlap_wearer.intimate_genital_piercing
	TEST_ASSERT_NOTNULL(overwriting_piercing, "cursed piercing should occupy the overwritten genital piercing slot")
	TEST_ASSERT_EQUAL(overwriting_piercing.get_effective_intimate_slot(), INTIMATE_SLOT_GENITAL, "cursed piercing should keep the configured genital slot")
	TEST_ASSERT(!(normal_genital_piercing in overlap_wearer.intimate_accessories), "overwritten normal piercing should be removed from intimate accessories")

	var/datum/cursed_collar_lobby_menu/piercing_menu = new(prefs)
	TEST_ASSERT(piercing_menu.ui_act("set_piercing_slot", list("slot" = INTIMATE_SLOT_NOSE), null), "lobby menu should accept a cursed piercing starting slot")
	qdel(piercing_menu)
	var/mob/living/carbon/human/nose_wearer = make_test_human("Roundstart Nose Piercing Wearer")
	prefs.pref_intimate_nose_piercing = /obj/item/intimate_accessory/piercing/nose/iron
	prefs.apply_intimate_preferences(nose_wearer)
	var/obj/item/intimate_accessory/piercing/normal_nose_piercing = nose_wearer.intimate_nose_piercing
	TEST_ASSERT_NOTNULL(normal_nose_piercing, "test setup should equip a normal nose piercing first")
	TEST_ASSERT(prefs.apply_cursed_collar_preferences(nose_wearer), "round-start cursed piercing should apply in the selected starting slot")
	var/obj/item/intimate_accessory/piercing/cursed/nose_piercing = nose_wearer.intimate_nose_piercing
	TEST_ASSERT_NOTNULL(nose_piercing, "cursed piercing should occupy the selected nose slot")
	TEST_ASSERT_EQUAL(nose_piercing.get_effective_intimate_slot(), INTIMATE_SLOT_NOSE, "cursed piercing should use the lobby-selected nose slot")
	TEST_ASSERT(!(normal_nose_piercing in nose_wearer.intimate_accessories), "selected-slot normal piercing should be removed from intimate accessories")

	prefs.pref_cursed_self_master = FALSE
	TEST_ASSERT(prefs.set_cursed_roundstart_master_name("Delayed Piercing Master"), "external master name should be stored for delayed binding")
	TEST_ASSERT(prefs.set_cursed_piercing_slot(INTIMATE_SLOT_EAR), "test should select a delayed-binding piercing slot")
	var/mob/living/carbon/human/deferred_wearer = make_test_human("Delayed Piercing Wearer")
	TEST_ASSERT(prefs.apply_cursed_collar_preferences(deferred_wearer, 10), "round-start cursed piercing should still equip while waiting for its configured master")
	var/obj/item/intimate_accessory/piercing/cursed/deferred_piercing = deferred_wearer.intimate_ear_piercing
	TEST_ASSERT_NOTNULL(deferred_piercing, "deferred cursed piercing should occupy the selected slot before its master is found")
	TEST_ASSERT_NULL(deferred_piercing.cursed_piercing_master, "deferred cursed piercing should not bind to an unrelated mind")
	var/mob/living/carbon/human/deferred_master = make_test_human("Delayed Piercing Master")
	TEST_ASSERT(prefs.bind_roundstart_cursed_piercing(deferred_wearer, deferred_piercing, deferred_master.mind), "deferred cursed piercing should bind once the configured master mind is available")
	TEST_ASSERT_EQUAL(deferred_piercing.cursed_piercing_master, deferred_master.mind, "deferred cursed piercing should store the later master mind")
	var/datum/component/collar_master/deferred_CM = deferred_master.mind.GetComponent(/datum/component/collar_master)
	TEST_ASSERT_NOTNULL(deferred_CM, "delayed master binding should create a collar master component")
	TEST_ASSERT(deferred_wearer in deferred_CM.my_pets, "delayed master binding should register the wearer as a controlled pet")

	prefs.reset_intimate_accessory_preferences()
	TEST_ASSERT_EQUAL(prefs.pref_cursed_roundstart_device, CURSED_ROUNDSTART_NONE, "reset should clear cursed device")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_master_name, "", "reset should clear cursed master name")
	TEST_ASSERT(!prefs.pref_cursed_self_master, "reset should clear self-master flag")
	TEST_ASSERT_EQUAL(prefs.pref_gilded_chastity_recipient, GILDED_CHASTITY_RECIPIENT_MASTER, "reset should restore gilded recipient default")
	TEST_ASSERT_EQUAL(prefs.pref_cursed_piercing_slot, INTIMATE_SLOT_GENITAL, "reset should restore cursed piercing default slot")

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
	device.finalize_chastity_equip(wearer)

	TEST_ASSERT_EQUAL(GILDED_CHASTITY_MAX_DRAIN, 100, "gilded drain max should allow 100 mammon")
	TEST_ASSERT(device.set_gilded_drain_amount(wearer, 200), "gilded drain amount setter should accept numeric input")
	TEST_ASSERT_EQUAL(device.gilded_drain_amount, 100, "gilded drain amount should clamp to 100")
	device.gilded_drain_amount = 5

	SStreasury.bank_accounts[wearer] = 3
	SStreasury.bank_accounts[master] = 7
	device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_MASTER
	device.chastity_move_delay = 1
	device.chastity_move_chance = 100
	device.chastity_move_counter = 0
	var/datum/component/intimate_reaction/chastity_receive_flavor/reaction_component = device.GetComponent(/datum/component/intimate_reaction/chastity_receive_flavor)
	TEST_ASSERT_NOTNULL(reaction_component, "gilded chastity should have a movement reaction component while worn")
	reaction_component.try_handle_wearer_moved(wearer)
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 3, "movement jingles should not drain the wearer's Nervelock")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[master], 7, "movement jingles should not credit the master")
	SEND_SIGNAL(wearer, COMSIG_MOB_EJACULATED)
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 0, "orgasm drain should clamp to the wearer's available balance")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 0, "gilded drain should never overdraw the wearer")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[master], 10, "master recipient should receive drained mammon")

	SStreasury.bank_accounts[wearer] = 8
	var/self_master_treasury_before = SStreasury.treasury_value
	device.chastity_master = wearer.mind
	TEST_ASSERT(device.set_gilded_recipient(wearer, GILDED_CHASTITY_RECIPIENT_MASTER), "self-master should accept master recipient requests")
	TEST_ASSERT_EQUAL(device.gilded_recipient, GILDED_CHASTITY_RECIPIENT_TREASURY, "self-master device recipient should default to Keep Treasury")
	var/drained = device.on_gilded_orgasm_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 5, "self-master gilded drain should still take the configured amount")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 3, "self-master gilded drain should not credit mammon back to the wearer")
	TEST_ASSERT_EQUAL(SStreasury.treasury_value, self_master_treasury_before + 5, "self-master master recipient should default to Keep Treasury")
	device.chastity_master = master.mind

	SStreasury.bank_accounts[wearer] = 4
	var/treasury_recipient_before = SStreasury.treasury_value
	device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_TREASURY
	drained = device.on_gilded_orgasm_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 4, "treasury drain should clamp to the wearer's available balance")
	TEST_ASSERT_EQUAL(SStreasury.bank_accounts[wearer], 0, "treasury drain should leave the wearer at zero")
	TEST_ASSERT_EQUAL(SStreasury.treasury_value, treasury_recipient_before + 4, "treasury recipient should receive drained mammon")

	if(SSmapping?.retainer)
		SStreasury.bank_accounts[wearer] = 2
		device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_HOARDMASTER
		drained = device.on_gilded_orgasm_triggered(wearer)
		TEST_ASSERT_EQUAL(drained, 2, "hoardmaster drain should clamp to the wearer's available balance")
		TEST_ASSERT_EQUAL(SSmapping.retainer.bandit_contribute, old_bandit_contribute + 2, "hoardmaster recipient should credit bandit contribution")

	penis.penis_size = DEFAULT_PENIS_SIZE
	SStreasury.bank_accounts[wearer] = GILDED_CHASTITY_SHRINK_DRAIN_STEP
	device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_MASTER
	device.gilded_total_drained = GILDED_CHASTITY_SHRINK_DRAIN_STEP - 1
	device.gilded_next_shrink_threshold = GILDED_CHASTITY_SHRINK_DRAIN_STEP
	device.gilded_drain_amount = 1
	drained = device.on_gilded_orgasm_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 1, "threshold orgasm should drain the configured amount")
	TEST_ASSERT_EQUAL(penis.penis_size, DEFAULT_PENIS_SIZE - 1, "threshold drain should shrink penis size by one step")

	penis.penis_size = MIN_PENIS_SIZE
	device.apply_gilded_shrink(wearer, TRUE)
	TEST_ASSERT_EQUAL(penis.penis_size, MIN_PENIS_SIZE, "gilded shrink should not reduce below minimum penis size")

	SStreasury.bank_accounts[wearer] = 0
	device.gilded_zero_fund_orgasms = 0
	device.gilded_limped = FALSE
	TEST_ASSERT(!is_valid_gilded_chastity_overdraw_effect("arousal"), "gilded overdraw arousal should no longer be a valid empty-Nervelock punishment")
	TEST_ASSERT(!is_valid_gilded_chastity_overdraw_effect("climax"), "gilded overdraw climax should no longer be a valid empty-Nervelock punishment")
	TEST_ASSERT(device.set_gilded_overdraw_effect(wearer, GILDED_CHASTITY_OVERDRAW_SHRINK), "gilded overdraw shrink effect should be accepted")
	REMOVE_TRAIT(wearer, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
	penis.penis_size = DEFAULT_PENIS_SIZE
	drained = device.on_gilded_orgasm_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 0, "overdraw orgasm should not drain mammon")
	sleep(1)
	TEST_ASSERT_EQUAL(penis.penis_size, DEFAULT_PENIS_SIZE - 1, "default overdraw effect should shrink penis size")

	TEST_ASSERT(device.set_gilded_overdraw_effect(wearer, GILDED_CHASTITY_OVERDRAW_STRIP), "gilded overdraw strip effect should be accepted")
	var/obj/item/clothing/shoes/roguetown/simpleshoes/strip_shoes = allocate(/obj/item/clothing/shoes/roguetown/simpleshoes, wearer)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(strip_shoes, SLOT_SHOES, FALSE, TRUE, TRUE, TRUE), "test setup should equip removable shoes")
	TEST_ASSERT_EQUAL(wearer.get_item_by_slot(SLOT_SHOES), strip_shoes, "test shoes should occupy the shoe slot before strip punishment")
	drained = device.on_gilded_orgasm_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 0, "strip overdraw orgasm should not drain mammon")
	sleep(1)
	TEST_ASSERT_NULL(wearer.get_item_by_slot(SLOT_SHOES), "strip overdraw effect should remove removable clothing")
	TEST_ASSERT_EQUAL(strip_shoes.loc, get_turf(wearer), "strip overdraw effect should drop removed clothing at the wearer")

	TEST_ASSERT(device.set_gilded_forced_message_enabled(wearer, TRUE), "gilded forced messages should be toggleable")
	TEST_ASSERT(device.set_gilded_forced_message(wearer, 1, GILDED_CHASTITY_FORCED_MESSAGE_SAY, "I am empty."), "first forced message should be accepted")
	TEST_ASSERT(device.set_gilded_forced_message(wearer, 2, GILDED_CHASTITY_FORCED_MESSAGE_ME, "trembles in the empty gilded cage."), "second forced message should allow /me")
	TEST_ASSERT(device.set_gilded_forced_message(wearer, 3, GILDED_CHASTITY_FORCED_MESSAGE_SAY, "Please fill my Nervelock."), "third forced message should be accepted")
	TEST_ASSERT(!device.set_gilded_forced_message(wearer, 4, GILDED_CHASTITY_FORCED_MESSAGE_SAY, "too many"), "forced message slots should be capped at three")
	TEST_ASSERT(!device.set_gilded_forced_message(wearer, 1, "bad-kind", "invalid kind"), "forced message kind should be validated")
	TEST_ASSERT_EQUAL(length(device.get_configured_gilded_forced_messages()), GILDED_CHASTITY_MAX_FORCED_MESSAGES, "configured forced message list should expose at most three messages")
	TEST_ASSERT(device.apply_gilded_forced_message(wearer), "configured forced message punishment should run independently")
	TEST_ASSERT(device.set_gilded_overdraw_effect(wearer, GILDED_CHASTITY_OVERDRAW_STRIP), "strip should remain selectable while forced message punishment is enabled")
	var/obj/item/clothing/shoes/roguetown/simpleshoes/paired_strip_shoes = allocate(/obj/item/clothing/shoes/roguetown/simpleshoes, wearer)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(paired_strip_shoes, SLOT_SHOES, FALSE, TRUE, TRUE, TRUE), "test setup should equip removable shoes for paired message punishment")
	drained = device.on_gilded_orgasm_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 0, "paired strip/message overdraw orgasm should not drain mammon")
	sleep(1)
	TEST_ASSERT_NULL(wearer.get_item_by_slot(SLOT_SHOES), "forced message punishment should pair with strip instead of replacing it")

	device.gilded_zero_fund_orgasms = 0
	device.gilded_limped = FALSE
	device.set_gilded_forced_message_enabled(wearer, FALSE)
	REMOVE_TRAIT(wearer, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
	for(var/i in 1 to GILDED_CHASTITY_ZERO_ORGASMS_FOR_LIMP)
		device.on_gilded_orgasm_triggered(wearer)
		sleep(1)
	TEST_ASSERT(HAS_TRAIT(wearer, TRAIT_LIMPDICK), "three zero-fund orgasms should apply round-only limpness")

	if(wearer.chastity_device == device)
		device.remove_chastity(wearer)
	SStreasury.bank_accounts = old_accounts
	SStreasury.treasury_value = old_treasury_value
	if(SSmapping?.retainer)
		SSmapping.retainer.bandit_contribute = old_bandit_contribute

/datum/unit_test/cursed_piercing_contract/proc/setup_test_mind(mob/living/carbon/human/H, character_name)
	H.name = character_name
	H.real_name = character_name
	var/datum/mind/M = new /datum/mind(null)
	allocated += M
	M.name = character_name
	M.transfer_to(H)
	return M

/datum/unit_test/cursed_piercing_contract/proc/make_test_human(character_name, add_penis = FALSE, add_testicles = FALSE, add_breasts = FALSE)
	var/mob/living/carbon/human/dummy/H = allocate(/mob/living/carbon/human/dummy, null)
	setup_test_mind(H, character_name)
	if(add_penis && !H.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
		penis.Insert(H)
	if(add_testicles && !H.getorganslot(ORGAN_SLOT_TESTICLES))
		var/obj/item/organ/testicles/testicles = allocate(/obj/item/organ/testicles, null)
		testicles.Insert(H)
	if(add_breasts && !H.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/breasts/breasts = allocate(/obj/item/organ/breasts, null)
		breasts.Insert(H)
	return H

/datum/unit_test/cursed_piercing_contract/proc/list_has_text(list/lines, needle)
	for(var/line in lines)
		if(findtext(line, needle))
			return TRUE
	return FALSE

/datum/unit_test/cursed_piercing_contract/Run()
	var/mob/living/carbon/human/wearer = make_test_human("Cursed Piercing Wearer", TRUE, TRUE, TRUE)
	var/mob/living/carbon/human/master = make_test_human("Cursed Piercing Master")
	var/obj/item/organ/penis/penis = wearer.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/organ/testicles/testicles = wearer.getorganslot(ORGAN_SLOT_TESTICLES)
	var/obj/item/organ/breasts/breasts = wearer.getorganslot(ORGAN_SLOT_BREASTS)
	penis.penis_size = DEFAULT_PENIS_SIZE
	testicles.ball_size = DEFAULT_TESTICLES_SIZE
	breasts.breast_size = DEFAULT_BREASTS_SIZE
	breasts.lactating = FALSE
	REMOVE_TRAIT(wearer, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE)

	var/list/ruby_option = find_cursed_piercing_option(get_cursed_piercing_gem_options(), "ruby")
	TEST_ASSERT_EQUAL(ruby_option["label"], "Rontz", "cursed piercing gem menu should use Roguetown gem labels")
	TEST_ASSERT_EQUAL(ruby_option["descriptor"], "rontz", "cursed piercing gem descriptors should use Roguetown gem names")
	var/list/green_option = find_cursed_piercing_option(get_cursed_piercing_gem_options(), "green")
	TEST_ASSERT_EQUAL(green_option["label"], "Gemerald", "green cursed piercing gem option should use Roguetown naming")
	TEST_ASSERT_EQUAL(green_option["descriptor"], "gemerald", "green cursed piercing descriptor should use Roguetown naming")

	var/obj/item/intimate_accessory/piercing/cursed/piercing = allocate(/obj/item/intimate_accessory/piercing/cursed, wearer)
	piercing.cursed_piercing_master = master.mind
	var/formatted_message = piercing.format_cursed_piercing_message("cursed_piercing_organ_size_changed", list(
		"%ORGAN%" = "penis",
		"%DIRECTION%" = "larger",
		"%SIZE%" = "3"
	))
	TEST_ASSERT(istext(formatted_message) && length(formatted_message), "cursed piercing organ-size string bank should return wearer-facing text")
	TEST_ASSERT(!findtext(formatted_message, "%ORGAN%"), "cursed piercing organ-size message should resolve organ token")
	TEST_ASSERT(!findtext(formatted_message, "%DIRECTION%"), "cursed piercing organ-size message should resolve direction token")
	TEST_ASSERT(!findtext(formatted_message, "%SIZE%"), "cursed piercing organ-size message should resolve size token")
	formatted_message = piercing.format_cursed_piercing_message("cursed_piercing_slot_changed", list("%SLOT%" = "Nose"))
	TEST_ASSERT(istext(formatted_message) && length(formatted_message), "cursed piercing slot string bank should return wearer-facing text")
	TEST_ASSERT(!findtext(formatted_message, "%SLOT%"), "cursed piercing slot message should resolve slot token")
	formatted_message = piercing.format_cursed_piercing_message("cursed_piercing_metal_changed", list("%METAL%" = "gold"))
	TEST_ASSERT(istext(formatted_message) && length(formatted_message), "cursed piercing metal string bank should return wearer-facing text")
	TEST_ASSERT(!findtext(formatted_message, "%METAL%"), "cursed piercing metal message should resolve metal token")
	formatted_message = piercing.format_cursed_piercing_message("cursed_piercing_gem_changed", list("%GEM%" = "rontz"))
	TEST_ASSERT(istext(formatted_message) && length(formatted_message), "cursed piercing gem string bank should return wearer-facing text")
	TEST_ASSERT(!findtext(formatted_message, "%GEM%"), "cursed piercing gem message should resolve gem token")
	TEST_ASSERT(piercing.supports_intimate_slot(INTIMATE_SLOT_NOSE), "cursed piercings should support non-genital piercing slots")
	TEST_ASSERT(piercing.supports_intimate_slot(INTIMATE_SLOT_GENITAL), "cursed piercings should still support genital piercing slots")
	TEST_ASSERT(piercing.set_current_intimate_slot(INTIMATE_SLOT_NOSE), "test piercing should be able to take the nose slot form")
	piercing.finalize_intimate_equip(wearer)
	TEST_ASSERT_EQUAL(wearer.intimate_nose_piercing, piercing, "nose-form cursed piercing should occupy the nose intimate slot")

	var/datum/component/collar_master/CM = master.mind.AddComponent(/datum/component/collar_master)
	TEST_ASSERT(CM.add_pet(wearer), "collar master component should accept a wearer bound by cursed piercing")
	TEST_ASSERT_EQUAL(CM.get_pet_cursed_piercing(wearer), piercing, "component should resolve the pet's cursed piercing")
	var/list/piercing_data = piercing.get_cursed_piercing_ui_data(wearer)
	TEST_ASSERT_EQUAL(piercing_data["current_slot"], INTIMATE_SLOT_NOSE, "cursed piercing UI data should expose the current slot")
	TEST_ASSERT(INTIMATE_SLOT_EAR in piercing_data["supported_slots"], "cursed piercing UI data should expose supported movement slots")
	var/datum/intimate_menu/intimate_menu = new(wearer)
	var/list/menu_item_data = intimate_menu._build_item_data(wearer, piercing, TRUE)
	TEST_ASSERT(!menu_item_data["can_customize_descriptor"], "wearer intimate menu should not expose cursed piercing descriptor controls")
	TEST_ASSERT(!intimate_menu._intimate_act_set_piercing_descriptor(wearer, piercing, "Jacob's ladder"), "wearer intimate menu should not rename cursed piercings")
	TEST_ASSERT_NULL(piercing.custom_piercing_descriptor, "wearer intimate menu should leave cursed piercing descriptors unchanged")
	qdel(intimate_menu)
	TEST_ASSERT(CM.set_pet_cursed_piercing_slot(wearer, INTIMATE_SLOT_EAR), "master should move a worn cursed piercing to another supported slot")
	TEST_ASSERT_NULL(wearer.intimate_nose_piercing, "moving cursed piercing should clear the old worn slot")
	TEST_ASSERT_EQUAL(wearer.intimate_ear_piercing, piercing, "moving cursed piercing should occupy the selected slot")
	TEST_ASSERT_EQUAL(piercing.get_effective_intimate_slot(), INTIMATE_SLOT_EAR, "moved cursed piercing should store the selected slot")
	TEST_ASSERT_NOTNULL(piercing.intimate_feature, "visible moved cursed piercing should have a sprite accessory feature")
	TEST_ASSERT_EQUAL(piercing.intimate_feature.accessory_colors, "#363636#990033", "moved cursed piercing sprite feature should start with current cursed colors")
	TEST_ASSERT(CM.set_pet_cursed_piercing_descriptor(wearer, "Jacob's ladder"), "master should set cursed piercing examine descriptor")
	TEST_ASSERT_EQUAL(piercing.custom_piercing_descriptor, "jacob's ladder", "master-set cursed piercing descriptor should be sanitized and stored")
	piercing_data = piercing.get_cursed_piercing_ui_data(wearer)
	TEST_ASSERT_EQUAL(piercing_data["custom_descriptor"], "jacob's ladder", "cursed piercing UI data should expose the master-set descriptor")
	var/list/cursed_piercing_lines = wearer.human_modular_intimate_piercing_examine_lines(wearer, TRUE)
	TEST_ASSERT(list_has_text(cursed_piercing_lines, "jacob's ladder"), "master-set cursed piercing descriptor should appear in examine text")
	TEST_ASSERT(CM.set_pet_cursed_piercing_descriptor(wearer, null), "master should clear cursed piercing examine descriptor")
	TEST_ASSERT_NULL(piercing.custom_piercing_descriptor, "cleared cursed piercing descriptor should return to the generated examine name")

	TEST_ASSERT(CM.adjust_pet_cursed_piercing_organ_size(wearer, CURSED_PIERCING_ORGAN_PENIS, 1), "master should enlarge penis through cursed piercing")
	TEST_ASSERT_EQUAL(penis.penis_size, DEFAULT_PENIS_SIZE + 1, "penis should grow by one size step")
	penis.penis_size = MAX_PENIS_SIZE
	TEST_ASSERT(!CM.adjust_pet_cursed_piercing_organ_size(wearer, CURSED_PIERCING_ORGAN_PENIS, 1), "penis growth should refuse to exceed maximum")
	TEST_ASSERT_EQUAL(penis.penis_size, MAX_PENIS_SIZE, "penis size should clamp at maximum")

	TEST_ASSERT(CM.adjust_pet_cursed_piercing_organ_size(wearer, CURSED_PIERCING_ORGAN_TESTICLES, -1), "master should shrink testicles through cursed piercing")
	TEST_ASSERT_EQUAL(testicles.ball_size, DEFAULT_TESTICLES_SIZE - 1, "testicles should shrink by one size step")
	testicles.ball_size = MIN_TESTICLES_SIZE
	TEST_ASSERT(!CM.adjust_pet_cursed_piercing_organ_size(wearer, CURSED_PIERCING_ORGAN_TESTICLES, -1), "testicle shrink should refuse to go below minimum")
	TEST_ASSERT_EQUAL(testicles.ball_size, MIN_TESTICLES_SIZE, "testicle size should clamp at minimum")

	TEST_ASSERT(CM.adjust_pet_cursed_piercing_organ_size(wearer, CURSED_PIERCING_ORGAN_BREASTS, 1), "master should enlarge breasts through cursed piercing")
	TEST_ASSERT_EQUAL(breasts.breast_size, DEFAULT_BREASTS_SIZE + 1, "breasts should grow by one size step")
	TEST_ASSERT(CM.set_pet_cursed_piercing_lactation(wearer, TRUE), "master should induce lactation through cursed piercing")
	TEST_ASSERT(breasts.lactating, "breasts should be lactating after cursed piercing command")
	TEST_ASSERT(CM.set_pet_cursed_piercing_lactation(wearer, FALSE), "master should stop lactation through cursed piercing")
	TEST_ASSERT(!breasts.lactating, "breasts should stop lactating after cursed piercing command")

	TEST_ASSERT(CM.set_pet_cursed_piercing_impotence(wearer, TRUE), "master should induce impotence through cursed piercing")
	TEST_ASSERT(HAS_TRAIT(wearer, TRAIT_LIMPDICK), "impotence command should apply limp trait")
	TEST_ASSERT(CM.set_pet_cursed_piercing_impotence(wearer, FALSE), "master should reverse impotence through cursed piercing")
	TEST_ASSERT(!HAS_TRAIT(wearer, TRAIT_LIMPDICK), "reverse impotence command should remove limp trait")

	TEST_ASSERT_EQUAL(piercing.intimate_metal_color, "#363636", "cursed piercing should default to dark cursed metal")
	TEST_ASSERT_EQUAL(piercing.intimate_gem_color, "#990033", "cursed piercing should default to crimson gem")
	TEST_ASSERT(CM.set_pet_cursed_piercing_metal(wearer, "gold"), "master should set cursed piercing metal appearance")
	TEST_ASSERT_EQUAL(piercing.intimate_metal_name, "gold", "gold metal selection should update descriptor")
	TEST_ASSERT_EQUAL(piercing.intimate_metal_color, "#C4B651", "gold metal selection should use existing piercing metal color")
	TEST_ASSERT_EQUAL(piercing.intimate_feature.accessory_colors, "#C4B651#990033", "metal changes should update the worn sprite accessory colors")
	TEST_ASSERT(CM.set_pet_cursed_piercing_gem(wearer, "ruby"), "master should set cursed piercing gem appearance")
	TEST_ASSERT_EQUAL(piercing.current_gem_descriptor, "rontz", "ruby gem selection should update to Roguetown descriptor")
	TEST_ASSERT_EQUAL(piercing.intimate_gem_color, "#B4142C", "ruby gem selection should use existing socket color")
	TEST_ASSERT_EQUAL(piercing.intimate_feature.accessory_colors, "#C4B651#B4142C", "gem changes should update the worn sprite accessory colors")
	TEST_ASSERT(!CM.set_pet_cursed_piercing_metal(wearer, "badmetal"), "invalid metal selection should be rejected")
	TEST_ASSERT(!CM.set_pet_cursed_piercing_gem(wearer, "badgem"), "invalid gem selection should be rejected")
	TEST_ASSERT(!CM.set_pet_cursed_piercing_slot(wearer, INTIMATE_SLOT_MISC + 100), "invalid cursed piercing slot movement should be rejected")

	TEST_ASSERT(CM.set_pet_cursed_piercing_impotence(wearer, TRUE), "impotence should be active before release cleanup")
	TEST_ASSERT(CM.remove_pet(wearer), "release should remove a cursed-piercing-bound pet")
	TEST_ASSERT_NULL(wearer.intimate_ear_piercing, "release should clear the moved worn cursed piercing slot")
	TEST_ASSERT(!(piercing in wearer.intimate_accessories), "release should remove cursed piercing from worn intimate accessories")
	TEST_ASSERT(!HAS_TRAIT(wearer, TRAIT_LIMPDICK), "release should clear cursed piercing impotence trait")
