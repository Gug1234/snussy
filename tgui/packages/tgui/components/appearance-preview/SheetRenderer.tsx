/**
 * @file SheetRenderer.tsx
 * @description v2 sheet-cropping renderer. One React component that, given a
 * manifest, an icon_state, and a direction, displays the exact tile at the
 * crop rect reported by the manifest. The untinted path stays on CSS
 * `background-image` + `background-position` so repeat renders of the same
 * tile are zero-cost.
 *
 * Missing states render the shared `<AppearancePreviewFallback>` so QA
 * notices immediately; silent-hide is forbidden by the fail-closed contract.
 *
 * Tinting (Remediation Step 3) is handled by the canvas compositor in
 * {@link ./tint.ts}. The prior `filter: drop-shadow … saturate(0)` path
 * did not actually recolour the sprite — it desaturated to greyscale and
 * painted a zero-offset shadow behind — and silently dropped multi-colour
 * GAGS input because a comma-joined colour list is not a valid CSS colour.
 * The canvas path resolves both bugs: single-colour callers get the
 * canonical multiply-then-remask tint, and GAGS callers get one multiply
 * pass per declared colour band in adapter order.
 *
 * For multi-layer previews (e.g. piercing gem on top of metal), wrap several
 * `<SheetPreviewTile>` instances in a positioned container. This component
 * does not own layer stacking or offsets — that belongs to the editor
 * compositor, which already knows the content-family rules.
 */

import { Box } from '../Box';
import { AppearancePreviewFallback } from './fallback';
import { resolvePreviewTile } from './lookup';
import { resolveSheetAssetUrl } from './preload';
import type {
  AppearancePreviewManifestV2,
  DirectionKey,
  HybridGuideLayerColor,
} from './shared';
import { normaliseColorList, useTintedTile } from './tint';

export interface SheetPreviewTileProps {
  /** Current v2 manifest. Null while preload is in flight. */
  manifest: AppearancePreviewManifestV2 | null;
  /** Canonical icon_state to render. */
  iconState: string;
  /** Direction to render. Defaults to 's'. */
  direction?: DirectionKey;
  /**
   * Optional tint colour(s) to multiply onto the tile. Accepts:
   *   - a single CSS colour string (e.g. `"#C0C0C0"`),
   *   - a comma-joined string (legacy wire shape, kept for backward compat
   *     for one release — new callers should pass an array),
   *   - an ordered array of CSS colours for GAGS-style multi-band tints,
   *   - `null` or `undefined` to render untinted.
   * Invalid entries are dropped with a one-shot dev-console warning; the
   * compositor never throws on bad adapter data.
   */
  color?: HybridGuideLayerColor;
  /** Optional integer scale factor (e.g. 2 for a 64x64 preview of a 32x32 tile). */
  scale?: number;
  /** Optional CSS class name passed through. */
  className?: string;
}

/**
 * Render one tile from the packed preview sheet. The untinted path uses
 * pure CSS background cropping and calls no hooks, so it remains safe to
 * invoke as a plain function from unit tests. The tinted path delegates to
 * {@link TintedTile}, which owns the canvas compositor subscription.
 * Falls back to a loud placeholder when the tile cannot be resolved.
 */
export function SheetPreviewTile(props: SheetPreviewTileProps) {
  const {
    manifest,
    iconState,
    direction = 's',
    color,
    scale = 1,
    className,
  } = props;

  const tile = resolvePreviewTile(manifest, iconState, direction);
  if (!tile) {
    return (
      <AppearancePreviewFallback
        iconState={iconState}
        direction={direction}
        width={32 * scale}
        height={32 * scale}
      />
    );
  }

  const resolvedColors = normaliseColorList(color ?? null);
  if (resolvedColors.length > 0) {
    return (
      <TintedTile
        tile={tile}
        colors={resolvedColors}
        scale={scale}
        className={className}
      />
    );
  }

  // Untinted path: pure CSS crop, no hooks, no canvas — safe to invoke as
  // a plain function from unit tests. Inlined into the parent component
  // so the existing snapshot tests that assert `el.type === Box` continue
  // to hold without plumbing through an intermediate component.
  const { sheet, crop } = tile;
  const displayWidth = crop.width * scale;
  const displayHeight = crop.height * scale;
  const sheetUrl = resolveSheetAssetUrl(sheet.path);
  return (
    <Box
      className={className}
      style={{
        width: `${displayWidth}px`,
        height: `${displayHeight}px`,
        // background-position uses negative offsets to expose the tile at
        // (0,0) of the element box. `background-size` is scaled in lockstep
        // so one "native" sheet pixel maps to `scale` on-screen pixels.
        backgroundImage: `url("${sheetUrl}")`,
        backgroundRepeat: 'no-repeat',
        backgroundPosition: `${-crop.x * scale}px ${-crop.y * scale}px`,
        backgroundSize: `${sheet.width * scale}px ${sheet.height * scale}px`,
        imageRendering: 'pixelated',
        display: 'inline-block',
      }}
    />
  );
}

// ── Internal render helpers ─────────────────────────────────────────────────

/**
 * Tinted render path. Subscribes to the canvas compositor via
 * {@link useTintedTile}; while the sheet bitmap is still decoding we render
 * the untinted sprite as a transient fallback so the user sees the shape
 * immediately, then swap to the composited data URL once ready.
 */
function TintedTile(props: {
  tile: NonNullable<ReturnType<typeof resolvePreviewTile>>;
  colors: readonly string[];
  scale: number;
  className?: string;
}) {
  const { tile, colors, scale, className } = props;
  const { sheet, crop } = tile;
  const sheetUrl = resolveSheetAssetUrl(sheet.path);
  const tintedDataUrl = useTintedTile(
    sheetUrl,
    {
      x: crop.x,
      y: crop.y,
      width: crop.width,
      height: crop.height,
    },
    colors,
  );

  const displayWidth = crop.width * scale;
  const displayHeight = crop.height * scale;

  // While the compositor has not produced a URL yet (sheet still loading or
  // a pre-canvas environment such as SSR), fall back to the untinted CSS
  // crop. Rendering the raw sprite is strictly better than a blank square
  // and avoids a first-paint flash of placeholder content.
  if (tintedDataUrl === null) {
    return (
      <Box
        className={className}
        style={{
          width: `${displayWidth}px`,
          height: `${displayHeight}px`,
          backgroundImage: `url("${sheetUrl}")`,
          backgroundRepeat: 'no-repeat',
          backgroundPosition: `${-crop.x * scale}px ${-crop.y * scale}px`,
          backgroundSize: `${sheet.width * scale}px ${sheet.height * scale}px`,
          imageRendering: 'pixelated',
          display: 'inline-block',
        }}
      />
    );
  }

  return (
    <Box
      className={className}
      style={{
        width: `${displayWidth}px`,
        height: `${displayHeight}px`,
        backgroundImage: `url("${tintedDataUrl}")`,
        backgroundRepeat: 'no-repeat',
        backgroundPosition: '0 0',
        backgroundSize: `${displayWidth}px ${displayHeight}px`,
        imageRendering: 'pixelated',
        display: 'inline-block',
      }}
    />
  );
}
