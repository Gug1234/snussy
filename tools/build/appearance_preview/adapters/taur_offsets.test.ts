/**
 * tools/build/appearance_preview/adapters/taur_offsets.test.ts
 *
 * Coverage for the v3 taur adapter. The v3 layout mirrors DMI state names
 * verbatim (no bespoke renaming); tests pin the cardinality of each
 * enumerated group so drift in either direction — adapter-side or DMI-side
 * — fails loudly.
 */

import { describe, expect, it } from "bun:test";
import * as path from "node:path";

import { taurOffsetsAdapter } from "./taur_offsets";
import { validateDiscovery } from "./registry";

const REPO_ROOT = path.resolve(import.meta.dir, "..", "..", "..", "..");

const DMI_PENIS = "modular/icons/obj/lewd/taur_pintle.dmi";
const DMI_TESTICLES = "modular/icons/obj/lewd/taur_gonads.dmi";
const DMI_VAGINA = "modular/icons/obj/lewd/taur_nethers.dmi";

// Enumeration constants repeated here so a future adapter-side refactor
// has to prove it preserved the shape of the cartesian product.
const PENIS_SHAPES = 10;
const PENIS_EROS = 2;
const PENIS_SIZES = 3;
const PENIS_FRONT_TILES = PENIS_SHAPES * PENIS_EROS * PENIS_SIZES; // 60
const PENIS_BEHIND_TILES = PENIS_SHAPES; // 10, one fallback per shape
const SHEATH_TILES = 4;
const SLIT_TILES = 3;
const VAGINA_TILES = 7;
const TESTICLE_TILES = 4 * 2; // size × layer
const TOTAL_TILES =
  PENIS_FRONT_TILES +
  PENIS_BEHIND_TILES +
  SHEATH_TILES +
  SLIT_TILES +
  VAGINA_TILES +
  TESTICLE_TILES;

describe("taur_offsets adapter record (v3)", () => {
  it("declares the expected family and tile contract", () => {
    expect(taurOffsetsAdapter.record.family).toBe("taur_offsets");
    expect(taurOffsetsAdapter.record.adapterVersion).toBe("3.0.0");
    expect(taurOffsetsAdapter.record.tileSize).toEqual({ width: 32, height: 32 });
    expect(taurOffsetsAdapter.record.directionOrder).toEqual(["s"]);
  });
});

describe("taur_offsets discoverSources (v3)", () => {
  it("emits exactly the cartesian-enumerated state count", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    expect(discovery.states).toHaveLength(TOTAL_TILES);
  });

  it("references the three taur override DMIs", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    const sourcePaths = discovery.sources.map((s) => s.path).sort();
    expect(sourcePaths).toEqual([DMI_PENIS, DMI_VAGINA, DMI_TESTICLES].sort());
  });

  it("routes each state to the correct DMI", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    for (const s of discovery.states) {
      if (
        s.iconState.startsWith("pair_")
      ) {
        expect(s.iconFile).toBe(DMI_TESTICLES);
      } else if (
        /^(human|hairy|spade|furred|gaping|cloaca|trimmed)_FRONT$/.test(
          s.iconState,
        )
      ) {
        expect(s.iconFile).toBe(DMI_VAGINA);
      } else {
        expect(s.iconFile).toBe(DMI_PENIS);
      }
    }
  });

  it("uses identity sourceState (DMI mirror, no renaming)", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    for (const s of discovery.states) {
      expect(s.sourceState).toBe(s.iconState);
    }
  });

  it("declares no variants on v3 states", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    for (const s of discovery.states) {
      expect(s.variants).toBeUndefined();
    }
  });

  it("lists a single 's' direction on every state", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    for (const state of discovery.states) {
      expect(state.directions).toEqual(["s"]);
    }
  });

  it("includes representative canonical states", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    const keys = new Set(discovery.states.map((s) => s.iconState));
    // Penis FRONT corners of the cartesian product.
    expect(keys.has("human_1_1_FRONT_1")).toBe(true);
    expect(keys.has("human_2_3_FRONT_1")).toBe(true);
    expect(keys.has("tentacle_2_3_FRONT_1")).toBe(true);
    expect(keys.has("flaredknot_1_2_FRONT_1")).toBe(true);
    // BEHIND fallbacks.
    expect(keys.has("human_1_BEHIND_1")).toBe(true);
    expect(keys.has("knotted_3_BEHIND_1")).toBe(true);
    expect(keys.has("tentacle_1_BEHIND_1")).toBe(true);
    // Sheath / slit (2 colour layers where present).
    expect(keys.has("sheath_1_FRONT_1")).toBe(true);
    expect(keys.has("sheath_2_FRONT_2")).toBe(true);
    expect(keys.has("slit_2_FRONT_1")).toBe(true);
    expect(keys.has("slit_2_FRONT_2")).toBe(true);
    expect(keys.has("slit_1_FRONT_2")).toBe(true);
    // Vagina shape coverage.
    expect(keys.has("human_FRONT")).toBe(true);
    expect(keys.has("spade_FRONT")).toBe(true);
    expect(keys.has("cloaca_FRONT")).toBe(true);
    // Testicles shape coverage.
    expect(keys.has("pair_0_ADJ")).toBe(true);
    expect(keys.has("pair_3_BEHIND")).toBe(true);
  });

  it("omits DMI states the runtime never requests", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    const keys = new Set(discovery.states.map((s) => s.iconState));
    // `slit_1_FRONT_1` absent from the DMI — enumeration must skip it.
    expect(keys.has("slit_1_FRONT_1")).toBe(false);
  });
});

