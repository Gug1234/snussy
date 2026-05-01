/**
 * @file prefs_categories/intimacy.dm
 * @description Step 14 — Intimacy category registration.
 *
 * Every Intimacy row currently delegates to a standalone editor via the
 * Step 14 launch_singleton handshake (see prefs_singleton_handshake.dm).
 * The Cursed Collar overview/master-mode setters are already registered
 * by the Step 3 dispatch seed (cursed_collar_opt) and Step 17 will add
 * the master-mode + specified-name setters when the round-start equip
 * path lands.
 *
 * Registration hook is exposed for symmetry with identity.dm and
 * body.dm; presently a no-op.
 *
 * ERP gating: `build_prefs_snapshot` slices the snapshot per-category
 * server-side; this file does not own that slicing, but the launcher
 * stubs in prefs_singleton_handshake.dm refuse to open ERP editors when
 * the user lacks `extreme_erp` (handled inside the editor's own
 * is_valid()/ui_state guards, not here).
 */

/proc/register_prefs_intimacy_setters()
	return // intentional no-op for Step 14
