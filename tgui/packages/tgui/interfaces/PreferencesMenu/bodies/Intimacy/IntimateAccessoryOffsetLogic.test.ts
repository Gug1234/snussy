/**
 * @file IntimateAccessoryOffsetLogic.test.ts
 * @description Regression coverage for the phase-one intimate accessory
 * offset scope exposed by the PreferencesMenu intimacy row.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'bun:test';

import {
  applyIntimateAccessoryDirectionalDraftsToProps,
  applyIntimateAccessoryHybridDraftToProps,
  buildIntimateAccessoryOffsetSaveProps,
  findIntimateAccessoryOffsetRow,
  getEditableIntimateAccessoryOffsetRows,
  getInitialIntimateAccessoryOffsetTarget,
  getIntimateAccessoryHybridDescriptor,
  groupIntimateAccessoryOffsetRows,
  INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS,
  intimateAccessoryPropsToHybridDraft,
  isPhaseOneIntimateAccessoryOffsetField,
  normalizeIntimateAccessoryOffsetRows,
} from './IntimateAccessoryOffsetLogic';

const readLocalFile = (name: string) =>
  readFileSync(join(import.meta.dir, name), 'utf8');

describe('intimate accessory offset scope', () => {
  it('keeps phase one constrained to x/y offsets', () => {
    expect(INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS).toEqual(['x', 'y']);
    expect(isPhaseOneIntimateAccessoryOffsetField('x')).toBe(true);
    expect(isPhaseOneIntimateAccessoryOffsetField('y')).toBe(true);

    for (const deferredField of ['turn', 'flip', 'hide', 'shrink', 'above']) {
      expect(isPhaseOneIntimateAccessoryOffsetField(deferredField)).toBe(false);
    }
  });

  it('normalizes server rows and strips unsupported fields', () => {
    const rows = normalizeIntimateAccessoryOffsetRows([
      {
        key: 'genital_piercing',
        label: 'Genital Piercing',
        group: 'genital',
        current: 'Iron Genital Piercing',
        custom_key: 'genital',
        offset_target_key: 'genital',
        offset_editable: 1,
        offset_allowed_fields: ['x', 'turn', 'y', 'shrink'],
        offset_scope: 'phase_one_xy',
        offset_editor_family: 'intimate_accessory_offsets',
        slot_props: {
          sx: 4,
          sy: -2,
          sturn: 90,
          sflip: 1,
          nx: 1,
          ny: 2,
        },
      },
      {
        key: 'breast_insertable',
        label: 'Breast Insertable',
        group: 'torso',
        current: 'None',
        custom_key: null,
        offset_target_key: null,
        offset_editable: 0,
        offset_allowed_fields: ['x', 'y', 'flip'],
        offset_scope: 'phase_one_xy',
        offset_editor_family: 'intimate_accessory_offsets',
      },
      null,
      'bad-row',
    ]);

    expect(rows).toHaveLength(2);
    expect(rows[0]).toMatchObject({
      key: 'genital_piercing',
      label: 'Genital Piercing',
      group: 'genital',
      current: 'Iron Genital Piercing',
      custom_key: 'genital',
      offset_target_key: 'genital',
      offset_editable: 1,
      offset_allowed_fields: ['x', 'y'],
      offset_scope: 'phase_one_xy',
      offset_editor_family: 'intimate_accessory_offsets',
    });
    expect(rows[0].slot_props).toMatchObject({
      sx: 4,
      sy: -2,
      nx: 1,
      ny: 2,
    });
    expect(rows[0].slot_props).not.toHaveProperty('sturn');
    expect(rows[0].slot_props).not.toHaveProperty('sflip');
    expect(rows[1].offset_allowed_fields).toEqual(['x', 'y']);
    expect(getEditableIntimateAccessoryOffsetRows(rows)).toEqual([rows[0]]);
  });

  it('groups rows by server-provided body region', () => {
    const grouped = groupIntimateAccessoryOffsetRows([
      {
        key: 'ear_piercing',
        label: 'Ear Piercing',
        group: 'head',
        current: 'Gold Earring',
        custom_key: 'ear',
        offset_target_key: 'ear',
        offset_editable: 1,
        offset_allowed_fields: ['x', 'y'],
        offset_scope: 'phase_one_xy',
        offset_editor_family: 'intimate_accessory_offsets',
        slot_props: {},
      },
      {
        key: 'rear_insertable',
        label: 'Rear Insertable',
        group: 'rear',
        current: 'Iron Butt Plug',
        custom_key: 'insertable_rear',
        offset_target_key: 'insertable_rear',
        offset_editable: 1,
        offset_allowed_fields: ['x', 'y'],
        offset_scope: 'phase_one_xy',
        offset_editor_family: 'intimate_accessory_offsets',
        slot_props: {},
      },
    ]);

    expect(Object.keys(grouped)).toEqual(['head', 'rear']);
    expect(grouped.head[0].key).toBe('ear_piercing');
    expect(grouped.rear[0].offset_target_key).toBe('insertable_rear');
  });

  it('selects an editable target without inventing client-side targets', () => {
    const rows = normalizeIntimateAccessoryOffsetRows([
      {
        key: 'breast_insertable',
        label: 'Breast Insertable',
        current: 'None',
        offset_editable: 0,
      },
      {
        key: 'ear_piercing',
        label: 'Ear Piercing',
        current: 'Gold Earring',
        custom_key: 'ear',
        offset_target_key: 'ear',
        offset_editable: 1,
      },
    ]);

    expect(getInitialIntimateAccessoryOffsetTarget(rows, 'ear')).toBe('ear');
    expect(getInitialIntimateAccessoryOffsetTarget(rows, 'bad')).toBe('ear');
    expect(findIntimateAccessoryOffsetRow(rows, 'ear')?.label).toBe(
      'Ear Piercing',
    );
    expect(findIntimateAccessoryOffsetRow(rows, 'bad')).toBeNull();
  });

  it('looks up server-owned descriptors by target and direction', () => {
    const descriptor = {
      id: 'ear:s',
      family: 'intimate_accessory_offsets',
      targetKey: 'ear',
      manifestCategory: 'intimate_accessory',
      direction: 's',
      layers: [{ iconState: 'earring_s', role: 'guide' }],
      nativeWidth: 32,
      nativeHeight: 32,
      allowedFields: ['x', 'y'],
      approximateColor: true,
    } as const;

    expect(
      getIntimateAccessoryHybridDescriptor(
        {
          ear: { s: descriptor },
        },
        'ear',
        's',
      ),
    ).toBe(descriptor);
    expect(
      getIntimateAccessoryHybridDescriptor(
        { ear: { s: descriptor } },
        'ear',
        'n',
      ),
    ).toBeNull();
    expect(
      getIntimateAccessoryHybridDescriptor(
        { ear: { s: descriptor } },
        null,
        's',
      ),
    ).toBeNull();
  });

  it('converts and writes x/y-only hybrid drafts', () => {
    const props = {
      sx: 2,
      sy: -3,
      sturn: 180,
      sflip: 1,
      sshrink: 2,
      nx: 1,
      ny: 1,
    };

    expect(intimateAccessoryPropsToHybridDraft(props, 's')).toEqual({
      x: 2,
      y: -3,
      turn: 0,
      flip: false,
      above: undefined,
      hide: false,
      shrink: 1,
    });

    const next = applyIntimateAccessoryHybridDraftToProps(
      props,
      's',
      {
        x: 128,
        y: -129,
        turn: 45,
        flip: true,
        above: true,
        hide: true,
        shrink: 3,
      },
      -64,
      64,
    );

    expect(next).toMatchObject({ sx: 64, sy: -64, nx: 1, ny: 1 });
    expect(next).not.toHaveProperty('sturn');
    expect(next).not.toHaveProperty('sflip');
    expect(next).not.toHaveProperty('sshrink');
  });

  it('builds a compact x/y save payload for all directions', () => {
    const props = applyIntimateAccessoryDirectionalDraftsToProps(
      {},
      {
        s: { x: 1, y: 2, turn: 9, flip: true, hide: true, shrink: 4 },
        n: { x: -1, y: -2, turn: 9, flip: true, hide: true, shrink: 4 },
        e: { x: 3, y: 4, turn: 9, flip: true, hide: true, shrink: 4 },
        w: { x: -3, y: -4, turn: 9, flip: true, hide: true, shrink: 4 },
      },
      -64,
      64,
    );

    expect(buildIntimateAccessoryOffsetSaveProps(props)).toEqual({
      sx: 1,
      sy: 2,
      nx: -1,
      ny: -2,
      ex: 3,
      ey: 4,
      wx: -3,
      wy: -4,
    });
  });

  it('keeps the prefs row wired to server-provided scope data', () => {
    const rowSource = readLocalFile('IntimateAccessory.tsx');
    const tabSource = readFileSync(
      join(import.meta.dir, '../../tabs/IntimateAccessoriesTab.tsx'),
      'utf8',
    );

    expect(rowSource).toContain('intimate_accessory_offset_rows');
    expect(rowSource).toContain('normalizeIntimateAccessoryOffsetRows');
    expect(tabSource).toContain('intimate_accessory_offset_rows');
    expect(rowSource).not.toContain("act('open_piercing_editor'");
    expect(tabSource).not.toContain("act('open_piercing_editor'");
    expect(rowSource).toContain("act('set_intimate_accessory_offset_target'");
    expect(tabSource).toContain("act('set_intimate_accessory_offset_target'");
  });
});
