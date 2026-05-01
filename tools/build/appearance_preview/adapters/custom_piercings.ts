/**
 * tools/build/appearance_preview/adapters/custom_piercings.ts
 *
 * Adapter for the custom piercing sticker preview family. Mirrors the
 * authoritative sticker registry defined in
 * `modular/code/datums/custom_piercings/sticker_registry.dm` (proc
 * `init_custom_piercing_sticker_registry`). Source DMI is
 * `modular/icons/obj/lewd/intimate_stickers.dmi`
 * (the `CUSTOM_PIERCING_STICKER_ICON` define).
 *
 * Per the DMI convention documented in the registry header:
 *   - `<id>_metal` — greyscale metal mask, always present.
 *   - `<id>_gem`   — greyscale gem mask, present only when `has_gem = TRUE`.
 *   - the un-suffixed base state is *not* used by the renderer.
 *
 * Canonical state key convention used by this adapter:
 *   - `piercing_<id>_metal` for the metal layer.
 *   - `piercing_<id>_gem`   for the gem layer (when applicable).
 * Metal states with a gem expose `variants: { gem: "piercing_<id>_gem" }`
 * so the runtime resolves both layers from a single lookup.
 *
 * Direction handling: 4-direction sticker authoring is purely informational
 * on the DM side (the renderer treats 1-dir and 4-dir DMIs identically).
 * In the manifest we always declare the full direction set; the iconforge
 * pack pass reads whichever frames the DMI actually contains.
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

const FAMILY = "custom_piercings";

const RECORD: AdapterRecord = {
  family: FAMILY,
  adapterVersion: "1.0.0",
  tileSize: { width: 32, height: 32 },
  directionOrder: ["s", "n", "e", "w"] as const,
};

/** Source DMI path (== DM-side `CUSTOM_PIERCING_STICKER_ICON`). */
const SOURCE_DMI = "modular/icons/obj/lewd/intimate_stickers.dmi";

const DIRECTIONS: readonly DirectionKey[] = RECORD.directionOrder;

/**
 * Sticker registry mirror. Order matches `init_custom_piercing_sticker_registry`
 * so the runtime picker order stays in lockstep with the DM-side registry.
 *
 * IMPORTANT: this list must stay in sync with the DM registry. A drift
 * detector belongs in Step 14's adapter tests; this file is the canonical
 * build-side mirror.
 */
interface StickerEntry {
  id: string;
  hasGem: boolean;
  /** True if the source DMI authored 4-direction frames. Informational. */
  directional: boolean;
}

const STICKERS: readonly StickerEntry[] = [
  // All 20 stickers are now authored as 4-direction metal+gem pairs on the
  // DMI (40 states total). Both fields stay in the schema so a future
  // regression back to 1-dir / no-gem art is caught by the drift detector
  // against `sticker_registry.dm`.
  // Studs.
  { id: "stud", hasGem: true, directional: true },
  // Hoops.
  { id: "hoop_small", hasGem: true, directional: true },
  { id: "hoop_large", hasGem: true, directional: true },
  // Bars.
  { id: "straightbar", hasGem: true, directional: true },
  { id: "barbell", hasGem: true, directional: true },
  // Rings.
  { id: "ring", hasGem: true, directional: true },
  { id: "vertical_ring", hasGem: true, directional: true },
  { id: "thick_ring", hasGem: true, directional: true },
  { id: "large_thick_ring", hasGem: true, directional: true },
  // Cockrings.
  { id: "cockring_small", hasGem: true, directional: true },
  { id: "cockring_medium", hasGem: true, directional: true },
  { id: "cockring_large", hasGem: true, directional: true },
  // Plugs.
  { id: "plug", hasGem: true, directional: true },
  { id: "heartplug", hasGem: true, directional: true },
  // Novelty.
  { id: "cross", hasGem: true, directional: true },
  { id: "bell", hasGem: true, directional: true },
  { id: "chain", hasGem: true, directional: true },
  { id: "thin_chain", hasGem: true, directional: true },
  // Bands.
  { id: "armband", hasGem: true, directional: true },
  { id: "legband", hasGem: true, directional: true },
];

