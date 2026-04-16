/datum/advclass/wretch/blooddrunk
	name = "Blood Drunk Hunter"
	tutorial = "You were once part of a hunting order - or perhaps you simply found a trick weapon and let the blood guide your hand. \
	Either way, the old blood sings in your veins, and you fight with a ferocity that terrifies even the garrison."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/wretch/blooddrunk
	cmode_music = 'sound/music/combat_blooddrunk1.ogg'
	class_select_category = CLASS_CAT_WARRIOR
	category_tags = list(CTAG_WRETCH)
	traits_applied = list(TRAIT_DODGEEXPERT, TRAIT_BEAST_DRUNK, TRAIT_CRITICAL_RESISTANCE)
	maximum_possible_slots = 2 // These guys are strong, don't want them to be too common.
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_CON = 2,
		STATKEY_SPD = 3, // NYOOOM
		STATKEY_WIL = 2,
		STATKEY_LCK = -2, // Fortunate people don't end up blood drunk.
	)
	subclass_skills = list(
		/datum/skill/misc/swimming = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/wrestling = SKILL_LEVEL_MASTER,
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/climbing = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/medicine = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/reading = SKILL_LEVEL_EXPERT, // 99 insight, GRANT US EYES
		/datum/skill/labor/butchering = SKILL_LEVEL_EXPERT,
	)

/datum/outfit/job/roguetown/wretch/blooddrunk/pre_equip(mob/living/carbon/human/H)
	..()
	var/datum/action/sense = new /datum/action/cooldown/beast_sense(H)
	sense.Grant(H)
	var/datum/action/frenzy = new /datum/action/cooldown/blood_drunk_frenzy(H)
	frenzy.Grant(H)
	H.apply_status_effect(/datum/status_effect/beast_drunk)
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
	shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
	armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/jacket
	neck = /obj/item/clothing/neck/roguetown/chaincoif
	mask = /obj/item/clothing/mask/rogue/hunter_mask
	belt = /obj/item/storage/belt/rogue/leather
	gloves = /obj/item/clothing/gloves/roguetown/hunter_gloves
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather/reinforced
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather/heavy
	backl = /obj/item/storage/backpack/rogue/satchel
	backpack_contents = list(
		/obj/item/storage/belt/rogue/pouch/coins/poor = 1,
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpot = 1, // bloodvial or something
		)
	if(H.mind)
		var/classes = list("Old Hunter", "Church Hunter", "Hawthorne Malumite", "Blastpowder Keg", "Eccentric")
		var/classchoice = input(H, "Choose your hunting order.", "THE HUNT BEGINS") as anything in classes
		H.set_blindness(0)
		switch(classchoice)
			if("Old Hunter")
				old_hunter_equip(H)
			if("Church Hunter")
				church_hunter_equip(H)
			if("Hawthorne Malumite")
				malumite_equip(H)
			if("Blastpowder Keg")
				keg_equip(H)
			if("Eccentric")
				eccentric_equip(H)
		if(H.age == AGE_OLD) // Gerhman joins the hunt
			H.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/maces, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/axes, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/polearms, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/whipsflails, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/knives, 1, TRUE)
			H.adjust_skillrank(/datum/skill/combat/unarmed, 1, TRUE)
			H.change_stat(STATKEY_LCK, 2) // maybe you aren't so unlucky if you live long enough while being blood drunk. Nuked by -3 when frenzied. 
			H.change_stat(STATKEY_INT, 2) // Eyes on the inside, still gets nuked by frenzy -3 int so not busted when it matters.
			H.change_stat(STATKEY_SPD, 1) // Don't wanna handicap the old hunter's too too much. They'd get skill gapped otherwise because dodge builds kinda suck

/datum/outfit/job/roguetown/wretch/blooddrunk/proc/old_hunter_equip(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_NASTY_EATER, TRAIT_GENERIC)
	var/weapons = list("Beast Cutter", "Saw Cleaver", "Saw Spear", "Hunter Axe", "Burial Blade", "Hunter's Saif")
	var/weapon_choice = input(H, "Choose your serrated weapon.", "WHAT'S THAT SMELL?") as anything in weapons
	switch(weapon_choice)
		if("Beast Cutter")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/whipsflails, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/beastcutter
		if("Saw Cleaver")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/sawcleaver
		if("Saw Spear")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/sawspear
		if("Hunter Axe")
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/hunteraxe
		if("Burial Blade")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/burialblade
		if("Hunter's Saif")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/huntersaif
	armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_old
	head = /obj/item/clothing/head/roguetown/helmet/leather/hunter_old_hat
	cloak = /obj/item/clothing/cloak/thief_cloak
	wretch_select_bounty(H)

