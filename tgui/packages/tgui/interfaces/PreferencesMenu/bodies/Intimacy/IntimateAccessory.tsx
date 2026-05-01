/**
 * @file bodies/Intimacy/IntimateAccessory.tsx
 * @description Intimacy -> Intimate Accessory row. Launches the existing
 * selector and exposes the phase-one x/y offset scope prepared for the shared
 * hybrid overlay editor.
 */

import { useMemo } from 'react';
import { Box, Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import {
  getEditableIntimateAccessoryOffsetRows,
  groupIntimateAccessoryOffsetRows,
  INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS,
  normalizeIntimateAccessoryOffsetRows,
} from './IntimateAccessoryOffsetLogic';

const ROW_ID = 'intimate_accessory';

const GROUP_LABELS: Record<string, string> = {
  genital: 'Genital',
  rear: 'Rear',
  torso: 'Torso',
  head: 'Head',
  other: 'Other',
};

function IntimateAccessoryBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const activeOffsetTarget = data.intimate_accessory_offset_active_target;
  const offsetRows = useMemo(
    () =>
      normalizeIntimateAccessoryOffsetRows(data.intimate_accessory_offset_rows),
    [data.intimate_accessory_offset_rows],
  );
  const editableRows = useMemo(
    () => getEditableIntimateAccessoryOffsetRows(offsetRows),
    [offsetRows],
  );
  const groupedRows = useMemo(
    () => groupIntimateAccessoryOffsetRows(offsetRows),
    [offsetRows],
  );
  const scopeLabel = INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS.join(' / ');

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Intimate Accessory">
          <Stack vertical>
            <Stack.Item>
              <Stack>
                <Stack.Item>
                  <Button
                    icon="gem"
                    onClick={() =>
                      act('launch_singleton', {
                        editor: 'intimate_accessory',
                        return_category: PREFS_CATEGORIES.INTIMACY,
                        return_row: ROW_ID,
                      })
                    }
                  >
                    Open Accessory Selector
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
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
                    Focus Offset Target
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Offset scope">
                  {scopeLabel}
                </LabeledList.Item>
                <LabeledList.Item label="Targets">
                  {editableRows.length}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            {!!offsetRows.length && (
              <Stack.Item>
                <Stack vertical>
                  {Object.entries(groupedRows).map(([group, rows]) => (
                    <Stack.Item key={group}>
                      <Box fontSize="12px" opacity={0.75} mb={0.5}>
                        {GROUP_LABELS[group] ?? group}
                      </Box>
                      <LabeledList>
                        {rows.map((row) => (
                          <LabeledList.Item key={row.key} label={row.label}>
                            <Stack align="center">
                              <Stack.Item grow>
                                <Box
                                  color={
                                    row.offset_editable ? undefined : 'label'
                                  }
                                >
                                  {row.current}
                                </Box>
                              </Stack.Item>
                              {row.offset_editable && row.offset_target_key ? (
                                <Stack.Item>
                                  <Button
                                    compact
                                    icon="crosshairs"
                                    selected={
                                      activeOffsetTarget ===
                                      row.offset_target_key
                                    }
                                    tooltip="Focus this target in the offset preview"
                                    onClick={() =>
                                      act(
                                        'set_intimate_accessory_offset_target',
                                        {
                                          target_key: row.offset_target_key,
                                        },
                                      )
                                    }
                                  />
                                </Stack.Item>
                              ) : null}
                            </Stack>
                          </LabeledList.Item>
                        ))}
                      </LabeledList>
                    </Stack.Item>
                  ))}
                </Stack>
              </Stack.Item>
            )}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.INTIMACY,
  id: ROW_ID,
  label: 'Intimate Accessory',
  component: IntimateAccessoryBody,
  visible: (data) => !data?.intimacy_gated,
});
