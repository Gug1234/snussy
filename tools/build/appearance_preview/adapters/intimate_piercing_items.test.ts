/**
 * tools/build/appearance_preview/adapters/intimate_piercing_items.test.ts
 *
 * Contract + DMI-presence checks for the intimate_piercing_items adapter.
 * Mirrors the structure of custom_piercings.test.ts.
 */

import { describe, expect, it } from "bun:test";
import * as path from "node:path";

import { intimatePiercingItemsAdapter } from "./intimate_piercing_items";
import { validateDiscovery } from "./registry";

const REPO_ROOT = path.resolve(__dirname, "../../../..");

describe("intimate_piercing_items adapter", () => {
  it("declares its expected canonical states", () => {
    const discovery = intimatePiercingItemsAdapter.discoverSources(REPO_ROOT);
    const keys = discovery.states.map((s) => s.iconState).sort();
    expect(keys).toEqual(
      [
        "belly_pierce",
        "belly_pierce_gem",
        "belly_pierce_psy",
        "belly_pierce_zizo",
        "nose_pierce",
        "nose_pierce_gem",
      ].sort(),
    );
  });

  it("every state points at intimate_overlays.dmi", () => {
    const discovery = intimatePiercingItemsAdapter.discoverSources(REPO_ROOT);
    for (const state of discovery.states) {
      expect(state.iconFile).toBe(
        "modular/icons/obj/lewd/intimate_overlays.dmi",
      );
    }
  });

  it("base states expose their gem mask as a variant", () => {
    const discovery = intimatePiercingItemsAdapter.discoverSources(REPO_ROOT);
    const byKey = new Map(
      discovery.states.map((s) => [s.iconState, s] as const),
    );
    expect(byKey.get("nose_pierce")?.variants).toEqual({
      gem: "nose_pierce_gem",
    });
    expect(byKey.get("belly_pierce")?.variants).toEqual({
      gem: "belly_pierce_gem",
    });
    // Gem + standalone variant states must not declare further variants.
    expect(byKey.get("nose_pierce_gem")?.variants).toBeUndefined();
    expect(byKey.get("belly_pierce_psy")?.variants).toBeUndefined();
  });

  it("passes registry validation", () => {
    const discovery = intimatePiercingItemsAdapter.discoverSources(REPO_ROOT);
    expect(() =>
      validateDiscovery(intimatePiercingItemsAdapter, discovery),
    ).not.toThrow();
  });

  it("emits a single category covering every state", () => {
    const discovery = intimatePiercingItemsAdapter.discoverSources(REPO_ROOT);
    const meta = intimatePiercingItemsAdapter.previewMetadata(discovery);
    expect(meta.categories.length).toBe(1);
    const cat = meta.categories[0];
    expect(cat.key).toBe("intimate_piercing_items");
    expect(cat.scope).toBe("family");
    expect(cat.states.length).toBe(discovery.states.length);
  });

  it("normalizeStateName rejects foreign and malformed keys", () => {
    const adapter = intimatePiercingItemsAdapter;
    expect(adapter.normalizeStateName("nose_pierce")).toBe("nose_pierce");
    expect(adapter.normalizeStateName("belly_pierce_psy")).toBe(
      "belly_pierce_psy",
    );
    expect(adapter.normalizeStateName("ear_pierce")).toBeNull();
    expect(adapter.normalizeStateName("piercing_stud_metal")).toBeNull();
    expect(adapter.normalizeStateName("")).toBeNull();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    expect(adapter.normalizeStateName(null as any)).toBeNull();
  });

  // Note: we do not do a shallow DMI-parse presence check here. The DMI
  // metadata block is zTXt-compressed in this repo so a latin1 regex sweep
  // yields false negatives. The authoritative presence check is the
  // iconforge pack pass during materialize; that step hard-fails on any
  // state this adapter enumerates which the DMI does not actually contain.
});
