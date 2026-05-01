/**
 * @file widgets/BarkPreviewButton.tsx
 * @description Sibling of {@link VoicePreviewButton} for the bark
 * preview row in Identity → Voice.
 *
 * Kept as a sibling component (rather than a `kind` prop on a single
 * shared component) because the two previews talk to different
 * server-side handlers and may diverge in disabled-state semantics
 * once the bark preview gets cooldown gating. The shared shape is the
 * play-icon Button only.
 */

import { Button } from 'tgui-core/components';

import { useBackend } from '../../../backend';

export interface BarkPreviewButtonProps {
  /** Optional bark id; omitted = current bark. */
  barkId?: string;
  /** Disable explicitly (e.g. while another preview is playing). */
  disabled?: boolean;
  /** Optional className hook for §19 styling. */
  className?: string;
}

export function BarkPreviewButton(props: BarkPreviewButtonProps) {
  const { barkId, disabled, className } = props;
  const { act } = useBackend();
  return (
    <Button
      className={className}
      icon="play"
      tooltip="Preview bark"
      disabled={disabled}
      onClick={() => act('preview_bark', barkId ? { bark: barkId } : undefined)}
    >
      Bark
    </Button>
  );
}
