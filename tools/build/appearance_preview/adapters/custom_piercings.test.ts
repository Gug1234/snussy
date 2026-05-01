/**
 * tools/build/appearance_preview/adapters/custom_piercings.test.ts
 *
 * Step 14 coverage for the custom piercing adapter. Verifies the adapter's
 * contract (record, discovery, normalization, ordering, metadata) AND acts
 * as a DRIFT DETECTOR against the authoritative DM-side sticker registry in
 * `modular/code/datums/custom_piercings/sticker_registry.dm`.
 *
 * The drift detector parses the DM registry block with a regex, extracts
 * every declared sticker id + has_gem flag, and compares the resulting set
 * to the adapter's output. This is the guard rail the Step 3 adapter header
 * pointed at: "A drift detector test belongs in Step 14". If a maintainer
 * adds a sticker to DM but forgets the adapter (or vice versa), this test
 * fails loudly.
 */

import { describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as path from "node:path";

import { customPiercingsAdapter } from "./custom_piercings";
import { validateDiscovery } from "./registry";

const REPO_ROOT = path.resolve(import.meta.dir, "..", "..", "..", "..");
const DM_REGISTRY_PATH = path.join(
  REPO_ROOT,
  "modular",
  "code",
  "datums",
  "custom_piercings",
  "sticker_registry.dm",
);

/** Shape of one entry extracted from the DM registry. */
interface DmStickerEntry {
  id: string;
  hasGem: boolean;
  directional: boolean;
}

/**
 * Parse the DM sticker registry block. The block is a list of
 *   new /datum/piercing_sticker("id", "Name", "category", has_gem, directional, list(...)),
 * entries. This regex is intentionally strict so a DM syntax change will
 * make us re-examine the parser.
 */
function parseDmRegistry(text: string): DmStickerEntry[] {
  const re =
    /new\s+\/datum\/piercing_sticker\s*\(\s*"([^"]+)"\s*,\s*"[^"]*"\s*,\s*"[^"]*"\s*,\s*(TRUE|FALSE)\s*,\s*(TRUE|FALSE)\s*,/g;
  const out: DmStickerEntry[] = [];
  let match: RegExpExecArray | null;
  while ((match = re.exec(text)) !== null) {
    out.push({
      id: match[1],
      hasGem: match[2] === "TRUE",
      directional: match[3] === "TRUE",
    });
  }
  return out;
}

describe("custom_piercings adapter record", () => {
  it("declares the expected family and tile contract", () => {
    expect(customPiercingsAdapter.record.family).toBe("custom_piercings");
    expect(customPiercingsAdapter.record.adapterVersion).toBe("1.0.0");
    expect(customPiercingsAdapter.record.tileSize).toEqual({
      width: 32,
      height: 32,
    });
    expect(customPiercingsAdapter.record.directionOrder).toEqual([
      "s",
      "n",
      "e",
      "w",
    ]);
  });
});

describe("custom_piercings discoverSources", () => {
  it("references exactly one source DMI", () => {
    const discovery = customPiercingsAdapter.discoverSources(REPO_ROOT);
    expect(discovery.sources).toHaveLength(1);
    expect(discovery.sources[0].path).toBe(
      "modular/icons/obj/lewd/intimate_stickers.dmi",
    );
  });

  it("emits a _metal state for every sticker", () => {
    const discovery = customPiercingsAdapter.discoverSources(REPO_ROOT);
    const metalKeys = discovery.states
      .map((s) => s.iconState)
      .filter((k) => k.endsWith("_metal"));
    // 20 stickers in the DM registry -> 20 _metal states.
    expect(metalKeys.length).toBe(20);
  });

  it("declares gem variants only on metal states", () => {
    const discovery = customPiercingsAdapter.discoverSources(REPO_ROOT);
    for (const state of discovery.states) {
      if (state.variants) {
        expect(state.iconState.endsWith("_metal")).toBe(true);
        expect(Object.keys(state.variants)).toEqual(["gem"]);
      }
    }
  });
});

describe("custom_piercings normalizeStateName", () => {
  it("accepts canonical keys", () => {
    expect(customPiercingsAdapter.normalizeStateName("piercing_stud_metal")).toBe(
      "piercing_stud_metal",
    );
    expect(customPiercingsAdapter.normalizeStateName("piercing_stud_gem")).toBe(
      "piercing_stud_gem",
    );
  });

  it("rejects the un-suffixed base state", () => {
    expect(customPiercingsAdapter.normalizeStateName("piercing_stud")).toBeNull();
  });

  it("rejects foreign prefixes", () => {
    expect(customPiercingsAdapter.normalizeStateName("taur_penis")).toBeNull();
    expect(customPiercingsAdapter.normalizeStateName("stud_metal")).toBeNull();
  });
});

describe("custom_piercings orderStates", () => {
  it("places the metal state before its gem sibling", () => {
    const ordered = customPiercingsAdapter.orderStates([
      "piercing_stud_gem",
      "piercing_stud_metal",
      "piercing_ring_gem",
      "piercing_ring_metal",
    ]);
    expect(ordered).toEqual([
      "piercing_stud_metal",
      "piercing_stud_gem",
      "piercing_ring_metal",
      "piercing_ring_gem",
    ]);
  });
});

describe("custom_piercings previewMetadata", () => {
  it("emits a single sticker category with catalog scope", () => {
    const discovery = customPiercingsAdapter.discoverSources(REPO_ROOT);
    const metadata = customPiercingsAdapter.previewMetadata(discovery);
    expect(metadata.categories).toHaveLength(1);
    expect(metadata.categories[0].key).toBe("sticker");
    expect(metadata.categories[0].scope).toBe("catalog");
  });
});

describe("custom_piercings passes registry validation", () => {
  it("validateDiscovery accepts the canonical output without error", () => {
    const discovery = customPiercingsAdapter.discoverSources(REPO_ROOT);
    expect(() =>
      validateDiscovery(customPiercingsAdapter, discovery),
    ).not.toThrow();
  });
});

describe("custom_piercings drift detector vs DM sticker_registry.dm", () => {
  const dmText = fs.readFileSync(DM_REGISTRY_PATH, "utf8");
  const dmEntries = parseDmRegistry(dmText);

  it("parses at least one DM entry (regex sanity check)", () => {
    expect(dmEntries.length).toBeGreaterThan(0);
  });

  it("ids and has_gem flags match between DM registry and adapter", () => {
    const discovery = customPiercingsAdapter.discoverSources(REPO_ROOT);

    // Build adapter view keyed by sticker id.
    const metalIds = new Set<string>();
    const gemIds = new Set<string>();
    for (const state of discovery.states) {
      const match = /^piercing_(.+)_(metal|gem)$/.exec(state.iconState);
      if (!match) continue;
      const [, id, kind] = match;
      if (kind === "metal") metalIds.add(id);
      else gemIds.add(id);
    }

    const dmIds = new Set(dmEntries.map((e) => e.id));
    const dmGemIds = new Set(dmEntries.filter((e) => e.hasGem).map((e) => e.id));

    // Every DM id must appear as a metal state.
    expect([...metalIds].sort()).toEqual([...dmIds].sort());
    // Gem set must match exactly — no stray gem states, no missing ones.
    expect([...gemIds].sort()).toEqual([...dmGemIds].sort());
  });
});
