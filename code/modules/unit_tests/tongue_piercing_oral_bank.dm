/datum/unit_test/tongue_piercing_oral_bank/Run()
	var/obj/item/intimate_accessory/piercing/tongue/silver/silver = allocate(/obj/item/intimate_accessory/piercing/tongue/silver)
	TEST_ASSERT_NOTNULL(silver.reaction_component, "Silver tongue piercing should carry a piercing reaction component.")
	TEST_ASSERT_EQUAL(silver.reaction_component.get_oral_flavor_key(SEX_FORCE_LOW), "tongue_piercing_oral_silver_gentle", "Silver tongue piercing should use the gentle silver oral bank at low force.")
	TEST_ASSERT_EQUAL(silver.reaction_component.get_oral_flavor_key(SEX_FORCE_HIGH), "tongue_piercing_oral_silver_rough", "Silver tongue piercing should use the rough silver oral bank above mid force.")

	var/obj/item/intimate_accessory/piercing/tongue/psydonic/psydonic = allocate(/obj/item/intimate_accessory/piercing/tongue/psydonic)
	TEST_ASSERT_EQUAL(psydonic.reaction_component.get_oral_flavor_key(SEX_FORCE_LOW), "tongue_piercing_oral_psydonic_gentle", "Plain psydonic tongue piercing should use the psydonic oral bank.")
	psydonic.socketed_item_type = /obj/item/clothing/neck/roguetown/psicross/silver
	TEST_ASSERT_EQUAL(psydonic.reaction_component.get_oral_flavor_key(SEX_FORCE_HIGH), "tongue_piercing_oral_psydonic_silver_rough", "Silver psydonic tongue piercing should use the silver psydonic oral bank.")
	psydonic.socketed_item_type = /obj/item/clothing/neck/roguetown/psicross/g
	TEST_ASSERT_EQUAL(psydonic.reaction_component.get_oral_flavor_key(SEX_FORCE_LOW), "tongue_piercing_oral_psydonic_gold_gentle", "Golden psydonic tongue piercing should use the golden psydonic oral bank.")

	var/obj/item/intimate_accessory/piercing/tongue/zizite/zizite = allocate(/obj/item/intimate_accessory/piercing/tongue/zizite)
	TEST_ASSERT_EQUAL(zizite.reaction_component.get_oral_flavor_key(SEX_FORCE_LOW), "tongue_piercing_oral_zizite_gentle", "Plain zizite tongue piercing should use the zizite oral bank.")
	zizite.socketed_item_type = /obj/item/clothing/neck/roguetown/psicross/inhumen/ancient
	TEST_ASSERT_EQUAL(zizite.reaction_component.get_oral_flavor_key(SEX_FORCE_HIGH), "tongue_piercing_oral_zizite_ancient_rough", "Ancient zizite tongue piercing should use the ancient zizite oral bank.")

	var/message = silver.reaction_component.pick_string_bank("tongue_piercing_oral_messages.json", "tongue_piercing_oral_silver_gentle", "modular/code/game/objects/items/lewd/intimate_accessory/strings")
	TEST_ASSERT_NOTNULL(message, "Tongue piercing oral flavor should be backed by an accessory JSON string bank.")
