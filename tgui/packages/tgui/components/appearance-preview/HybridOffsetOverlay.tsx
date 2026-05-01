/**
 * @file HybridOffsetOverlay.tsx
 * @description Shared hybrid offset preview shell for editor surfaces that
 * need one locally movable guide sprite over the server-owned character map.
 *
 * The backend remains authoritative for full character rendering. This
 * component only renders the active guide descriptor and mutates local draft
 * offset props while the user drags; it deliberately has no `act()` import,
 * no persistence logic, and no editor-specific icon-state naming rules.
 */

import {
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
  useCallback,
  useRef,
} from 'react';

import { Box } from '../Box';
import { CharacterPreviewMapView } from './CharacterPreviewMapView';
import type {
  AppearancePreviewManifestV2,
  DirectionKey,
  HybridGuideDescriptor,
  HybridOffsetField,
  OffsetTransformProps,
} from './shared';
import { SheetPreviewTile } from './SheetRenderer';

const DEFAULT_DIRECTION: DirectionKey = 's';
const DEFAULT_PREVIEW_SIZE = 96;
const DEFAULT_GUIDE_SCALE = 1;

const FALLBACK_TRANSFORM: OffsetTransformProps = {
  x: 0,
  y: 0,
  turn: 0,
  flip: false,
  hide: false,
  shrink: 1,
  above: undefined,
};

/** Pointer geometry captured at drag start. */
type HybridOffsetDragState = {
  startClientX: number;
  startClientY: number;
  draftAtStart: OffsetTransformProps;
};

/** Raw pointer coordinates used to resolve a draft after movement. */
export interface HybridOffsetDragDelta {
  startClientX: number;
  startClientY: number;
  currentClientX: number;
  currentClientY: number;
  /**
   * Converts screen pixels into BYOND icon pixels. Leave at 1 when the guide
   * is displayed at native size; use the overlay zoom when editors scale the
   * guide for readability.
   */
  pixelRatio?: number;
}

/**
 * Optional axis gates for local drag math.
 *
 * Undefined preserves the raw helper behavior for standalone math callers.
 * Component calls pass descriptor `allowedFields` so drag cannot emit draft
 * x/y values for a server-declared non-offset target.
 */
type HybridOffsetDragAllowedFields =
  | readonly HybridOffsetField[]
  | null
  | undefined;

/** Props for the shared hybrid offset overlay. */
export interface HybridOffsetOverlayProps {
  /** Current v2 manifest. Null while the shared manifest loader is pending. */
  manifest: AppearancePreviewManifestV2 | null;
  /**
   * Server-resolved guide descriptor. Null means the real map view still
   * renders, but no editable TGUI overlay is shown.
   */
  descriptor: HybridGuideDescriptor | null;
  /** Active direction. Defaults to descriptor.direction, then south. */
  direction?: DirectionKey;
  /** Current local draft transform for the active direction. */
  draftProps: OffsetTransformProps;
  /** Called for local draft changes. This component never calls backend act(). */
  onDraftChange: (nextProps: OffsetTransformProps) => void;
  /**
   * Optional prebuilt map view. Tests and custom editor shells can pass a
   * stable node here to avoid mounting the BYOND map wrapper.
   */
  mapView?: ReactNode;
  /** BYOND map control id used when `mapView` is not supplied. */
  mapId?: string;
  /** Current background state forwarded to `CharacterPreviewMapView`. */
  backgroundState?: string;
  /** Pixel width of the map/overlay stage. Defaults to the existing map size. */
  previewWidth?: number;
  /** Pixel height of the map/overlay stage. Defaults to the existing map size. */
  previewHeight?: number;
  /** Scale factor applied to each guide tile. */
  guideScale?: number;
  /** Screen-to-BYOND drag pixel ratio. Defaults to `guideScale`. */
  dragPixelRatio?: number;
  /**
   * BYOND-to-CSS transform pixel ratio. Editors that display a native 32px
   * guide at 3x should pass 3 so a persisted x/y offset of 1 BYOND pixel moves
   * the visible guide by 3 screen pixels.
   */
  transformPixelRatio?: number;
  /** Optional class name for outer integration surfaces. */
  className?: string;
}

/**
 * Returns whether a server descriptor allows a transform field.
 *
 * The helper is intentionally tiny because descriptor field gating is a
 * security boundary on the server and a UI affordance on the client. TGUI
 * must not invent support for fields the descriptor did not advertise.
 */
export function hybridOffsetAllowsField(
  allowedFields: readonly HybridOffsetField[] | null | undefined,
  field: HybridOffsetField,
): boolean {
  return Array.isArray(allowedFields) && allowedFields.includes(field);
}

/**
 * Finite-number guard used before putting draft values into CSS. Invalid data
 * should already be sanitized server-side, but this keeps malformed in-flight
 * draft state from emitting `NaNpx` or `Infinitydeg` into the DOM.
 */
function finiteOr(value: number, fallback: number): number {
  return Number.isFinite(value) ? value : fallback;
}

