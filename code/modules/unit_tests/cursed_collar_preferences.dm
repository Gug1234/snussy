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
	TEST_ASSERT(device.set_gilded_overdraw_effect(wearer, GILDED_CHASTITY_OVERDRAW_SHRINK), "gilded overdraw shrink effect should be accepted")
	REMOVE_TRAIT(wearer, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
	penis.penis_size = DEFAULT_PENIS_SIZE
	drained = device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 0, "overdraw jingle should not drain mammon")
	TEST_ASSERT_EQUAL(penis.penis_size, DEFAULT_PENIS_SIZE - 1, "default overdraw effect should shrink penis size")

	TEST_ASSERT(device.set_gilded_overdraw_effect(wearer, GILDED_CHASTITY_OVERDRAW_AROUSAL), "gilded overdraw arousal effect should be accepted")
	penis.penis_size = DEFAULT_PENIS_SIZE
	wearer.sexcon = new /datum/sex_controller(wearer)
	wearer.sexcon.set_arousal(0)
	drained = device.on_chastity_jingle_triggered(wearer)
	TEST_ASSERT_EQUAL(drained, 0, "arousal overdraw jingle should not drain mammon")
	TEST_ASSERT_EQUAL(penis.penis_size, DEFAULT_PENIS_SIZE, "arousal overdraw effect should not shrink penis size")
	TEST_ASSERT_EQUAL(wearer.sexcon.arousal, 20, "arousal overdraw effect should raise arousal")

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

	var/obj/item/intimate_accessory/piercing/cursed/piercing = allocate(/obj/item/intimate_accessory/piercing/cursed, wearer)
	piercing.cursed_piercing_master = master.mind
	TEST_ASSERT(piercing.supports_intimate_slot(INTIMATE_SLOT_NOSE), "cursed piercings should support non-genital piercing slots")
	TEST_ASSERT(piercing.supports_intimate_slot(INTIMATE_SLOT_GENITAL), "cursed piercings should still support genital piercing slots")
	TEST_ASSERT(piercing.set_current_intimate_slot(INTIMATE_SLOT_NOSE), "test piercing should be able to take the nose slot form")
	piercing.finalize_intimate_equip(wearer)
	TEST_ASSERT_EQUAL(wearer.intimate_nose_piercing, piercing, "nose-form cursed piercing should occupy the nose intimate slot")

	var/datum/component/collar_master/CM = master.mind.AddComponent(/datum/component/collar_master)
	TEST_ASSERT(CM.add_pet(wearer), "collar master component should accept a wearer bound by cursed piercing")
	TEST_ASSERT_EQUAL(CM.get_pet_cursed_piercing(wearer), piercing, "component should resolve the pet's cursed piercing")

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
	TEST_ASSERT(CM.set_pet_cursed_piercing_gem(wearer, "ruby"), "master should set cursed piercing gem appearance")
	TEST_ASSERT_EQUAL(piercing.current_gem_descriptor, "ruby", "ruby gem selection should update descriptor")
	TEST_ASSERT_EQUAL(piercing.intimate_gem_color, "#B4142C", "ruby gem selection should use existing socket color")
	TEST_ASSERT(!CM.set_pet_cursed_piercing_metal(wearer, "badmetal"), "invalid metal selection should be rejected")
	TEST_ASSERT(!CM.set_pet_cursed_piercing_gem(wearer, "badgem"), "invalid gem selection should be rejected")

	TEST_ASSERT(CM.set_pet_cursed_piercing_impotence(wearer, TRUE), "impotence should be active before release cleanup")
	TEST_ASSERT(CM.remove_pet(wearer), "release should remove a cursed-piercing-bound pet")
	TEST_ASSERT_NULL(wearer.intimate_nose_piercing, "release should clear the worn cursed piercing slot")
	TEST_ASSERT(!(piercing in wearer.intimate_accessories), "release should remove cursed piercing from worn intimate accessories")
	TEST_ASSERT(!HAS_TRAIT(wearer, TRAIT_LIMPDICK), "release should clear cursed piercing impotence trait")
