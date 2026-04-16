#define CHASTITY_HARDMODE_DISABLED 0
#define CHASTITY_HARDMODE_ENABLED 1

/// Root directory for all chastity flavor-text JSON banks.
/// Used by pick_chastity_string() and anywhere a raw strings() call targets the chastity string dir.
#define CHASTITY_STRINGS_PATH "modular/code/game/objects/items/lewd/chastity/strings"

/// Picks a random entry from a chastity string bank.
/// Usage: pick_chastity_string("chastity_lock_messages.json", "chastity_lock_denial")
#define pick_chastity_string(FILE, KEY) (pick(strings(FILE, KEY, CHASTITY_STRINGS_PATH)))

/// Global registry of chastity keys that haven't been delivered yet because the
/// target character wasn't online when the wearer spawned. Keyed by LOWER_TEXT
/// character name → list of assoc lists with "lockhash" and "owner_name" entries.
/// Entries are consumed and removed when the target character spawns via copy_to.
GLOBAL_LIST_EMPTY(pending_chastity_keys)
