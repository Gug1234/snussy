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

	var/obj/item/intimate_accessory/genital/plug/gold/vaginal_plug = allocate(/obj/item/intimate_accessory/genital/plug/gold)
	TEST_ASSERT(vaginal_plug.socket_item_by_type(/obj/item/roguegem/ruby, "rontz", "#B4142C", 0), "genital plug should accept a socketed gem")
	var/colored_vaginal_plug_name = vaginal_plug.get_intimate_examine_colored_name()
	TEST_ASSERT(findtext(colored_vaginal_plug_name, "<font color='#b4142c'>rontz-set</font>"), "genital plug examine text should include socket descriptors")
	TEST_ASSERT(findtext(colored_vaginal_plug_name, "<font color='#c4b651'>gold</font>"), "genital plug examine text should include material descriptors")

	var/obj/item/intimate_accessory/genital/plug/sounding_rod/gold/sounding_rod = allocate(/obj/item/intimate_accessory/genital/plug/sounding_rod/gold)
	TEST_ASSERT(sounding_rod.socket_item_by_type(/obj/item/roguegem/ruby, "rontz", "#B4142C", 0), "sounding rod should accept a socketed gem")
	var/colored_sounding_rod_name = sounding_rod.get_intimate_examine_colored_name()
	TEST_ASSERT(findtext(colored_sounding_rod_name, "<font color='#b4142c'>rontz-set</font>"), "sounding rod examine text should include socket descriptors")
	TEST_ASSERT(findtext(colored_sounding_rod_name, "<font color='#c4b651'>gold</font>"), "sounding rod examine text should include material descriptors")

	var/mob/living/carbon/human/consistent/human = allocate(/mob/living/carbon/human/consistent)
	human.name = "Josh Killerfang"
	human.real_name = "Josh Killerfang"
	human.gender = MALE

	var/obj/item/intimate_accessory/piercing/ear/psydonic/psydonic_earring = allocate(/obj/item/intimate_accessory/piercing/ear/psydonic)
	var/obj/item/roguegem/ruby/ear_ruby = allocate(/obj/item/roguegem/ruby)
	psydonic_earring.attackby(ear_ruby, human, null)
	TEST_ASSERT(!psydonic_earring.has_socketed_insert(), "fixed psycross earrings should reject additional socketed gems")

	var/obj/item/intimate_accessory/piercing/belly/zizite/zizite_belly = allocate(/obj/item/intimate_accessory/piercing/belly/zizite)
	var/obj/item/roguegem/ruby/belly_ruby = allocate(/obj/item/roguegem/ruby)
	zizite_belly.attackby(belly_ruby, human, null)
	TEST_ASSERT(!zizite_belly.has_socketed_insert(), "fixed zcross belly piercings should reject additional socketed gems")

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

	var/mob/living/carbon/human/consistent/cursed_piercing_human = allocate(/mob/living/carbon/human/consistent)
	cursed_piercing_human.name = "Cursed Piercing Tester"
	cursed_piercing_human.real_name = "Cursed Piercing Tester"
	cursed_piercing_human.gender = MALE
	var/obj/item/organ/penis/cursed_penis = cursed_piercing_human.getorganslot(ORGAN_SLOT_PENIS)
	if(!cursed_penis)
		cursed_penis = allocate(/obj/item/organ/penis, null)
		cursed_penis.Insert(cursed_piercing_human)
	var/obj/item/organ/testicles/cursed_testes = cursed_piercing_human.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!cursed_testes)
		cursed_testes = allocate(/obj/item/organ/testicles, null)
		cursed_testes.Insert(cursed_piercing_human)

	var/obj/item/intimate_accessory/piercing/cursed/cursed_genital_piercing = allocate(/obj/item/intimate_accessory/piercing/cursed)
	TEST_ASSERT(cursed_genital_piercing.set_current_intimate_slot(INTIMATE_SLOT_GENITAL), "test cursed piercing should take the genital slot")
	cursed_genital_piercing.finalize_intimate_equip(cursed_piercing_human)
	descriptor_lines = build_cool_description(cursed_piercing_human.get_mob_descriptors(FALSE, cursed_piercing_human), cursed_piercing_human, cursed_piercing_human)
	TEST_ASSERT(list_has_text(descriptor_lines, "pierced through with") && list_has_text(descriptor_lines, "genital piercing"), "genital cursed piercings should append inline to genital descriptor lines")

	var/obj/item/intimate_accessory/piercing/cursed/cursed_nose_piercing = allocate(/obj/item/intimate_accessory/piercing/cursed)
	TEST_ASSERT(cursed_nose_piercing.set_current_intimate_slot(INTIMATE_SLOT_NOSE), "test cursed piercing should take the nose slot")
	cursed_nose_piercing.finalize_intimate_equip(cursed_piercing_human)
	piercing_lines = cursed_piercing_human.human_modular_intimate_piercing_examine_lines(cursed_piercing_human, TRUE)
	TEST_ASSERT(list_has_text(piercing_lines, "His nose is pierced through with") && list_has_text(piercing_lines, "nose piercing"), "non-inline cursed piercings should be reported by the descriptor-adjacent piercing helper")

	var/mob/living/carbon/human/dummy/cursed_fallback_human = allocate(/mob/living/carbon/human/dummy)
	cursed_fallback_human.name = "Cursed Piercing Fallback Tester"
	cursed_fallback_human.real_name = "Cursed Piercing Fallback Tester"
	cursed_fallback_human.gender = MALE
	var/obj/item/intimate_accessory/piercing/cursed/cursed_fallback_piercing = allocate(/obj/item/intimate_accessory/piercing/cursed)
	TEST_ASSERT(cursed_fallback_piercing.set_current_intimate_slot(INTIMATE_SLOT_GENITAL), "fallback test cursed piercing should take the genital slot")
	cursed_fallback_piercing.finalize_intimate_equip(cursed_fallback_human)
	piercing_lines = cursed_fallback_human.human_modular_intimate_piercing_examine_lines(cursed_fallback_human, TRUE)
	TEST_ASSERT(list_has_text(piercing_lines, "His sex is pierced through with") && list_has_text(piercing_lines, "genital piercing"), "genital cursed piercings should get a descriptor-adjacent examine line when no inline genital descriptor is available")

