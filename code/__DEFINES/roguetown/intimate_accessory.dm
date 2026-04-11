/// Region slot IDs — each region has TWO sub-slots (piercing + insertable).
/// The routing between sub-slots is automatic based on INTIMATE_FLAG_PIERCING.
#define INTIMATE_SLOT_GENITAL 1
#define INTIMATE_SLOT_REAR 2
#define INTIMATE_SLOT_BREAST 3
#define INTIMATE_SLOT_MOUTH 4
#define INTIMATE_SLOT_MISC INTIMATE_SLOT_MOUTH
/// Dedicated slot for the Eora jelly — doesn't compete with piercings or insertables.
#define INTIMATE_SLOT_JELLY 5
/// Non-sexual piercing-only slots — no insertable sub-slot.
#define INTIMATE_SLOT_EAR 6
#define INTIMATE_SLOT_NOSE 7
#define INTIMATE_SLOT_BELLY 8

#define INTIMATE_FLAG_INSERTABLE (1<<0)
#define INTIMATE_FLAG_PIERCING (1<<1)
#define INTIMATE_FLAG_LOCKABLE (1<<2)
#define INTIMATE_FLAG_REMOTE (1<<3)
#define INTIMATE_FLAG_BERIDDLEABLE (1<<4)
/// Flag for the Eora jelly — routes to the dedicated jelly slot.
#define INTIMATE_FLAG_JELLY (1<<5)

#define TRAIT_SOURCE_INTIMATE "intimate_accessory"

