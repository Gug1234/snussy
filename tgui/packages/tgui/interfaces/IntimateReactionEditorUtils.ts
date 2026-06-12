import type {
  CustomAnatomyTokenData,
  ErpPreviewProfileData,
} from './common/ErpPreviewOptions';
import { resolveErpPreviewTokens } from './common/ErpPreviewOptions';

export type IntimateReactionPreviewPerspective = 'wearer' | 'bystander';

export function resolveIntimateReactionPreviewTokens(
  text: string,
  perspective: IntimateReactionPreviewPerspective = 'wearer',
  profile?: ErpPreviewProfileData,
  anatomyTokens?: CustomAnatomyTokenData,
): string {
  return resolveErpPreviewTokens(
    text,
    perspective === 'wearer' ? 'intimate-wearer' : 'intimate-bystander',
    profile,
    anatomyTokens,
  );
}
