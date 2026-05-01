/**
 * appearance_preview/_defines.dm — Shared taxonomy for appearance preview atlases.
 *
 * This file freezes the canonical vocabulary used by the browser preview,
 * the atlas exporter, and the server-side render hooks that will eventually
 * feed both editors. The contract is intentionally narrow: icon-state strings
 * are the canonical lookup keys, and the category list stays fixed so atlas
 * generation can fail loudly when source content changes.
 */

/// Manifest schema version. Bumped from 1 (per-state, Python exporter) to
/// 2 (sheet-backed, RustG/iconforge backend). Must stay in lockstep with
/// `APPEARANCE_PREVIEW_MANIFEST_VERSION` in
/// `tools/build/appearance_preview/types.ts`.
#define APPEARANCE_PREVIEW_MANIFEST_VERSION 2

/// Sole supported preview build backend. Per the v2 contract there is no
/// Python or fallback backend; a manifest carrying a different value MUST
/// be rejected at load time.
#define APPEARANCE_PREVIEW_BACKEND_ID "rustg_iconforge"

/// Sole supported asset layout in v2. Per-state file layouts are removed.
#define APPEARANCE_PREVIEW_LAYOUT_KIND "sheet"

// Root envelope keys. These MUST match the camelCase keys emitted by the
// TS build pipeline (see `tools/build/appearance_preview/types.ts`).
// A mismatch here is what the Step 4 DM validator was quietly suffering
// from: the loader rejected every valid bundle because the keys it looked
// up did not exist.
#define APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION "version"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_BACKEND "backend"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_LAYOUT "layout"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_CANONICAL_LOOKUP "canonicalLookupKey"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORY_ORDER "categoryOrder"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES "categories"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_SHEETS "sheets"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_STATES "states"
#define APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD "build"

/// Sheet record field keys (mirrors `SheetRecord` in the TS types).
#define APPEARANCE_PREVIEW_SHEET_KEY_ID "id"
#define APPEARANCE_PREVIEW_SHEET_KEY_FAMILY "family"
#define APPEARANCE_PREVIEW_SHEET_KEY_PATH "path"
#define APPEARANCE_PREVIEW_SHEET_KEY_WIDTH "width"
#define APPEARANCE_PREVIEW_SHEET_KEY_HEIGHT "height"
#define APPEARANCE_PREVIEW_SHEET_KEY_TILE_WIDTH "tileWidth"
#define APPEARANCE_PREVIEW_SHEET_KEY_TILE_HEIGHT "tileHeight"
#define APPEARANCE_PREVIEW_SHEET_KEY_CONTENT_HASH "contentHash"

/// State record field keys (mirrors `StateRecord` in the TS types).
#define APPEARANCE_PREVIEW_STATE_KEY_ICON_STATE "iconState"
#define APPEARANCE_PREVIEW_STATE_KEY_FAMILY "family"
#define APPEARANCE_PREVIEW_STATE_KEY_SHEET_ID "sheetId"
#define APPEARANCE_PREVIEW_STATE_KEY_CROPS "crops"
#define APPEARANCE_PREVIEW_STATE_KEY_VARIANTS "variants"
#define APPEARANCE_PREVIEW_STATE_KEY_FLAGS "flags"

/// Crop rect field keys.
#define APPEARANCE_PREVIEW_CROP_KEY_X "x"
#define APPEARANCE_PREVIEW_CROP_KEY_Y "y"
#define APPEARANCE_PREVIEW_CROP_KEY_WIDTH "width"
#define APPEARANCE_PREVIEW_CROP_KEY_HEIGHT "height"

/// Build metadata field keys (mirrors `BuildMetadata` in the TS types).
#define APPEARANCE_PREVIEW_BUILD_KEY_BUILT_AT "builtAt"
#define APPEARANCE_PREVIEW_BUILD_KEY_BACKEND "backend"
#define APPEARANCE_PREVIEW_BUILD_KEY_LAYOUT "layout"
#define APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT "sourceFingerprint"
#define APPEARANCE_PREVIEW_BUILD_KEY_ADAPTER_VERSIONS "adapterVersions"

