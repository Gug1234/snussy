/**
 * Step 13 — Keybindings category.
 *
 * Defers entirely to the existing keybinds TGUI window
 * (`/client/proc/setup_character_keybinds` → KeybindingsMenu) via the
 * Step 14 `launch_singleton` handshake. Inline embedding was
 * scoped-out: the keybinds UI ships a self-contained capture surface
 * (mod-key matrix + conflict resolver) whose state shape doesn't
 * round-trip cleanly through the flat prefs snapshot.
 *
 * Registration hook present for symmetry.
 */

/proc/register_prefs_keybindings_setters()
	return // intentional no-op for Step 13
