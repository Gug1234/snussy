/**
 * @file IntimateAccessoriesTab.tsx
 * @description Legacy tab body for the intimate accessories surface.
 *
 * The middle-column Intimacy row now receives compact server scope data for
 * the phase-one offset route. This tab keeps the older full-width path alive
 * while reading the same `intimate_accessory_offset_rows` payload so both
 * entrypoints agree on whether an offset-capable target exists.
 */

import { useMemo } from 'react';
import { Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import {
  getEditableIntimateAccessoryOffsetRows,
  INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS,
  normalizeIntimateAccessoryOffsetRows,
} from '../bodies/Intimacy/IntimateAccessoryOffsetLogic';
import type { PreferencesMenuData } from '../types';

export function IntimateAccessoriesTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const offsetRows = useMemo(
    () =>
      normalizeIntimateAccessoryOffsetRows(data.intimate_accessory_offset_rows),
    [data.intimate_accessory_offset_rows],
  );
  const editableRows = useMemo(
    () => getEditableIntimateAccessoryOffsetRows(offsetRows),
    [offsetRows],
  );

  return (
    <Section title="Intimate Accessories">
      <Stack vertical>
        <Stack.Item>
          <LabeledList>
            <LabeledList.Item label="Offset scope">
              {INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS.join(' / ')}
            </LabeledList.Item>
            <LabeledList.Item label="Targets">
              {editableRows.length}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="crosshairs"
            disabled={!editableRows.length}
            tooltip={
              editableRows.length
                ? 'Focus the first editable target in the preview panel'
                : 'No offset-capable intimate accessory target is available'
            }
            onClick={() =>
              act('set_intimate_accessory_offset_target', {
                target_key: editableRows[0]?.offset_target_key,
              })
            }
          >
            Focus Accessory Offset Target
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}