/datum/unit_test/intimate_piercing_visual_overlays/proc/make_visual_test_human()
	var/mob/living/carbon/human/consistent/H = allocate(/mob/living/carbon/human/consistent)
	H.forceMove(run_loc_bottom_left)
	H.name = "Piercing Visual Tester"
	H.real_name = "Piercing Visual Tester"
	H.gender = MALE
	H.underwear = null
	return H

/datum/unit_test/intimate_piercing_visual_overlays/proc/ensure_knotted_max_penis(mob/living/carbon/human/H)
	var/obj/item/organ/penis/knotted/penis = allocate(/obj/item/organ/penis/knotted, null)
	penis.accessory_type = /datum/sprite_accessory/penis/knotted
	penis.penis_size = MAX_PENIS_SIZE
	penis.erect_state = ERECT_STATE_HARD
	penis.Insert(H)
	return penis

/datum/unit_test/intimate_piercing_visual_overlays/proc/appearance_list_has_existing_icon_state(list/appearances)
	if(!length(appearances))
		return FALSE
	for(var/mutable_appearance/appearance as anything in appearances)
		if(appearance?.icon && appearance.icon_state && icon_exists(appearance.icon, appearance.icon_state))
			return TRUE
	return FALSE

/datum/unit_test/intimate_piercing_visual_overlays/proc/assert_piercing_visual(mob/living/carbon/human/H, obj/item/intimate_accessory/piercing/piercing, slot, failure_context)
	TEST_ASSERT(piercing.set_current_intimate_slot(slot), "[failure_context] should accept the test slot")
	TEST_ASSERT(piercing.attach_intimate_feature(H), "[failure_context] should attach an intimate feature")
	piercing.finalize_intimate_equip(H)
	TEST_ASSERT_NOTNULL(piercing.intimate_feature, "[failure_context] should create a bodypart feature")

	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "[failure_context] should have a chest bodypart for intimate overlays")
	TEST_ASSERT(piercing.intimate_feature in chest.bodypart_features, "[failure_context] should add its feature to the wearer")
	var/list/appearances = piercing.intimate_feature.get_bodypart_overlay(chest)
	TEST_ASSERT(appearance_list_has_existing_icon_state(appearances), "[failure_context] should generate at least one real visible overlay icon state")

/datum/unit_test/intimate_piercing_visual_overlays/Run()
	var/mob/living/carbon/human/consistent/H = make_visual_test_human()
	var/obj/item/organ/penis/knotted/penis = ensure_knotted_max_penis(H)
	var/datum/sprite_accessory/penis/penis_accessory = SPRITE_ACCESSORY(penis.accessory_type)
	TEST_ASSERT_EQUAL(penis_accessory.get_icon_state(penis, H.get_bodypart(BODY_ZONE_CHEST), H), "knotted_2_3", "max-size knotted penises should use the available size-3 sprite state")

	assert_piercing_visual(H, allocate(/obj/item/intimate_accessory/piercing/genital/iron), INTIMATE_SLOT_GENITAL, "normal genital piercing on max-size knotted penis")
	assert_piercing_visual(H, allocate(/obj/item/intimate_accessory/piercing/nose/iron), INTIMATE_SLOT_NOSE, "normal nose piercing")
	assert_piercing_visual(H, allocate(/obj/item/intimate_accessory/piercing/belly/iron), INTIMATE_SLOT_BELLY, "normal belly piercing")

	var/obj/item/intimate_accessory/piercing/cursed/cursed_genital = allocate(/obj/item/intimate_accessory/piercing/cursed)
	assert_piercing_visual(H, cursed_genital, INTIMATE_SLOT_GENITAL, "cursed genital piercing")
	var/obj/item/intimate_accessory/piercing/cursed/cursed_nose = allocate(/obj/item/intimate_accessory/piercing/cursed)
	assert_piercing_visual(H, cursed_nose, INTIMATE_SLOT_NOSE, "cursed nose piercing")
	var/obj/item/intimate_accessory/piercing/cursed/cursed_belly = allocate(/obj/item/intimate_accessory/piercing/cursed)
	assert_piercing_visual(H, cursed_belly, INTIMATE_SLOT_BELLY, "cursed belly piercing")

