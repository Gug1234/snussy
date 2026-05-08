import { describe, expect, it } from 'bun:test';

import {
  applyTargetPresetToPreviewProfile,
  createDefaultErpPreviewProfile,
  resolveErpPreviewTokens,
} from './interfaces/common/ErpPreviewOptions';

describe('ERP preview token options', () => {
  it('uses configured wearer tokens in intimate wearer and bystander previews', () => {
    const profile = {
      ...createDefaultErpPreviewProfile(),
      userName: 'Mara Ratwood',
      userThey: 'she',
      userThem: 'her',
      userTheir: 'her',
      penisType: 'equine cock',
      targetName: 'John Ratwood',
      targetThey: 'he',
      targetThem: 'him',
      targetTheir: 'his',
      targetCock: 'barbed cock',
    };

    const text =
      '[USER] shifts [THEIR] [PENIS_TYPE] toward [TARGET] as [TTHEY] watches.';

    expect(resolveErpPreviewTokens(text, 'intimate-wearer', profile)).toBe(
      'You shift your equine cock toward John Ratwood as he watches.',
    );
    expect(resolveErpPreviewTokens(text, 'intimate-bystander', profile)).toBe(
      'Mara Ratwood shifts her equine cock toward John Ratwood as he watches.',
    );
  });

  it('uses the same profile for custom sex giving and receiving previews', () => {
    const profile = {
      ...createDefaultErpPreviewProfile(),
      userName: 'Mara Ratwood',
      userThey: 'she',
      userThem: 'her',
      userTheir: 'her',
      userCock: 'equine cock',
      targetName: 'Jane Ratwood',
      targetThey: 'she',
      targetThem: 'her',
      targetTheir: 'her',
      targetVag: 'furred slit',
    };

    const text = '[USER] guides [UCOCK] toward [TARGET] and [TVAG].';

    expect(resolveErpPreviewTokens(text, 'sex-giving', profile)).toBe(
      'You guide your equine cock toward Jane Ratwood and her furred slit.',
    );
    expect(resolveErpPreviewTokens(text, 'sex-receiving', profile)).toBe(
      'Mara Ratwood guides her equine cock toward You and your furred slit.',
    );
  });

  it('applies fixed target presets for name and pronouns', () => {
    const profile = applyTargetPresetToPreviewProfile(
      createDefaultErpPreviewProfile(),
      'jean',
    );

    expect(profile.targetName).toBe('Jean Ratwood');
    expect(profile.targetThey).toBe('they');
    expect(profile.targetThem).toBe('them');
    expect(profile.targetTheir).toBe('their');
  });
});