/datum/outfit/job/roguetown/wretch/blooddrunk/proc/church_hunter_equip(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_SILVER_BLESSED, TRAIT_GENERIC)
	var/weapons = list("Penitent's Wheel", "Psydonic Hammer", "Pontifex Greatsword", "Church Pick", "Bloodletter")
	var/weapon_choice = input(H, "Choose your blessed weapon.", "BEASTS ALL OVER THE SHOP") as anything in weapons
	switch(weapon_choice)
		if("Penitent's Wheel")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/logariuswheel
		if("Psydonic Hammer")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/kirkhammer
		if("Pontifex Greatsword")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/ludwigblade
		if("Church Pick")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/churchpick
		if("Bloodletter")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/bloodletter
	armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_orthodox
	head = /obj/item/clothing/head/roguetown/helmet/gold_ardeo
	neck = /obj/item/clothing/neck/roguetown/hunter_orthodox_mantle
	cloak = /obj/item/clothing/cloak/cape/puritan
	wretch_select_bounty(H)

/datum/outfit/job/roguetown/wretch/blooddrunk/proc/malumite_equip(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_DUALWIELDER, TRAIT_GENERIC)
	var/weapons = list("Chikage", "Threaded Cane", "Rakuyo", "Reiterpallasch", "Blades of Mercy", "Ranger's Bowblade")
	var/weapon_choice = input(H, "Choose your weapon.", "Hawthrone's Finest") as anything in weapons
	switch(weapon_choice)
		if("Chikage")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/chikage
		if("Threaded Cane")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/whipsflails, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/threadedcane
		if("Rakuyo")
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/rakuyo
		if("Reiterpallasch")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/reiterpallasch
		if("Blades of Mercy")
			H.adjust_skillrank_up_to(/datum/skill/combat/knives, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/bladesofmercy
		if("Ranger's Bowblade")
			H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/bows, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/simonsbowblade
	armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_standard
	head = /obj/item/clothing/head/roguetown/helmet/leather/hunter_standard_hat
	neck = /obj/item/clothing/neck/roguetown/hunter_standard_mantle
	cloak = /obj/item/clothing/cloak/half
	wretch_select_bounty(H)

/datum/outfit/job/roguetown/wretch/blooddrunk/proc/keg_equip(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_EXTREME_TEMPERATURE_IMMUNE, TRAIT_GENERIC)
	var/weapons = list("Boom Hammer", "Stake Driver", "Rifle Spear", "Whirligig Saw", "Tonitrus")
	var/weapon_choice = input(H, "Choose your weapon.", "If a weapon ain't got kick...") as anything in weapons
	switch(weapon_choice)
		if("Boom Hammer")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/boomhammer
		if("Stake Driver")
			H.adjust_skillrank_up_to(/datum/skill/combat/unarmed, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/stakedriver
		if("Rifle Spear")
			H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/riflespear
			beltr = /obj/item/quiver/bullet/grapeshot
		if("Whirligig Saw")
			H.adjust_skillrank_up_to(/datum/skill/combat/axes, SKILL_LEVEL_EXPERT, TRUE)
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/whirligigsaw
		if("Tonitrus") // technically not a keg weapon but uhh ummm uhhh ummm 
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/tonitrus
	armor = /obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_old
	head = /obj/item/clothing/head/roguetown/helmet/leather/hunter_orthodox_hat
	cloak = /obj/item/clothing/cloak/raincloak/mortus
	wretch_select_bounty(H)

/datum/outfit/job/roguetown/wretch/blooddrunk/proc/eccentric_equip(mob/living/carbon/human/H)
	ADD_TRAIT(H, TRAIT_STRONGBITE, TRAIT_GENERIC)
	var/weapons = list("Abyssoid Parasite", "Feral Claw", "Dreamfiend Arm")
	var/weapon_choice = input(H, "Choose your weapon.", "GRANT US EYES...") as anything in weapons
	switch(weapon_choice)
		if("Abyssoid Parasite")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/kosparasite
		if("Feral Claw")
			H.adjust_skillrank_up_to(/datum/skill/combat/unarmed, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/beastclaws
		if("Dreamfiend Arm")
			H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_EXPERT, TRUE)
			r_hand = /obj/item/rogueweapon/trickweapon/amygdalanarm
	head = /obj/item/clothing/head/roguetown/helmet/leather/brador_helm
	cloak = /obj/item/clothing/cloak/hunter/brador_cape
	mask = null // Brador helm covers the face
	wretch_select_bounty(H)
