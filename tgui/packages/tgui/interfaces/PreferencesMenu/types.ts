/**
 * @file types.ts
 * @description Shared TypeScript types for the PreferencesMenu shell
 * (Step 7 rebuild — 3-column Elden-Ring layout).
 *
 * The 7-tab shape from Phase 1 is retained for compatibility with the
 * server's `set_active_tab` envelope (used by the preview pipeline to
 * select `active_editor_family`). New shell routing happens through
 * `PrefsCategoryId` / row-id pairs registered via the MiddleColumn
 * body registry.
 */

import type { HybridGuideDescriptor } from '../../components/appearance-preview';
import type { PrefsCategoryId } from './constants';

/**
 * Server-side tab ids. Drive the preview pipeline's
 * `active_editor_family` selection. Adding a tab id here MUST be paired
 * with an entry in `GLOB.appearance_preview_valid_tabs` and a
 * corresponding strip-pass branch.
 */
export type PrefsTab =
  | 'info'
  | 'features'
  | 'taur_offsets'
  | 'markings'
  | 'intimate_accessories'
  | 'keybinds'
  | 'game';

/**
 * Flat snapshot of all registered prefs for the active slot. Keys are
 * the PREF_KEY_* string constants; values are post-validator raw values.
 * Built server-side by `build_prefs_snapshot()` (Step 4).
 */
export type PrefsSnapshot = Record<string, unknown>;

/**
 * Per-row stat-matrix payload (Step 5).
 */
export interface StatMatrixData {
  order: readonly string[];
  stats: readonly string[];
  rows: Record<string, Record<string, number>>;
  baseline: number;
  ranges?: Record<string, Record<string, [number, number]>>;
}

export interface TraitGainDescriptor {
  id: string;
  desc?: string | null;
}

export interface SkillGainDescriptor {
  name: string;
  level: string;
}

export interface AdvClassDescriptor {
  id: string;
  name: string;
  tutorial?: string | null;
  extra_context?: string | null;
  subclass_stats?: Record<string, number>;
  stat_ceilings?: Record<string, number>;
  traits?: readonly TraitGainDescriptor[];
  spellpoints?: number;
  languages?: readonly string[];
  stashed_items?: readonly string[];
  skills?: readonly SkillGainDescriptor[];
}

/**
 * Bottom-bar migrant wave descriptor (Step 15).
 */
export interface MigrantWaveDescriptor {
  id: string;
  label: string;
  slots_remaining: number;
}

/**
 * Compact regular-accessory offset scope row emitted by
 * `/datum/preferences/proc/get_intimate_accessory_offset_scope_data`.
 *
 * Phase one is x/y-only. Rows without `offset_editable=1` are still surfaced
 * so the UI can show the full regular accessory scope without pretending that
 * every selection has a resolvable overlay target.
 */
export interface IntimateAccessoryOffsetRowData {
  key: string;
  label: string;
  group: string | null;
  current: string;
  custom_key: string | null;
  offset_target_key: string | null;
  offset_editable: 0 | 1;
  offset_allowed_fields: readonly string[];
  offset_scope: 'phase_one_xy';
  offset_editor_family: 'intimate_accessory_offsets';
  slot_props?: Record<string, number> | null;
}

/**
 * Addendum Turn 4 (C6) — loadout catalogue row. One per
 * /datum/loadout_item subtype. `id` is the typepath string used as
 * the wire identifier for set_loadout_slot.
 */
export interface LoadoutCatalogRow {
  id: string;
  name: string;
  desc: string;
  category: string;
  triumph_cost: number;
  donator_locked: 0 | 1;
  accessible: 0 | 1;
}

/**
 * Addendum Turn 4 (C6) — live state of one of the 10 loadout slots.
 * `item_id` is null when the slot is empty; `name` falls back to the
 * item's default name when no per-slot override is set.
 */
export interface LoadoutSlot {
  slot: number;
  item_id: string | null;
  name: string | null;
  triumph_cost: number;
}

