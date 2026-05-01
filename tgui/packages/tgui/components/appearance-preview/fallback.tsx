/**
 * @file fallback.tsx
 * @description Visible placeholder rendered when a preview state or crop is
 * unresolvable in the v2 sheet-backed runtime. Shown instead of silently
 * hiding the tile so missing adapter data or a stale manifest surfaces
 * immediately during QA.
 */

import { Box } from '../Box';

interface Props {
  /** The icon_state the renderer was asked for, shown as debug text. */
  iconState?: string;
  /** Tile width in pixels (defaults to the project's 32x32 convention). */
  width?: number;
  /** Tile height in pixels (defaults to the project's 32x32 convention). */
  height?: number;
  /** Optional direction key shown alongside the state for quick triage. */
  direction?: string;
}

/**
 * Red-dashed-border placeholder with a "?" glyph and compact debug text.
 * Intentionally loud so no reviewer mistakes it for an expected tile.
 */
export function AppearancePreviewFallback(props: Props) {
  const { iconState, width = 32, height = 32, direction } = props;
  const label = iconState
    ? direction
      ? `${iconState} @${direction}`
      : iconState
    : 'missing';

  // Title is set via a native tooltip wrapper so screen-readers still get
  // the debug text without fighting the Box prop surface.
  return (
    <span title={`Appearance preview missing: ${label}`}>
      <Box
        style={{
          width: `${width}px`,
          height: `${height}px`,
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          border: '1px dashed #c0392b',
          color: '#c0392b',
          background: 'rgba(192, 57, 43, 0.08)',
          fontFamily: 'monospace',
          fontSize: '10px',
          lineHeight: 1,
          boxSizing: 'border-box',
        }}
      >
        ?
      </Box>
    </span>
  );
}
