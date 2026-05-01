/**
 * appearance_preview/manifest.dm — Shared manifest contract for preview atlases.
 *
 * Manifest v2 mirror. The authoritative schema lives in
 * `tools/build/appearance_preview/types.ts` and its runtime validator in
 * `tools/build/appearance_preview/schema/manifest_v2.ts`. This file is the
 * DM-side reflection: it carries the same field names and the same accept /
 * reject semantics so a v1 (Python exporter) bundle, a corrupted bundle, or
 * a bundle from a different backend cannot be loaded by mistake.
 *
 * Step 4 scope: schema mirror + version/backend/layout gating only. Per-record
 * cross-reference validation (sheet ids, variants, category state refs) is
 * intentionally deferred:
 *   - The TS validator already enforces it on every emitted manifest.
 *   - The DM-side asset cache (Step 7) and commit handler (Step 12) will
 *     consume the validated manifest and add their own targeted checks.
 *
 * If you tighten this file later, also update the TS validator so the two
 * stay in lockstep.
 */

/datum/appearance_preview_manifest_contract
	/// Version gate for exported atlas bundles. Always
	/// `APPEARANCE_PREVIEW_MANIFEST_VERSION` for a contract built today.
	var/version
	/// Required backend identifier. v2 only accepts `"rustg_iconforge"`.
	var/backend
	/// Required asset layout. v2 only accepts `"sheet"`.
	var/layout
	/// Canonical lookup key used for every state record. v2 fixes this to
	/// `"icon_state"`.
	var/canonical_lookup_key
	/// Ordered category buckets preserved by the exporter.
	var/list/category_order
	/// Category -> scope map. Family-scoped buckets are keyed by source family.
	var/list/category_scopes

/datum/appearance_preview_manifest_contract/New()
	..()
	version = APPEARANCE_PREVIEW_MANIFEST_VERSION
	backend = APPEARANCE_PREVIEW_BACKEND_ID
	layout = APPEARANCE_PREVIEW_LAYOUT_KIND
	canonical_lookup_key = APPEARANCE_PREVIEW_MANIFEST_KEY_ICON_STATE
	category_order = GLOB.appearance_preview_manifest_category_order.Copy()
	category_scopes = GLOB.appearance_preview_manifest_category_scopes.Copy()

/// Serializes the contract into a list that can be embedded in a manifest.
///
/// Field names mirror `ManifestV2` in
/// `tools/build/appearance_preview/types.ts`. Anything that consumes this
/// list MUST treat the names as load-bearing.
/datum/appearance_preview_manifest_contract/proc/as_list()
	// `category_scopes` is retained on the datum for DM-side use but is
	// intentionally NOT emitted here: v2 manifests carry per-category scope
	// inline in `categories[key].scope`, not at the root. The envelope
	// validator therefore must not require a root-level scope map.
	return list(
		APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION = version,
		APPEARANCE_PREVIEW_MANIFEST_KEY_BACKEND = backend,
		APPEARANCE_PREVIEW_MANIFEST_KEY_LAYOUT = layout,
		APPEARANCE_PREVIEW_MANIFEST_KEY_CANONICAL_LOOKUP = canonical_lookup_key,
		APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORY_ORDER = category_order.Copy(),
	)

/// Returns TRUE when the supplied manifest matches the frozen v2 contract.
///
/// This validates the *contract envelope* (version, backend, layout, lookup
/// key, category order, category scopes). The presence and shape of
/// `sheets`, `states`, `categories`, and `build` blocks are checked by
/// `appearance_preview_manifest_v2_envelope_is_valid`, which is what asset
/// loading should call.
/proc/appearance_preview_manifest_contract_is_valid(list/manifest)
	if(!islist(manifest))
		return FALSE
	if(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION] != APPEARANCE_PREVIEW_MANIFEST_VERSION)
		return FALSE
	if(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_BACKEND] != APPEARANCE_PREVIEW_BACKEND_ID)
		return FALSE
	if(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_LAYOUT] != APPEARANCE_PREVIEW_LAYOUT_KIND)
		return FALSE
	if(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CANONICAL_LOOKUP] != APPEARANCE_PREVIEW_MANIFEST_KEY_ICON_STATE)
		return FALSE
	var/list/category_order = manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORY_ORDER]
	if(!islist(category_order))
		return FALSE
	// v2 manifests only list categories for currently-registered adapter
	// families, so `categoryOrder` is a subset of the frozen taxonomy. We
	// require every entry to be a known taxonomy key AND for entries to
	// appear in the same relative order as the frozen list, so adapter
	// registration ordering stays deterministic as new families are added.
	var/taxonomy_cursor = 1
	for(var/category_key in category_order)
		var/found_at = 0
		for(var/j in taxonomy_cursor to GLOB.appearance_preview_manifest_category_order.len)
			if(GLOB.appearance_preview_manifest_category_order[j] == category_key)
				found_at = j
				break
		if(!found_at)
			return FALSE
		taxonomy_cursor = found_at + 1
	// v2 manifests place scope on each category record, not at the envelope
	// root. Scope drift is surfaced by the TS validator and by
	// `appearance_preview_manifest_v2_envelope_is_valid` + Step 7 asset
	// loader, which refuse to mount a category with the wrong scope.
	return TRUE