/**
 * Identity → Origin static descriptor (Step 10). One per /datum/origin
 * registered in GLOB.origins. Coordinates are in source pixels of the
 * existing `rwmap1.png` (550×400). The OriginMap widget rescales them
 * to its rendered dimensions.
 */
export interface OriginRegionDescriptor {
  /** Typepath string, e.g. `/datum/origin/otava`. */
  id: string;
  /** Human-readable name. */
  label: string;
  /** Source-pixel x. */
  x: number;
  /** Source-pixel y. */
  y: number;
}

/**
 * Generic `{id,label}` row used by Body category dropdowns (Step 11).
 * `id` is the wire token sent via `act('set_pref', { value: id })`;
 * `label` is the human-readable text rendered in the dropdown.
 */
export interface PrefsOption {
  id: string;
  label: string;
  color?: string;
}

/**
 * Backend payload exposed to the shell. Step 7 fields are the minimum
 * the new 3-column shell needs to render; Steps 8-15 extend in place.
 */
export interface PreferencesMenuData {
  character_preview_view: string;
  active_tab: PrefsTab;
  background_state: string;
  valid_tabs: readonly PrefsTab[];
  background_states: readonly string[];
  taur_offsets_available: 0 | 1;

  // --- Step 4 additions ---------------------------------------------------
  prefs?: PrefsSnapshot;

  // --- Step 5 additions ---------------------------------------------------
  stat_matrix?: StatMatrixData;

  // --- Step 6 additions ---------------------------------------------------
  prefs_bundle_children?: readonly string[];

  // --- Step 10 additions (Identity → Origin static data) ------------------
  origin_regions?: readonly OriginRegionDescriptor[];

  // --- Step 11 additions (Body category static data) ----------------------
  /** {id,label} pairs from get_selectable_species(). */
  species_options?: readonly PrefsOption[];
  /** {id,label,color} pairs from the current species get_skin_list(). */
  skin_tone_options?: readonly PrefsOption[];
  skin_tone_label?: string;
  skin_tone_enabled?: 0 | 1;
  mutant_color_enabled?: 0 | 1;
  mutant_color_partsonly_enabled?: 0 | 1;
  /** Hairstyle name list. Empty in Step 11; populated in Step 12 part B. */
  hairstyle_options?: readonly PrefsOption[];
  facial_hairstyle_options?: readonly PrefsOption[];
  /** Voice pack names — keys of GLOB.voice_packs_list. */
  voice_pack_options?: readonly string[];
  /** Body size slider bounds (×100, integer percent). */
  body_size_min_x100?: number;
  body_size_max_x100?: number;

  // --- Identity extras (Misc / Food / Gnoll / Familiar) -------------------
  age_options?: readonly string[];
  pronouns_options?: readonly string[];
  food_options?: readonly {
    id: string;
    label: string;
    quality?: string | number;
  }[];
  drink_options?: readonly {
    id: string;
    label: string;
    quality?: string | number;
  }[];
  gnoll_pelt_options?: readonly string[];
  gnoll_descriptor_options?: Record<string, readonly string[]>;
  familiar_species_options?: readonly string[];

  // --- Identity v2 (TB1 + I5/I9 + IN6) ------------------------------------
  faith_options?: readonly string[];
  patron_options_by_faith?: Record<
    string,
    readonly { id: string; label: string }[]
  >;
  combat_music_options?: readonly {
    id: string;
    label: string;
    shortname?: string;
    credits?: string;
  }[];
  gnoll_row_visible?: 0 | 1;
  familiar_row_visible?: 0 | 1;
  jelly_row_visible?: 0 | 1;
  intimacy_gated?: 0 | 1;
  chastity_available?: 0 | 1;
  chastity_has_penis?: 0 | 1;
  chastity_has_vagina?: 0 | 1;
  intimate_accessory_offset_allowed_fields?: readonly string[];
  intimate_accessory_offset_scope?: 'phase_one_xy';
  intimate_accessory_offset_rows?: readonly IntimateAccessoryOffsetRowData[];
  intimate_accessory_offset_active_target?: string | null;
  intimate_accessory_offset_descriptors?: Record<
    string,
    Partial<Record<'s' | 'n' | 'e' | 'w', HybridGuideDescriptor | null>>
  >;
  intimate_accessory_offset_min?: number;
  intimate_accessory_offset_max?: number;

