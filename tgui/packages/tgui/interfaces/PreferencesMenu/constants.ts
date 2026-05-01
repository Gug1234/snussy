/**
 * @file constants.ts
 * @description Single source of truth for client-side prefs key strings
 * and the category/row taxonomy. MUST stay byte-for-byte aligned with
 * the DM defines in `code/__DEFINES/preferences_tgui.dm` (PREF_KEY_*).
 *
 * Adding a new pref:
 *   1. Add `#define PREF_KEY_FOO "foo"` to the DM defines header.
 *   2. Add `FOO: 'foo'` here under the matching category section.
 *   3. Register the setter in `prefs_set_pref_dispatch.dm`.
 *   4. Add a row to the relevant body module (Steps 10+).
 *
 * The string literals below are the exact tokens exchanged via
 * `act('set_pref', { key, value })`; never typo-tolerate them.
 */

/**
 * Top-level shell category ids. Drive the LeftColumn dropdown and
 * MiddleColumn body registry. Identity is the default landing
 * category per the spec critical path (§1.3).
 */
export const PREFS_CATEGORIES = {
  IDENTITY: 'identity',
  BODY: 'body',
  CLASS_STATS: 'class_stats',
  INTIMACY: 'intimacy',
  OPTIONS: 'options',
  KEYBINDINGS: 'keybindings',
} as const;

export type PrefsCategoryId =
  (typeof PREFS_CATEGORIES)[keyof typeof PREFS_CATEGORIES];

/**
 * Display labels for each category id. Kept here (not in TSX) so the
 * LeftColumn and TopBar can render labels without duplicating strings.
 */
export const PREFS_CATEGORY_LABELS: Record<PrefsCategoryId, string> = {
  identity: 'Identity',
  body: 'Body',
  class_stats: 'Class & Stats',
  intimacy: 'Intimacy',
  options: 'Options',
  keybindings: 'Keybindings',
};

/**
 * Category render order. Categories not in this list render after the
 * known set in insertion order; out-of-order categories are a bug.
 */
export const PREFS_CATEGORY_ORDER: readonly PrefsCategoryId[] = [
  PREFS_CATEGORIES.IDENTITY,
  PREFS_CATEGORIES.BODY,
  PREFS_CATEGORIES.CLASS_STATS,
  PREFS_CATEGORIES.INTIMACY,
  PREFS_CATEGORIES.OPTIONS,
  PREFS_CATEGORIES.KEYBINDINGS,
];

/**
 * Pref-key string constants. Mirror PREF_KEY_* defines verbatim.
 * Grouped by category for grep-ability; the grouping is informational
 * only — server dispatch is flat over GLOB.prefs_setter_table.
 */
