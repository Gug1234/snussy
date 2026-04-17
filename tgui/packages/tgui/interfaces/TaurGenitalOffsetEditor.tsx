/**
 * @file TaurGenitalOffsetEditor.tsx
 * @description Per-direction taur genital sprite tuning panel. Players pick a
 * part (penis/testicles/vagina) and a direction (S/N/E/W) and adjust x/y/turn/
 * flip/above/hide/shrink for just that combination. The preview image mirrors
 * the classic character preview but for the selected direction only, and can be
 * drag-manipulated:
 *   - LMB drag: pan X/Y offsets
 *   - RMB drag: rotate (horizontal motion sets turn delta)
 *   - MMB drag: scale (vertical motion sets shrink delta)
 */

import { useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

type PartKey = 'penis' | 'testicles' | 'vagina';
type DirKey = 's' | 'n' | 'e' | 'w';
type FieldKey = 'x' | 'y' | 'turn' | 'flip' | 'above' | 'hide' | 'shrink';

type PartProps = Record<string, number>;

type BackendData = {
  active_part: PartKey;
  active_dir: DirKey;
  part_keys: PartKey[];
  dir_keys: DirKey[];
  field_keys: FieldKey[];
  props: Record<PartKey, PartProps>;
  global_hide: Record<DirKey, number>;
  preview_b64: string | null;
  part_preview_b64: string | null;
  time_dilation: number;
  drag_disable_threshold: number;
  drag_disabled: BooleanLike;
};

const DIR_LABELS: Record<DirKey, string> = {
  s: 'South',
  n: 'North',
  e: 'East',
  w: 'West',
};

const PART_LABELS: Record<PartKey, string> = {
  penis: 'Penis',
  testicles: 'Testicles',
  vagina: 'Vagina',
};

// Drag sensitivity constants.
const ROT_PER_PIXEL = 1.5; // degrees per horizontal pixel during RMB drag
const SCALE_PER_PIXEL = 0.01; // shrink delta per vertical pixel during MMB drag
// Native sprite-space size of the preview canvas (server renders 32x32
// mannequin into a 96x96 transparent canvas so parts can be offset well past
// the body edge without clipping).
const PREVIEW_SPRITE_PX = 96;
// Preview image display size (square, px). Used to scale the ghost overlay.
const PREVIEW_PX = 288;
// Clamps matching the server-side `_apply_field` bounds.
const XY_MIN = -64;
const XY_MAX = 64;
const SHRINK_MIN = 0.1;
const SHRINK_MAX = 4.0;
const clamp = (v: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, v));