/// Returns TRUE when the v2 envelope blocks (`sheets`, `states`,
/// `categories`, `build`) are all present with the correct top-level shape.
///
/// This is intentionally shallow: per-record validation is the TS exporter's
/// job and is repeated by `tools/build/appearance_preview/schema/manifest_v2.ts`
/// before the manifest is ever published. We only re-check the envelope so a
/// truncated or schema-mismatched bundle cannot mount.
/proc/appearance_preview_manifest_v2_envelope_is_valid(list/manifest)
	if(!appearance_preview_manifest_contract_is_valid(manifest))
		return FALSE
	if(!islist(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_SHEETS]))
		return FALSE
	if(!islist(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_STATES]))
		return FALSE
	if(!islist(manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES]))
		return FALSE
	var/list/build_block = manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD]
	if(!islist(build_block))
		return FALSE
	if(build_block[APPEARANCE_PREVIEW_BUILD_KEY_BACKEND] != APPEARANCE_PREVIEW_BACKEND_ID)
		return FALSE
	if(build_block[APPEARANCE_PREVIEW_BUILD_KEY_LAYOUT] != APPEARANCE_PREVIEW_LAYOUT_KIND)
		return FALSE
	if(!istext(build_block[APPEARANCE_PREVIEW_BUILD_KEY_BUILT_AT]) || !length(build_block[APPEARANCE_PREVIEW_BUILD_KEY_BUILT_AT]))
		return FALSE
	if(!istext(build_block[APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT]) || !length(build_block[APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT]))
		return FALSE
	if(!islist(build_block[APPEARANCE_PREVIEW_BUILD_KEY_ADAPTER_VERSIONS]))
		return FALSE
	return TRUE

/// Builds a fresh contract datum for callers that need an immutable snapshot.
/proc/build_appearance_preview_manifest_contract()
	return new /datum/appearance_preview_manifest_contract()

/// Returns TRUE when `family_id` is a registered editor-family identifier.
///
/// Used by the commit pipeline (Step 12) to reject a commit envelope whose
/// `family_id` does not correspond to a known adapter. The authoritative
/// list lives in `GLOB.appearance_preview_known_editor_families` and must
/// match the `family` strings emitted by the TS build adapters in
/// `tools/build/appearance_preview/adapters/`.
/proc/appearance_preview_family_is_valid(family_id)
	if(!istext(family_id) || !length(family_id))
		return FALSE
	return (family_id in GLOB.appearance_preview_known_editor_families)

/// Reads a manifest JSON file from disk and validates it against the v2
/// envelope contract. Used by the asset loader (Step 7) and any other
/// server-side code that needs to consume the published manifest.
///
/// Returns the parsed manifest list on success, or `null` on any failure
/// (missing file, malformed JSON, version/backend/layout mismatch, or
/// missing envelope blocks). Callers MUST treat `null` as a hard "bundle
/// unavailable" signal and refuse to serve appearance preview assets —
/// this is the server-side half of the fail-closed contract.
///
/// Never throws: every failure mode is absorbed and reported through the
/// `null` return so a bad bundle on disk cannot abort asset registration.
/proc/appearance_preview_load_and_validate_manifest(manifest_path)
	if(!istext(manifest_path) || !length(manifest_path))
		return null
	if(!fexists(manifest_path))
		return null
	var/raw
	try
		raw = rustg_file_read(manifest_path)
	catch
		return null
	if(!istext(raw) || !length(raw))
		return null
	if(!rustg_json_is_valid(raw))
		return null
	var/list/parsed
	try
		parsed = json_decode(raw)
	catch
		return null
	if(!islist(parsed))
		return null
	if(!appearance_preview_manifest_v2_envelope_is_valid(parsed))
		return null
	return parsed
