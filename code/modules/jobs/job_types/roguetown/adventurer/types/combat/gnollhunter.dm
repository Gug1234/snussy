/datum/advclass/gnollhunter
	name = "Gnoll Hunter"
	tutorial = "You are a trick weapon specialist - trained in the use of serrated and blastpowder-driven arms to hunt beasts and gnolls alike. \
	Your weapons are unconventional, but devastatingly effective in practiced hands."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/adventurer/gnollhunter
	cmode_music = 'sound/music/combat_gnollhunter.ogg'
	subclass_social_rank = SOCIAL_RANK_PEASANT
	traits_applied = list(TRAIT_DODGEEXPERT)
	class_select_category = CLASS_CAT_WARRIOR
	category_tags = list(CTAG_ADVENTURER)
	maximum_possible_slots = 6 // Don't want gnoll valid hunters to be too common. 
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_CON = 1,
		STATKEY_SPD = 2,
		STATKEY_WIL = 2,
	)
	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/maces = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/axes = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/polearms = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/whipsflails = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/unarmed = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_EXPERT, // so they dont get grapple fucked by john gnoll
		/datum/skill/misc/swimming = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_EXPERT, // GRANT US EYES
	)

/datum/outfit/job/roguetown/adventurer/gnollhunter/pre_equip(mob/living/carbon/human/H)
	..()
	H.dna.species.soundpack_m = new /datum/voicepack/male/warrior()
	H.set_blindness(0)
	var/datum/action/sense = new /datum/action/cooldown/beast_sense(H)
	sense.Grant(H)
	if(H.mind)
		var/is_devotee = (H.client?.prefs?.virtue?.type == /datum/virtue/combat/devotee) || (H.client?.prefs?.virtuetwo?.type == /datum/virtue/combat/devotee)
		if(is_devotee)
			church_hunter_equip(H)
		else
			standard_hunter_equip(H)
		// "I don't seem to be apt for this life anymore... My glory days were long ago now..."
		if(H.age == AGE_OLD)
			H.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/maces, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/axes, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/polearms, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/whipsflails, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/unarmed, 1, TRUE)
			H.change_stat(STATKEY_INT, 1)
			H.change_stat(STATKEY_SPD, 1)
		var/armors = list("Hunter Set", "Orthodox Hunter Set", "Old Hunter Set", "Skinned Beast Set", "Executioner's Set")
		var/armor_choice = input(H, "Choose your armor.", "TAKE UP ARMOR") as anything in armors
		switch(armor_choice)
			if("Hunter Set")
				armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_standard
				shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
				pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
				head = /obj/item/clothing/head/roguetown/helmet/leather/hunter_standard_hat
				neck = /obj/item/clothing/neck/roguetown/hunter_standard_mantle
				gloves = /obj/item/clothing/gloves/roguetown/hunter_gloves
				wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
				mask = /obj/item/clothing/mask/rogue/hunter_mask
			if("Orthodox Hunter Set")
				armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_orthodox
				shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
				pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
				head = /obj/item/clothing/head/roguetown/helmet/leather/hunter_orthodox_hat
				neck = /obj/item/clothing/neck/roguetown/hunter_orthodox_mantle
				gloves = /obj/item/clothing/gloves/roguetown/hunter_gloves
				wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
				mask = /obj/item/clothing/mask/rogue/hunter_mask
			if("Old Hunter Set")
				armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_old
				shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
				pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
				head = /obj/item/clothing/head/roguetown/helmet/leather/hunter_old_hat
				neck = /obj/item/clothing/neck/roguetown/chaincoif
				gloves = /obj/item/clothing/gloves/roguetown/hunter_gloves
				wrists = /obj/item/clothing/wrists/roguetown/bracers/leather/heavy
				mask = /obj/item/clothing/mask/rogue/hunter_mask
			if("Skinned Beast Set")
				armor = /obj/item/clothing/suit/roguetown/armor/gambeson
				shirt = /obj/item/clothing/suit/roguetown/shirt/tunic/random
				pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
				head = /obj/item/clothing/head/roguetown/helmet/leather/brador_helm
				cloak = /obj/item/clothing/cloak/hunter/brador_cape
				neck = /obj/item/clothing/neck/roguetown/chaincoif
				gloves = /obj/item/clothing/gloves/roguetown/hunter_gloves
				wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
			if("Executioner's Set")
				armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_orthodox
				shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
				pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
				head = /obj/item/clothing/head/roguetown/helmet/gold_ardeo
				neck = /obj/item/clothing/neck/roguetown/hunter_orthodox_mantle
				gloves = /obj/item/clothing/gloves/roguetown/hunter_gloves
				wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
	belt = /obj/item/storage/belt/rogue/leather
	backl = /obj/item/storage/backpack/rogue/satchel
	beltl = /obj/item/storage/belt/rogue/pouch/coins/poor
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather/reinforced
	backpack_contents = list(
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpot = 1,
		)

/datum/outfit/job/roguetown/adventurer/gnollhunter/proc/standard_hunter_equip(mob/living/carbon/human/H)
	var/weapons = list("Saw Cleaver", "Saw Spear", "Beast Cutter", "Whirligig Saw", "Hunter Axe", "Hunter's Saif", "Burial Blade", "Boom Hammer", "Stake Driver", "Rifle Spear")
	var/weapon_choice = input(H, "Choose your trick weapon.", "A hunter must hunt.") as anything in weapons
	switch(weapon_choice)
		// --- Serrated Weapons ---
		if("Saw Cleaver")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/sawcleaver
		if("Saw Spear")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/sawspear
		if("Beast Cutter")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/whipsflails, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/beastcutter
		if("Whirligig Saw")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/whirligigsaw
		if("Hunter Axe")
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/hunteraxe
		if("Hunter's Saif")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/huntersaif
		if("Burial Blade")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/burialblade
		// --- Blastpowder Keg Weapons ---
		if("Boom Hammer")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/boomhammer
		if("Stake Driver")
			H.adjust_skillrank_up_to(/datum/skill/combat/unarmed, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/stakedriver
		if("Rifle Spear")
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/riflespear
			beltr = /obj/item/quiver/bullet/grapeshot

/datum/outfit/job/roguetown/adventurer/gnollhunter/proc/church_hunter_equip(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_SILVER_BLESSED, TRAIT_GENERIC)
	var/weapons = list("Penitent's Wheel", "Psydonic Hammer", "Pontifex Greatsword", "Church Pick")
	var/weapon_choice = input(H, "Choose your blessed weapon.", "Ahh... you where there all along...") as anything in weapons
	switch(weapon_choice)
		if("Penitent's Wheel")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/logariuswheel
		if("Psydonic Hammer")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/kirkhammer
		if("Pontifex Greatsword")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/ludwigblade
		if("Church Pick")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/churchpick

/datum/advclass/gnollhunter/post_equip(mob/living/carbon/human/H)
	..()
	if(H.age == AGE_OLD)
		H.cmode_music = 'sound/music/combat_oldhunter.ogg'
	else if((H.client?.prefs?.virtue?.type == /datum/virtue/combat/devotee) || (H.client?.prefs?.virtuetwo?.type == /datum/virtue/combat/devotee))
		H.cmode_music = 'sound/music/combat_churchhunter.ogg'
