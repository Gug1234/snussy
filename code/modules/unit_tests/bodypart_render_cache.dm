/datum/unit_test/proc/_bodypart_render_cache_test_spawn_human()
	var/list/locs = block(run_loc_bottom_left, run_loc_top_right)
	return allocate(/mob/living/carbon/human/consistent, pick(locs))

/datum/unit_test/proc/_bodypart_render_cache_test_get_head_feature(obj/item/bodypart/head/head)
	for(var/datum/bodypart_feature/hair/head/existing_feature as anything in head.bodypart_features)
		return existing_feature

	var/datum/bodypart_feature/hair/head/fallback_feature = new
	fallback_feature.accessory_type = /datum/sprite_accessory/hair/head/adventurer
	fallback_feature.accessory_colors = "#FFFFFF"
	return fallback_feature

/datum/unit_test/bodypart_limb_state_key/Run()
	var/mob/living/carbon/human/consistent/character = _bodypart_render_cache_test_spawn_human()
	TEST_ASSERT_NOTNULL(character, "test character should allocate")

	var/obj/item/bodypart/head/head = character.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_NOTNULL(head, "test character should have a head bodypart")

	head.update_limb(FALSE, character)
	head.get_limb_icon(FALSE)
	var/first_key = head.limb_state_key
	TEST_ASSERT_NOTNULL(first_key, "update_limb should build the cached limb state key")
	TEST_ASSERT_NOTNULL(head.cached_base_appearances, "base limb appearances should be cached after a render")

	head.update_limb(FALSE, character)
	TEST_ASSERT_EQUAL(head.limb_state_key, first_key, "unchanged update_limb should preserve the cached limb state key")
	TEST_ASSERT_NOTNULL(head.cached_base_appearances, "unchanged update_limb should preserve the base limb cache")

	character.gender = (character.gender == MALE) ? FEMALE : MALE
	head.update_limb(FALSE, character)
	var/gender_key = head.limb_state_key
	TEST_ASSERT_NOTEQUAL(gender_key, first_key, "owner appearance changes should rebuild the limb state key")

	head.get_limb_icon(FALSE)
	TEST_ASSERT_NOTNULL(head.cached_base_appearances, "cache should repopulate after rerendering")
	head.status = BODYPART_ROBOTIC
	head.update_limb(FALSE, character)
	TEST_ASSERT_NULL(head.cached_base_appearances, "render-state changes should invalidate the cached base appearances")

/datum/unit_test/bodypart_supplemental_overlay_cache_copies/Run()
	var/mob/living/carbon/human/consistent/character = _bodypart_render_cache_test_spawn_human()
	TEST_ASSERT_NOTNULL(character, "test character should allocate")

	var/obj/item/bodypart/head/head = character.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_NOTNULL(head, "test character should have a head bodypart")

	var/obj/item/organ/eyes/eyes = character.getorganslot(ORGAN_SLOT_EYES)
	TEST_ASSERT_NOTNULL(eyes, "test character should have eyes")

	var/list/first_organ_overlays = eyes.get_bodypart_overlay(head)
	TEST_ASSERT_NOTNULL(first_organ_overlays, "eyes should generate visible bodypart overlays")
	var/first_organ_len = length(first_organ_overlays)
	first_organ_overlays += "sentinel"
	var/list/second_organ_overlays = eyes.get_bodypart_overlay(head)
	TEST_ASSERT_EQUAL(length(second_organ_overlays), first_organ_len, "organ overlay cache should return a safe list copy")
	TEST_ASSERT(!("sentinel" in second_organ_overlays), "mutating a prior organ overlay list must not poison the cache")
	TEST_ASSERT_NOTNULL(eyes.bodypart_overlay_cache_key, "organ overlay generation should populate the cache key")

	var/datum/bodypart_feature/hair/head/feature = _bodypart_render_cache_test_get_head_feature(head)
	TEST_ASSERT_NOTNULL(feature, "test head should expose or synthesize a hair feature")

	var/list/first_feature_overlays = feature.get_bodypart_overlay(head)
	TEST_ASSERT_NOTNULL(first_feature_overlays, "feature should generate bodypart overlays")
	var/first_feature_len = length(first_feature_overlays)
	first_feature_overlays += "sentinel"
	var/list/second_feature_overlays = feature.get_bodypart_overlay(head)
	TEST_ASSERT_EQUAL(length(second_feature_overlays), first_feature_len, "feature overlay cache should return a safe list copy")
	TEST_ASSERT(!("sentinel" in second_feature_overlays), "mutating a prior feature overlay list must not poison the cache")
	TEST_ASSERT_NOTNULL(feature.bodypart_overlay_cache_key, "feature overlay generation should populate the cache key")

/datum/unit_test/bodypart_taur_render_cache/Run()
	var/obj/item/bodypart/taur/canine/taur = allocate(/obj/item/bodypart/taur/canine)
	TEST_ASSERT_NOTNULL(taur, "taur bodypart should allocate")

	var/list/first_icons = taur.get_cached_taur_icon_triplet(0, FALSE)
	var/list/second_icons = taur.get_cached_taur_icon_triplet(0, FALSE)
	TEST_ASSERT_EQUAL(first_icons, second_icons, "identical taur render state should hit the shared icon cache")

	taur.taur_color = "#123456"
	var/list/third_icons = taur.get_cached_taur_icon_triplet(0, FALSE)
	TEST_ASSERT_NOTEQUAL(first_icons, third_icons, "taur color changes should miss the shared icon cache")

	var/list/dropped_icons = taur.get_cached_taur_icon_triplet(SOUTH, TRUE)
	TEST_ASSERT_NOTEQUAL(third_icons, dropped_icons, "dropped taur renders should use a distinct cache bucket")

/datum/unit_test/bodypart_taur_ref_self_heals/Run()
	var/mob/living/carbon/human/consistent/character = _bodypart_render_cache_test_spawn_human()
	TEST_ASSERT_NOTNULL(character, "test character should allocate")

	var/obj/item/bodypart/taur/canine/taur = allocate(/obj/item/bodypart/taur/canine)
	TEST_ASSERT_NOTNULL(taur, "taur bodypart should allocate")
	TEST_ASSERT(taur.attach_limb(character, TRUE), "taur bodypart should attach to the character")

	TEST_ASSERT_EQUAL(character.get_taur_tail(), taur, "attached taur bodypart should be returned directly")
	character.taur_bodypart = null
	TEST_ASSERT_EQUAL(character.get_taur_tail(), taur, "fallback scan should recover a missing taur ref")
	TEST_ASSERT_EQUAL(character.taur_bodypart, taur, "fallback scan should repair the cached taur ref")
