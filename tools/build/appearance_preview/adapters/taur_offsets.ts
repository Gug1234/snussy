/**
 * tools/build/appearance_preview/adapters/taur_offsets.ts
 *
 * Adapter for the taur genital offset preview family (v3 convention-enum).
 * Manifest keys are the real DMI state names verbatim so the preview
 * displays exactly what the runtime composes — no bespoke renaming.
 *
 * ## Convention (authoritative)
 *
 * Source DMIs swapped in by `generate_taur_genital_overlay`:
 *   - penis     -> `modular/icons/obj/lewd/taur_pintle.dmi`
 *   - testicles -> `modular/icons/obj/lewd/taur_gonads.dmi`
 *   - vagina    -> `modular/icons/obj/lewd/taur_nethers.dmi`
 *
 * State-name format (runtime composition via `get_icon_state` +
 * `generate_icon_state` from `_sprite_accessory.dm`):
 *
 *   penis   : `<shape>_<erect>_<size>_<LAYER>_<colorkey>`
 *             shape  in { human, knotted, barbknot, flared, flaredknot,
 *                         hemi, hemiknot, tapered, taperedknot, tentacle }
 *             erect  in { 1 (flaccid/partial), 2 (hard) }
 *             size   in { 1, 2, 3 } (runtime caps at 2; DMI contains 3)
 *             LAYER  in { FRONT, BEHIND }
 *             colorkey in { 1, 2 } (2 only populated for sheath/slit)
 *
 *   penis BEHIND fallback: the DMI stores a single size-invariant BEHIND
 *   tile per shape as `<shape>_<N>_BEHIND_1` (see BEHIND_EROS map below).
 *
 *   sheath  : `sheath_<arousal>_FRONT_<colorkey>`, arousal in { 1, 2 },
 *             both colour keys populated.
 *   slit    : `slit_<arousal>_FRONT_<colorkey>`, partial coverage
 *             (see SLIT_STATES).
 *
 *   vagina  : `<shape>_FRONT`, shape in { human, hairy, spade, furred,
 *             gaping, cloaca, trimmed }.
 *
 *   testicles: `pair_<size>_<LAYER>`, size in 0..3, LAYER in { ADJ, BEHIND }.
 *
 * Direction handling: taur DMIs encode direction in the state name (not in
 * DMI dir slots), so every manifest entry declares a single `"s"`
 * direction and the client composes the runtime state name per render.
 */

import { registerAdapter } from "./registry";
import { dmiSourceEntry } from "./source_scan";
import type {
  Adapter,
  AdapterDiscovery,
  DiscoveredState,
  PreviewMetadata,
} from "./contract";
import type { AdapterRecord, DirectionKey } from "../types";

const FAMILY = "taur_offsets";

const RECORD: AdapterRecord = {
  family: FAMILY,
  adapterVersion: "3.0.0",
  tileSize: { width: 32, height: 32 },
  directionOrder: ["s"] as const,
};

const DMI_PENIS = "modular/icons/obj/lewd/taur_pintle.dmi";
const DMI_TESTICLES = "modular/icons/obj/lewd/taur_gonads.dmi";
const DMI_VAGINA = "modular/icons/obj/lewd/taur_nethers.dmi";

const ALLOWED_DMIS: ReadonlySet<string> = new Set([
  DMI_PENIS,
  DMI_TESTICLES,
  DMI_VAGINA,
]);

const DIRECTIONS: readonly DirectionKey[] = RECORD.directionOrder;

// ── Penis ────────────────────────────────────────────────────────────
/** Shape order. Drives the manifest-visible ordering. */
const PENIS_SHAPES: readonly string[] = [
  "human",
  "knotted",
  "barbknot",
  "flared",
  "flaredknot",
  "hemi",
  "hemiknot",
  "tapered",
  "taperedknot",
  "tentacle",
];

const PENIS_EROS: readonly number[] = [1, 2];
const PENIS_SIZES: readonly number[] = [1, 2, 3];
const PENIS_COLOR_KEYS: readonly number[] = [1]; // `_2` absent for non-sheath/slit.

/**
 * Per-shape BEHIND fallback state. DMI authors a single size-invariant
 * BEHIND tile per shape; the number encodes the authoring sprite
 * (knotted's is labelled `_3_BEHIND_1`, all others `_1_BEHIND_1`).
 */
const BEHIND_EROS: Record<string, number> = {
  human: 1,
  knotted: 3,
  barbknot: 1,
  flared: 1,
  flaredknot: 1,
  hemi: 1,
  hemiknot: 1,
  tapered: 1,
  taperedknot: 1,
  tentacle: 1,
};

// ── Sheath / slit ────────────────────────────────────────────────────
/**
 * Sheath has both colour layers for both arousal stages.
 * Slit has partial coverage — `slit_1_FRONT_1` is absent in the DMI.
 */
const SHEATH_STATES: readonly string[] = [
  "sheath_1_FRONT_1",
  "sheath_1_FRONT_2",
  "sheath_2_FRONT_1",
  "sheath_2_FRONT_2",
];

const SLIT_STATES: readonly string[] = [
  "slit_1_FRONT_2",
  "slit_2_FRONT_1",
  "slit_2_FRONT_2",
];

