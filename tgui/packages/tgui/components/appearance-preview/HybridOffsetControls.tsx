/**
 * @file HybridOffsetControls.tsx
 * @description Shared transform controls for the hybrid offset overlay.
 *
 * These controls are intentionally draft-only: they mutate local
 * `OffsetTransformProps` through callbacks and never import backend `act()`.
 * Server descriptors decide which transform fields are visible through
 * `allowedFields`, so TGUI cannot present unsupported controls for a target.
 */

import {
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
} from 'tgui-core/components';

import { Box } from '../Box';
import { DirectionControls } from './DirectionControls';
import {
  copyHybridOffsetToAllDirections,
  hybridOffsetControlAllowsField as allowsField,
  mirrorHybridOffsetTransform,
  updateHybridOffsetField,
} from './HybridOffsetControlLogic';
import type {
  DirectionalOffsetProps,
  DirectionKey,
  HybridGuideDescriptor,
  HybridOffsetField,
  OffsetTransformProps,
} from './shared';

export {
  copyHybridOffsetToAllDirections,
  DEFAULT_HYBRID_OFFSET_TRANSFORM,
  hybridOffsetControlAllowsField,
  mirrorHybridOffsetTransform,
  updateHybridOffsetField,
} from './HybridOffsetControlLogic';

/** Direction order used when copying one draft to every direction. */
const CONTROL_DIRECTION_KEYS: readonly DirectionKey[] = ['s', 'n', 'e', 'w'];

/** Numeric range defaults chosen to match the existing offset editors. */
const DEFAULT_OFFSET_MIN = -64;
const DEFAULT_OFFSET_MAX = 64;
const DEFAULT_TURN_MIN = -180;
const DEFAULT_TURN_MAX = 180;
const DEFAULT_SHRINK_MIN = 0.1;
const DEFAULT_SHRINK_MAX = 4;

/** Props for the shared transform controls. */
export interface HybridOffsetControlsProps {
  /** Descriptor whose `allowedFields` gates every control. */
  descriptor: HybridGuideDescriptor | null;
  /** Current local draft for the active direction. */
  draftProps: OffsetTransformProps;
  /** Called whenever one local transform field changes. */
  onDraftChange: (nextProps: OffsetTransformProps) => void;
  /** Optional active direction for rendering the shared direction picker. */
  direction?: DirectionKey;
  /** Optional direction change handler. Omit to hide direction controls. */
  onDirectionChange?: (direction: DirectionKey) => void;
  /** Optional direction subset. Defaults to S/N/E/W in DirectionControls. */
  dirKeys?: readonly DirectionKey[];
  /**
   * Called when Copy to All is pressed. Receives a full directional draft map
   * generated from the active draft.
   */
  onCopyToAll?: (nextProps: DirectionalOffsetProps) => void;
  /** Optional reset hook for owners that need to mark a separate dirty scope. */
  onReset?: (nextProps: OffsetTransformProps) => void;
  /** Optional mirror hook for owners that need custom direction bookkeeping. */
  onMirror?: (nextProps: OffsetTransformProps) => void;
  /** Numeric bounds for x/y controls. */
  offsetMin?: number;
  offsetMax?: number;
  /** Numeric bounds for rotation controls. */
  turnMin?: number;
  turnMax?: number;
  /** Numeric bounds for shrink/scale controls. */
  shrinkMin?: number;
  shrinkMax?: number;
  /** Disable all controls while an owner is committing or read-only. */
  disabled?: boolean;
}

/**
 * Renders the shared numeric and toggle controls for a hybrid overlay draft.
 *
 * Rendering is data-driven from `descriptor.allowedFields`: unsupported fields
 * are omitted, supported fields use local callbacks, and action buttons remain
 * disabled when their callback or field requirements are absent.
 */
