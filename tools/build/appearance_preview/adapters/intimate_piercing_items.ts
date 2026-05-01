/**
 * tools/build/appearance_preview/adapters/intimate_piercing_items.ts
 *
 * Adapter for the nose + belly intimate-piercing mob overlays. These states
 * live on `modular/icons/obj/lewd/intimate_overlays.dmi` alongside the
 * pre-existing ear/breast/genital overlays, but they were authored late
 * (previously nose/belly piercings were examine-only / flavour-text only)
 * so they ship their own adapter rather than polluting the taur_offsets
 * family.
 *
 * ## States covered
 *
 *   nose_pierce, nose_pierce_gem
 *     — base + gem mask for `/obj/item/intimate_accessory/piercing/nose`.
 *
 *   belly_pierce, belly_pierce_gem, belly_pierce_psy, belly_pierce_zizo
 *     — base + gem mask + psydonic/zizite cross variants for
 *       `/obj/item/intimate_accessory/piercing/belly(/psydonic|/zizite)`.
 *
 * All states are 4-directional. Layering parallels piercing_ear: the
 * `_gem` mask is composed over the base metal tint; `_psy` / `_zizo` are
 * standalone variant states selected up-front by the sprite_accessory
 * based on the equipped item subtype.
 *
 * Category: `intimate_accessory` (shared with the taur + ear/breast
 * overlay families in the manifest; per-family scope keeps state lookups
 * unambiguous).
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

const FAMILY = "intimate_piercing_items";

const RECORD: AdapterRecord = {
  family: FAMILY,
  adapterVersion: "1.0.0",
  tileSize: { width: 32, height: 32 },
  directionOrder: ["s", "n", "e", "w"] as const,
};

const SOURCE_DMI = "modular/icons/obj/lewd/intimate_overlays.dmi";

const DIRECTIONS: readonly DirectionKey[] = RECORD.directionOrder;

/**
 * Canonical state list in manifest order. The metal base comes first, its
 * gem mask second, then any cross variants. This order drives
 * `orderStates` so picker UIs render deterministically.
 */
interface PiercingItemEntry {
  /** Base iconState (metal layer). Matches DMI state name verbatim. */
  base: string;
  /** Optional gem mask state. */
  gem?: string;
  /** Optional standalone variant states (psydonic/zizite crosses). */
  variants?: readonly string[];
}

const ENTRIES: readonly PiercingItemEntry[] = [
  {
    base: "nose_pierce",
    gem: "nose_pierce_gem",
  },
  {
    base: "belly_pierce",
    gem: "belly_pierce_gem",
    variants: ["belly_pierce_psy", "belly_pierce_zizo"],
  },
];

/** Flat list of every canonical state key this adapter emits. */
const ORDERED_KEYS: readonly string[] = (() => {
  const out: string[] = [];
  for (const entry of ENTRIES) {
    out.push(entry.base);
    if (entry.gem) out.push(entry.gem);
    if (entry.variants) out.push(...entry.variants);
  }
  return out;
})();

const VALID_KEYS: ReadonlySet<string> = new Set(ORDERED_KEYS);

export const intimatePiercingItemsAdapter: Adapter = {
  record: RECORD,

  discoverSources(repoRoot: string): AdapterDiscovery {
    const source = dmiSourceEntry(repoRoot, SOURCE_DMI, FAMILY);
    const states: DiscoveredState[] = [];

    for (const entry of ENTRIES) {
      // Metal base. When a gem mask is authored, expose it as a `gem`
      // variant so the runtime resolves both layers from one lookup —
      // mirrors the custom_piercings adapter convention.
      const baseState: DiscoveredState = {
        iconState: entry.base,
        iconFile: SOURCE_DMI,
        sourceState: entry.base,
        directions: DIRECTIONS,
      };
      if (entry.gem) {
        baseState.variants = { gem: entry.gem };
      }
      states.push(baseState);

      if (entry.gem) {
        states.push({
          iconState: entry.gem,
          iconFile: SOURCE_DMI,
          sourceState: entry.gem,
          directions: DIRECTIONS,
        });
      }

      if (entry.variants) {
        for (const variant of entry.variants) {
          states.push({
            iconState: variant,
            iconFile: SOURCE_DMI,
            sourceState: variant,
            directions: DIRECTIONS,
          });
        }
      }
    }

    return {
      states,
      sources: [source],
    };
  },

  normalizeStateName(raw: string): string | null {
    if (typeof raw !== "string") return null;
    return VALID_KEYS.has(raw) ? raw : null;
  },

  orderStates(keys: readonly string[]): readonly string[] {
    const present = new Set(keys);
    const ordered = ORDERED_KEYS.filter((k) => present.has(k));
    const extras = keys
      .filter((k) => !VALID_KEYS.has(k))
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
    if (!VALID_KEYS.has(state.iconState)) {
      errors.push(
        `state "${state.iconState}" is not a recognised ` +
          `intimate_piercing_items key`,
      );
    }
    // Only base states are permitted to declare a `gem` variant.
    if (state.variants) {
      const isBase = ENTRIES.some((e) => e.base === state.iconState);
      if (!isBase) {
        errors.push(
          `state "${state.iconState}" declares variants but only ` +
            `base metal states may.`,
        );
      } else {
        const allowed = new Set(["gem"]);
        for (const name of Object.keys(state.variants)) {
          if (!allowed.has(name)) {
            errors.push(
              `state "${state.iconState}" declares unknown variant ` +
                `"${name}".`,
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
          // Distinct category key per adapter: the manifest contract
          // (build.ts ~L187) forbids two adapters from claiming the same
          // category, and `intimate_accessory` is already owned by the
          // taur_offsets family.
          key: "intimate_piercing_items",
          scope: "family",
          states: ordered,
        },
      ],
    };
  },
};

registerAdapter(intimatePiercingItemsAdapter);
