/datum/advclass/gnollhunter
	name = "Gnoll Hunter"
	tutorial = "You are a trick weapon specialist - trained in the use of serrated and blastpowder-driven arms to hunt beasts and gnolls alike. \
	Your weapons are unconventional, but devastatingly effective in practiced hands."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/adventurer/gnollhunter
	cmode_music = 'sound/music/cmode/adventurer/combat_outlander2.ogg'
	subclass_social_rank = SOCIAL_RANK_PEASANT
	traits_applied = list(TRAIT_DODGEEXPERT)
	class_select_category = CLASS_CAT_WARRIOR
	category_tags = list(CTAG_ADVENTURER)
	maximum_possible_slots = 8 // Don't want gnoll valid hunters to be too common. 
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_CON = 2,
		STATKEY_SPD = 1,
		STATKEY_WIL = 1,
	)
	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/maces = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/axes = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/polearms = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/whipsflails = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/unarmed = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/swimming = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/athletics = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_NOVICE,
	)

/datum/outfit/job/roguetown/adventurer/gnollhunter/pre_equip(mob/living/carbon/human/H)
	..()
	H.dna.species.soundpack_m = new /datum/voicepack/male/warrior()
	H.set_blindness(0)
	var/datum/action/sense = new /datum/action/cooldown/beast_sense(H)
	sense.Grant(H)
	if(H.mind)
		var/weapons = list("Saw Cleaver", "Saw Spear", "Beast Cutter", "Whirligig Saw", "Hunter Axe", "Hunter's Saif", "Burial Blade", "Boom Hammer", "Stake Driver", "Rifle Spear")
		var/weapon_choice = input(H, "Choose your trick weapon.", "ARM YOURSELF") as anything in weapons
		switch(weapon_choice)
			// --- Serrated Weapons ---
			if("Saw Cleaver")
				H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/sawcleaver(H), TRUE)
			if("Saw Spear")
				H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/sawspear(H), TRUE)
			if("Beast Cutter")
				H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/whipsflails, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/beastcutter(H), TRUE)
			if("Whirligig Saw")
				H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/whirligigsaw(H), TRUE)
			if("Hunter Axe")
				H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/hunteraxe(H), TRUE)
			if("Hunter's Saif")
				H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/huntersaif(H), TRUE)
			if("Burial Blade")
				H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/burialblade(H), TRUE)
			// --- Blastpowder Keg Weapons ---
			if("Boom Hammer")
				H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/boomhammer(H), TRUE)
			if("Stake Driver")
				H.adjust_skillrank_up_to(/datum/skill/combat/unarmed, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/stakedriver(H), TRUE)
			if("Rifle Spear")
				H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_JOURNEYMAN, TRUE)
				H.put_in_hands(new /obj/item/rogueweapon/trickweapon/riflespear(H), TRUE)
				beltr = /obj/item/quiver/bullet/grapeshot
		// "I don't seem to be apt for this life anymore... My glory days were long ago now..."
		if(H.age == AGE_OLD)
			H.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/maces, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/axes, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/polearms, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/whipsflails, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/unarmed, 1, TRUE)
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
				head = /obj/item/clothing/head/roguetown/helmet/leather/gold_ardeo
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
