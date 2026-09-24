/datum/advclass/wretch/emancipator
	name = "Crocs de l'araignée Émancipatrice"
	desc = "Once a decorated veteran, enviable among drow, they now only call you \"Émancipatrice\", emancipator in imperial. \
	A drow without enemies is a rare thing indeed... rarer still is a drow thats been made an enemy of the societal whole... \
	Such is the lot of the Emancipator: the freer of slaves. Praised as righteous by some, emancipation is regarded as an existential threat by the undercities, \
	whose farms, mines, foundries, and estates depend upon vast labor forces kept in bondage. History has given them reason enough to fear disruption. \
	Outbreaks of black-rot among slave populations have crippled harvests and left entire metropolises to starve in the dark. Regardless of the reason, your actions have marked you \
	for death, be it at the hands of your former comrades-in-arms, surface slavers, merchants, or even the underdark slaves you \
	sought to free... Give them no quarter, for they offer none to you."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = list(
		/datum/species/elf/dark,
		/datum/species/human/halfelf, // Because half-drows are half-elves, guh.
	)
	outfit = /datum/outfit/job/roguetown/wretch/emancipator
	class_select_category = CLASS_CAT_RACIAL
	category_tags = list(CTAG_WRETCH)
	class_select_category = CLASS_CAT_RACIAL
	traits_applied = list(TRAIT_DARKVISION, TRAIT_EQUESTRIAN, TRAIT_SPIDERBORN)
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_CON = 2,
		STATKEY_WIL = 2,
		STATKEY_PER = 1,
	)

	subclass_skills = list(
		/datum/skill/combat/bows = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/knives = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/unarmed = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/swimming = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT, 
		/datum/skill/misc/climbing = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/reading = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/riding = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/sneaking = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/craft/alchemy = SKILL_LEVEL_NOVICE,
		/datum/skill/craft/crafting = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/swords = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/whipsflails = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/shields = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/wrestling = SKILL_LEVEL_EXPERT,
		/datum/skill/craft/sewing = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/medicine = SKILL_LEVEL_APPRENTICE,
		/datum/skill/craft/tanning = SKILL_LEVEL_APPRENTICE,
		/datum/skill/craft/crafting = SKILL_LEVEL_APPRENTICE,
		/datum/skill/magic/holy = SKILL_LEVEL_EXPERT,
	)
