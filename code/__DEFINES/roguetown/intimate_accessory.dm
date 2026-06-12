/// Region slot IDs. Each sexual region has a piercing sub-slot and an
/// insertable sub-slot; non-sexual adornments are piercing-only.
#define INTIMATE_SLOT_GENITAL 1
#define INTIMATE_SLOT_REAR 2
#define INTIMATE_SLOT_BREAST 3
#define INTIMATE_SLOT_MOUTH 4
#define INTIMATE_SLOT_MISC INTIMATE_SLOT_MOUTH
/// Non-sexual piercing-only slots.
#define INTIMATE_SLOT_EAR 5
#define INTIMATE_SLOT_NOSE 6
#define INTIMATE_SLOT_BELLY 7

#define INTIMATE_FLAG_INSERTABLE (1<<0)
#define INTIMATE_FLAG_PIERCING (1<<1)
#define INTIMATE_FLAG_LOCKABLE (1<<2)
#define INTIMATE_FLAG_REMOTE (1<<3)
#define INTIMATE_FLAG_BERIDDLEABLE (1<<4)

#define TRAIT_SOURCE_INTIMATE "intimate_accessory"
#define CURSED_PIERCING_TRAIT_SOURCE "cursed_piercing"

#define CURSED_PIERCING_ORGAN_PENIS "penis"
#define CURSED_PIERCING_ORGAN_TESTICLES "testicles"
#define CURSED_PIERCING_ORGAN_BREASTS "breasts"

#define CURSED_PIERCING_STRINGS_PATH "modular/code/game/objects/items/lewd/intimate_accessory/strings"
#define pick_cursed_piercing_string(FILE, KEY) (pick(strings(FILE, KEY, CURSED_PIERCING_STRINGS_PATH)))

/// Bodypart feature slot prefix used by intimate accessory bodypart features.
#define BODYPART_FEATURE_INTIMATE_ACCESSORY "intimate_accessory"
