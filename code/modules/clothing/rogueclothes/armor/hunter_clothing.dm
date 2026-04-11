// ===================== HUNTER CLOTHING =====================
// Bloodborne-inspired armor sets for trick weapon hunter classes.
// Sprites live in modular/icons/obj/hunter_clothing/.
//
// Sets:
//   Brador's Set         - cape (cloak) + helm (head)
//   Old Hunter Set       - coat (armor, sleeved) + hat (head)
//   Gold Ardeo           - cone helm (head)
//   Orthodox Hunter Set  - coat (armor, sleeved) + hat (head) + mantle (neck)
//   Hunter Set           - coat (armor, sleeved) + hat (head) + mantle (neck) + gloves (gloves)

// ==================== BRADOR'S SET ====================

/obj/item/clothing/cloak/hunter/brador_cape
	name = "cloak of a skinned beast"
	desc = "The skinned hide of a terrible beast, fashioned into a tattered cape. It smells faintly of blood and decay, but offers some protection against the claws of night creatures."
	icon = 'modular/icons/obj/hunter_clothing/brador_cape_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/brador_cape.dmi'
	icon_state = "brador_cape"
	item_state = "brador_cape"
	alternate_worn_layer = CLOAK_BEHIND_LAYER
	slot_flags = ITEM_SLOT_CLOAK
	body_parts_covered = CHEST
	armor = ARMOR_LEATHER
	sewrepair = TRUE
	max_integrity = ARMOR_INT_CHEST_LIGHT_BASE
	sellprice = 15

/obj/item/clothing/head/roguetown/helmet/leather/brador_helm
	name = "hood of a skinned beast"
	desc = "The skinned head of a vile beast adorned with a pair of antlers. It's said that clergy oft become the most dreadful beasts..."
	icon = 'modular/icons/obj/hunter_clothing/brador_helm_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/brador_helm.dmi'
	icon_state = "brador_helm"
	item_state = "brador_helm"
	body_parts_covered = HEAD|HAIR|EARS
	flags_inv = HIDEEARS|HIDEHAIR
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_HELMET_LEATHER
	sewrepair = TRUE
	sellprice = 10

// ==================== OLD HUNTER SET ====================

/obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_old
	name = "old hunter coat"
	desc = "A long leather coat worn by hunters of old. The leather is cracked and faded, but still sturdy. Small trinkets adorn the garment, relics of a more superstitious era."
	icon = 'modular/icons/obj/hunter_clothing/browny_coat_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/browny_coat.dmi'
	sleeved = 'modular/icons/obj/hunter_clothing/browny_coat_sleeve.dmi'
	sleevetype = "armor"
	icon_state = "browny_coat"
	item_state = "browny_coat"
	body_parts_covered = COVERAGE_ALL_BUT_ARMS
	armor = ARMOR_LEATHER_GOOD
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_CHOP, BCLASS_SMASH)
	max_integrity = ARMOR_INT_CHEST_LIGHT_MASTER
	nodismemsleeves = TRUE
	sellprice = 20

/obj/item/clothing/head/roguetown/helmet/leather/hunter_old_hat
	name = "old hunter hat"
	desc = "A wide-brimmed hat favored by the old hunters. Battered and stained, but it keeps the blood out of your eyes."
	icon = 'modular/icons/obj/hunter_clothing/browny_hat_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/browny_hat.dmi'
	icon_state = "browny_hat"
	item_state = "browny_hat"
	body_parts_covered = HEAD|HAIR
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_HELMET_LEATHER
	sewrepair = TRUE
	sellprice = 10

// ==================== GOLD ARDEO ====================

/obj/item/clothing/head/roguetown/helmet/leather/gold_ardeo
	name = "gold ardeo"
	desc = "A tall, pointed golden cone worn by executioners of a forgotten order. It obscures the face entirely, a mercy for both the wearer and the condemned."
	icon = 'modular/icons/obj/hunter_clothing/cone_helm_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/cone_helm.dmi'
	icon_state = "cone_helm"
	item_state = "cone_helm"
	body_parts_covered = FULL_HEAD
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_HELMET_HARDLEATHER
	sewrepair = TRUE
	sellprice = 15

// ==================== ORTHODOX HUNTER SET (Gascoigne) ====================

/obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_orthodox
	name = "orthodox hunter coat"
	desc = "A heavy black coat fastened with numerous buckles and straps. Standard issue for hunters of the orthodox school."
	icon = 'modular/icons/obj/hunter_clothing/fedora_coat_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/fedora_coat.dmi'
	sleeved = 'modular/icons/obj/hunter_clothing/fedora_coat_sleeve.dmi'
	sleevetype = "armor"
	icon_state = "fedora_coat"
	item_state = "fedora_coat"
	body_parts_covered = COVERAGE_ALL_BUT_ARMS
	armor = ARMOR_LEATHER_GOOD
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_CHOP, BCLASS_SMASH)
	max_integrity = ARMOR_INT_CHEST_LIGHT_MASTER
	nodismemsleeves = TRUE
	sellprice = 20

