/**
 * @file
 * Regression coverage for the custom piercing editor's hybrid offset adapter.
 * These tests keep selected-entry preview rendering tied to server-owned
 * descriptor data instead of rebuilding sticker icon-state names in TGUI.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'bun:test';

import {
  applyCustomPiercingHybridDraftToProps,
  applySelectedCustomPiercingGuideDraftToFreeform,
  buildCustomPiercingCommitSnapshot,
  customPiercingPropsToHybridDraft,
  getCustomPiercingHybridDescriptor,
} from './CustomPiercingEditorLogic';

const repoRoot = join(import.meta.dir, '../../../..');

const readRepoFile = (...parts: string[]) =>
  readFileSync(join(repoRoot, ...parts), 'utf8');

describe('CustomPiercingEditor hybrid descriptor adapter', () => {
  it('uses the server descriptor for an existing selected entry', () => {
    const descriptor = getCustomPiercingHybridDescriptor({
      defaultGemColor: '#334455',
      defaultMetalColor: '#112233',
      descriptors: {
        custom_upper: {
          '2': {
            e: {
              id: 'custom_upper:2:e',
              family: 'custom_piercings',
              targetKey: 'custom_upper:2',
              manifestCategory: 'sticker',
              direction: 'e',
              nativeWidth: 32,
              nativeHeight: 32,
              allowedFields: [
                'x',
                'y',
                'turn',
                'flip',
                'hide',
                'shrink',
                'above',
              ],
              layers: [
                {
                  iconState: 'server_resolved_metal_state',
                  role: 'metal',
                },
                {
                  iconState: 'server_resolved_gem_state',
                  role: 'gem',
                },
              ],
            },
          },
        },
      },
      direction: 'e',
      entry: {
        sticker: 'rose',
        metal_color: '#abcdef',
        gem_color: '#fedcba',
        props: {},
      },
      entryIndex: 1,
      stickerRegistry: {},
      slotKey: 'custom_upper',
    });

    expect(descriptor?.targetKey).toBe('custom_upper:2');
    expect(descriptor?.layers).toEqual([
      {
        iconState: 'server_resolved_metal_state',
        role: 'metal',
        color: '#abcdef',
      },
      {
        iconState: 'server_resolved_gem_state',
        role: 'gem',
        color: '#fedcba',
      },
    ]);
  });

  it('builds unsaved-entry descriptors from registry hybrid layers without naming guesses', () => {
    const descriptor = getCustomPiercingHybridDescriptor({
      defaultGemColor: '#334455',
      defaultMetalColor: '#112233',
      descriptors: {},
      direction: 's',
      entry: {
        sticker: 'rose',
        metal_color: null,
        gem_color: null,
        props: {},
      },
      entryIndex: 0,
      stickerRegistry: {
        rose: {
          name: 'Rose',
          manifest_category: 'sticker',
          hybrid_layers: [
            {
              iconState: 'registry_supplied_metal_state',
              role: 'metal',
            },
            {
              iconState: 'registry_supplied_gem_state',
              role: 'gem',
            },
          ],
        },
      },
      slotKey: 'custom_upper',
    });

    expect(descriptor).toMatchObject({
      family: 'custom_piercings',
      targetKey: 'custom_upper:1',
      direction: 's',
      manifestCategory: 'sticker',
    });
    expect(descriptor?.layers.map((layer) => layer.iconState)).toEqual([
      'registry_supplied_metal_state',
      'registry_supplied_gem_state',
    ]);
  });

  it('converts between custom piercing props and shared hybrid draft props', () => {
    const source = {
      sx: 3,
      sy: -4,
      sturn: 15,
      sflip: 1,
      sabove: 0,
      shide: 0,
      sshrink: 2,
    };

    expect(customPiercingPropsToHybridDraft(source, 's')).toEqual({
      x: 3,
      y: -4,
      turn: 15,
      flip: true,
      above: false,
      hide: false,
      shrink: 2,
    });

    expect(
      applyCustomPiercingHybridDraftToProps(
        source,
        's',
        {
          x: 99,
          y: -99,
          turn: 725,
          flip: false,
          above: true,
          hide: true,
          shrink: 9,
        },
        -64,
        64,
      ),
    ).toEqual({
      sx: 64,
      sy: -64,
      sturn: 359,
      sflip: 0,
      sabove: 1,
      shide: 1,
      sshrink: 4,
    });
  });

  it('writes guide drag drafts back to the selected entry without mutating slot props or siblings', () => {
    const freeform = {
      custom_upper: {
        enabled: 1,
        suppress_legacy: 0,
        display_name: 'Upper custom marks',
        hide_from_examine: 0,
        slot_props: {
          sx: 10,
          sy: -2,
          sturn: 5,
          sflip: 0,
          sabove: 0,
          shide: 0,
          sshrink: 2,
        },
        entries: [
          {
            sticker: 'stud',
            metal_color: '#111111',
            gem_color: '#222222',
            custom_name: '',
            custom_desc: '',
            zone: '',
            hide_when_covered: 0,
            props: {
              sx: 1,
              sy: 2,
              sturn: 0,
              sflip: 0,
              sabove: 0,
              shide: 0,
              sshrink: 1,
            },
          },
          {
            sticker: 'ring',
            metal_color: '#333333',
            gem_color: '#444444',
            custom_name: '',
            custom_desc: '',
            zone: '',
            hide_when_covered: 0,
            props: {
              sx: 3,
              sy: 4,
              sturn: 10,
              sflip: 0,
              sabove: 0,
              shide: 0,
              sshrink: 1,
            },
          },
        ],
      },
    };

    const next = applySelectedCustomPiercingGuideDraftToFreeform(
      freeform,
      'custom_upper',
      1,
      's',
      {
        x: 20,
        y: 8,
        turn: 25,
        flip: true,
        above: true,
        hide: false,
        shrink: 4,
      },
      -64,
      64,
    );

    expect(next).not.toBe(freeform);
    expect(next.custom_upper.slot_props).toBe(freeform.custom_upper.slot_props);
    expect(next.custom_upper.entries[0]).toBe(freeform.custom_upper.entries[0]);
    expect(next.custom_upper.entries[1]).not.toBe(
      freeform.custom_upper.entries[1],
    );
    expect(next.custom_upper.entries[1].props).toEqual({
      sx: 10,
      sy: 10,
      sturn: 20,
      sflip: 1,
      sabove: 1,
      shide: 0,
      sshrink: 2,
    });
    expect(freeform.custom_upper.entries[1].props).toEqual({
      sx: 3,
      sy: 4,
      sturn: 10,
      sflip: 0,
      sabove: 0,
      shide: 0,
      sshrink: 1,
    });
  });

  it('builds a save snapshot without arbitrary drawing, canvas, or descriptor payloads', () => {
    const snapshot = buildCustomPiercingCommitSnapshot(
      {
        custom_upper: {
          enabled: 1,
          suppress_legacy: 0,
          display_name: 'Upper custom marks',
          hide_from_examine: 0,
          slot_props: {
            sx: 5,
            sy: 6,
            canvas: 9001,
          },
          entries: [
            {
              sticker: 'stud',
              metal_color: '#111111',
              gem_color: '#222222',
              custom_name: 'Mark',
              custom_desc: 'Placed mark',
              zone: '',
              hide_when_covered: 0,
              props: {
                sx: 7,
                sy: 8,
                mystery: 42,
              },
              canvas: { pixels: [1, 2, 3] },
              drawing: 'arbitrary user pixels',
              iconState: 'forged_state',
              layers: [{ iconState: 'forged_layer' }],
            },
          ],
          canvas: { pixels: [9, 9, 9] },
          drawing: 'slot-level user pixels',
          hybrid_descriptors: {
            custom_upper: {},
          },
        },
      } as any,
      {
        ear: 'Gold Stud',
      },
    );

    expect(snapshot).toEqual({
      custom_piercings: {
        custom_upper: {
          enabled: 1,
          suppress_legacy: 0,
          display_name: 'Upper custom marks',
          hide_from_examine: 0,
          slot_props: {
            sx: 5,
            sy: 6,
          },
          entries: [
            {
              sticker: 'stud',
              metal_color: '#111111',
              gem_color: '#222222',
              custom_name: 'Mark',
              custom_desc: 'Placed mark',
              zone: '',
              hide_when_covered: 0,
              props: {
                sx: 7,
                sy: 8,
              },
            },
          ],
        },
      },
      regular_slots: {
        ear: 'Gold Stud',
      },
    });

    const encoded = JSON.stringify(snapshot);
    expect(encoded).not.toContain('canvas');
    expect(encoded).not.toContain('drawing');
    expect(encoded).not.toContain('iconState');
    expect(encoded).not.toContain('layers');
    expect(encoded).not.toContain('hybrid_descriptors');
  });

  it('keeps custom piercing sidecar persistence staged until the main save succeeds', () => {
    const preferencesSource = readRepoFile(
      'modular/code/modules/client/preferences_custom_piercings.dm',
    );
    const editorSource = readRepoFile(
      'modular/code/modules/client/custom_piercing_editor.dm',
    );
    const commitSource = readRepoFile(
      'modular/code/modules/client/appearance_preview/appearance_preview_commit.dm',
    );

    expect(preferencesSource).toContain(
      '/datum/preferences/proc/compute_custom_piercings_payload',
    );
    expect(preferencesSource).toContain(
      '/datum/preferences/proc/write_custom_piercings_payload',
    );
    expect(preferencesSource).toContain('var/tmp_path = "[path].tmp"');
    expect(preferencesSource).toContain('fcopy(tmp_path, path)');

    const stageStart = editorSource.indexOf(
      '/datum/custom_piercing_editor/_stage_persist()',
    );
    const stageEnd = editorSource.indexOf(
      '/mob/living/carbon/human/verb/open_custom_piercing_editor()',
      stageStart,
    );
    const stageSource = editorSource.slice(stageStart, stageEnd);
    expect(stageSource).toContain('prefs.compute_custom_piercings_payload');
    expect(stageSource).toContain('pending_sidecars = list(payload)');
    expect(stageSource).not.toContain('write_custom_piercings_payload(');

    const saveIndex = commitSource.indexOf('editor.prefs.save_character()');
    const flushIndex = commitSource.indexOf('editor._flush_persist()');
    expect(saveIndex).toBeGreaterThan(-1);
    expect(flushIndex).toBeGreaterThan(-1);
    expect(saveIndex).toBeLessThan(flushIndex);
  });

  it('keeps the editor wired to HybridOffsetOverlay instead of local sheet composition', () => {
    const source = readFileSync(
      join(import.meta.dir, 'CustomPiercingEditor.tsx'),
      'utf8',
    );

    expect(source).toContain('HybridOffsetOverlay');
    expect(source).toContain('getCustomPiercingHybridDescriptor');
    expect(source).not.toContain('SheetPreviewTile');
    expect(source).not.toContain('function EntryLayer');
    expect(source).not.toContain(
      ['piercing_', '$', '{entry.sticker}'].join(''),
    );
  });
});
