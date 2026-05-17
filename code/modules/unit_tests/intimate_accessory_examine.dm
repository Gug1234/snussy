/datum/unit_test/intimate_accessory_examine_text/proc/list_has_text(list/lines, needle)
	for(var/line in lines)
		if(findtext(line, needle))
			return TRUE
	return FALSE

/datum/unit_test/intimate_accessory_examine_text/Run()
	var/obj/item/intimate_accessory/rear/plug/copper/plug = allocate(/obj/item/intimate_accessory/rear/plug/copper)
	plug.socketed_item_type = /obj/item/roguegem/ruby
	plug.current_gem_descriptor = "rontz"
	plug.intimate_gem_color = "#B4142C"
	plug.update_dynamic_name()

	var/colored_plug_name = plug.get_intimate_examine_colored_name()
	TEST_ASSERT(findtext(colored_plug_name, "<font color='#b4142c'>rontz-set</font>"), "socket descriptor should be colored in intimate examine names")
	TEST_ASSERT(findtext(colored_plug_name, "<font color='#8c4734'>copper</font>"), "material descriptor should be colored in intimate examine names")

	var/mob/living/carbon/human/consistent/human = allocate(/mob/living/carbon/human/consistent)
	human.name = "Josh Killerfang"
	human.real_name = "Josh Killerfang"
	human.gender = MALE

	var/obj/item/intimate_accessory/rear/plug/analbeads/copper/beads = allocate(/obj/item/intimate_accessory/rear/plug/analbeads/copper)
	beads.socketed_item_type = /obj/item/roguegem/ruby
	beads.current_gem_descriptor = "rontz"
	beads.intimate_gem_color = "#B4142C"
	beads.beads_inserted = 3
	beads.update_dynamic_name()

	var/bead_line = beads.get_intimate_examine_line(human, human, "rear")
	TEST_ASSERT(findtext(bead_line, "He is wearing a set of"), "anal bead examine text should use subject pronouns instead of the examined mob name")
	TEST_ASSERT(!findtext(bead_line, "Josh Killerfang"), "anal bead examine text should not print the examined mob name")
	TEST_ASSERT(findtext(bead_line, "stuffed three beads deep."), "anal bead examine text should spell out the current inserted depth")
	TEST_ASSERT(findtext(bead_line, "<font color='#b4142c'>rontz-set</font>"), "anal bead examine text should preserve socket coloring")

	var/obj/item/intimate_accessory/rear/plug/iron/iron_plug = allocate(/obj/item/intimate_accessory/rear/plug/iron)
	var/iron_plug_line = iron_plug.get_intimate_examine_line(human, human, "rear")
	TEST_ASSERT(findtext(iron_plug_line, "He has an "), "plug examine text should choose the correct indefinite article")
	TEST_ASSERT(!findtext(iron_plug_line, "He has a iron"), "plug examine text should not use 'a' before vowel-sound accessory names")
	TEST_ASSERT(!findtext(iron_plug_line, "Josh Killerfang"), "plug examine text should not print the examined mob name")

	var/obj/item/intimate_accessory/piercing/tongue/iron/tongue_piercing = allocate(/obj/item/intimate_accessory/piercing/tongue/iron)
	tongue_piercing.current_gem_descriptor = "gemerald"
	tongue_piercing.intimate_gem_color = "#55D6FF"
	tongue_piercing.update_dynamic_name()
	var/tongue_line = tongue_piercing.get_intimate_examine_line(human, human, "tongue")
	TEST_ASSERT(findtext(tongue_line, "His tongue is pierced through with a "), "piercing examine text should use possessive pronouns and include an indefinite article")
	TEST_ASSERT(findtext(tongue_line, "gemerald-set"), "piercing examine text should preserve gem descriptor names")
	TEST_ASSERT(!findtext(tongue_line, "Josh Killerfang"), "piercing examine text should not print the examined mob name")

	var/obj/item/organ/penis/penis = human.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		penis = allocate(/obj/item/organ/penis, null)
		penis.Insert(human)
	var/obj/item/organ/testicles/testes = human.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testes)
		testes = allocate(/obj/item/organ/testicles, null)
		testes.Insert(human)

	var/obj/item/intimate_accessory/piercing/genital/iron/genital_piercing = allocate(/obj/item/intimate_accessory/piercing/genital/iron)
	genital_piercing.set_custom_piercing_descriptor("Jacob's ladder")
	human.intimate_accessories = list(genital_piercing)
	human.intimate_genital_piercing = genital_piercing
	var/list/descriptor_lines = build_cool_description(human.get_mob_descriptors(FALSE, human), human, human)
	TEST_ASSERT(list_has_text(descriptor_lines, "pierced through with an <font color='#9ea48e'>iron</font> jacob's ladder"), "genital piercings should append inline to genital descriptor lines with custom descriptors")

	var/list/top_lines = human.human_modular_examine_extension(human, FALSE, "He is", "his", "He has")
	TEST_ASSERT(!list_has_text(top_lines, "jacob's ladder"), "genital piercings should not stay in the explicit pink intimate examine block")

	var/obj/item/organ/breasts/breasts = human.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		breasts = allocate(/obj/item/organ/breasts, null)
		breasts.Insert(human)
	var/obj/item/intimate_accessory/piercing/breast/iron/breast_piercing = allocate(/obj/item/intimate_accessory/piercing/breast/iron)
	human.intimate_breast_piercing = breast_piercing
	human.intimate_accessories = list(breast_piercing)
	descriptor_lines = build_cool_description(human.get_mob_descriptors(FALSE, human), human, human)
	TEST_ASSERT(list_has_text(descriptor_lines, "breasts, pierced through with an <font color='#9ea48e'>iron</font> nipple piercing"), "breast piercings should append inline to breast descriptor lines")

	var/obj/item/intimate_accessory/piercing/ear/copper/earring = allocate(/obj/item/intimate_accessory/piercing/ear/copper)
	var/obj/item/intimate_accessory/piercing/rear/iron/rear_piercing = allocate(/obj/item/intimate_accessory/piercing/rear/iron)
	var/obj/item/intimate_accessory/piercing/tongue/iron/mouth_piercing = allocate(/obj/item/intimate_accessory/piercing/tongue/iron)
	human.intimate_accessories = list(earring, rear_piercing, mouth_piercing)
	human.intimate_ear_piercing = earring
	human.intimate_rear_piercing = rear_piercing
	human.intimate_mouth_piercing = mouth_piercing
	var/list/piercing_lines = human.human_modular_intimate_piercing_examine_lines(human, TRUE)
	TEST_ASSERT_EQUAL(length(piercing_lines), 3, "non-inline piercings should be reported by the descriptor-adjacent piercing helper")
	TEST_ASSERT(list_has_text(piercing_lines, "His ears are pierced through with"), "ear jewelry should use possessive pronouns and the natural piercing examine shape")
	TEST_ASSERT(list_has_text(piercing_lines, "His rear is pierced through with"), "rear piercings should move to the descriptor-adjacent piercing helper")
	TEST_ASSERT(list_has_text(piercing_lines, "His tongue is pierced through with"), "tongue piercings should move to the descriptor-adjacent piercing helper")
	TEST_ASSERT(!list_has_text(piercing_lines, "Josh Killerfang"), "piercing examine text should not print the examined mob name")
