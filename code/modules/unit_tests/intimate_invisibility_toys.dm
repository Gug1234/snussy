/datum/unit_test/intimate_invisibility_toys/Run()
	var/obj/item/intimate_accessory/rear/plug/iron/plug = allocate(/obj/item/intimate_accessory/rear/plug/iron)
	TEST_ASSERT(plug.has_intimate_invisibility_appearance(), "Rear plugs should support intimate invisibility appearances.")
	TEST_ASSERT_EQUAL(plug.get_intimate_invisibility_icon_state("mt"), "plug_mt", "Male tall plugs should use the matching invistoys state.")

	var/mutable_appearance/plug_appearance = plug.build_intimate_invisibility_appearance("mt")
	TEST_ASSERT(plug_appearance, "Rear plugs should build an intimate invisibility appearance.")
	TEST_ASSERT(plug_appearance.appearance_flags & RESET_ALPHA, "Intimate invisibility appearances should ignore wearer alpha.")
	TEST_ASSERT(plug_appearance.appearance_flags & RESET_COLOR, "Intimate invisibility appearances should not inherit wearer color.")
	TEST_ASSERT_EQUAL(plug_appearance.alpha, 255, "Intimate invisibility appearances should remain fully visible.")
	TEST_ASSERT_EQUAL(plug_appearance.color, "#9EA48E", "Rear plug invisibility appearances should use the accessory metal color.")

	var/obj/item/intimate_accessory/rear/plug/analbeads/steel/beads = allocate(/obj/item/intimate_accessory/rear/plug/analbeads/steel)
	TEST_ASSERT(beads.has_intimate_invisibility_appearance(), "Anal beads should support intimate invisibility appearances.")
	TEST_ASSERT_EQUAL(beads.get_intimate_invisibility_icon_state("fm"), "beads_fm", "Female anal beads should use the matching invistoys state.")

	var/mob/living/carbon/human/consistent/human = allocate(/mob/living/carbon/human/consistent)
	human.alpha = 0
	TEST_ASSERT(!human.is_intimate_magic_invisible(), "Plain alpha or stealth invisibility should not show intimate invisibility props.")
	human.mob_timers[MT_INVISIBILITY] = world.time + 10 SECONDS
	TEST_ASSERT(human.is_intimate_magic_invisible(), "Magic invisibility timers should show intimate invisibility props.")

	human.intimate_rear_insertable = plug
	human.update_intimate_invisibility_props()
	TEST_ASSERT_NOTNULL(human.intimate_invisibility_visual, "Magic invisibility should create a separate prop visual.")
	TEST_ASSERT(human.intimate_invisibility_visual in human.vis_contents, "Intimate invisibility props should render through vis_contents instead of alpha-inherited overlays.")
	TEST_ASSERT_EQUAL(human.intimate_invisibility_visual.alpha, 255, "Intimate invisibility prop visuals should stay fully opaque while the wearer is faded.")
	TEST_ASSERT(human.intimate_invisibility_visual.layer >= ABOVE_MOB_LAYER, "Intimate invisibility prop visuals should use a visible world layer, not internal mob overlay layers.")
	TEST_ASSERT_EQUAL(human.intimate_invisibility_visual.icon_state, "plug_mt", "Intimate invisibility prop visuals should use the wearer's body suffix.")

	var/atom/movable/intimate_invisibility_visual/old_visual = human.intimate_invisibility_visual
	human.mob_timers[MT_INVISIBILITY] = world.time
	human.update_intimate_invisibility_props()
	TEST_ASSERT_NULL(human.intimate_invisibility_visual, "The prop visual should clear when magic invisibility ends.")
	TEST_ASSERT(!(old_visual in human.vis_contents), "The prop visual should be removed from vis_contents when magic invisibility ends.")