/// Category record field keys.
#define APPEARANCE_PREVIEW_CATEGORY_KEY_KEY "key"
#define APPEARANCE_PREVIEW_CATEGORY_KEY_SCOPE "scope"
#define APPEARANCE_PREVIEW_CATEGORY_KEY_STATES "states"

#define APPEARANCE_PREVIEW_MANIFEST_KEY_ICON_STATE "icon_state"

#define APPEARANCE_PREVIEW_CATEGORY_GUIDE_BODY "guide_body"
#define APPEARANCE_PREVIEW_CATEGORY_TAUR_BODY "taur_body"
#define APPEARANCE_PREVIEW_CATEGORY_BODY_MARKINGS "body_markings"
#define APPEARANCE_PREVIEW_CATEGORY_WINGS "wings"
#define APPEARANCE_PREVIEW_CATEGORY_SNOUTS "snouts"
#define APPEARANCE_PREVIEW_CATEGORY_EARS "ears"
#define APPEARANCE_PREVIEW_CATEGORY_HORNS "horns"
#define APPEARANCE_PREVIEW_CATEGORY_ANTENNA "antenna"
#define APPEARANCE_PREVIEW_CATEGORY_TAILS "tails"
#define APPEARANCE_PREVIEW_CATEGORY_TAIL_FEATURES "tail_features"
#define APPEARANCE_PREVIEW_CATEGORY_NECK_FEATURES "neck_features"
#define APPEARANCE_PREVIEW_CATEGORY_CRESTS "crests"
#define APPEARANCE_PREVIEW_CATEGORY_GENITALS "genitals"
#define APPEARANCE_PREVIEW_CATEGORY_HAIR "hair"
#define APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY "intimate_accessory"
#define APPEARANCE_PREVIEW_CATEGORY_STICKER "sticker"
#define APPEARANCE_PREVIEW_CATEGORY_INTIMATE_PIERCING_ITEMS "intimate_piercing_items"

#define APPEARANCE_PREVIEW_CATEGORY_SCOPE_FAMILY "family"
#define APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG "catalog"

/// Editor kinds for the commit contract (see
/// `modular/code/modules/client/appearance_preview/appearance_preview_commit.dm`).
#define APPEARANCE_PREVIEW_EDITOR_KIND_TAUR "taur_genital_offset"
#define APPEARANCE_PREVIEW_EDITOR_KIND_CUSTOM_PIERCING "custom_piercing"
#define APPEARANCE_PREVIEW_EDITOR_KIND_INTIMATE_ACCESSORY "intimate_accessory_offset"

/// Family IDs for the commit contract are defined canonically in
/// `code/__DEFINES/preferences.dm` (APPEARANCE_PREVIEW_FAMILY_*). The adapter
/// `family` strings emitted by `tools/build/appearance_preview/adapters/`
/// must match those canonical values.

/// Commit envelope keys (see
/// `modular/code/modules/client/appearance_preview/appearance_preview_commit.dm`).
/// Promoted out of the commit .dm file into shared defines so unit tests
/// and future consumers included earlier in the DME can reference them.
#define APPEARANCE_PREVIEW_COMMIT_KEY_EDITOR_KIND "editor_kind"
#define APPEARANCE_PREVIEW_COMMIT_KEY_PREF_KEY "pref_key"
#define APPEARANCE_PREVIEW_COMMIT_KEY_FAMILY_ID "family_id"
#define APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN "revision_token"
#define APPEARANCE_PREVIEW_COMMIT_KEY_DIRTY "dirty"
#define APPEARANCE_PREVIEW_COMMIT_KEY_SNAPSHOT "snapshot"