/** Compose the canonical metal-layer state key. */
function metalKey(id: string): string {
  return `piercing_${id}_metal`;
}

/** Compose the canonical gem-layer state key. */
function gemKey(id: string): string {
  return `piercing_${id}_gem`;
}

export const customPiercingsAdapter: Adapter = {
  record: RECORD,

  discoverSources(repoRoot: string): AdapterDiscovery {
    const source = dmiSourceEntry(repoRoot, SOURCE_DMI, FAMILY);
    const states: DiscoveredState[] = [];

    for (const sticker of STICKERS) {
      const metalState = metalKey(sticker.id);
      const flags: string[] = [];
      if (sticker.directional) flags.push("directional_authored");

      if (sticker.hasGem) {
        const gemState = gemKey(sticker.id);
        states.push({
          iconState: metalState,
          iconFile: SOURCE_DMI,
          // The on-disk icon-state matches the canonical key here; the
          // `piercing_` prefix is the manifest-side namespace, but on the
          // DMI the state is stored under the same name (e.g. `stud_metal`).
          // Declare the on-disk name explicitly so iconforge looks up the
          // right tile.
          sourceState: `${sticker.id}_metal`,
          directions: DIRECTIONS,
          variants: { gem: gemState },
          flags: flags.length > 0 ? flags : undefined,
        });
        states.push({
          iconState: gemState,
          iconFile: SOURCE_DMI,
          sourceState: `${sticker.id}_gem`,
          directions: DIRECTIONS,
          flags: flags.length > 0 ? flags : undefined,
        });
      } else {
        states.push({
          iconState: metalState,
          iconFile: SOURCE_DMI,
          sourceState: `${sticker.id}_metal`,
          directions: DIRECTIONS,
          flags: flags.length > 0 ? flags : undefined,
        });
      }
    }

    return {
      states,
      sources: [source],
    };
  },

  /**
   * Canonical sticker keys are `piercing_<id>_metal` or `piercing_<id>_gem`.
   * Anything else is rejected — this catches typos and the un-suffixed base
   * state from leaking into the manifest.
   */
  normalizeStateName(raw: string): string | null {
    if (typeof raw !== "string") return null;
    if (!/^piercing_[a-z][a-z0-9_]*_(metal|gem)$/.test(raw)) return null;
    return raw;
  },

  /**
   * Deterministic ordering: by sticker registry order, with the metal layer
   * preceding its gem sibling. Unknown keys sort to the end alphabetically.
   */
  orderStates(keys: readonly string[]): readonly string[] {
    const expected: string[] = [];
    for (const sticker of STICKERS) {
      expected.push(metalKey(sticker.id));
      if (sticker.hasGem) expected.push(gemKey(sticker.id));
    }
    const present = new Set(keys);
    const ordered = expected.filter((k) => present.has(k));
    const extras = keys
      .filter((k) => !expected.includes(k))
      .slice()
      .sort();
    return [...ordered, ...extras];
  },

  validateState(state: DiscoveredState): readonly string[] {
    const errors: string[] = [];
    if (state.iconFile !== SOURCE_DMI) {
      errors.push(
        `state "${state.iconState}" must come from ${SOURCE_DMI}, ` +
          `got ${state.iconFile}`,
      );
    }
    // Only metal states are permitted to declare a `gem` variant; gem
    // states must not chain further variants.
    if (state.variants) {
      if (!state.iconState.endsWith("_metal")) {
        errors.push(
          `state "${state.iconState}" declares variants but only ` +
            `_metal states may.`,
        );
      } else {
        const allowed = new Set(["gem"]);
        for (const name of Object.keys(state.variants)) {
          if (!allowed.has(name)) {
            errors.push(
              `state "${state.iconState}" declares unknown variant "${name}".`,
            );
          }
        }
      }
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
          key: "sticker",
          scope: "catalog",
          states: ordered,
        },
      ],
    };
  },
};

registerAdapter(customPiercingsAdapter);
