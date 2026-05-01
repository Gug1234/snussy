/**
 * @file widgets/OriginMap.tsx
 * @description Clickable origin-region overlay used by Identity → Origin.
 *
 * The server emits a static map image asset + a list of polygon
 * (or rectangle) regions in `ui_static_data`. This widget renders the
 * image, overlays each region as an absolutely-positioned hit zone,
 * and emits `onSelect(regionId)` on click. The active region carries
 * a gold border per §5.2 to mirror the row-list active treatment.
 *
 * Step 9 ships the primitive only — Step 10's Identity body wires
 * `onSelect` to `ledger.stage('origin', regionId)`.
 */

import type { CSSProperties, KeyboardEvent } from 'react';
import { Box } from 'tgui-core/components';

export interface OriginRegion {
  /** Stable region id matching the server's origin enum. */
  id: string;
  /** Display label for tooltip / a11y. */
  label: string;
  /**
   * Hit-zone rect in source-image pixels. The widget rescales to the
   * rendered image dimensions automatically.
   */
  rect: { x: number; y: number; w: number; h: number };
}

export interface OriginMapProps {
  /** Map image URL (already passed through `resolveAsset`). */
  imageUrl: string;
  /** Source image dimensions; needed to rescale hit zones. */
  sourceWidth: number;
  sourceHeight: number;
  /** Regions to overlay. */
  regions: readonly OriginRegion[];
  /** Currently selected region id, if any. */
  selected?: string | null;
  /** Click/keyboard select handler. */
  onSelect: (regionId: string) => void;
  /** Render width (defaults to sourceWidth). */
  width?: number;
  /** Optional className hook for §19 styling. */
  className?: string;
}

export function OriginMap(props: OriginMapProps) {
  const {
    imageUrl,
    sourceWidth,
    sourceHeight,
    regions,
    selected,
    onSelect,
    width,
    className,
  } = props;

  const renderW = width ?? sourceWidth;
  const renderH = (renderW / sourceWidth) * sourceHeight;
  const sx = renderW / sourceWidth;
  const sy = renderH / sourceHeight;

  const wrapStyle: CSSProperties = {
    position: 'relative',
    width: `${renderW}px`,
    height: `${renderH}px`,
    backgroundImage: `url("${imageUrl}")`,
    backgroundRepeat: 'no-repeat',
    backgroundSize: 'contain',
  };

  const onKey = (e: KeyboardEvent<HTMLDivElement>, id: string) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onSelect(id);
    }
  };

  return (
    <Box className={className} style={wrapStyle}>
      {regions.map((region) => {
        const isActive = region.id === selected;
        const style: CSSProperties = {
          position: 'absolute',
          left: `${region.rect.x * sx}px`,
          top: `${region.rect.y * sy}px`,
          width: `${region.rect.w * sx}px`,
          height: `${region.rect.h * sy}px`,
          border: isActive
            ? '2px solid #c9a24b'
            : '1px solid rgba(232, 200, 128, 0.25)',
          background: isActive
            ? 'rgba(201, 162, 75, 0.15)'
            : 'rgba(0, 0, 0, 0)',
          cursor: 'pointer',
          boxSizing: 'border-box',
        };
        return (
          <div
            key={region.id}
            role="button"
            tabIndex={0}
            aria-label={region.label}
            aria-pressed={isActive}
            title={region.label}
            style={style}
            onClick={() => onSelect(region.id)}
            onKeyDown={(e) => onKey(e, region.id)}
          />
        );
      })}
    </Box>
  );
}