// ── Vagina ───────────────────────────────────────────────────────────
const VAGINA_SHAPES: readonly string[] = [
  "human",
  "hairy",
  "spade",
  "furred",
  "gaping",
  "cloaca",
  "trimmed",
];

// ── Testicles ────────────────────────────────────────────────────────
const TESTICLE_SIZES: readonly number[] = [0, 1, 2, 3];
const TESTICLE_LAYERS: readonly string[] = ["ADJ", "BEHIND"];

// ── State enumeration ────────────────────────────────────────────────

interface EnumeratedState {
  key: string;
  iconFile: string;
}

function enumerateStates(): readonly EnumeratedState[] {
  const out: EnumeratedState[] = [];

  // Penis FRONT — deterministic shape × erect × size × colorkey.
  for (const shape of PENIS_SHAPES) {
    for (const erect of PENIS_EROS) {
      for (const size of PENIS_SIZES) {
        for (const ck of PENIS_COLOR_KEYS) {
          out.push({
            key: `${shape}_${erect}_${size}_FRONT_${ck}`,
            iconFile: DMI_PENIS,
          });
        }
      }
    }
  }

  // Penis BEHIND fallback — one per shape.
  for (const shape of PENIS_SHAPES) {
    const n = BEHIND_EROS[shape];
    out.push({
      key: `${shape}_${n}_BEHIND_1`,
      iconFile: DMI_PENIS,
    });
  }

  // Sheath / slit.
  for (const k of SHEATH_STATES) out.push({ key: k, iconFile: DMI_PENIS });
  for (const k of SLIT_STATES) out.push({ key: k, iconFile: DMI_PENIS });

  // Vagina.
  for (const shape of VAGINA_SHAPES) {
    out.push({ key: `${shape}_FRONT`, iconFile: DMI_VAGINA });
  }

  // Testicles.
  for (const size of TESTICLE_SIZES) {
    for (const layer of TESTICLE_LAYERS) {
      out.push({ key: `pair_${size}_${layer}`, iconFile: DMI_TESTICLES });
    }
  }

  return out;
}

const ALL_STATES: readonly EnumeratedState[] = enumerateStates();
const ORDERED_KEYS: readonly string[] = ALL_STATES.map((s) => s.key);

/**
 * Canonical DMI state-name patterns. `normalizeStateName` uses these to
 * reject accidental foreign keys, typos, and pre-v3 legacy names
 * (`taur_penis`, `taur_testicles`, etc).
 */
const STATE_PATTERNS: readonly RegExp[] = [
  // Penis shape states: <shape>_<erect>_<size>_<LAYER>_<ck> OR BEHIND fallback.
  /^(human|knotted|barbknot|flared|flaredknot|hemi|hemiknot|tapered|taperedknot|tentacle)_\d+_(\d+_)?(FRONT|BEHIND)_\d+$/,
  // Sheath / slit.
  /^(sheath|slit)_[12]_FRONT_[12]$/,
  // Vagina.
  /^(human|hairy|spade|furred|gaping|cloaca|trimmed)_FRONT$/,
  // Testicles.
  /^pair_[0-3]_(ADJ|BEHIND)$/,
];

export const taurOffsetsAdapter: Adapter = {
  record: RECORD,

  discoverSources(repoRoot: string): AdapterDiscovery {
    const sources = Array.from(ALLOWED_DMIS)
      .sort()
      .map((dmi) => dmiSourceEntry(repoRoot, dmi, FAMILY));

    const states: DiscoveredState[] = ALL_STATES.map((entry) => ({
      iconState: entry.key,
      iconFile: entry.iconFile,
      sourceState: entry.key,
      directions: DIRECTIONS,
    }));

    return { states, sources };
  },

  normalizeStateName(raw: string): string | null {
    if (typeof raw !== "string") return null;
    for (const pat of STATE_PATTERNS) {
      if (pat.test(raw)) return raw;
    }
    return null;
  },

  orderStates(keys: readonly string[]): readonly string[] {
    const present = new Set(keys);
    const ordered: string[] = ORDERED_KEYS.filter((k) => present.has(k));
    const extras = keys
      .filter((k) => !ORDERED_KEYS.includes(k))
      .slice()
      .sort();
    return [...ordered, ...extras];
  },

  validateState(state: DiscoveredState): readonly string[] {
    const errors: string[] = [];
    if (!ALLOWED_DMIS.has(state.iconFile)) {
      errors.push(
        `state "${state.iconState}" has unexpected iconFile ${state.iconFile}; ` +
          `allowed: ${Array.from(ALLOWED_DMIS).sort().join(", ")}`,
      );
    }
    if (!this.normalizeStateName(state.iconState)) {
      errors.push(
        `state "${state.iconState}" does not match any canonical ` +
          `taur DMI state-name pattern`,
      );
    }
    if (state.variants) {
      errors.push(
        `state "${state.iconState}" declares variants; ` +
          `v3 taur states are flat DMI mirrors with no variant slots`,
      );
    }
    return errors;
  },

  previewMetadata(discovery: AdapterDiscovery): PreviewMetadata {
    const ordered = this.orderStates(
      discovery.states.map((s) => s.iconState),
    );
    return {
      categories: [
        {
          key: "intimate_accessory",
          scope: "family",
          states: ordered,
        },
      ],
    };
  },
};

registerAdapter(taurOffsetsAdapter);
