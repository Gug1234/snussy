/**
 * tools/build/appearance_preview/schema/manifest_v2.test.ts
 *
 * Round-trip + negative-case coverage for the manifest v2 validator.
 *
 * Strategy: build a minimal but realistic manifest using the same shape the
 * Step 5 orchestrator will produce, run it through `validateManifestV2`, then
 * mutate single fields and assert the validator points at the right path.
 *
 * Step 4 ships the happy path + the most likely failure modes. Step 14 will
 * extend this file with adapter-shape edge cases (sheet overflow, mixed tile
 * sizes, etc.) once the orchestrator can produce real failure inputs.
 */

import { describe, expect, it } from "bun:test";

import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type ManifestV2,
} from "../types";
import { tryValidateManifestV2, validateManifestV2 } from "./manifest_v2";
import { ManifestInvalidError } from "../errors";

function buildSampleManifest(): ManifestV2 {
  return {
    version: APPEARANCE_PREVIEW_MANIFEST_VERSION,
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    canonicalLookupKey: "icon_state",
    categoryOrder: ["intimate_accessory", "sticker"],
    categories: {
      intimate_accessory: {
        key: "intimate_accessory",
        scope: "family",
        states: ["taur_penis", "taur_penis_partial"],
      },
      sticker: {
        key: "sticker",
        scope: "catalog",
        states: ["piercing_stud_metal", "piercing_stud_gem"],
      },
    },
    sheets: {
      taur_offsets__0: {
        id: "taur_offsets__0",
        family: "taur_offsets",
        path: "sheets/taur_offsets__0.png",
        width: 128,
        height: 128,
        tileWidth: 32,
        tileHeight: 32,
        contentHash: "deadbeefdeadbeef",
      },
      custom_piercings__0: {
        id: "custom_piercings__0",
        family: "custom_piercings",
        path: "sheets/custom_piercings__0.png",
        width: 64,
        height: 64,
        tileWidth: 32,
        tileHeight: 32,
        contentHash: "cafebabecafebabe",
      },
    },
    states: {
      taur_penis: {
        iconState: "taur_penis",
        family: "taur_offsets",
        sheetId: "taur_offsets__0",
        crops: {
          s: { x: 0, y: 0, width: 32, height: 32 },
          n: { x: 32, y: 0, width: 32, height: 32 },
          e: { x: 64, y: 0, width: 32, height: 32 },
          w: { x: 96, y: 0, width: 32, height: 32 },
        },
        variants: { partial: "taur_penis_partial" },
      },
      taur_penis_partial: {
        iconState: "taur_penis_partial",
        family: "taur_offsets",
        sheetId: "taur_offsets__0",
        crops: {
          s: { x: 0, y: 32, width: 32, height: 32 },
          n: { x: 32, y: 32, width: 32, height: 32 },
          e: { x: 64, y: 32, width: 32, height: 32 },
          w: { x: 96, y: 32, width: 32, height: 32 },
        },
      },
      piercing_stud_metal: {
        iconState: "piercing_stud_metal",
        family: "custom_piercings",
        sheetId: "custom_piercings__0",
        crops: {
          s: { x: 0, y: 0, width: 32, height: 32 },
        },
        variants: { gem: "piercing_stud_gem" },
      },
      piercing_stud_gem: {
        iconState: "piercing_stud_gem",
        family: "custom_piercings",
        sheetId: "custom_piercings__0",
        crops: {
          s: { x: 32, y: 0, width: 32, height: 32 },
        },
      },
    },
    build: {
      builtAt: "2026-04-19T00:00:00.000Z",
      backend: APPEARANCE_PREVIEW_BACKEND_ID,
      layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
      sourceFingerprint: "0123456789abcdef",
      adapterVersions: {
        taur_offsets: "1.0.0",
        custom_piercings: "1.0.0",
      },
    },
  };
}

/** Deep clone helper — JSON round-trip is fine for plain manifest data. */
function clone(m: ManifestV2): ManifestV2 {
  return JSON.parse(JSON.stringify(m)) as ManifestV2;
}

describe("manifest_v2 happy path", () => {
  it("validates a well-formed manifest", () => {
    const manifest = buildSampleManifest();
    expect(() => validateManifestV2(manifest)).not.toThrow();
    const result = tryValidateManifestV2(manifest);
    expect(result.ok).toBe(true);
  });

  it("survives a JSON round trip", () => {
    const manifest = buildSampleManifest();
    const round = JSON.parse(JSON.stringify(manifest));
    const result = tryValidateManifestV2(round);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.manifest.version).toBe(APPEARANCE_PREVIEW_MANIFEST_VERSION);
      expect(result.manifest.backend).toBe(APPEARANCE_PREVIEW_BACKEND_ID);
    }
  });
});