/// Commit result codes. `OK` is emitted on success; every other code marks
/// a specific failure mode recorded on `editor.last_commit_result`.
#define APPEARANCE_PREVIEW_COMMIT_OK "ok"
#define APPEARANCE_PREVIEW_COMMIT_ERR_NO_PREFS "no_prefs"
#define APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_ENVELOPE "invalid_envelope"
#define APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_EDITOR_KIND "invalid_editor_kind"
#define APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_PREF_KEY "invalid_pref_key"
#define APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_FAMILY_ID "invalid_family_id"
#define APPEARANCE_PREVIEW_COMMIT_ERR_STALE_REVISION "stale_revision"
#define APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_SNAPSHOT "invalid_snapshot"
#define APPEARANCE_PREVIEW_COMMIT_ERR_APPLY_FAILED "apply_failed"
#define APPEARANCE_PREVIEW_COMMIT_ERR_PERSIST_FAILED "persist_failed"
/// Step 4 remediation (two-phase persist): `save_character()` succeeded but
/// the post-save sidecar flush failed. In-memory prefs + main prefs file are
/// authoritative; sidecars are eventually consistent and the next successful
/// commit reconciles them. Clients should surface this as a warning banner
/// but still treat the commit as a success (draft is not preserved).
#define APPEARANCE_PREVIEW_COMMIT_DEGRADED_SIDECAR "degraded_sidecar"

#define APPEARANCE_PREVIEW_DIR_KEY_S "s"
#define APPEARANCE_PREVIEW_DIR_KEY_N "n"
#define APPEARANCE_PREVIEW_DIR_KEY_E "e"
#define APPEARANCE_PREVIEW_DIR_KEY_W "w"

#define APPEARANCE_PREVIEW_PROP_X "x"
#define APPEARANCE_PREVIEW_PROP_Y "y"
#define APPEARANCE_PREVIEW_PROP_TURN "turn"
#define APPEARANCE_PREVIEW_PROP_FLIP "flip"
#define APPEARANCE_PREVIEW_PROP_ABOVE "above"
#define APPEARANCE_PREVIEW_PROP_HIDE "hide"
#define APPEARANCE_PREVIEW_PROP_SHRINK "shrink"

/**
 * Hybrid offset guide descriptor contract.
 *
 * DM remains the authoritative renderer for the full character preview. These
 * keys describe the single active guide sprite that TGUI may overlay and move
 * locally while editing offsets. Keep this schema intentionally small:
 * descriptor builders must emit resolved manifest categories and icon states,
 * and TGUI must not infer runtime DMI naming conventions from target ids.
 */
#define HYBRID_OFFSET_DESCRIPTOR_KEY_ID "id"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_FAMILY "family"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_TARGET_KEY "target_key"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY "manifest_category"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_DIRECTION "direction"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS "layers"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_WIDTH "native_width"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_HEIGHT "native_height"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS "allowed_fields"
#define HYBRID_OFFSET_DESCRIPTOR_KEY_APPROXIMATE_COLOR "approximate_color"

/// Hybrid descriptor layer keys. A descriptor may contain one or more layers,
/// but the overall descriptor still represents exactly one active edit target.
#define HYBRID_OFFSET_LAYER_KEY_ICON_STATE "icon_state"
#define HYBRID_OFFSET_LAYER_KEY_COLOR "color"
#define HYBRID_OFFSET_LAYER_KEY_ROLE "role"

/// Semantic layer roles. These are UI hints only; DM remains authoritative for
/// the final composited appearance after the editor commits.
#define HYBRID_OFFSET_LAYER_ROLE_BASE "base"
#define HYBRID_OFFSET_LAYER_ROLE_METAL "metal"
#define HYBRID_OFFSET_LAYER_ROLE_GEM "gem"
#define HYBRID_OFFSET_LAYER_ROLE_GUIDE "guide"

/// Generic guide sprite dimensions used by descriptor shells before an
/// editor-specific resolver can provide the exact sheet tile size.
#define HYBRID_OFFSET_DEFAULT_NATIVE_SIZE 32
/// Bound target ids so forged TGUI input cannot allocate arbitrarily large
/// descriptor keys while future editor-specific resolvers are still landing.
#define HYBRID_OFFSET_TARGET_KEY_MAX_LENGTH 128

