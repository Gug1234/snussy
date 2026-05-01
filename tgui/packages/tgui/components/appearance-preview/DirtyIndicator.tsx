/**
 * @file DirtyIndicator.tsx
 * @description Reusable dirty-state badge for the v2 editor scaffold. Shown
 * when local draft state differs from the last committed snapshot so users
 * understand that Save/Close are the only moments state is persisted.
 *
 * Purely presentational. Editors pass `dirty` from their own draft
 * bookkeeping; the badge does not track state itself.
 */

import { Box } from '../Box';

interface Props {
  /** Whether the draft has uncommitted changes. */
  dirty: boolean;
  /** Optional override label for the dirty state. */
  dirtyLabel?: string;
  /** Optional override label for the clean state. */
  cleanLabel?: string;
}

/**
 * Pill-shaped badge. Amber when dirty (matches commit-affordance accent in
 * the design system), muted slate when clean. Kept compact so it can sit in
 * the CommitBar or EditorShell header without dominating.
 */
export function DirtyIndicator(props: Props) {
  const { dirty, dirtyLabel = 'Unsaved changes', cleanLabel = 'Saved' } = props;
  // Wrap the Box in a plain span so we can attach ARIA attributes — the
  // Box component restricts its prop surface and doesn't pass through
  // `role` / `aria-live`.
  return (
    <span role="status" aria-live="polite">
      <Box
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '0.25rem',
          padding: '0.15rem 0.5rem',
          borderRadius: '999px',
          fontSize: '11px',
          fontWeight: 600,
          letterSpacing: '0.02em',
          // Amber for dirty, muted slate for clean. WCAG AA on dark panels.
          background: dirty
            ? 'rgba(217, 147, 42, 0.18)'
            : 'rgba(128, 128, 128, 0.12)',
          color: dirty ? '#d9932a' : '#9a9a9a',
          border: `1px solid ${dirty ? 'rgba(217, 147, 42, 0.55)' : 'rgba(128, 128, 128, 0.35)'}`,
        }}
      >
        {dirty ? '●' : '○'} {dirty ? dirtyLabel : cleanLabel}
      </Box>
    </span>
  );
}
