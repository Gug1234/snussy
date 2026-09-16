/datum/advclass/wretch/entombed/// Thespian wretch with a twist. Super heavy armor that never breaks BUT has bronze protection so it can be stabbed through. Can't be removed.
	name = "Patinated Entombed"
	tutorial = "Ageless, undying warrior, armor caked in a tarnished sheen, speckled with long-ago viscera. \
	It will not break; it will not come off. Parts of your skin have fused to the once shimmering panoply. \
	Your blood has been in the boots far more times than you can count; it's your skin, and you will die in it. \
	O' entombed juggernaut, take root in your bronzed warcasket and, perched within, RISE!"
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_NO_ANNOYING
	allowed_ages = list(AGE_MIDDLEAGED, AGE_OLD)
	class_select_category = CLASS_CAT_ACCURSED
	outfit = /datum/outfit/job/roguetown/wretch/entombed
	cmode_music = 'sound/music/combat_thespian.ogg'
	category_tags = list(CTAG_WRETCH)
	traits_applied = list(
	TRAIT_HEAVYARMOR,
	TRAIT_DNR,
	TRAIT_NORUN,
	TRAIT_CRITICAL_RESISTANCE,
	TRAIT_BLOOD_RESISTANCE,//pre nerf crit resistance basically, whole gimmick is you have to bleed them out, drown them, burn them, etc.
	TRAIT_NOPAIN,//POWERED BY PURE HELLENIC φεντ
	TRAIT_HARDDISMEMBER,//cutting off the head of the ancient warcasket dreadnaught should be hard
	TRAIT_NOSLEEP,
	TRAIT_NOHUNGER//helmets dont open, so we cant eat or... but we also cant drink (i.e. no potions)
	)
	subclass_stats = list(
		STATKEY_CON = 5,//grudgebearer soldier statline on bronze age bathsalts
		STATKEY_WIL = 5,
		STATKEY_STR = 5,
		STATKEY_SPD = -6//slowest, fattest fucks
	)
	subclass_skills = list(
		/datum/skill/combat/shields = SKILL_LEVEL_MASTER,//hilarious
		/datum/skill/combat/wrestling = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/swimming = SKILL_LEVEL_EXPERT,//water destroys these guys, least we can do is give them some deniability to being dragged through it
		/datum/skill/combat/unarmed = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/climbing = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/reading = SKILL_LEVEL_EXPERT,//been around a while
	)
	maximum_possible_slots = 1//john indestructible armor doesn't need more than one

	extra_context = "This subclass is age-limited to middle aged and old. Middle-aged gives expert \
	in the chosen weapon skill while old gets master."

/datum/outfit/job/roguetown/wretch/entombed/pre_equip(mob/living/carbon/human/H, visualsOnly)
	..()

