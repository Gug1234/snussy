import { describe, expect, it } from 'bun:test';

import {
  getImportTransferPlan,
  splitImportTextForUpload,
} from './interfaces/CharacterSlotIOMenuUtils';

describe('splitImportTextForUpload', () => {
  it('keeps small imports as one upload chunk', () => {
    expect(splitImportTextForUpload('abc', 12)).toEqual(['abc']);
  });

  it('splits large imports into bounded upload chunks', () => {
    const chunks = splitImportTextForUpload('abcdefghijklmnop', 5);

    expect(chunks).toEqual(['abcde', 'fghij', 'klmno', 'p']);
  });

  it('normalizes import text before upload planning', () => {
    const plan = getImportTransferPlan('  abcdef  ', 20, 2);

    expect(plan.trimmedText).toBe('abcdef');
    expect(plan.hasImport).toBe(true);
    expect(plan.importTooLarge).toBe(false);
    expect(plan.chunks).toEqual(['ab', 'cd', 'ef']);
  });

  it('marks oversized import text before building upload chunks', () => {
    const plan = getImportTransferPlan('abcdef', 4, 2);

    expect(plan.importTooLarge).toBe(true);
    expect(plan.chunks).toEqual([]);
  });
});
