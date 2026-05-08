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
});