GLOBAL_LIST_INIT(appearance_preview_manifest_category_order, list(
	APPEARANCE_PREVIEW_CATEGORY_GUIDE_BODY,
	APPEARANCE_PREVIEW_CATEGORY_TAUR_BODY,
	APPEARANCE_PREVIEW_CATEGORY_BODY_MARKINGS,
	APPEARANCE_PREVIEW_CATEGORY_WINGS,
	APPEARANCE_PREVIEW_CATEGORY_SNOUTS,
	APPEARANCE_PREVIEW_CATEGORY_EARS,
	APPEARANCE_PREVIEW_CATEGORY_HORNS,
	APPEARANCE_PREVIEW_CATEGORY_ANTENNA,
	APPEARANCE_PREVIEW_CATEGORY_TAILS,
	APPEARANCE_PREVIEW_CATEGORY_TAIL_FEATURES,
	APPEARANCE_PREVIEW_CATEGORY_NECK_FEATURES,
	APPEARANCE_PREVIEW_CATEGORY_CRESTS,
	APPEARANCE_PREVIEW_CATEGORY_GENITALS,
	APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY,
	APPEARANCE_PREVIEW_CATEGORY_STICKER,
	APPEARANCE_PREVIEW_CATEGORY_INTIMATE_PIERCING_ITEMS,
	APPEARANCE_PREVIEW_CATEGORY_HAIR,
))

GLOBAL_LIST_INIT(appearance_preview_manifest_category_scopes, list(
	APPEARANCE_PREVIEW_CATEGORY_GUIDE_BODY = APPEARANCE_PREVIEW_CATEGORY_SCOPE_FAMILY,
	APPEARANCE_PREVIEW_CATEGORY_TAUR_BODY = APPEARANCE_PREVIEW_CATEGORY_SCOPE_FAMILY,
	APPEARANCE_PREVIEW_CATEGORY_BODY_MARKINGS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_FAMILY,
	APPEARANCE_PREVIEW_CATEGORY_WINGS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_SNOUTS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_EARS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_HORNS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_ANTENNA = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_TAILS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_TAIL_FEATURES = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_NECK_FEATURES = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_CRESTS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_GENITALS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_HAIR = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_STICKER = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
	APPEARANCE_PREVIEW_CATEGORY_INTIMATE_PIERCING_ITEMS = APPEARANCE_PREVIEW_CATEGORY_SCOPE_CATALOG,
))

GLOBAL_LIST_INIT(appearance_preview_dir_keys, list(
	APPEARANCE_PREVIEW_DIR_KEY_S,
	APPEARANCE_PREVIEW_DIR_KEY_N,
	APPEARANCE_PREVIEW_DIR_KEY_E,
	APPEARANCE_PREVIEW_DIR_KEY_W,
))

GLOBAL_LIST_INIT(appearance_preview_field_keys, list(
	APPEARANCE_PREVIEW_PROP_X,
	APPEARANCE_PREVIEW_PROP_Y,
	APPEARANCE_PREVIEW_PROP_TURN,
	APPEARANCE_PREVIEW_PROP_FLIP,
	APPEARANCE_PREVIEW_PROP_ABOVE,
	APPEARANCE_PREVIEW_PROP_HIDE,
	APPEARANCE_PREVIEW_PROP_SHRINK,
))

GLOBAL_LIST_INIT(hybrid_offset_known_families, list(
	APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS,
	APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS,
	APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS,
))

GLOBAL_LIST_INIT(hybrid_offset_descriptor_keys, list(
	HYBRID_OFFSET_DESCRIPTOR_KEY_ID,
	HYBRID_OFFSET_DESCRIPTOR_KEY_FAMILY,
	HYBRID_OFFSET_DESCRIPTOR_KEY_TARGET_KEY,
	HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY,
	HYBRID_OFFSET_DESCRIPTOR_KEY_DIRECTION,
	HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS,
	HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_WIDTH,
	HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_HEIGHT,
	HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS,
	HYBRID_OFFSET_DESCRIPTOR_KEY_APPROXIMATE_COLOR,
))

