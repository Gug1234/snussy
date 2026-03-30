// ====================================================================
// TRICK WEAPON ARTIFICER RECIPES
// ====================================================================
// Organized by faction. All trick weapons are Artificer's Guild creations,
// requiring Engineering skill and crafted at an artificer's workbench.
// Faction determines the primary ingot used in crafting.
// ====================================================================

/datum/artificer_recipe/trickweapon
	i_type = "Trick Weapons"

// ===================== STEEL TIER (ARTIFICER'S GUILD) =====================
// Standard trick weapons engineered from steel and iron. These are the
// workhorses of the Artificer's Guild — mechanical marvels designed for
// hunting deadites and werewolves alike.

/// Saw Cleaver — the quintessential hunter's tool
/datum/artificer_recipe/trickweapon/sawcleaver
	name = "Saw Cleaver (+1 Iron, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/sawcleaver
	hammers_per_item = 10
	skill_level = 2

/// Saw Spear — polearm variant of the saw weapon line
/datum/artificer_recipe/trickweapon/sawspear
	name = "Saw Spear (+1 Iron, +1 Small Log, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/grown/log/tree/small, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/sawspear
	hammers_per_item = 10
	skill_level = 2

/// Hunter Axe — compact axe that extends into a greataxe
/datum/artificer_recipe/trickweapon/hunteraxe
	name = "Hunter Axe (+1 Iron, +1 Stick)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/grown/log/tree/stick)
	created_item = /obj/item/rogueweapon/trickweapon/hunteraxe
	hammers_per_item = 10
	skill_level = 2

/// Hunter's Saif — compact curved blade with lunge mechanics
/datum/artificer_recipe/trickweapon/huntersaif
	name = "Hunter's Saif (+1 Iron, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/huntersaif
	hammers_per_item = 10
	skill_level = 2

/// Beast Cutter — heavy cleaver that extends into a chain-whip
/datum/artificer_recipe/trickweapon/beastcutter
	name = "Beast Cutter (+2 Iron, +1 Chain)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/ingot/iron, /obj/item/rope/chain)
	created_item = /obj/item/rogueweapon/trickweapon/beastcutter
	hammers_per_item = 14
	skill_level = 3

/// Stake Driver — gauntlet with pile bunker mechanism
/datum/artificer_recipe/trickweapon/stakedriver
	name = "Stake Driver (+1 Steel, +1 Chain, +2 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/steel, /obj/item/roguegear/bronze, /obj/item/roguegear/bronze, /obj/item/rope/chain)
	created_item = /obj/item/rogueweapon/trickweapon/stakedriver
	hammers_per_item = 14
	skill_level = 3

/// Whirligig Saw — heavy grinding saw mechanism
/datum/artificer_recipe/trickweapon/whirligigsaw
	name = "Whirligig Saw (+2 Steel, +1 Iron, +1 Chain, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel, /obj/item/ingot/iron, /obj/item/rope/chain, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/whirligigsaw
	hammers_per_item = 16
	skill_level = 3

/// Boom Hammer — explosive impact hammer
/datum/artificer_recipe/trickweapon/boomhammer
	name = "Boom Hammer (+2 Steel, +1 Iron, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel, /obj/item/ingot/iron, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/boomhammer
	hammers_per_item = 16
	skill_level = 3

/// Tonitrus — arcyne-charged mace engineered by the Guild
/datum/artificer_recipe/trickweapon/tonitrus
	name = "Tonitrus (+2 Steel)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel)
	created_item = /obj/item/rogueweapon/trickweapon/tonitrus
	hammers_per_item = 14
	skill_level = 3

/// Rifle Spear — spear with integrated rifle mechanism
/datum/artificer_recipe/trickweapon/riflespear
	name = "Rifle Spear (+2 Steel, +1 Small Log, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel, /obj/item/grown/log/tree/small, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/riflespear
	hammers_per_item = 18
	skill_level = 4

// ================ BLESSED STEEL TIER (HAWTHORNE / FERENTIA) ================
// Trick weapons forged from holy steel — the signature metal of Hawthorne
// aristocracy and Ferentian martial traditions. These refined weapons reflect
// the elegance and precision of their noble patrons.

/// Threaded Cane — gentleman's cane that transforms into a serrated whip
/datum/artificer_recipe/trickweapon/threadedcane
	name = "Threaded Cane (+1 Steel, +1 Iron, +1 Chain)"
	required_item = /obj/item/ingot/steelholy
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/iron, /obj/item/rope/chain)
	created_item = /obj/item/rogueweapon/trickweapon/threadedcane
	hammers_per_item = 14
	skill_level = 3

/// Rakuyo — twin-blade that separates into saber and dagger
/datum/artificer_recipe/trickweapon/rakuyo
	name = "Rakuyo (+1 Steel, +1 Iron)"
	required_item = /obj/item/ingot/steelholy
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/iron)
	created_item = /obj/item/rogueweapon/trickweapon/rakuyo
	hammers_per_item = 14
	skill_level = 3

/// Reiterpallasch — rapier with integrated firearm mechanism
/datum/artificer_recipe/trickweapon/reiterpallasch
	name = "Reiterpallasch (+2 Steel, +1 Iron)"
	required_item = /obj/item/ingot/steelholy
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel, /obj/item/ingot/iron)
	created_item = /obj/item/rogueweapon/trickweapon/reiterpallasch
	hammers_per_item = 18
	skill_level = 4