/obj/item/clothing/head/roguetown/helmet/leather/hunter_orthodox_hat
	name = "orthodox hunter hat"
	desc = "A distinctive wide-brimmed hat with a tall crown. The mark of a hunter who walks the orthodox path."
	icon = 'modular/icons/obj/hunter_clothing/fedora_hat_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/fedora_hat.dmi'
	icon_state = "fedora_hat"
	item_state = "fedora_hat"
	body_parts_covered = HEAD|HAIR
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_HELMET_LEATHER
	sewrepair = TRUE
	sellprice = 10

/obj/item/clothing/neck/roguetown/hunter_orthodox_mantle
	name = "orthodox hunter mantle"
	desc = "A layered shoulder wrap of dark leather and cloth, shielding the neck and upper chest from claws and fangs."
	icon = 'modular/icons/obj/hunter_clothing/fedora_mantle_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/fedora_mantle.dmi'
	icon_state = "fedora_mantle"
	item_state = "fedora_mantle"
	slot_flags = ITEM_SLOT_NECK
	body_parts_covered = NECK
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_SIDE_LEATHER
	sewrepair = TRUE
	sellprice = 10

// ==================== HUNTER SET ====================

/obj/item/clothing/suit/roguetown/armor/leather/heavy/coat/hunter_standard
	name = "hunter coat"
	desc = "A well-worn leather coat with reinforced stitching. The standard garb of those who take up the hunt."
	icon = 'modular/icons/obj/hunter_clothing/hunter_coat_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/hunter_coat.dmi'
	sleeved = 'modular/icons/obj/hunter_clothing/hunter_coat_sleeve.dmi'
	sleevetype = "armor"
	icon_state = "hunter_coat"
	item_state = "hunter_coat"
	body_parts_covered = COVERAGE_ALL_BUT_ARMS
	armor = ARMOR_LEATHER_GOOD
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_CHOP, BCLASS_SMASH)
	max_integrity = ARMOR_INT_CHEST_LIGHT_MASTER
	nodismemsleeves = TRUE
	sellprice = 20

/obj/item/clothing/head/roguetown/helmet/leather/hunter_standard_hat
	name = "hunter hat"
	desc = "A tricorn-like hat with a low brim. It marks its wearer as one who hunts beasts in the night."
	icon = 'modular/icons/obj/hunter_clothing/hunter_hat_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/hunter_hat.dmi'
	icon_state = "hunter_hat"
	item_state = "hunter_hat"
	body_parts_covered = HEAD|HAIR
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_HELMET_LEATHER
	sewrepair = TRUE
	sellprice = 10

/obj/item/clothing/neck/roguetown/hunter_standard_mantle
	name = "hunter mantle"
	desc = "A practical shoulder drape that protects the neck from beast bites and the night air alike."
	icon = 'modular/icons/obj/hunter_clothing/hunter_mantle_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/hunter_mantle.dmi'
	icon_state = "hunter_mantle"
	item_state = "hunter_mantle"
	slot_flags = ITEM_SLOT_NECK
	body_parts_covered = NECK
	armor = ARMOR_LEATHER
	max_integrity = ARMOR_INT_SIDE_LEATHER
	sewrepair = TRUE
	sellprice = 10

// ==================== HUNTER MASK ====================

/obj/item/clothing/mask/rogue/hunter_mask
	name = "hunter face wrap"
	desc = "A length of dark cloth wound tightly across the lower face. Hunters wear these to keep blood and bile from their mouths, and to make themselves harder to identify after the hunt."
	icon_state = "shepherd"
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	slot_flags = ITEM_SLOT_MASK
	color = COLOR_ALMOST_BLACK
	sewrepair = TRUE
	sellprice = 3

/obj/item/clothing/gloves/roguetown/hunter_gloves
	name = "hunter gloves"
	desc = "A pair of fingerless gloves with reinforced palms and forearms. They help hunters maintain their grip on slippery weapons and prevent damage to the hands during a frenzied struggle with a beast."
	icon = 'modular/icons/obj/hunter_clothing/hunter_gloves_icon.dmi'
	mob_overlay_icon = 'modular/icons/obj/hunter_clothing/hunter_gloves.dmi'
	icon_state = "hunter_gloves"
	item_state = "hunter_gloves"
	slot_flags = ITEM_SLOT_GLOVES
	body_parts_covered = HANDS|ARMS
	armor = ARMOR_LEATHER_STUDDED
	max_integrity = ARMOR_INT_SIDE_LEATHER
	sewrepair = TRUE
	sellprice = 5
