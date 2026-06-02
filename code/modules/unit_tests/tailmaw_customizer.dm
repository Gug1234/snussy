/datum/preferences/unit_test_tailmaw_customizer/New(client/C)
	return

/datum/unit_test/tailmaw_customizer_uses_manticore_tail_organ

/datum/unit_test/tailmaw_customizer_uses_manticore_tail_organ/proc/make_tail_entry(accessory_type)
	var/datum/customizer_entry/entry = new /datum/customizer_entry()
	entry.customizer_choice_type = /datum/customizer_choice/organ/tail/demihuman
	entry.accessory_type = accessory_type
	allocated += entry
	return entry

/datum/unit_test/tailmaw_customizer_uses_manticore_tail_organ/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_tailmaw_customizer(null)
	allocated += prefs
	var/datum/customizer_choice/organ/tail/demihuman/tail_choice = CUSTOMIZER_CHOICE(/datum/customizer_choice/organ/tail/demihuman)
	var/list/tailmaw_accessories = list(
		/datum/sprite_accessory/tail/tailmaw,
		/datum/sprite_accessory/tail/tailmaw2,
		/datum/sprite_accessory/tail/tailmaw2_head,
		/datum/sprite_accessory/tail/tailmaw2_stripes,
		/datum/sprite_accessory/tail/tailmaw2_headstripes,
	)

	for(var/accessory_type as anything in tailmaw_accessories)
		var/datum/customizer_entry/entry = make_tail_entry(accessory_type)
		var/datum/organ_dna/organ_dna = tail_choice.create_organ_dna(entry, prefs)
		TEST_ASSERT(ispath(organ_dna.organ_type, /obj/item/organ/tail/manticore), "[accessory_type] must create a manticore-tail organ")
