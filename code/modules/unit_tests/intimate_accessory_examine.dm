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
	var/obj/item/intimate_accessory/rear/plug/analbeads/copper/beads = allocate(/obj/item/intimate_accessory/rear/plug/analbeads/copper)
	beads.socketed_item_type = /obj/item/roguegem/ruby
	beads.current_gem_descriptor = "rontz"
	beads.intimate_gem_color = "#B4142C"
	beads.beads_inserted = 3
	beads.update_dynamic_name()

	var/bead_line = beads.get_intimate_examine_line(human, human, "rear")
	TEST_ASSERT(findtext(bead_line, "stuffed three beads deep."), "anal bead examine text should spell out the current inserted depth")
	TEST_ASSERT(findtext(bead_line, "<font color='#b4142c'>rontz-set</font>"), "anal bead examine text should preserve socket coloring")

	var/obj/item/intimate_accessory/piercing/ear/copper/earring = allocate(/obj/item/intimate_accessory/piercing/ear/copper)
	human.intimate_accessories = list(earring)
	human.intimate_ear_piercing = earring
	var/list/jewelry_lines = human.human_modular_intimate_jewelry_examine_lines(human, TRUE)
	TEST_ASSERT_EQUAL(length(jewelry_lines), 1, "non-explicit intimate jewelry should be reported by the descriptor-adjacent jewelry helper")
	TEST_ASSERT(findtext(jewelry_lines[1], "ears are pierced through with"), "ear jewelry should use the natural piercing examine shape")
