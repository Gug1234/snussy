/**
 * @file IntimatePrefsMenu.tsx
 * @description Lobby-side TGUI panel for selecting intimate accessories
 * before spawning. Shows anatomy-grouped tabs with a dropdown selector and
 * clear button for each slot.
 */

import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

type SlotData = {
  key: string;
  label: string;
  current: string;
  options: string[];
  can_customize_descriptor?: boolean;
  descriptor?: string;
};

type AccessoryGroupKey = 'genital' | 'rear' | 'torso' | 'head' | 'other';

type AccessoryGroupData = {
  key: AccessoryGroupKey;
  label: string;
  slots: SlotData[];
};

const ACCESSORY_GROUP_LABELS: Record<AccessoryGroupKey, string> = {
  genital: 'Genital',
  rear: 'Rear',
  torso: 'Torso',
  head: 'Head',
  other: 'Other',
};

const ACCESSORY_GROUP_ORDER: AccessoryGroupKey[] = [
  'genital',
  'rear',
  'torso',
  'head',
  'other',
];

function getAccessoryGroupKey(slotKey: string): AccessoryGroupKey {
  switch (slotKey) {
    case 'genital_piercing':
    case 'genital_insertable':
      return 'genital';
    case 'rear_piercing':
    case 'rear_insertable':
      return 'rear';
    case 'breast_piercing':
    case 'breast_insertable':
    case 'belly_piercing':
      return 'torso';
    case 'mouth_piercing':
    case 'mouth_insertable':
    case 'ear_piercing':
    case 'nose_piercing':
      return 'head';
    default:
      return 'other';
  }
}

function groupAccessorySlots(slots: SlotData[]): AccessoryGroupData[] {
  const sourceSlots = Array.isArray(slots) ? slots : [];
  const grouped: Record<AccessoryGroupKey, SlotData[]> = {
    genital: [],
    rear: [],
    torso: [],
    head: [],
    other: [],
  };

  for (const slot of sourceSlots) {
    if (!slot?.key) {
      continue;
    }
    grouped[getAccessoryGroupKey(slot.key)].push(slot);
  }

  return ACCESSORY_GROUP_ORDER.flatMap((key) => {
    const groupSlots = grouped[key] ?? [];
    if (!Array.isArray(groupSlots) || !groupSlots.length) {
      return [];
    }

    return [
      {
        key,
        label: ACCESSORY_GROUP_LABELS[key],
        slots: groupSlots,
      },
    ];
  });
}

type BackendData = {
  slots: SlotData[];
};

export function IntimatePrefsMenu(props) {
  const { act, data } = useBackend<BackendData>();
  const { slots = [] } = data ?? {};
  const groupedSlots = groupAccessorySlots(slots);
  const [activeGroup, setActiveGroup] = useState<AccessoryGroupKey>(
    groupedSlots[0]?.key ?? 'genital',
  );

  const activeGroupData = groupedSlots.find(
    (group) => group.key === activeGroup,
  );

  useEffect(() => {
    if (!groupedSlots.length) {
      return;
    }
    if (!activeGroupData) {
      setActiveGroup(groupedSlots[0].key);
    }
  }, [activeGroupData, groupedSlots]);

  return (
    <Window>
      <Window.Content scrollable>
        <Section
          title="Intimate Accessories"
          buttons={
            <Box opacity={0.6} fontSize="11px" mt="4px">
              Select accessories to start the round with.
            </Box>
          }
        >
          <Box mb={1} opacity={0.5} fontSize="11px" italic>
            Genital plugs require vaginal anatomy. Silver items are skipped for
            silver-weak races.
          </Box>

          <Tabs>
            {groupedSlots.map((group) => (
              <Tabs.Tab
                key={group.key}
                selected={activeGroup === group.key}
                onClick={() => setActiveGroup(group.key)}
              >
                {group.label}
              </Tabs.Tab>
            ))}
          </Tabs>

          <Box mt={1}>
            <AccessoryGroupSection group={activeGroupData} />
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
}

function AccessoryGroupSection(props: {
  group: AccessoryGroupData | undefined;
}) {
  const { group } = props;
  const slots = Array.isArray(group?.slots) ? group.slots : [];

  if (!slots.length) {
    return null;
  }

  return (
    <Section title={`${group?.label ?? 'Accessory'} Accessories`}>
      <Stack vertical fill>
        {slots.map((slot) => (
          <Stack.Item key={slot.key}>
            <AccessorySlotRow slot={slot} />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
}

function AccessorySlotRow(props: { slot: SlotData }) {
  const { act } = useBackend<BackendData>();
  const { slot } = props;
  const savedDescriptor = slot.descriptor ?? '';
  const [descriptorInput, setDescriptorInput] = useState(savedDescriptor);
  const trimmedDescriptor = descriptorInput.trim();
  const descriptorDirty = trimmedDescriptor !== savedDescriptor;

  useEffect(() => {
    setDescriptorInput(savedDescriptor);
  }, [savedDescriptor, slot.key]);

  const saveDescriptor = () => {
    if (!descriptorDirty) {
      return;
    }
    act('set_descriptor', {
      slot: slot.key,
      descriptor: trimmedDescriptor,
    });
  };

  return (
    <Section
      title={slot.label + ' Slot'}
      buttons={
        slot.current !== 'None' && (
          <Button
            icon="times"
            color="bad"
            compact
            tooltip="Clear this slot"
            onClick={() => act('clear', { slot: slot.key })}
          />
        )
      }
    >
      <Stack vertical>
        <Stack.Item>
          <Dropdown
            width="100%"
            selected={slot.current}
            options={Array.isArray(slot.options) ? slot.options : []}
            onSelected={(val: string) =>
              act('select', {
                slot: slot.key,
                option: val,
              })
            }
          />
        </Stack.Item>

        {!!slot.can_customize_descriptor && (
          <Stack.Item>
            <Stack align="center">
              <Stack.Item width="72px" color="label">
                Descriptor
              </Stack.Item>
              <Stack.Item grow>
                <Input
                  fluid
                  value={descriptorInput}
                  placeholder="jacob's ladder, prince albert..."
                  onChange={setDescriptorInput}
                  onEnter={saveDescriptor}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  compact
                  icon="save"
                  disabled={!descriptorDirty}
                  tooltip="Save descriptor"
                  onClick={saveDescriptor}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  compact
                  icon="undo"
                  disabled={!savedDescriptor}
                  tooltip="Use default descriptor"
                  onClick={() =>
                    act('set_descriptor', {
                      slot: slot.key,
                      descriptor: '',
                    })
                  }
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
}