/datum/unit_test/rear_insertable_stomach_brute_eject/Run()
	var/mob/living/carbon/human/consistent/wearer = allocate(/mob/living/carbon/human/consistent)
	wearer.forceMove(run_loc_bottom_left)
	var/obj/item/intimate_accessory/rear/plug/analbeads/copper/beads = allocate(/obj/item/intimate_accessory/rear/plug/analbeads/copper)
	beads.finalize_intimate_equip(wearer)
	beads.beads_inserted = 3

	TEST_ASSERT_EQUAL(wearer.intimate_rear_insertable, beads, "rear beads should start in the rear insertable slot")
	TEST_ASSERT(wearer.try_eject_rear_insertable_from_stomach_hit(BRUTE, BODY_ZONE_PRECISE_STOMACH, 100, 0), "stomach brute hit should eject worn rear insertables when normal chance succeeds")
	TEST_ASSERT_NULL(wearer.intimate_rear_insertable, "stomach brute ejection should clear the rear insertable slot")
	TEST_ASSERT(!(beads in wearer.intimate_accessories), "stomach brute ejection should remove the rear insertable from worn accessory tracking")
	TEST_ASSERT_EQUAL(beads.loc, get_turf(wearer), "ejected rear insertable should land on the wearer's turf")
	TEST_ASSERT_EQUAL(beads.beads_inserted, 0, "ejected beads should reset their inserted count")

	var/obj/item/intimate_accessory/rear/plug/iron/plug = allocate(/obj/item/intimate_accessory/rear/plug/iron)
	plug.finalize_intimate_equip(wearer)
	TEST_ASSERT(!wearer.try_eject_rear_insertable_from_stomach_hit(BURN, BODY_ZONE_PRECISE_STOMACH, 100, 100), "non-brute stomach damage should not eject rear insertables")
	TEST_ASSERT_EQUAL(wearer.intimate_rear_insertable, plug, "non-brute stomach damage should leave rear insertables equipped")
	TEST_ASSERT(!wearer.try_eject_rear_insertable_from_stomach_hit(BRUTE, BODY_ZONE_CHEST, 100, 100), "generic chest brute damage should not eject rear insertables")
	TEST_ASSERT_EQUAL(wearer.intimate_rear_insertable, plug, "generic chest brute damage should leave rear insertables equipped")

	TEST_ASSERT(wearer.try_eject_rear_insertable_from_stomach_hit(BRUTE, BODY_ZONE_PRECISE_STOMACH, 0, 100), "stomach brute hit should violently eject worn rear insertables when violent chance succeeds")
	TEST_ASSERT_NULL(wearer.intimate_rear_insertable, "violent stomach brute ejection should clear the rear insertable slot")
	TEST_ASSERT(plug.violent_rear_ejection_active, "violently ejected rear plugs should keep temporary projectile stats until impact")
	TEST_ASSERT_EQUAL(plug.throwforce, 30, "violently ejected rear plugs should hit with iron sling bullet damage")
	TEST_ASSERT_EQUAL(plug.armor_penetration, 30, "violently ejected rear plugs should use iron sling bullet armor penetration")
	TEST_ASSERT_EQUAL(plug.throw_range, 15, "violently ejected rear plugs should fly as far as sling bullets")
	plug.restore_violent_rear_ejection_throw_stats()

	var/mob/living/carbon/human/consistent/victim = allocate(/mob/living/carbon/human/consistent)
	victim.forceMove(run_loc_bottom_left)
	var/obj/item/intimate_accessory/rear/plug/analbeads/copper/bola_beads = allocate(/obj/item/intimate_accessory/rear/plug/analbeads/copper, get_turf(victim))
	bola_beads.prepare_violent_rear_ejection_throw()
	bola_beads.ensnare_violent_rear_ejection(victim)
	TEST_ASSERT_EQUAL(victim.legcuffed, bola_beads, "violently ejected rear beads should ensnare legs like a bola")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/debuff/netted), "violently ejected rear beads should apply netted slowdown")
