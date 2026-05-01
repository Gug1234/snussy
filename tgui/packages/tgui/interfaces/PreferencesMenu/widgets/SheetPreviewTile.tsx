/**
 * @file widgets/SheetPreviewTile.tsx
 * @description CSS-cropped sprite tile backed by a preloaded asset.
 *
 * The prefs asset bundle (Step 6) registers per-category sheets under
 * stable resource names so the client can address sprites by
 * `(sheetAsset, x, y, width, height)` without ever round-tripping the
 * server during a render. This widget is the single point that
 * resolves a sheet asset to a URL via `resolveAsset()` and clips the
 * background to the requested rect.
 *
 * Steps 10-13 will pass concrete `(sheet, x, y)` values from
 * server-emitted offset maps in `ui_static_data`. Until then this
 * widget is a callable but unused primitive; rendering with
 * `sheetAsset=undefined` falls through to a checker placeholder so
 * incomplete bodies stay visually obvious during incremental landing.
 *
 * Performance: uses CSS `background-image` + `background-position`
 * (no `<img>`), so multiple tiles against the same sheet cost one
 * texture decode at most. `imageRendering: pixelated` preserves the
 * DMI aesthetic at integer scale.
 */

import type { CSSProperties, ReactNode } from 'react';
import { Box } from 'tgui-core/components';

import { resolveAsset } from '../../../assets';

/** Native source tile size for DMI sprites (32x32). */
const DEFAULT_TILE_PX = 32;

export interface SheetPreviewTileProps {
  /**
   * Asset resource name (matches what the server emits via
   * `send_asset` → `resolveAsset()`). When undefined the tile renders
   * a checker placeholder.
   */
  sheetAsset?: string;
  /** X offset into the sheet, in source pixels. */
  x?: number;
  /** Y offset into the sheet, in source pixels. */
  y?: number;
  /** Source crop width in pixels (default 32). */
  width?: number;
  /** Source crop height in pixels (default 32). */
  height?: number;
  /**
   * Integer scale factor applied via background-size. Use 1, 2, or 3
   * for crisp pixelated output. Non-integer scales blur.
   */
  scale?: number;
  /** Optional className hook for §19 styling. */
  className?: string;
  /** Optional click handler (e.g. picker tiles). */
  onClick?: () => void;
  /**
   * Optional tint color (CSS string, e.g. `#aabbcc`). When set, a
   * colored overlay is composited over the sprite with
   * `mix-blend-mode: multiply`, masked by the sprite's alpha via
   * `mask-image`. This mirrors the GAGS-style multiply tint used
   * by the in-game accessory rendering pipeline. The tile container
   * becomes a relatively-positioned wrapper so the overlay can
   * stack.
   */
  tint?: string;
}

/** Reusable repeating-conic checker for the missing-asset state. */
const CHECKER_BG =
  'repeating-conic-gradient(#222 0 25%, #2a2a2a 0 50%) 50% / 8px 8px';

export function SheetPreviewTile(props: SheetPreviewTileProps) {
  const {
    sheetAsset,
    x = 0,
    y = 0,
    width = DEFAULT_TILE_PX,
    height = DEFAULT_TILE_PX,
    scale = 1,
    className,
    onClick,
    tint,
  } = props;

  const url = sheetAsset ? resolveAsset(sheetAsset) : null;
  const dispW = Math.max(1, Math.round(width * scale));
  const dispH = Math.max(1, Math.round(height * scale));

  const style: CSSProperties = {
    width: `${dispW}px`,
    height: `${dispH}px`,
    imageRendering: 'pixelated',
    cursor: onClick ? 'pointer' : undefined,
    display: 'inline-block',
    position: 'relative',
  };
  if (url) {
    // Position the sheet so the requested (x,y) lands at (0,0) in the
    // tile. Multiply by `-scale` so the crop scales together with the
    // tile dimensions; otherwise sub-tile picks would drift.
    style.background = `url("${url}") no-repeat`;
    style.backgroundPosition = `${-x * scale}px ${-y * scale}px`;
    // background-size scales the underlying sheet; we only know the
    // tile rect, so scale by ratio of crop-to-display.
    style.backgroundSize = 'auto';
    if (scale !== 1) {
      // Use a transform on the bg by leveraging backgroundSize. Sheets
      // are authored at native res; scale via CSS transform on the
      // background by setting an explicit size relative to the source.
      // Simpler + correct: scale the whole tile via transform and keep
      // background as 1:1 by undoing the integer scale.
      style.transform = `scale(${scale})`;
      style.transformOrigin = 'top left';
      style.width = `${width}px`;
      style.height = `${height}px`;
      style.backgroundPosition = `${-x}px ${-y}px`;
    }
  } else {
    style.background = CHECKER_BG;
  }

  // Tint overlay: a colored block masked by the sprite alpha, blended
  // multiply over the sprite so saturated tints darken/colorize the
  // base art without painting over transparent pixels. Only emitted
  // when the caller passed a tint AND we have a real sprite URL —
  // tinting the checker placeholder would be misleading.
  let overlay: ReactNode = null;
  if (url && tint) {
    const overlayStyle: CSSProperties = {
      position: 'absolute',
      left: 0,
      top: 0,
      width: `${width}px`,
      height: `${height}px`,
      backgroundColor: tint,
      mixBlendMode: 'multiply',
      pointerEvents: 'none',
      // Mask to the sprite's opaque pixels via the same crop. Using
      // both -webkit-mask-* and mask-* keeps Chromium and Firefox
      // happy. CSS doesn't auto-prefix `mask-position` / `mask-size`
      // when the standard properties land in different shipping
      // versions; tgui targets recent Electron, but the prefix is
      // cheap insurance.
      maskImage: `url("${url}")`,
      maskRepeat: 'no-repeat',
      maskPosition: `${-x}px ${-y}px`,
      maskSize: 'auto',
      WebkitMaskImage: `url("${url}")`,
      WebkitMaskRepeat: 'no-repeat',
      WebkitMaskPosition: `${-x}px ${-y}px`,
      WebkitMaskSize: 'auto',
    };
    overlay = <Box style={overlayStyle} />;
  }

  return (
    <Box
      className={className}
      style={style}
      onClick={onClick}
      // a11y attrs (role/tabIndex/aria-label) omitted: not on tgui-core Box typing.
    >
      {overlay}
    </Box>
  );
}