GLOBAL_LIST_INIT(hybrid_offset_layer_keys, list(
	HYBRID_OFFSET_LAYER_KEY_ICON_STATE,
	HYBRID_OFFSET_LAYER_KEY_COLOR,
	HYBRID_OFFSET_LAYER_KEY_ROLE,
))

GLOBAL_LIST_INIT(hybrid_offset_layer_roles, list(
	HYBRID_OFFSET_LAYER_ROLE_BASE,
	HYBRID_OFFSET_LAYER_ROLE_METAL,
	HYBRID_OFFSET_LAYER_ROLE_GEM,
	HYBRID_OFFSET_LAYER_ROLE_GUIDE,
))

GLOBAL_LIST_INIT(hybrid_offset_allowed_field_keys, list(
	APPEARANCE_PREVIEW_PROP_X,
	APPEARANCE_PREVIEW_PROP_Y,
	APPEARANCE_PREVIEW_PROP_TURN,
	APPEARANCE_PREVIEW_PROP_FLIP,
	APPEARANCE_PREVIEW_PROP_ABOVE,
	APPEARANCE_PREVIEW_PROP_HIDE,
	APPEARANCE_PREVIEW_PROP_SHRINK,
))

GLOBAL_LIST_INIT(appearance_preview_family_scoped_categories, list(
	APPEARANCE_PREVIEW_CATEGORY_GUIDE_BODY,
	APPEARANCE_PREVIEW_CATEGORY_TAUR_BODY,
	APPEARANCE_PREVIEW_CATEGORY_BODY_MARKINGS,
))

/// Returns the canonical lookup key for a manifest entry.
///
/// The atlas contract treats the icon-state string as the one true key. This
/// helper only normalizes null/empty input so callers can safely reject bad
/// source content before export or render time.
/proc/appearance_preview_manifest_icon_state_key(icon_state)
	if(!istext(icon_state) || !length(icon_state))
		return null
	return icon_state

/// Returns the canonical preview direction key for a BYOND dir constant.
/proc/appearance_preview_dir_to_key(dir)
	switch(dir)
		if(NORTH)
			return APPEARANCE_PREVIEW_DIR_KEY_N
		if(EAST)
			return APPEARANCE_PREVIEW_DIR_KEY_E
		if(WEST)
			return APPEARANCE_PREVIEW_DIR_KEY_W
	return APPEARANCE_PREVIEW_DIR_KEY_S

/// Returns the BYOND dir constant for a canonical preview direction key.
/proc/appearance_preview_key_to_dir(dir_key)
	switch(dir_key)
		if(APPEARANCE_PREVIEW_DIR_KEY_N)
			return NORTH
		if(APPEARANCE_PREVIEW_DIR_KEY_E)
			return EAST
		if(APPEARANCE_PREVIEW_DIR_KEY_W)
			return WEST
	return SOUTH

/// Returns the family key shared by guide-body and body-marking atlas groups.
///
/// Family-scoped categories stay keyed by the exact `limbs_icon_m` /
/// `limbs_icon_f` pair so the exporter can group variants without inventing
/// race-specific aliases.
/proc/appearance_preview_guide_body_family_key(limb_icon_m, limb_icon_f)
	var/m_icon = appearance_preview_manifest_icon_state_key(limb_icon_m)
	var/f_icon = appearance_preview_manifest_icon_state_key(limb_icon_f)
	if(!m_icon || !f_icon)
		return null
	return "[m_icon]::[f_icon]"

/// Body markings reuse the guide-body family key so both atlas groups stay in
/// the same family bucket.
/proc/appearance_preview_body_marking_family_key(limb_icon_m, limb_icon_f)
	return appearance_preview_guide_body_family_key(limb_icon_m, limb_icon_f)

/// Returns the canonical taur family key for atlas lookups.
/proc/appearance_preview_taur_family_key(taur_icon_state)
	return appearance_preview_manifest_icon_state_key(taur_icon_state)

/// Returns TRUE when the category is family-scoped instead of a flat catalog.
/proc/appearance_preview_category_is_family_scoped(category_key)
	return istext(category_key) && (category_key in GLOB.appearance_preview_family_scoped_categories)
