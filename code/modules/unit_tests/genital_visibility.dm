/datum/unit_test/genital_visibility/Run()
	var/mob/living/carbon/human/consistent/human = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis)
	penis.Insert(human, drop_if_replaced = FALSE)

	TEST_ASSERT("genital_visibility_preference" in penis.vars, "Genital organs should track a visibility preference.")

	human.underwear = allocate(/obj/item/undies)
	var/datum/sprite_accessory/penis/penis_accessory = SPRITE_ACCESSORY(penis.accessory_type)
	TEST_ASSERT(!penis_accessory.is_visible(penis, null, human), "Default genital visibility should still respect underwear.")

	TEST_ASSERT(call(human, "set_genital_visibility_preference")(penis, "always"), "Humans should be able to set one genital to always show.")
	TEST_ASSERT(penis_accessory.is_visible(penis, null, human), "Always-show genitals should render through underwear.")

	human.underwear = null
	var/datum/mob_descriptor/penis/penis_descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/penis)
	var/datum/sex_action/masturbate_penis/masturbate_penis = SEX_ACTION(/datum/sex_action/masturbate_penis)
	human.sexcon.set_target(human)
	TEST_ASSERT(penis_descriptor.can_describe(human), "Visible penises should be available to examine descriptors.")
	TEST_ASSERT(masturbate_penis.shows_on_menu(human, human), "Visible penises should be available to sexcon menus.")
	TEST_ASSERT(human.sexcon.can_perform_action(/datum/sex_action/masturbate_penis, FALSE), "Visible penises should be available to sexcon actions.")

	TEST_ASSERT(call(human, "set_genital_visibility_preference")(penis, "never"), "Humans should be able to set one genital to never show.")
	TEST_ASSERT(!penis_accessory.is_visible(penis, null, human), "Never-show genitals should stay hidden even when clothing would show them.")
	TEST_ASSERT(!penis_descriptor.can_describe(human), "Never-show penises should be hidden from examine descriptors.")
	TEST_ASSERT(!masturbate_penis.shows_on_menu(human, human), "Never-show penises should be hidden from sexcon menus.")
	TEST_ASSERT(!human.sexcon.can_perform_action(/datum/sex_action/masturbate_penis, FALSE), "Never-show penises should not be available to sexcon actions.")
	var/obj/item/intimate_accessory/piercing/genital/iron/genital_piercing = allocate(/obj/item/intimate_accessory/piercing/genital/iron)
	human.intimate_genital_piercing = genital_piercing
	human.intimate_accessories = list(genital_piercing)
	TEST_ASSERT(!length(human.human_modular_intimate_piercing_examine_lines(human, TRUE)), "Never-show genitals should hide genital piercing examine fallback lines.")

	var/obj/item/organ/testicles/testicles = allocate(/obj/item/organ/testicles)
	testicles.Insert(human, drop_if_replaced = FALSE)
	var/datum/mob_descriptor/testicles/testicles_descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/testicles)
	TEST_ASSERT(testicles_descriptor.can_describe(human), "Visible testicles should be available to examine descriptors.")
	TEST_ASSERT(call(human, "set_genital_visibility_preference")(testicles, "never"), "Humans should be able to set testicles to never show.")
	TEST_ASSERT(!testicles_descriptor.can_describe(human), "Never-show testicles should be hidden from examine descriptors.")

	var/obj/item/organ/breasts/breasts = allocate(/obj/item/organ/breasts)
	breasts.Insert(human, drop_if_replaced = FALSE)
	var/datum/mob_descriptor/breasts/breasts_descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/breasts)
	var/datum/sex_action/masturbate_breasts/masturbate_breasts = SEX_ACTION(/datum/sex_action/masturbate_breasts)
	TEST_ASSERT(breasts_descriptor.can_describe(human), "Visible breasts should be available to examine descriptors.")
	TEST_ASSERT(masturbate_breasts.shows_on_menu(human, human), "Visible breasts should be available to sexcon menus.")
	TEST_ASSERT(human.sexcon.can_perform_action(/datum/sex_action/masturbate_breasts, FALSE), "Visible breasts should be available to sexcon actions.")
	TEST_ASSERT(call(human, "set_genital_visibility_preference")(breasts, "never"), "Humans should be able to set breasts to never show.")
	TEST_ASSERT(!breasts_descriptor.can_describe(human), "Never-show breasts should be hidden from examine descriptors.")
	TEST_ASSERT(!masturbate_breasts.shows_on_menu(human, human), "Never-show breasts should be hidden from sexcon menus.")
	TEST_ASSERT(!human.sexcon.can_perform_action(/datum/sex_action/masturbate_breasts, FALSE), "Never-show breasts should not be available to sexcon actions.")
	var/obj/item/intimate_accessory/piercing/breast/iron/breast_piercing = allocate(/obj/item/intimate_accessory/piercing/breast/iron)
	human.intimate_breast_piercing = breast_piercing
	human.intimate_accessories = list(breast_piercing)
	TEST_ASSERT(!length(human.human_modular_intimate_piercing_examine_lines(human, TRUE)), "Never-show breasts should hide breast piercing examine fallback lines.")

	TEST_ASSERT(call(human, "set_genital_visibility_preference")(null, "always", TRUE), "Humans should be able to set all eligible genital organs at once.")
	TEST_ASSERT_EQUAL(penis.vars["genital_visibility_preference"], "always", "All-setting should apply to the penis.")
	TEST_ASSERT_EQUAL(testicles.vars["genital_visibility_preference"], "always", "All-setting should apply to the testicles.")
	TEST_ASSERT_EQUAL(breasts.vars["genital_visibility_preference"], "always", "All-setting should apply to the breasts.")

	var/obj/item/organ/testicles/internal/internal_testicles = allocate(/obj/item/organ/testicles/internal)
	internal_testicles.Insert(human, drop_if_replaced = FALSE)
	TEST_ASSERT(!call(human, "set_genital_visibility_preference")(internal_testicles, "always"), "Skipped/internal genital organs should reject visibility changes.")
