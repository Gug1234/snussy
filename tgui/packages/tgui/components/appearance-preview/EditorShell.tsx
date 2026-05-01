/**
 * @file EditorShell.tsx
 * @description Shared layout + commit surface for v2 sheet-backed
 * appearance-preview editors. Owns:
 *   - Header (title, dirty indicator, optional header slot).
 *   - Body (caller-composed children — the editor's own sections).
 *   - Footer CommitBar (Save / Close wired through the commit controller).
 *   - Error banner (red, assertive) on commit failure.
 *   - Warning banner (amber, polite) on degraded-success commits.
 *
 * Before this shell each editor hand-rolled its own `<DirtyIndicator>`
 * stack-row, trailing `<CommitBar>` + `<NoticeBox>`, and manually wired
 * Save/Close to `controller.requestCommit`. That pattern had three issues:
 *   1. Duplicated commit-result plumbing across every future editor.
 *   2. Close handlers that had to know the `!dirty → act('close')` shortcut
 *      and the `dirty → requestCommit('close')` path.
 *   3. No home for the degraded-success warning banner, so Step 4's
 *      two-phase persist outcome had nowhere to surface in the UI.
 *
 * This shell collapses all three into a single contract the editors just
 * drop their body into.
 *
 * ## Contract for callers
 *
 * The editor supplies:
 *   - `commitController` — the hook return from `useCommitController`.
 *   - `buildSnapshot` — a pure closure over current draft state. Called
 *     at click time; must NOT have side effects.
 *   - `onCommitted` — clears the local `dirty` flag after a successful
 *     save-intent commit. Not called on close-intent (window is going
 *     away) or on failure.
 *   - `onCloseClean` — fires `act('close')` when the draft is already
 *     clean. The shell takes the clean-path shortcut so a pristine editor
 *     never generates commit traffic just to shut down.
 *
 * The shell does NOT know about the editor's draft shape — it is purely
 * a composition + commit-UX layer.
 *
 * ## Scale note (200-client worst case)
 *
 * The shell does not subscribe to ui_data, does not poll, and does not
 * trigger any background work. The only re-renders it forces are on
 * controller state transitions (at most one per click). Under 200
 * concurrent editors the shell's render cost is bounded by user input
 * rate, not by server tick rate.
 */

import type { ReactNode } from 'react';
import { NoticeBox } from 'tgui-core/components';

import { Box } from '../Box';
import { CommitBar } from './CommitBar';
import type { CommitController } from './CommitController';
import { DirtyIndicator } from './DirtyIndicator';

interface Props<TSnapshot> {
  /** Editor title shown in the header. */
  title: string;
  /** Whether the draft has uncommitted changes. Drives Save-button enablement
   *  and the dirty badge. Owned by the editor, not the shell. */
  dirty: boolean;
  /** The close-safe commit controller from `useCommitController`. */
  commitController: CommitController<TSnapshot>;
  /** Pure snapshot builder invoked at click time for Save and Close. */
  buildSnapshot: () => TSnapshot;
  /**
   * Called after a successful save-intent commit. Intended to clear the
   * editor's local `dirty` flag. Not invoked on close-intent (the window
   * is already closing) or on failure.
   */
  onCommitted?: () => void;
  /**
   * Clean-path close dispatch. Invoked when Close is clicked while the
   * draft is clean; typically wraps `act('close')`.
   */
  onCloseClean: () => void;
  /** Body content — the editor's own composition of sections, previews, and
   *  controls. Renders full-width; no preview/controls split is imposed. */
  children: ReactNode;
  /** Optional header slot between the title and the dirty badge (e.g. a
   *  part picker, description line, Export/Import buttons). */
  headerSlot?: ReactNode;
  /** Optional tertiary slot rendered on the left of the CommitBar. */
  commitTertiary?: ReactNode;
  /** Save-button label override. */
  saveLabel?: string;
  /** Close-button label override. */
  closeLabel?: string;
}

/**
 * Mandatory shell for appearance-preview editors. See file-level docs for
 * the full contract.
 */
export function EditorShell<TSnapshot>(props: Props<TSnapshot>) {
  const {
    title,
    dirty,
    commitController,
    buildSnapshot,
    onCommitted,
    onCloseClean,
    children,
    headerSlot,
    commitTertiary,
    saveLabel,
    closeLabel,
  } = props;

  const committing = commitController.status === 'committing';

  // Save path: route through the controller; clear dirty on success. The
  // controller preserves the draft on failure and surfaces the error banner.
  const onSave = async () => {
    const result = await commitController.requestCommit(
      'save',
      buildSnapshot(),
    );
    if (result.ok && onCommitted) {
      onCommitted();
    }
  };

  // Close path: skip the server round-trip if clean. Otherwise route the
  // close-intent commit through the controller, which only dispatches the
  // actual close AFTER the server confirms persistence.
  const onClose = async () => {
    if (!dirty) {
      onCloseClean();
      return;
    }
    await commitController.requestCommit('close', buildSnapshot());
    // On success the controller fires its closeDispatch internally; on
    // failure the shell stays mounted and the error banner shows.
  };

  return (
    <Box
      style={{
        display: 'flex',
        flexDirection: 'column',
        minHeight: 0,
      }}
    >
      {/* ── Header ────────────────────────────────────────────────────── */}
      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '0.75rem',
          padding: '0.5rem 0.75rem',
          borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
          flexWrap: 'wrap',
        }}
      >
        <Box
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            flexWrap: 'wrap',
          }}
        >
          <Box style={{ fontWeight: 700, fontSize: '13px' }}>{title}</Box>
          {headerSlot}
        </Box>
        <DirtyIndicator dirty={dirty} />
      </Box>

      {/* ── Banners (error > warning) ─────────────────────────────────── */}
      {commitController.error && (
        <NoticeBox danger m={0} style={{ borderRadius: 0 }}>
          Commit failed: {commitController.error}
        </NoticeBox>
      )}
      {!commitController.error && commitController.warning && (
        <NoticeBox
          m={0}
          style={{
            borderRadius: 0,
            background: '#a47b18',
            color: '#fff',
          }}
        >
          {commitController.warning}
        </NoticeBox>
      )}

      {/* ── Body ──────────────────────────────────────────────────────── */}
      <Box style={{ padding: '0.5rem 0.75rem' }}>{children}</Box>

      {/* ── Footer ────────────────────────────────────────────────────── */}
      <CommitBar
        onSave={onSave}
        onClose={onClose}
        dirty={dirty}
        committing={committing}
        tertiary={commitTertiary}
        saveLabel={saveLabel}
        closeLabel={closeLabel}
      />
    </Box>
  );
}
