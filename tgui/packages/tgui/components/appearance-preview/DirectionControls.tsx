/**
 * @file DirectionControls.tsx
 * @description Reusable S/N/E/W direction picker for the v2 preview editor
 * scaffold. This file owns the pure direction-button implementation so helper
 * tests can import transform controls without pulling in the full preview
 * barrel and its BYOND map-view side effects.
 */

import { Button } from 'tgui-core/components';

import { Box } from '../Box';
import type { AppearancePreviewV2DirectionKey } from './shared';

/** Shared S/N/E/W ordering for appearance-preview editors. */
export const APPEARANCE_PREVIEW_DIRECTION_KEYS: readonly AppearancePreviewV2DirectionKey[] =
  ['s', 'n', 'e', 'w'];

const DIRECTION_LABELS: Record<AppearancePreviewV2DirectionKey, string> = {
  s: 'S',
  n: 'N',
  e: 'E',
  w: 'W',
};

const DIRECTION_ICONS: Record<AppearancePreviewV2DirectionKey, string> = {
  s: 'arrow-down',
  n: 'arrow-up',
  e: 'arrow-right',
  w: 'arrow-left',
};

/**
 * @deprecated Alias for `AppearancePreviewV2DirectionKey`. Kept for editors
 * mid-migration; remove when Steps 10/11 land.
 */
export type AppearancePreviewDirectionKey = AppearancePreviewV2DirectionKey;

interface Props {
  /** Currently active direction. */
  activeDir: AppearancePreviewV2DirectionKey;
  /** Called with the newly selected direction. */
  onChange: (dir: AppearancePreviewV2DirectionKey) => void;
  /** Optional subset of directions to display. Defaults to S/N/E/W. */
  dirKeys?: readonly AppearancePreviewV2DirectionKey[];
  /** Optional label rendered before the buttons. */
  label?: string;
}

/**
 * Shared S/N/E/W direction buttons used by both editors.
 *
 * Each button has an icon and text label so the control remains usable for
 * keyboard and screen-reader paths while still fitting compact editor rows.
 */
export function AppearancePreviewDirectionButtons(props: {
  activeDir: AppearancePreviewV2DirectionKey;
  dirKeys?: readonly AppearancePreviewV2DirectionKey[];
  onChange: (dir: AppearancePreviewV2DirectionKey) => void;
}) {
  const {
    activeDir,
    dirKeys = APPEARANCE_PREVIEW_DIRECTION_KEYS,
    onChange,
  } = props;

  return (
    <Box
      style={{
        display: 'flex',
        gap: '0.25rem',
        alignItems: 'center',
        flexWrap: 'nowrap',
      }}
    >
      {dirKeys.map((dir) => (
        <Button
          key={dir}
          compact
          selected={dir === activeDir}
          icon={DIRECTION_ICONS[dir]}
          tooltip={`Preview direction ${DIRECTION_LABELS[dir]}`}
          onClick={() => onChange(dir)}
        >
          {DIRECTION_LABELS[dir]}
        </Button>
      ))}
    </Box>
  );
}

/**
 * Labelled direction picker. Label is rendered inline and skipped when
 * omitted so the control can be dropped into tight toolbars.
 */
export function DirectionControls(props: Props) {
  const {
    activeDir,
    onChange,
    dirKeys = APPEARANCE_PREVIEW_DIRECTION_KEYS,
    label,
  } = props;
  return (
    <Box
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
      }}
    >
      {label ? (
        <Box style={{ fontWeight: 600, fontSize: '11px' }}>{label}</Box>
      ) : null}
      <AppearancePreviewDirectionButtons
        activeDir={activeDir}
        dirKeys={dirKeys}
        onChange={onChange}
      />
    </Box>
  );
}
