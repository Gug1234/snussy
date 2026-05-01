/**
 * @file widgets/BracketedValueSlot.tsx
 * @description The gold-bordered `[ value ]` value-display primitive
 * specified in design system §5.6.
 *
 * Used wherever a row needs to show a single readable value alongside
 * an editor (e.g. left-column row right-side value display in §5.6,
 * or a body-card "current value" header). Pure presentation; no
 * dispatch, no ledger interaction.
 *
 * Step 19 will swap the inline style for class-based theming. Until
 * then the inline gold/slate keeps the visual landing reviewable.
 */

import type { CSSProperties, ReactNode } from 'react';
import { Box } from 'tgui-core/components';

export interface BracketedValueSlotProps {
  /** Renderable value content. Strings, numbers, or arbitrary nodes. */
  children: ReactNode;
  /** Disable styling (40% opacity) per §5.6. */
  disabled?: boolean;
  /** Optional click handler — turns the slot into a focusable target. */
  onClick?: () => void;
  /** Optional className hook for §19 styling. */
  className?: string;
  /** Optional aria-label for screen readers when the value isn't text. */
  ariaLabel?: string;
}

export function BracketedValueSlot(props: BracketedValueSlotProps) {
  const { children, disabled, onClick, className } = props;
  const interactive = !!onClick && !disabled;

  const style: CSSProperties = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    padding: '2px 8px',
    border: '1px solid #c9a24b',
    color: '#e7dcc0',
    background: '#1e1c18',
    fontFamily: 'serif',
    minHeight: '22px',
    opacity: disabled ? 0.4 : 1,
    cursor: interactive ? 'pointer' : 'default',
  };

  return (
    <Box
      className={className}
      style={style}
      onClick={interactive ? onClick : undefined}
      // a11y attrs (role/tabIndex/aria-label) intentionally omitted: tgui-core Box
      // does not type them. Wrap with a native <div> if a11y becomes required.
    >
      <span style={{ color: '#9b8e6b' }}>[</span>
      <span>{children}</span>
      <span style={{ color: '#9b8e6b' }}>]</span>
    </Box>
  );
}
