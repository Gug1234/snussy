// Phase 6 — composite sub-entries on /datum/customizer_entry.
// See modular/code/datums/EXTREME_OFFSET_POLICY.md (Composite Sub-Entries).
//
// Hard cap per parent entry. Mirrors MAXIMUM_MARKINGS_PER_LIMB from
// code/__DEFINES/customization/body_markings.dm — the same "three is
// already enough to abuse, four is gratuitous" rationale.
#define MAX_SUB_ENTRIES 3

// Current sub-entry migration revision. `migrated_v == 0` on a loaded
// entry means "legacy save, wrap top-level accessory into sub_entries[1]".
// Bump this if a future phase adds new sub-entry fields that need back-
// filling on load.
#define SUB_ENTRIES_MIGRATION_VERSION 1
