import { describe, expect, it } from 'bun:test';

import { resolveIntimateReactionPreviewTokens } from './interfaces/IntimateReactionEditorUtils';

describe('resolveIntimateReactionPreviewTokens', () => {
  it('renders wearer-facing preview text in second person', () => {
    expect(
      resolveIntimateReactionPreviewTokens(
        '[USER] shifts [THEIR] [PENIS_TYPE] as [THEY] pass [TARGET].',
        'wearer',
      ),
    ).toBe('You shift your knotted cock as you pass John Ratwood.');
  });

  it('renders bystander-facing preview text in third person', () => {
    expect(
      resolveIntimateReactionPreviewTokens(
        '[USER] shifts [THEIR] [PENIS_TYPE] as [THEY] pass [TARGET].',
        'bystander',
      ),
    ).toBe('Wearer shifts their knotted cock as they pass John Ratwood.');
  });

  it('renders user possessive tokens without forming You-s possessives', () => {
    const text = '[USERPOS] tail blooms while [USER] can feel it.';

    expect(resolveIntimateReactionPreviewTokens(text, 'wearer')).toBe(
      'your tail blooms while you can feel it.',
    );
    expect(resolveIntimateReactionPreviewTokens(text, 'bystander')).toBe(
      "Wearer's tail blooms while Wearer can feel it.",
    );
  });
});