describe("manifest_v2 negative cases", () => {
  it("rejects a non-object root", () => {
    const r = tryValidateManifestV2(null);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("$root");
  });

  it("rejects a wrong version", () => {
    const m = clone(buildSampleManifest());
    (m as { version: number }).version = 1;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("version");
  });

  it("rejects a wrong backend", () => {
    const m = clone(buildSampleManifest());
    (m as { backend: string }).backend = "python_exporter";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("backend");
  });

  it("rejects a wrong layout", () => {
    const m = clone(buildSampleManifest());
    (m as { layout: string }).layout = "per_state";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("layout");
  });

  it("rejects categoryOrder/categories mismatch", () => {
    const m = clone(buildSampleManifest());
    m.categoryOrder = ["intimate_accessory"];
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("categoryOrder");
  });

  it("rejects a state pointing at an unknown sheet", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.sheetId = "ghost_sheet";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.sheetId");
  });

  it("rejects a variant pointing at an unknown state", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.variants = { partial: "missing_state" };
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.variants.partial");
  });

  it("rejects a self-referential variant", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.variants = { partial: "taur_penis" };
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.variants.partial");
  });

  it("rejects a category referencing an unknown state", () => {
    const m = clone(buildSampleManifest());
    m.categories.sticker.states = ["piercing_stud_metal", "ghost_state"];
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("categories.sticker.states[1]");
  });

  it("rejects a state with an unknown direction key in crops", () => {
    const m = clone(buildSampleManifest());
    (m.states.taur_penis.crops as Record<string, unknown>).up = {
      x: 0,
      y: 0,
      width: 32,
      height: 32,
    };
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.crops.up");
  });

  it("rejects a crop rect with a non-positive width", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.crops.s!.width = 0;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.crops.s.width");
  });

  it("rejects a sheet whose tile exceeds its dimensions", () => {
    const m = clone(buildSampleManifest());
    m.sheets.taur_offsets__0.tileWidth = 256;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("sheets.taur_offsets__0.tileWidth");
  });

  it("rejects a state whose family is not in build.adapterVersions", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.family = "unknown_family";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.family");
  });

  it("throws ManifestInvalidError from the strict validator", () => {
    const m = clone(buildSampleManifest());
    (m as { backend: string }).backend = "bogus";
    expect(() => validateManifestV2(m)).toThrow(ManifestInvalidError);
  });
});

describe("manifest_v2 negative cases (Step 14 extensions)", () => {
  it("rejects negative crop coordinates", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.crops.s!.x = -1;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.crops.s.x");
  });

  it("rejects non-integer crop dimensions", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.crops.s!.height = 32.5;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("states.taur_penis.crops.s.height");
  });

  it("rejects a state with zero crops declared", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.crops = {};
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path.startsWith("states.taur_penis.crops")).toBe(true);
  });

  it("rejects a sheet record with non-positive dimensions", () => {
    const m = clone(buildSampleManifest());
    m.sheets.taur_offsets__0.width = 0;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("sheets.taur_offsets__0.width");
  });

  it("rejects a sheet record whose id does not match its map key", () => {
    const m = clone(buildSampleManifest());
    m.sheets.taur_offsets__0.id = "mismatch";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path.startsWith("sheets.taur_offsets__0")).toBe(true);
  });

  it("rejects a state whose map key does not match its iconState", () => {
    const m = clone(buildSampleManifest());
    m.states.taur_penis.iconState = "mismatch";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path.startsWith("states.taur_penis")).toBe(true);
  });

  it("rejects a build block missing its adapterVersions", () => {
    const m = clone(buildSampleManifest());
    (m.build as { adapterVersions?: unknown }).adapterVersions = undefined;
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path.startsWith("build")).toBe(true);
  });

  it("rejects a categoryOrder containing duplicate keys", () => {
    const m = clone(buildSampleManifest());
    m.categoryOrder = ["intimate_accessory", "intimate_accessory", "sticker"];
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("categoryOrder");
  });

  it("rejects a canonicalLookupKey other than icon_state", () => {
    const m = clone(buildSampleManifest());
    (m as { canonicalLookupKey: string }).canonicalLookupKey = "state_id";
    const r = tryValidateManifestV2(m);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.path).toBe("canonicalLookupKey");
  });
});