export function TaurGenitalOffsetEditor(props) {
  const { act, data } = useBackend<BackendData>();
  const {
    active_part,
    active_dir,
    part_keys = [],
    dir_keys = [],
    props: allProps = {} as Record<PartKey, PartProps>,
    global_hide = {} as Record<DirKey, number>,
    preview_b64,
    part_preview_b64,
    time_dilation = 0,
    drag_disable_threshold = 40,
    drag_disabled,
  } = data;

  const currentProps = allProps[active_part] ?? {};
  const k = (field: FieldKey) => `${active_dir}${field}`;
  const val = (field: FieldKey, fallback = 0): number => {
    const v = currentProps[k(field)];
    return typeof v === 'number' ? v : fallback;
  };

  return (
    <Window theme="rogue">
      <Window.Content scrollable>
        <Section title="Taur Genital Offsets">
          <Box mb={1} opacity={0.6} fontSize="11px" italic>
            Tune per-direction sprite placement for each taur genital. Drag the
            preview with LMB to pan, RMB to rotate, MMB to scale.
          </Box>

          {!!drag_disabled && (
            <NoticeBox danger>
              Mouse-drag editing disabled — server time dilation is{' '}
              {Math.round(time_dilation)}% (threshold{' '}
              {drag_disable_threshold}%). Use the number inputs below; they
              send only one update per edit. Spamming edits may be rate-limited
              and reported to admins.
            </NoticeBox>
          )}

          <Tabs>
            {part_keys.map((p) => (
              <Tabs.Tab
                key={p}
                selected={p === active_part}
                onClick={() => act('select_part', { part: p })}
              >
                {PART_LABELS[p]}
              </Tabs.Tab>
            ))}
          </Tabs>

          <Stack mt={1}>
            <Stack.Item basis="300px">
              <PreviewPanel
                previewB64={preview_b64}
                partPreviewB64={part_preview_b64}
                activePart={active_part}
                activeDir={active_dir}
                dragDisabled={!!drag_disabled}
                currentX={val('x')}
                currentY={val('y')}
                currentTurn={val('turn')}
                currentShrink={val('shrink', 1)}
                currentFlip={!!val('flip')}
                currentAbove={!!val('above')}
                currentHide={!!val('hide') || !!global_hide[active_dir]}
              />
            </Stack.Item>

            <Stack.Item grow>
              <Section
                title={`${PART_LABELS[active_part]} — ${DIR_LABELS[active_dir]}`}
                buttons={
                  <>
                    <Button
                      icon="undo"
                      compact
                      tooltip="Reset this direction to defaults"
                      onClick={() =>
                        act('reset_dir', {
                          part: active_part,
                          dir: active_dir,
                        })
                      }
                    >
                      Reset Dir
                    </Button>
                    <Button
                      icon="undo-alt"
                      color="bad"
                      compact
                      tooltip="Reset ALL directions of this part to defaults"
                      onClick={() =>
                        act('reset_part', { part: active_part })
                      }
                    >
                      Reset Part
                    </Button>
                  </>
                }
              >
                <Tabs>
                  {dir_keys.map((d) => (
                    <Tabs.Tab
                      key={d}
                      selected={d === active_dir}
                      onClick={() => act('select_dir', { dir: d })}
                    >
                      {DIR_LABELS[d]}
                    </Tabs.Tab>
                  ))}
                </Tabs>

                <LabeledList>
                  <LabeledList.Item label="Offset X">
                    <NumberInput
                      width="60px"
                      step={1}
                      stepPixelSize={4}
                      value={val('x')}
                      minValue={-64}
                      maxValue={64}
                      onChange={(value) =>
                        act('set_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'x',
                          value,
                        })
                      }
                    />
                    <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
                  </LabeledList.Item>
                  <LabeledList.Item label="Offset Y">
                    <NumberInput
                      width="60px"
                      step={1}
                      stepPixelSize={4}
                      value={val('y')}
                      minValue={-64}
                      maxValue={64}
                      onChange={(value) =>
                        act('set_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'y',
                          value,
                        })
                      }
                    />
                    <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
                  </LabeledList.Item>
                  <LabeledList.Item label="Rotation">
                    <NumberInput
                      width="60px"
                      step={5}
                      stepPixelSize={4}
                      value={val('turn')}
                      minValue={0}
                      maxValue={359}
                      onChange={(value) =>
                        act('set_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'turn',
                          value,
                        })
                      }
                    />
                    <span style={{ opacity: 0.4, marginLeft: '6px' }}>
                      deg
                    </span>
                  </LabeledList.Item>
                  <LabeledList.Item label="Scale">
                    <NumberInput
                      width="70px"
                      step={0.05}
                      stepPixelSize={4}
                      value={val('shrink', 1.0)}
                      minValue={0.1}
                      maxValue={4.0}
                      onChange={(value) =>
                        act('set_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'shrink',
                          value,
                        })
                      }
                    />
                    <span style={{ opacity: 0.4, marginLeft: '6px' }}>x</span>
                    {(active_part === 'penis' ||
                      active_part === 'testicles') &&
                      val('shrink', 1) >= 3 && (
                        <span
                          style={{
                            marginLeft: '8px',
                            fontSize: '11px',
                            fontStyle: 'italic',
                            color: '#c97a7a',
                            opacity: 0.85,
                          }}
                        >
                          very mature.
                        </span>
                      )}
                  </LabeledList.Item>
                  <LabeledList.Item label="Horizontal Flip">
                    <Button.Checkbox
                      checked={!!val('flip')}
                      onClick={() =>
                        act('toggle_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'flip',
                        })
                      }
                    >
                      {val('flip') ? 'Flipped' : 'Normal'}
                    </Button.Checkbox>
                  </LabeledList.Item>
                  <LabeledList.Item label="Layer">
                    <Button.Checkbox
                      checked={!!val('above')}
                      onClick={() =>
                        act('toggle_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'above',
                        })
                      }
                    >
                      {val('above') ? 'Over Body' : 'Under Body'}
                    </Button.Checkbox>
                  </LabeledList.Item>
                  <LabeledList.Item label="Hide">
                    <Button.Checkbox
                      checked={!!val('hide')}
                      color={val('hide') ? 'bad' : undefined}
                      onClick={() =>
                        act('toggle_field', {
                          part: active_part,
                          dir: active_dir,
                          field: 'hide',
                        })
                      }
                    >
                      {val('hide')
                        ? 'Hidden this direction'
                        : 'Visible'}
                    </Button.Checkbox>
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>
          </Stack>
        </Section>

        <Section title="Global Per-Direction Hide">
          <Box mb={1} opacity={0.6} fontSize="11px" italic>
            Hides ALL taur genital sprites (not just this part) when the
            character faces the toggled direction. Stacks on top of per-part
            hide.
          </Box>
          <Stack>
            {(dir_keys as DirKey[]).map((d) => (
              <Stack.Item key={d} grow>
                <Button.Checkbox
                  fluid
                  checked={!!global_hide[d]}
                  color={global_hide[d] ? 'bad' : undefined}
                  onClick={() => act('toggle_global_hide', { dir: d })}
                >
                  {DIR_LABELS[d]}
                </Button.Checkbox>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
}

/**
 * Preview panel with ghost-drag editing.
 *
 * Pattern: during a drag, NO network traffic is sent. We track the drag delta
 * purely in local React state and render a semi-transparent "ghost" overlay
 * that shows where the sprite will move/rotate/scale to. On mouseup, a single
 * `commit_drag` act() call fires with the final absolute values, and the
 * server regenerates the mannequin preview exactly once.
 *
 * Compared to the old delta-accumulation + throttled-flush pattern, this cuts
 * server load for a typical drag from "N regenerations per drag at 12Hz" to
 * "exactly 1 regeneration per drag" — critical when dozens of players edit
 * concurrently.
 *
 * Controls: LMB=pan, RMB=rotate, MMB=scale.
 */
function PreviewPanel(props: {
  previewB64: string | null;
  partPreviewB64: string | null;
  activePart: PartKey;
  activeDir: DirKey;
  dragDisabled: boolean;
  currentX: number;
  currentY: number;
  currentTurn: number;
  currentShrink: number;
  currentFlip: boolean;
  currentAbove: boolean;
  currentHide: boolean;
}) {
  const { act } = useBackend<BackendData>();
  const {
    previewB64,
    partPreviewB64,
    activePart,
    activeDir,
    dragDisabled,
    currentX,
    currentY,
    currentTurn,
    currentShrink,
    currentFlip,
    currentAbove,
    currentHide,
  } = props;

  type DragMode = 'xy' | 'turn' | 'shrink';
  // Drag state. Refs for mutable data, useState only to trigger re-render of
  // the ghost overlay on mousemove.
  const dragMode = useRef<DragMode | null>(null);
  const dragStartPos = useRef<{ x: number; y: number } | null>(null);
  // Snapshot of the committed values at drag-start, so the ghost delta is
  // applied relative to the correct base (not to the value updated during the
  // drag — there are no such updates).
  const dragStartVals = useRef<{
    x: number;
    y: number;
    turn: number;
    shrink: number;
  }>({ x: 0, y: 0, turn: 0, shrink: 1 });
  const [ghost, setGhost] = useState<{
    dx: number;
    dy: number;
  } | null>(null);

  const handleMouseDown = (e: React.MouseEvent) => {
    e.preventDefault();
    if (dragDisabled) {
      return;
    }
    let mode: DragMode;
    if (e.button === 0) {
      mode = 'xy';
    } else if (e.button === 1) {
      mode = 'shrink';
    } else if (e.button === 2) {
      mode = 'turn';
    } else {
      return;
    }
    dragMode.current = mode;
    dragStartPos.current = { x: e.clientX, y: e.clientY };
    dragStartVals.current = {
      x: currentX,
      y: currentY,
      turn: currentTurn,
      shrink: currentShrink,
    };
    setGhost({ dx: 0, dy: 0 });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!dragMode.current || !dragStartPos.current) {
      return;
    }
    // Pure client-side state update. No network traffic during drag.
    setGhost({
      dx: e.clientX - dragStartPos.current.x,
      dy: e.clientY - dragStartPos.current.y,
    });
  };

  const computeFinal = (
    mode: DragMode,
    dx: number,
    dy: number,
  ): Record<string, number> => {
    const start = dragStartVals.current;
    switch (mode) {
      case 'xy':
        // Screen +y = downward; sprite +y = upward. Invert dy.
        return {
          x: clamp(Math.round(start.x + dx), XY_MIN, XY_MAX),
          y: clamp(Math.round(start.y - dy), XY_MIN, XY_MAX),
        };
      case 'turn':
        return {
          turn: ((Math.round(start.turn + dx * ROT_PER_PIXEL) % 360) + 360) % 360,
        };
      case 'shrink':
        // Up = zoom in, down = zoom out.
        return {
          shrink: clamp(
            Number((start.shrink + -dy * SCALE_PER_PIXEL).toFixed(2)),
            SHRINK_MIN,
            SHRINK_MAX,
          ),
        };
    }
  };

  const finishDrag = () => {
    const mode = dragMode.current;
    const g = ghost;
    dragMode.current = null;
    dragStartPos.current = null;
    setGhost(null);
    if (!mode || !g) {
      return;
    }
    // Ignore no-op drags (single click with no movement).
    if (g.dx === 0 && g.dy === 0) {
      return;
    }
    const final = computeFinal(mode, g.dx, g.dy);
    // Fire one batched commit per drag. Server regenerates preview once.
    act('commit_drag', {
      part: activePart,
      dir: activeDir,
      ...final,
    });
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    // Suppress the browser context menu so RMB-drag can rotate.
    e.preventDefault();
  };

  // Live committed-part transform: reflects the CURRENT committed flip/turn/
  // shrink + pixel offsets on the part-only sprite. This is what gives the
  // editor immediate visual feedback for flip/turn/shrink changes — BYOND's
  // `getFlatIcon` does not honor mutable_appearance.transform, so the full
  // mannequin render alone cannot show those edits.
  const screenScale = PREVIEW_PX / PREVIEW_SPRITE_PX;
  const committedTransform =
    `translate(${currentX * screenScale}px, ${-currentY * screenScale}px) ` +
    `rotate(${currentTurn}deg) ` +
    `scale(${currentShrink * (currentFlip ? -1 : 1)}, ${currentShrink})`;

  // Ghost overlay transform: mirrors what the sprite will look like after
  // commit. Only shown while a drag is in progress. Applied on top of the
  // part-only sprite (not the whole mannequin) so mid-drag preview shows only
  // the part being adjusted.
  let ghostTransform: string | undefined;
  let ghostOpacity = 0;
  if (ghost && dragMode.current) {
    const final = computeFinal(dragMode.current, ghost.dx, ghost.dy);
    const nextX = final.x ?? currentX;
    const nextY = final.y ?? currentY;
    const nextTurn = final.turn ?? currentTurn;
    const nextShrink = final.shrink ?? currentShrink;
    ghostTransform =
      `translate(${nextX * screenScale}px, ${-nextY * screenScale}px) ` +
      `rotate(${nextTurn}deg) ` +
      `scale(${nextShrink * (currentFlip ? -1 : 1)}, ${nextShrink})`;
    ghostOpacity = 0.5;
  }

  return (
    <Section title="Preview" fill>
      {previewB64 ? (
        (() => {
          const mannequinImg = (
            <img
              key="mannequin"
              src={`data:image/png;base64,${previewB64}`}
              draggable={false}
              style={{
                imageRendering: 'pixelated',
                width: `${PREVIEW_PX}px`,
                height: `${PREVIEW_PX}px`,
                background: '#0e0e0e',
                border: '1px solid #333',
                position: 'absolute',
                top: 0,
                left: 0,
              }}
              alt="taur preview"
            />
          );
          const committedPartImg =
            !currentHide && partPreviewB64 ? (
              <img
                key="committed-part"
                src={`data:image/png;base64,${partPreviewB64}`}
                draggable={false}
                style={{
                  imageRendering: 'pixelated',
                  width: `${PREVIEW_PX}px`,
                  height: `${PREVIEW_PX}px`,
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  pointerEvents: 'none',
                  transform: committedTransform,
                  transformOrigin: '50% 50%',
                }}
                alt=""
              />
            ) : null;
          const ghostImg =
            ghostTransform && partPreviewB64 ? (
              <img
                key="ghost"
                src={`data:image/png;base64,${partPreviewB64}`}
                draggable={false}
                style={{
                  imageRendering: 'pixelated',
                  width: `${PREVIEW_PX}px`,
                  height: `${PREVIEW_PX}px`,
                  position: 'absolute',
                  top: 0,
                  left: 0,
                  pointerEvents: 'none',
                  opacity: ghostOpacity,
                  transform: ghostTransform,
                  transformOrigin: '50% 50%',
                }}
                alt=""
              />
            ) : null;
          // `above` toggle is reflected purely via DOM order: when the part is
          // "over body", render the committed part AFTER the mannequin (higher
          // stacking); when "under body", render it BEFORE so the mannequin's
          // opaque body pixels occlude it. The ghost always stays on top so
          // players can see what they're dragging regardless of layer.
          const stack = currentAbove
            ? [mannequinImg, committedPartImg, ghostImg]
            : [committedPartImg, mannequinImg, ghostImg];
          return (
            <Box
              style={{
                userSelect: 'none',
                cursor: dragMode.current ? 'grabbing' : 'grab',
                imageRendering: 'pixelated',
                textAlign: 'center',
                position: 'relative',
                width: `${PREVIEW_PX}px`,
                height: `${PREVIEW_PX}px`,
                margin: '0 auto',
              }}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={finishDrag}
              onMouseLeave={finishDrag}
              onContextMenu={handleContextMenu}
            >
              {stack}
            </Box>
          );
        })()
      ) : (
        <NoticeBox>No preview available.</NoticeBox>
      )}
      <Box mt={1} fontSize="10px" opacity={0.5} textAlign="center">
        Facing: {DIR_LABELS[activeDir]}
      </Box>
      <Box mt={0.5} fontSize="10px" opacity={0.4} textAlign="center">
        LMB pan · RMB rotate · MMB scale
      </Box>
      <Box mt={0.5} fontSize="10px" opacity={0.4} textAlign="center" italic>
        Drag to preview; release to commit.
      </Box>
    </Section>
  );
}