  // --- Body B1 deviation (race/nobility title) ----------------------------
  /**
   * Per-species title bank. Keyed by the human-readable species name
   * (matches PrefsOption.label for species_options). Absent keys mean
   * the species has `use_titles = FALSE` and the Race row should hide
   * the title dropdown entirely.
   */
  species_race_titles?: Record<string, readonly string[]>;
  /** Human-readable species name → flavor description. */
  species_descriptions?: Record<string, string>;

  // --- Class & Stats C3/C4/C5 deviations (inline pickers) ------------------
  statpack_options?: readonly {
    id: string;
    label: string;
    desc: string;
    /** Assoc STAT_* → number or [min,max] range tuple. */
    stat_array: Record<string, number | readonly [number, number]>;
  }[];
  virtue_options?: readonly { id: string; label: string; desc: string }[];
  vice_options?: readonly { id: string; label: string; desc: string }[];
  language_options?: readonly { id: string; label: string }[];

  // --- Addendum Turn 3 (C1 class picker / C2 villain grid) ---------------
  /** Static job catalogue. One descriptor per /datum/job/roguetown in
   *  SSjob.occupations (sorted by cmp_job_display_asc). `category` is
   *  the human-readable department bucket ("Nobility", "Garrison",
   *  …, or "Other"). `banned` = 1 when the caller is jobbanned from
   *  this title; `selectable` = 0 when the classic availability checks
   *  render the row without a preference link. */
  job_options?: readonly {
    title: string;
    display_title: string;
    category: string;
    selection_color: string;
    description: string | null;
    job_stats?: Record<string, number>;
    stat_ceilings?: Record<string, number>;
    job_traits?: readonly TraitGainDescriptor[];
    advclasses?: readonly AdvClassDescriptor[];
    banned: 0 | 1;
    selectable?: 0 | 1;
    unavailable_reason?: string | null;
  }[];
  /** Static villain-antag catalogue. One descriptor per ROLE_* in
   *  GLOB.special_roles_rogue. `banned` includes the syndicate-wide
   *  jobban; `selectable` mirrors the classic account-age gate. */
  villain_role_options?: readonly {
    id: string;
    label: string;
    banned: 0 | 1;
    selectable?: 0 | 1;
    unavailable_reason?: string | null;
  }[];
  /** Per-tick snapshot of `job_preferences`: title → JP_LOW/MEDIUM/HIGH.
   *  Titles absent from this map are treated as level 0 (off). */
  job_preferences_map?: Record<string, number>;
  /** Per-tick snapshot of `be_special` — enabled villain role ids. */
  villain_roles_enabled?: readonly string[];

  // --- Body deviation pass (B7) — genital inline toggles ------------------
  /** Named penis/ball/breast size dropdowns. `id` is the integer size
   *  value sent over the wire; `label` is the human-readable name from
   *  the corresponding GLOB.named_*_sizes list. */
  named_penis_sizes?: readonly { id: number; label: string }[];
  named_ball_sizes?: readonly { id: number; label: string }[];
  named_breast_sizes?: readonly { id: number; label: string }[];
  /** Per-organ availability flag for the current species. 1 = the
   *  species declares a matching customizer; 0 = hide the row. */
  genital_customizers_available?: {
    penis: 0 | 1;
    testicles: 0 | 1;
    breasts: 0 | 1;
    vagina: 0 | 1;
  };

  // --- Phase 3 — pref_catalog manifest ------------------------------------
  /** Pre-baked customizer-choice thumbnail manifest. Emitted verbatim
   *  from `data/pref_catalog/manifest.json` via `ui_static_data`. The
   *  `<AccessoryPicker>` widget consumes this shape directly. Absent or
   *  empty when the materialize stage hasn't run yet. */
  pref_catalog_manifest?: import('./widgets').PrefCatalogManifest;

