/**
 * @file widgets/VoicePreviewButton.tsx
 * @description Tiny play-icon button that triggers a server-side voice
 * preview via `act('preview_voice')`.
 *
 * Used in Identity → Voice. The action is intentionally action-table
 * scoped, NOT set_pref — playing audio is an effect, not a pref
 * mutation. Step 10's Identity body wires the matching server handler.
 *
 * Disabled state respects in-flight previews when the server reports
 * `voice_preview_busy = TRUE`; until then the button is a fire-and-
 * forget click.
 */

import { Button } from 'tgui-core/components';

import { useBackend } from '../../../backend';

export interface VoicePreviewButtonProps {
  /** Optional voice id; omitted = current voice. */
  voiceId?: string;
  /** Disable explicitly (e.g. while another preview is playing). */
  disabled?: boolean;
  /** Optional className hook for §19 styling. */
  className?: string;
}

export function VoicePreviewButton(props: VoicePreviewButtonProps) {
  const { voiceId, disabled, className } = props;
  const { act } = useBackend();
  return (
    <Button
      className={className}
      icon="play"
      tooltip="Preview voice"
      disabled={disabled}
      onClick={() =>
        act('preview_voice', voiceId ? { voice: voiceId } : undefined)
      }
    >
      Voice
    </Button>
  );
}