export function HybridOffsetControls(props: HybridOffsetControlsProps) {
  const {
    descriptor,
    draftProps,
    onDraftChange,
    direction,
    onDirectionChange,
    dirKeys = CONTROL_DIRECTION_KEYS,
    onCopyToAll,
    onReset,
    onMirror,
    offsetMin = DEFAULT_OFFSET_MIN,
    offsetMax = DEFAULT_OFFSET_MAX,
    turnMin = DEFAULT_TURN_MIN,
    turnMax = DEFAULT_TURN_MAX,
    shrinkMin = DEFAULT_SHRINK_MIN,
    shrinkMax = DEFAULT_SHRINK_MAX,
    disabled = false,
  } = props;

  const allowedFields = descriptor?.allowedFields ?? [];
  const canEdit = !!descriptor && !disabled;
  const anyFieldAllowed = allowedFields.length > 0;

  const setField = (
    field: HybridOffsetField,
    value: number | boolean,
  ): void => {
    onDraftChange(
      updateHybridOffsetField(draftProps, field, value, allowedFields),
    );
  };

  const resetCurrent = (): void => {
    const next = updateHybridOffsetField(
      draftProps,
      'reset',
      null,
      allowedFields,
    );
    onDraftChange(next);
    onReset?.(next);
  };

  const copyToAll = (): void => {
    onCopyToAll?.(copyHybridOffsetToAllDirections(draftProps));
  };

  const mirrorCurrent = (): void => {
    const next = mirrorHybridOffsetTransform(draftProps, allowedFields);
    onDraftChange(next);
    onMirror?.(next);
  };

  if (!descriptor) {
    return (
      <NoticeBox>
        No editable guide descriptor is available for this target.
      </NoticeBox>
    );
  }

  return (
    <Box
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '0.5rem',
      }}
    >
      {direction && onDirectionChange ? (
        <DirectionControls
          activeDir={direction}
          dirKeys={dirKeys}
          label="Direction"
          onChange={onDirectionChange}
        />
      ) : null}

      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '0.35rem',
        }}
      >
        <Button
          compact
          icon="undo"
          tooltip="Reset supported transform fields for this direction"
          disabled={!canEdit || !anyFieldAllowed}
          onClick={resetCurrent}
        >
          Reset
        </Button>
        <Button
          compact
          icon="copy"
          tooltip="Copy this direction's transform to every direction"
          disabled={!canEdit || !onCopyToAll || !anyFieldAllowed}
          onClick={copyToAll}
        >
          Copy All
        </Button>
        <Button
          compact
          icon="redo"
          tooltip="Mirror horizontal placement and rotation for the current direction"
          disabled={
            !canEdit ||
            (!allowsField(allowedFields, 'x') &&
              !allowsField(allowedFields, 'turn'))
          }
          onClick={mirrorCurrent}
        >
          Mirror
        </Button>
      </Box>

      <LabeledList>
        {allowsField(allowedFields, 'x') ? (
          <LabeledList.Item label="Offset X">
            <NumberInput
              width="60px"
              step={1}
              stepPixelSize={4}
              value={draftProps.x}
              minValue={offsetMin}
              maxValue={offsetMax}
              disabled={!canEdit}
              onChange={(value) => setField('x', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
          </LabeledList.Item>
        ) : null}
        {allowsField(allowedFields, 'y') ? (
          <LabeledList.Item label="Offset Y">
            <NumberInput
              width="60px"
              step={1}
              stepPixelSize={4}
              value={draftProps.y}
              minValue={offsetMin}
              maxValue={offsetMax}
              disabled={!canEdit}
              onChange={(value) => setField('y', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
          </LabeledList.Item>
        ) : null}
        {allowsField(allowedFields, 'turn') ? (
          <LabeledList.Item label="Rotation">
            <NumberInput
              width="60px"
              step={5}
              stepPixelSize={4}
              value={draftProps.turn}
              minValue={turnMin}
              maxValue={turnMax}
              disabled={!canEdit}
              onChange={(value) => setField('turn', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>deg</span>
          </LabeledList.Item>
        ) : null}
        {allowsField(allowedFields, 'shrink') ? (
          <LabeledList.Item label="Scale">
            <NumberInput
              width="70px"
              step={0.05}
              stepPixelSize={4}
              value={draftProps.shrink}
              minValue={shrinkMin}
              maxValue={shrinkMax}
              disabled={!canEdit}
              onChange={(value) => setField('shrink', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>x</span>
          </LabeledList.Item>
        ) : null}
        {allowsField(allowedFields, 'flip') ? (
          <LabeledList.Item label="Horizontal Flip">
            <Button.Checkbox
              checked={!!draftProps.flip}
              disabled={!canEdit}
              tooltip="Flip the guide horizontally in this direction"
              onClick={() => setField('flip', !draftProps.flip)}
            >
              {draftProps.flip ? 'Flipped' : 'Normal'}
            </Button.Checkbox>
          </LabeledList.Item>
        ) : null}
        {allowsField(allowedFields, 'above') ? (
          <LabeledList.Item label="Layer">
            <Button.Checkbox
              checked={!!draftProps.above}
              disabled={!canEdit}
              tooltip="Render the guide above the map backdrop while editing"
              onClick={() => setField('above', !draftProps.above)}
            >
              {draftProps.above ? 'Above' : 'Below'}
            </Button.Checkbox>
          </LabeledList.Item>
        ) : null}
        {allowsField(allowedFields, 'hide') ? (
          <LabeledList.Item label="Hide">
            <Button.Checkbox
              checked={!!draftProps.hide}
              color={draftProps.hide ? 'bad' : undefined}
              disabled={!canEdit}
              tooltip="Hide the guide in this direction without changing saved offsets"
              onClick={() => setField('hide', !draftProps.hide)}
            >
              {draftProps.hide ? 'Hidden' : 'Visible'}
            </Button.Checkbox>
          </LabeledList.Item>
        ) : null}
      </LabeledList>
    </Box>
  );
}