/**
 * Applies descriptor `allowedFields` to a draft transform.
 *
 * Unsupported fields fall back to inert values, so an x/y-only descriptor can
 * safely share the same draft shape as a taur/custom-piercing descriptor with
 * rotation, flip, hide, shrink, and above support.
 */
export function normaliseHybridOffsetTransform(
  draft: OffsetTransformProps,
  allowedFields: readonly HybridOffsetField[] | null | undefined,
): OffsetTransformProps {
  return {
    x: hybridOffsetAllowsField(allowedFields, 'x')
      ? finiteOr(draft.x, FALLBACK_TRANSFORM.x)
      : FALLBACK_TRANSFORM.x,
    y: hybridOffsetAllowsField(allowedFields, 'y')
      ? finiteOr(draft.y, FALLBACK_TRANSFORM.y)
      : FALLBACK_TRANSFORM.y,
    turn: hybridOffsetAllowsField(allowedFields, 'turn')
      ? finiteOr(draft.turn, FALLBACK_TRANSFORM.turn)
      : FALLBACK_TRANSFORM.turn,
    flip: hybridOffsetAllowsField(allowedFields, 'flip')
      ? !!draft.flip
      : FALLBACK_TRANSFORM.flip,
    hide: hybridOffsetAllowsField(allowedFields, 'hide')
      ? !!draft.hide
      : FALLBACK_TRANSFORM.hide,
    shrink: hybridOffsetAllowsField(allowedFields, 'shrink')
      ? finiteOr(draft.shrink, FALLBACK_TRANSFORM.shrink)
      : FALLBACK_TRANSFORM.shrink,
    above: hybridOffsetAllowsField(allowedFields, 'above')
      ? !!draft.above
      : FALLBACK_TRANSFORM.above,
  };
}

/**
 * Builds the CSS transform for a guide overlay.
 *
 * BYOND icon coordinates use positive y for north/up. CSS screen coordinates
 * use positive y downward, so the y translation is negated here. Rotation and
 * scale stay CSS-native; horizontal flip is represented by a negative X scale.
 */
export function buildHybridOffsetCssTransform(
  draft: OffsetTransformProps,
  allowedFields: readonly HybridOffsetField[] | null | undefined,
  pixelRatio = 1,
): string {
  const safe = normaliseHybridOffsetTransform(draft, allowedFields);
  const transformPixelRatio =
    Number.isFinite(pixelRatio) && pixelRatio > 0 ? pixelRatio : 1;
  const scale = safe.shrink;
  const scaleX = safe.flip ? -scale : scale;
  return `translate(${safe.x * transformPixelRatio}px, ${-safe.y * transformPixelRatio}px) rotate(${safe.turn}deg) scale(${scaleX}, ${scale})`;
}

/**
 * Converts pointer movement into the next local draft.
 *
 * Moving the pointer down increases CSS y but must decrease BYOND y. The
 * helper rounds to integer icon pixels because the persisted offset model is
 * pixel based and later save actions are expected to send compact integers.
 */
export function resolveHybridOffsetDragDraft(
  draftAtStart: OffsetTransformProps,
  drag: HybridOffsetDragDelta,
  allowedFields?: HybridOffsetDragAllowedFields,
): OffsetTransformProps {
  const pixelRatio =
    Number.isFinite(drag.pixelRatio) && drag.pixelRatio! > 0
      ? drag.pixelRatio!
      : 1;
  const canMoveX =
    allowedFields === undefined || hybridOffsetAllowsField(allowedFields, 'x');
  const canMoveY =
    allowedFields === undefined || hybridOffsetAllowsField(allowedFields, 'y');
  const deltaX = Math.round(
    (drag.currentClientX - drag.startClientX) / pixelRatio,
  );
  const deltaY = Math.round(
    (drag.currentClientY - drag.startClientY) / pixelRatio,
  );
  return {
    ...draftAtStart,
    x: canMoveX ? finiteOr(draftAtStart.x, 0) + deltaX : draftAtStart.x,
    y: canMoveY ? finiteOr(draftAtStart.y, 0) - deltaY : draftAtStart.y,
  };
}

/**
 * Shared map-backed offset overlay. The component owns no draft state: it
 * renders the supplied draft and reports new local draft values while dragging
 * the active guide. Parent editors decide when to commit or discard.
 */
