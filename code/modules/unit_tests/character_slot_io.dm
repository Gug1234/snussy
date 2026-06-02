/datum/preferences/unit_test_character_slot_io/New(client/C)
	return

/datum/unit_test/character_slot_io_exports_current_savefile_version/Run()
	var/test_path = "tmp/character_slot_io_version_[world.time]_[rand(1, 999999)].sav"
	if(fexists(test_path))
		fdel(test_path)

	var/datum/preferences/prefs = new /datum/preferences/unit_test_character_slot_io(null)
	prefs.path = test_path
	prefs.default_slot = 1

	var/savefile/S = new /savefile(test_path)
	S.cd = "/character1"
	WRITE_FILE(S["version"], SAVEFILE_VERSION_MAX)
	WRITE_FILE(S["real_name"], "Version Test")
	S = null

	var/payload = prefs.export_character_slot_json(1)
	var/list/envelope
	if(istext(payload))
		envelope = json_decode(payload)

	if(fexists(test_path))
		fdel(test_path)
	qdel(prefs)

	TEST_ASSERT(istext(payload), "expected character slot export payload")
	TEST_ASSERT(islist(envelope), "character slot export payload must be JSON envelope")
	TEST_ASSERT_EQUAL(envelope["savefile_version"], SAVEFILE_VERSION_MAX, "character slot exports must use canonical savefile version")
