/**
 * assets_prefs_map.dm — TGUI asset datum for the Ratwood origin map.
 *
 * The Origin body in the PreferencesMenu TGUI resolves the map via
 * `resolveAsset('rwmap1.png')`. `resolveAsset` requires a registered
 * tgui asset mapping (SendAsset/browse_rsc alone is not enough — the
 * tgui runtime consults `loadedMappings` populated by the asset cache
 * `/asset/mappings` action). Shipping `html/rwmap1.png` through a
 * dedicated `/datum/asset/simple/prefs_origin_map` datum sent via
 * `/datum/preferences/ui_assets` gives the client a real mapping so
 * the image shows up on first open without the player first having
 * visited the legacy HTML origin window.
 */
/datum/asset/simple/prefs_origin_map
	keep_local_name = TRUE
	assets = list(
		"rwmap1.png" = file("html/rwmap1.png"),
	)
