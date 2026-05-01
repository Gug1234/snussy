/**
 * @file CommitBar.tsx
 * @description Reusable Save/Close action group for the v2 editor scaffold.
 * Primary action is Save, secondary is Close. Optional tertiary slot for
 * reset-style helpers. The bar does NOT dispatch commit requests itself;
 * owners wire `onSave` and `onClose` to their backend contract (per Step 12
 * that contract is standardised, so every editor will pass the same shape).
 *
 * Layout rationale: primary action right-aligned to match the project's
 * commit-action convention; dirty indicator slot left-aligned so the state
 * label sits nearest the content it describes.
 */

import type { ReactNode } from 'react';
import { Button } from 'tgui-core/components';

import { Box } from '../Box';

interface Props {
  /** Invoked when Save is clicked. Editors commit their draft snapshot here. */
  onSave: () => void;
  /** Invoked when Close is clicked. Per the commit-once contract this may
   *  also commit a draft if `dirty` is true — callers decide. */
  onClose: () => void;
  /** Whether the draft is dirty. Disables Save when false to reduce redundant
   *  commits; Close stays enabled. */
  dirty: boolean;
  /** Optional Save button label override. */
  saveLabel?: string;
  /** Optional Close button label override. */
  closeLabel?: string;
  /** Optional tertiary controls rendered at the left of the bar (e.g. reset,
   *  revision token display). */
  tertiary?: ReactNode;
  /** Optional dirty indicator or status slot rendered next to Save/Close. */
  statusSlot?: ReactNode;
  /** Whether the commit pipeline is currently in flight. Disables Save to
   *  prevent double-submit; Close stays usable so users can bail. */
  committing?: boolean;
}

/**
 * Bottom-of-editor action bar. Stacks on narrow screens via flex-wrap so the
 * commit actions remain reachable per the responsive guidance.
 */
export function CommitBar(props: Props) {
  const {
    onSave,
    onClose,
    dirty,
    saveLabel = 'Save',
    closeLabel = 'Close',
    tertiary,
    statusSlot,
    committing = false,
  } = props;

  return (
    <Box
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '0.5rem',
        padding: '0.5rem 0.75rem',
        borderTop: '1px solid rgba(255, 255, 255, 0.08)',
        flexWrap: 'wrap',
      }}
    >
      <Box style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
        {tertiary}
      </Box>
      <Box style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
        {statusSlot}
        <Button
          icon="times"
          onClick={onClose}
          disabled={committing}
          tooltip="Close this editor. The draft is committed if there are unsaved changes."
        >
          {closeLabel}
        </Button>
        <Button
          icon="floppy-disk"
          color="good"
          onClick={onSave}
          disabled={!dirty || committing}
          tooltip={
            committing
              ? 'Committing…'
              : dirty
                ? 'Commit the current draft to the server.'
                : 'No unsaved changes.'
          }
        >
          {saveLabel}
        </Button>
      </Box>
    </Box>
  );
}