/// Ranger's Bowblade — sword that unfolds into a bow
/datum/artificer_recipe/trickweapon/simonsbowblade
	name = "Ranger's Bowblade (+1 Steel, +1 Bowstring)"
	required_item = /obj/item/ingot/steelholy
	additional_items = list(/obj/item/ingot/steel, /obj/item/natural/bowstring)
	created_item = /obj/item/rogueweapon/trickweapon/simonsbowblade
	hammers_per_item = 14
	skill_level = 3

// =================== SILVER TIER (PSYDONIC INQUISITION) ====================
// Silver trick weapons forged from pure silver. These are the hallmark arms
// of the Psydonic Inquisition, wrought to slay the unholy and purge heresy.
// Silver's innate anti-curse properties make these weapons lethal against
// vampires, lycanthropes, and other aberrations.

/// Kirkhammer — silver sword that sheathes into a massive stone hammer
/datum/artificer_recipe/trickweapon/kirkhammer
	name = "Psydonic Hammer (+1 Steel, +1 Stone)"
	required_item = /obj/item/ingot/silver
	additional_items = list(/obj/item/ingot/steel, /obj/item/natural/stone)
	created_item = /obj/item/rogueweapon/trickweapon/kirkhammer
	hammers_per_item = 14
	skill_level = 3

/// Pontifex Blade — silver sword that slots into a greatsword sheath
/datum/artificer_recipe/trickweapon/ludwigblade
	name = "Pontifex Blade (+2 Steel, +1 Iron)"
	required_item = /obj/item/ingot/silver
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel, /obj/item/ingot/iron)
	created_item = /obj/item/rogueweapon/trickweapon/ludwigblade
	hammers_per_item = 18
	skill_level = 4

/// Church Pick — war pick favored by the old Inquisition hunters
/datum/artificer_recipe/trickweapon/churchpick
	name = "Inquisitor's Pick (+1 Steel, +1 Stick, +1 Cog)"
	required_item = /obj/item/ingot/silver
	additional_items = list(/obj/item/ingot/steel, /obj/item/grown/log/tree/stick, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/churchpick
	hammers_per_item = 14
	skill_level = 3

/// Blade of Mercy — arcyne-infused siderite blade wielded by Inquisition executors
/datum/artificer_recipe/trickweapon/bladesofmercy
	name = "Blade of Mercy (+1 Steel, +1 Iron)"
	required_item = /obj/item/ingot/silver
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/iron)
	created_item = /obj/item/rogueweapon/trickweapon/bladesofmercy
	hammers_per_item = 14
	skill_level = 3

/// Chikage — katana that channels the wielder's blood for devastating attacks
/datum/artificer_recipe/trickweapon/chikage
	name = "Chikage (+1 Steel, +1 Iron)"
	required_item = /obj/item/ingot/silver
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/iron)
	created_item = /obj/item/rogueweapon/trickweapon/chikage
	hammers_per_item = 14
	skill_level = 3

/// Penitent's Wheel — massive spiked wheel of Inquisitorial penance
/datum/artificer_recipe/trickweapon/logariuswheel
	name = "Penitent's Wheel (+2 Steel, +1 Iron, +1 Cog)"
	required_item = /obj/item/ingot/silver
	additional_items = list(/obj/item/ingot/steel, /obj/item/ingot/steel, /obj/item/ingot/iron, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/logariuswheel
	hammers_per_item = 18
	skill_level = 4

// =================== ABYSSORITE TIER (ELDRITCH / ABYSSOR) ==================
// Eldritch trick weapons forged with rare abyssal sea creatures as reagents.
// These weapons channel the dreamlike power of Abyssor — their creation
// requires components harvested from the deep: brain squids and iridescent
// reavers, fished from waters where Abyssor's dreams bleed into reality.

/// Abyssal Parasite — eldritch relic that unfurls into lashing tentacles
/datum/artificer_recipe/trickweapon/kosparasite
	name = "Abyssal Parasite (+1 Iron, +1 Brain Squid)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/reagent_containers/food/snacks/fish/creepy_squid)
	created_item = /obj/item/rogueweapon/trickweapon/kosparasite
	hammers_per_item = 18
	skill_level = 4

/// Abyssal Arm — severed leviathan limb that extends into a whip-scythe
/datum/artificer_recipe/trickweapon/amygdalanarm
	name = "Abyssal Arm (+2 Iron, +1 Iridescent Reaver)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/ingot/iron, /obj/item/reagent_containers/food/snacks/fish/creepy_shark)
	created_item = /obj/item/rogueweapon/trickweapon/amygdalanarm
	hammers_per_item = 20
	skill_level = 5

// ========================= NECRA TIER (DEATH) =============================
// Weapons tied to Necra, the goddess of death and the grave. Forged from
// iron and steel.

/// Gravereaper — curved sword that extends into a massive scythe
/datum/artificer_recipe/trickweapon/burialblade
	name = "Gravereaper (+2 Iron, +1 Cog)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/ingot/iron, /obj/item/roguegear/bronze)
	created_item = /obj/item/rogueweapon/trickweapon/burialblade
	hammers_per_item = 18
	skill_level = 4

// ====================== DENDOR TIER (WILDERNESS) ==========================
// Unique trick weapons derived from rare natural materials blessed by Dendor.
// These primal weapons channel the wild essence of the forest.

/// Feral Claw — clawed gauntlet born of Dendor's wildkin essence
/datum/artificer_recipe/trickweapon/beastclaws
	name = "Feral Claw (+1 Iron, +1 Essence of Wilderness)"
	required_item = /obj/item/ingot/steel
	additional_items = list(/obj/item/ingot/iron, /obj/item/natural/cured/essence)
	created_item = /obj/item/rogueweapon/trickweapon/beastclaws
	hammers_per_item = 14
	skill_level = 3