describe("taur_offsets normalizeStateName (v3)", () => {
  it("accepts canonical DMI state names", () => {
    expect(taurOffsetsAdapter.normalizeStateName("human_1_1_FRONT_1")).toBe(
      "human_1_1_FRONT_1",
    );
    expect(taurOffsetsAdapter.normalizeStateName("knotted_3_BEHIND_1")).toBe(
      "knotted_3_BEHIND_1",
    );
    expect(taurOffsetsAdapter.normalizeStateName("sheath_2_FRONT_2")).toBe(
      "sheath_2_FRONT_2",
    );
    expect(taurOffsetsAdapter.normalizeStateName("slit_1_FRONT_2")).toBe(
      "slit_1_FRONT_2",
    );
    expect(taurOffsetsAdapter.normalizeStateName("human_FRONT")).toBe(
      "human_FRONT",
    );
    expect(taurOffsetsAdapter.normalizeStateName("pair_2_ADJ")).toBe("pair_2_ADJ");
  });

  it("rejects legacy v2 keys", () => {
    expect(taurOffsetsAdapter.normalizeStateName("taur_penis")).toBeNull();
    expect(taurOffsetsAdapter.normalizeStateName("taur_penis_hard")).toBeNull();
    expect(taurOffsetsAdapter.normalizeStateName("taur_testicles")).toBeNull();
    expect(taurOffsetsAdapter.normalizeStateName("taur_vagina")).toBeNull();
  });

  it("rejects foreign and malformed names", () => {
    expect(taurOffsetsAdapter.normalizeStateName("piercing_stud_metal")).toBeNull();
    expect(taurOffsetsAdapter.normalizeStateName("Human_1_1_FRONT_1")).toBeNull();
    expect(taurOffsetsAdapter.normalizeStateName("human_1_1_front_1")).toBeNull();
    expect(taurOffsetsAdapter.normalizeStateName("pair_4_ADJ")).toBeNull();
  });

  it("rejects non-strings", () => {
    expect(
      taurOffsetsAdapter.normalizeStateName(123 as unknown as string),
    ).toBeNull();
  });
});

describe("taur_offsets orderStates (v3)", () => {
  it("preserves enumeration order for known keys", () => {
    const sample = [
      "pair_3_BEHIND",
      "human_1_1_FRONT_1",
      "slit_2_FRONT_1",
      "human_FRONT",
      "knotted_3_BEHIND_1",
    ];
    const ordered = taurOffsetsAdapter.orderStates(sample);
    // Known keys preceed unknown extras; enumeration order holds.
    expect(ordered[0]).toBe("human_1_1_FRONT_1");
    // knotted BEHIND follows all FRONT entries.
    const behindIdx = ordered.indexOf("knotted_3_BEHIND_1");
    const frontIdx = ordered.indexOf("human_1_1_FRONT_1");
    expect(behindIdx).toBeGreaterThan(frontIdx);
    // Vagina (human_FRONT) comes after penis & sheath/slit.
    expect(ordered.indexOf("human_FRONT")).toBeGreaterThan(
      ordered.indexOf("slit_2_FRONT_1"),
    );
    // Testicles come last.
    expect(ordered.indexOf("pair_3_BEHIND")).toBeGreaterThan(
      ordered.indexOf("human_FRONT"),
    );
  });

  it("appends unknown keys alphabetically at the end", () => {
    const ordered = taurOffsetsAdapter.orderStates([
      "human_1_1_FRONT_1",
      "zzz_unknown",
      "aaa_unknown",
    ]);
    expect(ordered[0]).toBe("human_1_1_FRONT_1");
    expect(ordered.slice(-2)).toEqual(["aaa_unknown", "zzz_unknown"]);
  });
});

describe("taur_offsets previewMetadata (v3)", () => {
  it("emits a single intimate_accessory category covering every state", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    const metadata = taurOffsetsAdapter.previewMetadata(discovery);
    expect(metadata.categories).toHaveLength(1);
    const cat = metadata.categories[0];
    expect(cat.key).toBe("intimate_accessory");
    expect(cat.scope).toBe("family");
    expect(cat.states).toHaveLength(TOTAL_TILES);
  });
});

describe("taur_offsets passes registry validation (v3)", () => {
  it("validateDiscovery accepts the canonical output without error", () => {
    const discovery = taurOffsetsAdapter.discoverSources(REPO_ROOT);
    expect(() => validateDiscovery(taurOffsetsAdapter, discovery)).not.toThrow();
  });
});