export const PREF_KEYS = {
  // Identity (Step 10)
  REAL_NAME: 'real_name',
  NICKNAME: 'nickname',
  NICKNAME_COLOR: 'nickname_color',
  GENDER: 'gender',
  PRONOUNS: 'pronouns',
  VOICE_PACK: 'voice_pack',
  VOICE_TYPE: 'voice_type',
  VOICE_COLOR: 'voice_color',
  VOICE_PITCH_X100: 'voice_pitch_x100',
  CHAR_ACCENT: 'char_accent',
  BARK_ID: 'bark_id',
  BARK_SPEED: 'bark_speed',
  HEAR_BARKS: 'hear_barks',
  PATREON_SAY_COLOR: 'patreon_say_color',
  PATREON_SAY_COLOR_ENABLED: 'patreon_say_color_enabled',
  ORIGIN: 'origin',
  FAMILY: 'family',
  SETSPOUSE: 'setspouse',
  GENDER_CHOICE: 'gender_choice',
  SONG_ARTIST: 'song_artist',
  SONG_TITLE: 'song_title',
  FLAVORTEXT: 'flavortext',
  OOC_NOTES: 'ooc_notes',
  NSFW_FLAVORTEXT: 'nsfw_flavortext',
  ERP_OOC_NOTES: 'erp_ooc_notes',

  // Body
  TAUR_CONSISTENT_AROUSAL: 'taur_consistent_arousal',
  TAUR_MIRROR_EW: 'taur_mirror_ew',
  TESTICLE_MIRROR_EW: 'testicle_mirror_ew',
  // Body (Step 11 part A)
  SPECIES: 'species',
  BODY_TYPE: 'body_type',
  SKIN_TONE: 'skin_tone',
  EYE_COLOR: 'eye_color',
  HETEROCHROMIA_ENABLED: 'heterochromia_enabled',
  SECOND_EYE_COLOR: 'second_eye_color',
  HAIRSTYLE: 'hairstyle',
  HAIR_COLOR: 'hair_color',
  FACIAL_HAIRSTYLE: 'facial_hairstyle',
  FACIAL_HAIR_COLOR: 'facial_hair_color',
  DETAIL: 'detail',
  DETAIL_COLOR: 'detail_color',
  ACCESSORY: 'accessory',
  BODY_SIZE_X100: 'body_size_x100',
  // Body (Step 12 part B)
  MUTANT_COLOR_1: 'mutant_color_1',
  MUTANT_COLOR_2: 'mutant_color_2',
  MUTANT_COLOR_3: 'mutant_color_3',
  ETHEREAL_COLOR: 'ethereal_color',
  TAUR_TYPE: 'taur_type',
  TAUR_COLOR: 'taur_color',
  TAUR_MARKINGS_COLOR: 'taur_markings_color',
  TAUR_TERTIARY_COLOR: 'taur_tertiary_color',
  USE_TAUR_GENITAL_SPRITES: 'use_taur_genital_sprites',

  // Class & Stats — populated in Step 13.
  PER_CHAR_HARDMODE: 'per_char_hardmode',
  // Class & Stats deviation pass (C3/C4/C5) — inline pickers.
  JOBLESS_ROLE: 'joblessrole',
  STATPACK: 'statpack',
  VIRTUE: 'virtue',
  VIRTUE_TWO: 'virtue_two',
  VICE_1: 'vice_1',
  VICE_2: 'vice_2',
  VICE_3: 'vice_3',
  VICE_4: 'vice_4',
  VICE_5: 'vice_5',
  EXTRA_LANGUAGE_1: 'extra_language_1',
  EXTRA_LANGUAGE_2: 'extra_language_2',

  // Intimacy / Cursed collar
  CURSED_COLLAR_OPT: 'cursed_collar_opt',
  CURSED_COLLAR_MASTER_MODE: 'cursed_collar_master_mode',
  CURSED_COLLAR_SPECIFIED_NAME: 'cursed_collar_specified_name',

  // Options (per-account UI toggles, savefile root scope)
  UI_PREFER_CLASSIC_HTML: 'ui_prefer_classic_html',
  UI_LOBBY_BUTTON_CLASSIC: 'ui_lobby_button_classic',

  // Identity extras — Misc / Food / Gnoll / Familiar / Jelly.
  AGE: 'age',
  DNR: 'dnr_pref',
  DOMHAND: 'domhand',
  CULINARY_FAV_FOOD: 'culinary_fav_food',
  CULINARY_FAV_DRINK: 'culinary_fav_drink',
  CULINARY_HATED_FOOD: 'culinary_hated_food',
  CULINARY_HATED_DRINK: 'culinary_hated_drink',

  GNOLL_NAME: 'gnoll_name',
  GNOLL_PRONOUNS: 'gnoll_pronouns',
  GNOLL_PELT: 'gnoll_pelt',
  GNOLL_PENIS: 'gnoll_penis',
  GNOLL_VAGINA: 'gnoll_vagina',
  GNOLL_BREASTS: 'gnoll_breasts',
  GNOLL_HEIGHT: 'gnoll_height',
  GNOLL_BODY: 'gnoll_body',
  GNOLL_FUR: 'gnoll_fur',
  GNOLL_VOICE: 'gnoll_voice',
  GNOLL_MUZZLE: 'gnoll_muzzle',
  GNOLL_EXPRESSION: 'gnoll_expression',

  FAMILIAR_NAME: 'familiar_name',
  FAMILIAR_PRONOUNS: 'familiar_pronouns',
  FAMILIAR_SPECIE: 'familiar_specie',
  FAMILIAR_FLAVORTEXT: 'familiar_flavortext',
  FAMILIAR_OOC_NOTES: 'familiar_ooc_notes',
  FAMILIAR_HEADSHOT: 'familiar_headshot_link',

  JELLY_ENABLED: 'jelly_controller_enabled',
  JELLY_NAME: 'jelly_name',
  JELLY_PRONOUNS: 'jelly_pronouns',
  JELLY_FLAVORTEXT: 'jelly_flavortext',
  JELLY_OOC_NOTES: 'jelly_ooc_notes',

  // Identity extras v2 — plan deviations I3/I4/I5/I7/I8/I9 + IN5/IN6.
  BARK_PITCH_X100: 'bark_pitch_x100',
  BARK_VARIANCE_X100: 'bark_variance_x100',
  FAITH: 'faith',
  PATRON: 'patron',
  RUMOR: 'rumor',
  NOBLE_GOSSIP: 'noble_gossip',
  OOC_IMAGE_URL: 'ooc_image_url',
  NSFW_OOC_IMAGE_URL: 'nsfw_ooc_image_url',
  COMBAT_MUSIC_TRACK: 'combat_music_track',
  HEADSHOT_LINK: 'headshot_link',
  CHATHEADSHOT_ENABLED: 'chatheadshot_enabled',
  CURSED_ENABLED: 'cursed_enabled',
  EXTREME_ERP: 'extreme_erp',
  EDGING: 'edging',
  INTIMATE_ENABLED: 'intimate_enabled',
  INTIMATE_REACTION: 'intimate_reaction_enabled',
  SHOW_INTIMATE_EXAMINE: 'show_intimate_examine',
  CHASTITY_HARDMODE: 'chastity_hardmode',
  CHASTITY_ENABLED: 'pref_chastity_enabled',
  CHASTITY_FLAT: 'pref_chastity_flat',
  CHASTITY_ANAL: 'pref_chastity_anal',
  CHASTITY_SPIKED: 'pref_chastity_spiked',
  CHASTITY_LOCKED: 'pref_chastity_locked',
  CHASTITY_SPAWN_KEY: 'pref_chastity_spawn_key',
  CHASTITY_RANDOM_KEYS: 'pref_chastity_random_keys',
  CHASTITY_KEY_STASHES: 'pref_chastity_key_stashes',
  // Body deviation pass (B1) — race/nobility title.
  RACE_TITLE: 'race_title',
  // Body deviation pass (B7) — inline genital toggles. These are
  // customizer_entry-backed shadow prefs; see genital_toggles.dm.
  GENITAL_PENIS_ENABLED: 'genital_penis_enabled',
  GENITAL_PENIS_SIZE: 'genital_penis_size',
  GENITAL_PENIS_FUNCTIONAL: 'genital_penis_functional',
  GENITAL_PENIS_SHEATHED: 'genital_penis_sheathed',
  GENITAL_TESTICLES_ENABLED: 'genital_testicles_enabled',
  GENITAL_TESTICLES_SIZE: 'genital_testicles_size',
  GENITAL_TESTICLES_VIRILITY: 'genital_testicles_virility',
  GENITAL_BREASTS_ENABLED: 'genital_breasts_enabled',
  GENITAL_BREASTS_SIZE: 'genital_breasts_size',
  GENITAL_BREASTS_LACTATING: 'genital_breasts_lactating',
  GENITAL_VAGINA_ENABLED: 'genital_vagina_enabled',
  GENITAL_VAGINA_FERTILITY: 'genital_vagina_fertility',
} as const;

export type PrefKey = (typeof PREF_KEYS)[keyof typeof PREF_KEYS];

/**
 * Cursed collar opt enum mirroring CURSED_COLLAR_OPT_* defines.
 */
export const CURSED_COLLAR_OPT = {
  NONE: 0,
  COLLAR: 1,
  CHASTITY_DEVICE: 2,
} as const;

/**
 * Cursed collar master-mode enum mirroring CURSED_COLLAR_MASTER_* defines.
 */
export const CURSED_COLLAR_MASTER = {
  SELF: 0,
  RANDOM: 1,
  SPECIFIED: 2,
} as const;

/**
 * Bottom-bar action keys (Step 15). Routed through the disjoint
 * GLOB.prefs_action_table — never use these via `set_pref`.
 */
export const PREFS_ACTIONS = {
  JOIN_ROUND: 'join_round',
  OBSERVE: 'observe',
  JOIN_MIGRANT: 'join_migrant',
} as const;
