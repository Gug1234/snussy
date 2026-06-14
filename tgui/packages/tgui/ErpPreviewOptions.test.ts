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
      'You shifts your equine cock toward John Ratwood as he watches.',
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
      'You guides your equine cock toward Jane Ratwood and her furred slit.',
    );
    expect(resolveErpPreviewTokens(text, 'sex-receiving', profile)).toBe(
      'Mara Ratwood guides her equine cock toward You and your furred slit.',
    );
  });

  it('uses separate custom anatomy token owners for sex action previews', () => {
    const profile = {
      ...createDefaultErpPreviewProfile(),
      userName: 'John Ratwood',
      userThey: 'he',
      userThem: 'him',
      userTheir: 'his',
      userCock: 'nonexistent',
      targetName: 'Jane Ratwood',
      targetThey: 'she',
      targetThem: 'her',
      targetTheir: 'her',
      targetVag: 'nonexistent',
      targetBreastType: 'nonexistent',
    };
    const userAnatomyTokens = {
      cock: 'big penis',
    };
    const targetAnatomyTokens = {
      vag: 'normal vagina',
      breast_type: 'big chest',
    };
    const text = '[USER] guides [UCOCK] toward [TVAG] and [TBREASTTYPE].';

    expect(
      resolveErpPreviewTokens(
        text,
        'sex-giving',
        profile,
        userAnatomyTokens,
        targetAnatomyTokens,
      ),
    ).toBe(
      'You guides your big penis toward her normal vagina and her big chest.',
    );
    expect(
      resolveErpPreviewTokens(
        text,
        'sex-receiving',
        profile,
        userAnatomyTokens,
        targetAnatomyTokens,
      ),
    ).toBe(
      'John Ratwood guides his big penis toward your normal vagina and your big chest.',
    );
  });

  it('uses shared custom anatomy tokens for sex and intimate preview nouns', () => {
    const profile = {
      ...createDefaultErpPreviewProfile(),
      userName: 'Mara Ratwood',
      userThey: 'she',
      userThem: 'her',
      userTheir: 'her',
      penisType: 'plain cock',
      sizeAdj: 'heavy',
      vagAdj: 'slick',
      vagType: 'plain slit',
      cupSize: 'plain cup',
      breastType: 'plain breasts',
      userCock: 'plain cock',
      userVag: 'plain slit',
      userCupSize: 'plain cup',
      userBreastType: 'plain breasts',
      targetName: 'Jane Ratwood',
      targetThey: 'she',
      targetThem: 'her',
      targetTheir: 'her',
      targetCock: 'barbed cock',
    };
    const anatomyTokens = {
      cock: 'big ol dick',
      vag: 'axe wound pussy',
      cup_size: 'double Qs',
      breast_type: 'hyper chest',
    };

    expect(
      resolveErpPreviewTokens(
        '[PENIS_TYPE] [VAGTYPE] [CUPSIZE] [BREASTTYPE] [SIZEADJ] [VAGADJ]',
        'intimate-bystander',
        profile,
        anatomyTokens,
      ),
    ).toBe('big ol dick axe wound pussy double Qs hyper chest heavy slick');
    expect(
      resolveErpPreviewTokens(
        '[USER] guides [UCOCK] toward [UVAG] and [UBREASTTYPE].',
        'sex-giving',
        profile,
        anatomyTokens,
      ),
    ).toBe(
      'You guides your big ol dick toward your axe wound pussy and your hyper chest.',
    );
    expect(
      resolveErpPreviewTokens(
        '[TARGET] guides [TCOCK] toward [TVAG].',
        'sex-receiving',
        profile,
        anatomyTokens,
      ),
    ).toBe('You guides your big ol dick toward your axe wound pussy.');
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