export function HybridOffsetOverlay(props: HybridOffsetOverlayProps) {
  const {
    manifest,
    descriptor,
    direction = descriptor?.direction ?? DEFAULT_DIRECTION,
    draftProps,
    onDraftChange,
    mapView,
    mapId = '',
    backgroundState,
    previewWidth = DEFAULT_PREVIEW_SIZE,
    previewHeight = DEFAULT_PREVIEW_SIZE,
    guideScale = DEFAULT_GUIDE_SCALE,
    dragPixelRatio = guideScale,
    transformPixelRatio = 1,
    className,
  } = props;

  const dragRef = useRef<HybridOffsetDragState | null>(null);
  const allowedFields = descriptor?.allowedFields ?? [];
  const safeDraft = normaliseHybridOffsetTransform(draftProps, allowedFields);
  const canRenderGuide = !!descriptor && descriptor.layers.length > 0;
  const guideHidden = safeDraft.hide || !canRenderGuide;
  const guideDraggable =
    !guideHidden &&
    (hybridOffsetAllowsField(allowedFields, 'x') ||
      hybridOffsetAllowsField(allowedFields, 'y'));
  const displayWidth = Math.max(
    1,
    Math.round((descriptor?.nativeWidth ?? 32) * guideScale),
  );
  const displayHeight = Math.max(
    1,
    Math.round((descriptor?.nativeHeight ?? 32) * guideScale),
  );

  const mapNode = mapView ?? (
    <CharacterPreviewMapView
      mapId={mapId}
      backgroundState={backgroundState}
      width={previewWidth}
      height={previewHeight}
      showRotateControls={false}
      showBackgroundPicker={false}
    />
  );

  const finishDrag = useCallback((event: ReactPointerEvent<HTMLDivElement>) => {
    dragRef.current = null;
    try {
      event.currentTarget.releasePointerCapture(event.pointerId);
    } catch {
      // Some test/browser environments do not track capture state. Releasing
      // is best-effort and should never break the editor.
    }
  }, []);

  const beginDrag = useCallback(
    (event: ReactPointerEvent<HTMLDivElement>) => {
      if (!guideDraggable) {
        return;
      }
      event.preventDefault();
      dragRef.current = {
        startClientX: event.clientX,
        startClientY: event.clientY,
        draftAtStart: safeDraft,
      };
      try {
        event.currentTarget.setPointerCapture(event.pointerId);
      } catch {
        // Pointer capture is not available in every embedded/test runtime.
        // Local drag still works while the pointer remains over the guide.
      }
    },
    [guideDraggable, safeDraft],
  );

  const updateDrag = useCallback(
    (event: ReactPointerEvent<HTMLDivElement>) => {
      const activeDrag = dragRef.current;
      if (!activeDrag) {
        return;
      }
      event.preventDefault();
      const nextDraft = resolveHybridOffsetDragDraft(
        activeDrag.draftAtStart,
        {
          startClientX: activeDrag.startClientX,
          startClientY: activeDrag.startClientY,
          currentClientX: event.clientX,
          currentClientY: event.clientY,
          pixelRatio: dragPixelRatio,
        },
        allowedFields,
      );
      onDraftChange(nextDraft);
    },
    [allowedFields, dragPixelRatio, onDraftChange],
  );

  const stageStyle: CSSProperties = {
    position: 'relative',
    width: `${previewWidth}px`,
    height: `${previewHeight}px`,
    overflow: 'visible',
  };

  const guideStyle: CSSProperties = {
    position: 'absolute',
    left: '50%',
    top: '50%',
    width: `${displayWidth}px`,
    height: `${displayHeight}px`,
    marginLeft: `${-displayWidth / 2}px`,
    marginTop: `${-displayHeight / 2}px`,
    transform: buildHybridOffsetCssTransform(
      safeDraft,
      allowedFields,
      transformPixelRatio,
    ),
    transformOrigin: 'center',
    opacity: guideHidden ? 0 : 0.92,
    pointerEvents: guideDraggable ? 'auto' : 'none',
    cursor: guideDraggable ? 'grab' : 'default',
    touchAction: 'none',
    imageRendering: 'pixelated',
    zIndex: safeDraft.above ? 3 : 2,
  };

  const layerStyle: CSSProperties = {
    position: 'absolute',
    inset: 0,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    pointerEvents: 'none',
  };

  return (
    <Box
      className={className}
      style={{
        display: 'inline-flex',
        flexDirection: 'column',
        alignItems: 'center',
      }}
    >
      <div data-hybrid-offset-stage style={stageStyle}>
        <div
          data-hybrid-offset-map
          style={{
            position: 'absolute',
            inset: 0,
            zIndex: 1,
          }}
        >
          {mapNode}
        </div>
        {canRenderGuide ? (
          <div
            data-hybrid-offset-guide
            data-hidden={guideHidden ? 'true' : 'false'}
            style={guideStyle}
            onPointerDown={beginDrag}
            onPointerMove={updateDrag}
            onPointerUp={finishDrag}
            onPointerCancel={finishDrag}
          >
            {descriptor.layers.map((layer, index) => (
              <div
                data-hybrid-offset-layer={layer.role ?? 'guide'}
                key={`${layer.iconState}:${layer.role ?? 'guide'}:${index}`}
                style={layerStyle}
              >
                <SheetPreviewTile
                  manifest={manifest}
                  iconState={layer.iconState}
                  direction={direction}
                  color={layer.color ?? null}
                  scale={guideScale}
                />
              </div>
            ))}
          </div>
        ) : null}
      </div>
    </Box>
  );
}