  /** Phase 4 — current entry-key selection per /datum/customizer_choice
   *  typepath the species owns. Values are the manifest entry keys
   *  (with `__sizeN` suffix where applicable) and may be null when the
   *  customizer is disabled or missing an accessory selection. */
  pref_catalog_selections?: Record<string, string | null>;
  /** Phase 4 — per-customizer accessory color slots. Each value is the
   *  list of `#RRGGBB` strings (one per `color_keys` slot); empty
   *  array when the customizer/accessory does not allow color
   *  customization. */
  pref_catalog_colors?: Record<string, readonly string[]>;

  // --- Addendum Turn 4 B3 — heterochromia -------------------------------
  /** 1 = the current species' eyes customizer_choice declares
   *  allows_heterochromia; 0 = hide the checkbox. Emitted in static
   *  data because it only changes on species switch. */
  eye_heterochromia_allowed?: 0 | 1;

  // --- Addendum Turn 4 C6 — inline loadout picker ------------------------
  /** Static catalogue of every /datum/loadout_item. `accessible=0`
   *  rows are donator-locked for this ckey and render disabled. */
  loadout_catalog?: readonly LoadoutCatalogRow[];
  /** Dynamic 10-slot state. Indices 0..9 correspond to slots 1..10. */
  loadout_slots?: readonly LoadoutSlot[];
  /** Point pool the loadout budget draws from. */
  loadout_points_total?: number;
  /** Sum of triumph_cost across currently-filled slots. */
  loadout_points_spent?: number;
  /** Actual triumph currency available to the caller. Informational —
   *  loadouts bill against loadout_points_*, not this. */
  triumphs_available?: number;

  // --- Step 7 additions (placeholders; populated by later steps) ----------
  active_slot?: number;
  standalone?: 0 | 1;

  // --- Step 15 additions (declared early so types stay one-source) --------
  can_join?: 0 | 1;
  join_block_reason?: string | null;
  migrant_waves?: readonly MigrantWaveDescriptor[];
  lobby_status?: string;

  // --- Step 14 additions (singleton-handshake resume hint) ----------------
  /** Route shell to this category on first paint after a resume reopen. */
  resume_category?: string;
  /** Route shell to this row on first paint after a resume reopen. */
  resume_row?: string;
  /** Monotonic token — bumped every resume emission so the TSX effect
   *  refires even when category/row match a prior hint. */
  resume_token?: number;
}

/**
 * Tab-definition shape used by the legacy preview pipeline only. The
 * new shell routes via `PrefsCategoryId` + row id, not via this shape.
 */
export interface PrefsTabDef {
  id: PrefsTab;
  label: string;
  component: React.ComponentType;
  visible?: (data: PreferencesMenuData) => boolean;
}

/**
 * Row descriptor consumed by LeftColumn. Body modules register a
 * concrete `PrefsBodyRegistration` (defined in MiddleColumn.tsx) that
 * extends this with the React component to render in the middle column.
 */
export interface PrefsRowDescriptor {
  /** Stable id; unique per category. */
  id: string;
  /** Display label rendered in the row list. */
  label: string;
  /**
   * Optional summary value rendered on the right of the row (the
   * "value slot" in §5.6). Implementation lands in Step 9.
   */
  rightColumnValue?: () => string;
}

/**
 * Per-category schema. Pure shape — populated implicitly via the
 * MiddleColumn registry (`getCategoryRows`).
 */
export interface PrefsCategory {
  id: PrefsCategoryId;
  label: string;
  rows: readonly PrefsRowDescriptor[];
}

/**
 * Per-tab draft-state shape (legacy; retained for the Phase 1 tab
 * bodies still living under `tabs/` until they are superseded by
 * Step 10-14 body modules).
 */
export interface TabDirtyState {
  dirty: boolean;
}
