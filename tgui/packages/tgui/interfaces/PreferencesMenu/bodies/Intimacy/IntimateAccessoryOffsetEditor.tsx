/**
 * @file IntimateAccessoryOffsetEditor.tsx
 * @description Compact right-column editor for regular intimate accessory
 * offsets inside PreferencesMenu.
 *
 * The editor follows the hybrid preview contract: DM owns the mannequin map
 * view and resolves the active guide descriptor, while TGUI keeps x/y draft
 * movement local until the player presses Save. Phase one intentionally omits
 * turn/flip/hide/shrink controls because the base accessory render path only
 * advertises x/y support.
 */

import { useEffect, useMemo, useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import {
  AppearancePreviewProvider,
  CharacterPreviewMapView,
  type DirectionalOffsetProps,
  type DirectionKey,
  HybridOffsetControls,
  HybridOffsetOverlay,
  type OffsetTransformProps,
  useAppearancePreview,
} from '../../../../components/appearance-preview';
import type { PreferencesMenuData } from '../../types';
import {
  applyIntimateAccessoryDirectionalDraftsToProps,
  applyIntimateAccessoryHybridDraftToProps,
  buildIntimateAccessoryOffsetSaveProps,
  findIntimateAccessoryOffsetRow,
  getEditableIntimateAccessoryOffsetRows,
  getInitialIntimateAccessoryOffsetTarget,
  getIntimateAccessoryHybridDescriptor,
  type IntimateAccessoryOffsetPropMap,
  intimateAccessoryPropsToHybridDraft,
  normalizeIntimateAccessoryOffsetProps,
  normalizeIntimateAccessoryOffsetRows,
} from './IntimateAccessoryOffsetLogic';

const PREVIEW_SIZE = 192;
const GUIDE_SCALE = 3;
const DEFAULT_DIRECTION: DirectionKey = 's';
const DEFAULT_OFFSET_MIN = -64;
const DEFAULT_OFFSET_MAX = 64;

/**
 * Provider wrapper so the main PreferencesMenu shell does not need to load
 * the appearance-preview manifest until the intimate offset panel is visible.
 */
export function IntimateAccessoryOffsetPreviewPanel() {
  return (
    <AppearancePreviewProvider>
      <IntimateAccessoryOffsetPreviewPanelInner />
    </AppearancePreviewProvider>
  );
}

/**
 * Renders target selection, the map-backed guide overlay, x/y controls, and
 * Save/Revert buttons for the currently selected regular accessory target.
 */
function IntimateAccessoryOffsetPreviewPanelInner() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const { manifest, loading, error } = useAppearancePreview();
  const rows = useMemo(
    () =>
      normalizeIntimateAccessoryOffsetRows(data.intimate_accessory_offset_rows),
    [data.intimate_accessory_offset_rows],
  );
  const editableRows = useMemo(
    () => getEditableIntimateAccessoryOffsetRows(rows),
    [rows],
  );
  const offsetMin = data.intimate_accessory_offset_min ?? DEFAULT_OFFSET_MIN;
  const offsetMax = data.intimate_accessory_offset_max ?? DEFAULT_OFFSET_MAX;
  const serverTarget = data.intimate_accessory_offset_active_target ?? null;
  const [selectedTarget, setSelectedTarget] = useState<string | null>(() =>
    getInitialIntimateAccessoryOffsetTarget(rows, serverTarget),
  );
  const [activeDir, setActiveDir] = useState<DirectionKey>(DEFAULT_DIRECTION);
  const [draftProps, setDraftProps] = useState<IntimateAccessoryOffsetPropMap>(
    {},
  );
  const [dirty, setDirty] = useState(false);

  const selectedRow = useMemo(
    () => findIntimateAccessoryOffsetRow(rows, selectedTarget),
    [rows, selectedTarget],
  );
  const selectedServerProps = selectedRow?.slot_props ?? {};

  useEffect(() => {
    const nextTarget = getInitialIntimateAccessoryOffsetTarget(
      rows,
      selectedTarget ?? serverTarget,
    );
    if (!dirty && nextTarget !== selectedTarget) {
      setSelectedTarget(nextTarget);
    }
  }, [dirty, rows, selectedTarget, serverTarget]);

  useEffect(() => {
    if (selectedTarget !== serverTarget) {
      act('set_intimate_accessory_offset_target', {
        target_key: selectedTarget,
      });
    }
  }, [act, selectedTarget, serverTarget]);

  useEffect(() => {
    if (!dirty) {
      setDraftProps(normalizeIntimateAccessoryOffsetProps(selectedServerProps));
    }
  }, [dirty, selectedServerProps]);

  const descriptor = useMemo(
    () =>
      getIntimateAccessoryHybridDescriptor(
        data.intimate_accessory_offset_descriptors,
        selectedTarget,
        activeDir,
      ),
    [activeDir, data.intimate_accessory_offset_descriptors, selectedTarget],
  );

  const activeDraft = useMemo(
    () => intimateAccessoryPropsToHybridDraft(draftProps, activeDir),
    [activeDir, draftProps],
  );

  const targetLabels = editableRows.map(
    (row) => `${row.label}: ${row.current}`,
  );
  const selectedIndex = editableRows.findIndex(
    (row) => row.offset_target_key === selectedTarget,
  );
  const selectedLabel = selectedIndex >= 0 ? targetLabels[selectedIndex] : '';

  const updateDraft = (nextDraft: OffsetTransformProps): void => {
    setDraftProps((prev) =>
      applyIntimateAccessoryHybridDraftToProps(
        prev,
        activeDir,
        nextDraft,
        offsetMin,
        offsetMax,
      ),
    );
    setDirty(true);
  };

  const copyDraftToAll = (nextDrafts: DirectionalOffsetProps): void => {
    setDraftProps((prev) =>
      applyIntimateAccessoryDirectionalDraftsToProps(
        prev,
        nextDrafts,
        offsetMin,
        offsetMax,
      ),
    );
    setDirty(true);
  };

  const revertDraft = (): void => {
    setDraftProps(normalizeIntimateAccessoryOffsetProps(selectedServerProps));
    setDirty(false);
  };

  const saveDraft = (): void => {
    if (!selectedTarget) {
      return;
    }
    act('save_intimate_accessory_offset_props', {
      target_key: selectedTarget,
      props: buildIntimateAccessoryOffsetSaveProps(draftProps),
    });
    setDirty(false);
  };

  if (!editableRows.length) {
    return (
      <NoticeBox>
        No equipped regular intimate accessory target can be offset right now.
      </NoticeBox>
    );
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Dropdown
          width="100%"
          options={targetLabels}
          selected={selectedLabel}
          displayText={selectedLabel || 'Select target'}
          disabled={dirty}
          onSelected={(label: string) => {
            const index = targetLabels.indexOf(label);
            const row = editableRows[index];
            if (row?.offset_target_key) {
              setSelectedTarget(row.offset_target_key);
            }
          }}
        />
      </Stack.Item>

      {dirty ? (
        <Stack.Item>
          <NoticeBox info>
            Save or revert this draft before switching targets.
          </NoticeBox>
        </Stack.Item>
      ) : null}

      <Stack.Item>
        <HybridOffsetOverlay
          manifest={manifest}
          descriptor={descriptor}
          direction={activeDir}
          draftProps={activeDraft}
          onDraftChange={updateDraft}
          mapView={
            <CharacterPreviewMapView
              mapId={data.character_preview_view}
              backgroundState={data.background_state}
              width={PREVIEW_SIZE}
              height={PREVIEW_SIZE}
              showRotateControls={false}
              showBackgroundPicker={false}
            />
          }
          previewWidth={PREVIEW_SIZE}
          previewHeight={PREVIEW_SIZE}
          guideScale={GUIDE_SCALE}
          dragPixelRatio={GUIDE_SCALE}
          transformPixelRatio={GUIDE_SCALE}
        />
      </Stack.Item>

      {loading ? (
        <Stack.Item>
          <Box color="label" italic>
            Loading guide sprites...
          </Box>
        </Stack.Item>
      ) : null}
      {error ? (
        <Stack.Item>
          <Box color="bad" italic>
            {error.message}
          </Box>
        </Stack.Item>
      ) : null}

      <Stack.Item>
        <Section fitted title="Offset">
          <HybridOffsetControls
            descriptor={descriptor}
            draftProps={activeDraft}
            onDraftChange={updateDraft}
            direction={activeDir}
            onDirectionChange={setActiveDir}
            onCopyToAll={copyDraftToAll}
            offsetMin={offsetMin}
            offsetMax={offsetMax}
          />
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Stack>
          <Stack.Item grow>
            <Button
              fluid
              icon="save"
              color={dirty ? 'good' : undefined}
              disabled={!dirty || !selectedTarget}
              onClick={saveDraft}
            >
              Save
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button fluid icon="undo" disabled={!dirty} onClick={revertDraft}>
              Revert
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}
