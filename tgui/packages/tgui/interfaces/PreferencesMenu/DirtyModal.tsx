/**
 * @file DirtyModal.tsx
 * @description Client-side "Save or discard?" modal (Step 8 rewrite).
 *
 * Two render variants:
 *   - `tab-switch` (default) — fired when the shell intercepts a
 *     category/row change while the DirtyLedger has non-autosave
 *     pending writes. Buttons: Save & switch / Discard & switch /
 *     Cancel. Used by index.tsx route changes and by the Close button.
 *   - `join` — fired by the BottomBar Join action (Step 15) when the
 *     ledger still has non-autosave dirt. Buttons: Save & Join /
 *     Discard & Join / Cancel.
 *
 * Why one component for two variants:
 *   - The structural body is identical (heading + explanatory copy +
 *     three-button row). Only the labels and copy diverge. A single
 *     component keeps DirtyModal as the single visual source of truth
 *     and lets Step 19 style both variants with one CSS class hook.
 *
 * Server-side dirty tracking is intentionally NOT introduced — by the
 * time a route change or join action reaches the server the user's
 * choice has already been resolved on the client.
 */

import { Box, Button, Stack } from 'tgui-core/components';

/** Modal usage context. */
export type DirtyModalVariant = 'tab-switch' | 'join';

/**
 * Props for the dirty-draft confirmation modal.
 */
export interface DirtyModalProps {
  /**
   * Variant selector. Defaults to `'tab-switch'` so existing call
   * sites keep their current behavior.
   */
  variant?: DirtyModalVariant;
  /**
   * For `tab-switch`: which tab the user is leaving (copy
   * personalisation). Ignored for `join`.
   */
  fromTabLabel?: string;
  /**
   * For `tab-switch`: which tab the user is switching to.
   * For `join`: the target action label (e.g. "Join Game",
   * "Join Migrant Wave: Refugees").
   */
  toTabLabel?: string;
  /** User chose Save (and switch / and join). */
  onSave: () => void;
  /** User chose Discard (and switch / and join). */
  onDiscard: () => void;
  /** User chose Cancel (or closed the modal). */
  onCancel: () => void;
}

/** Per-variant button copy. Kept out of the JSX for readability. */
function copyFor(variant: DirtyModalVariant): {
  saveLabel: string;
  discardLabel: string;
} {
  if (variant === 'join') {
    return { saveLabel: 'Save & Join', discardLabel: 'Discard & Join' };
  }
  return { saveLabel: 'Save & switch', discardLabel: 'Discard & switch' };
}

/**
 * Render the modal body. Intended to be composed inside a `<Modal>`
 * or absolute-positioned overlay by the caller.
 */
export function DirtyModal(props: DirtyModalProps) {
  const {
    variant = 'tab-switch',
    fromTabLabel = '',
    toTabLabel = '',
    onSave,
    onDiscard,
    onCancel,
  } = props;
  const { saveLabel, discardLabel } = copyFor(variant);

  return (
    <Box p={2} width="380px">
      <Box bold mb={1}>
        Unsaved changes
      </Box>
      <Box mb={2}>
        {variant === 'join' ? (
          <>
            You have uncommitted changes. Joining as <b>{toTabLabel}</b> will
            commit or discard them first.
          </>
        ) : (
          <>
            You have uncommitted changes
            {fromTabLabel ? (
              <>
                {' '}
                in the <b>{fromTabLabel}</b> section
              </>
            ) : null}
            {toTabLabel ? (
              <>
                . Switching to <b>{toTabLabel}</b> will lose these changes
                unless you save first.
              </>
            ) : (
              '.'
            )}
          </>
        )}
      </Box>
      <Stack>
        <Stack.Item grow>
          <Button fluid color="good" icon="save" onClick={onSave}>
            {saveLabel}
          </Button>
        </Stack.Item>
        <Stack.Item grow>
          <Button fluid color="bad" icon="trash" onClick={onDiscard}>
            {discardLabel}
          </Button>
        </Stack.Item>
        <Stack.Item grow>
          <Button fluid icon="times" onClick={onCancel}>
            Cancel
          </Button>
        </Stack.Item>
      </Stack>
    </Box>
  );
}
