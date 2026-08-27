/**
 * @file IntimatePrefsMenu.tsx
 * @description Lobby-side TGUI panel for selecting intimate accessories
 * before spawning. Intent is to prevent the already bloated features tab 
 * from overinflating further (guh)
 */

import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

type OptionData = {
  key: string;
  label: string;
  color?: string;
  disabled?: boolean;
  tooltip?: string;
};

type SlotData = {
  key: string;
  label: string;
  current: string;
  options: string[];
  current_type: string;
  current_metal: string | null;
  type_options: OptionData[];
  metal_options: OptionData[];
  current_socket: string;
  socket_options: OptionData[];
  show_socket?: boolean;
  can_bell?: boolean;
  has_bell?: boolean;
  show_bead_shape?: boolean;
  current_bead_shape?: string | null;
  bead_shape_options?: OptionData[];
  show_tail_picker?: boolean;
  tail_options?: OptionData[];
  tail_icon_options?: OptionData[];
  tail_current_type?: string | null;
  tail_current_colors?: string[];
  tail_current_icon?: string | null;
  tail_blocked?: boolean;
  can_customize_descriptor?: boolean;
  descriptor?: string;
};

type AccessoryGroupKey = 'genital' | 'rear' | 'torso' | 'head' | 'other';

type AccessoryGroupData = {
  key: AccessoryGroupKey;
  label: string;
  slots: SlotData[];
};

type BackendData = {
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

const ColorSwatch = (props: { color?: string; round?: boolean }) => (
  <Box
    inline
    style={{
      display: 'inline-block',
      width: '0.7em',
      height: '0.7em',
      background: props.color || '#ffffff',
      border: '1px solid rgba(255,255,255,0.22)',
      borderRadius: props.round ? '50%' : '2px',
      marginRight: '0.35em',
      verticalAlign: 'middle',
    }}
  />
);

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

function findOption(options: OptionData[] | undefined, key?: string | null) {
  return (options ?? []).find((option) => option.key === key);
}

export function IntimatePrefsMenu(props) {
  const { data } = useBackend<BackendData>();
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
    <Window width={620} height={640}>
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

function getOptionLabel(option: OptionData | undefined) {
  if (!option) {
    return 'None';
  }
  if (option.disabled && option.tooltip) {
    return `${option.label} (${option.tooltip})`;
  }
  return option.label;
}

function OptionDropdown(props: {
  options: OptionData[] | undefined;
  selected: string | null | undefined;
  onSelect: (option: OptionData) => void;
}) {
  const options = Array.isArray(props.options) ? props.options : [];

  if (!options.length) {
    return (
      <Box color="label" italic>
        None
      </Box>
    );
  }

  const selectedOption =
    findOption(options, props.selected) ??
    options.find((option) => !option.disabled) ??
    options[0];
  const optionLabels = options.map(getOptionLabel);

  return (
    <Stack align="center">
      {!!selectedOption?.color && (
        <Stack.Item>
          <ColorSwatch color={selectedOption.color} />
        </Stack.Item>
      )}
      <Stack.Item grow>
        <Dropdown
          width="100%"
          selected={getOptionLabel(selectedOption)}
          options={optionLabels}
          onSelected={(label: string) => {
            const option = options.find(
              (candidate) => getOptionLabel(candidate) === label,
            );
            if (!option || option.disabled) {
              return;
            }
            props.onSelect(option);
          }}
        />
      </Stack.Item>
    </Stack>
  );
}

function AccessorySlotRow(props: { slot: SlotData }) {
  const { act } = useBackend<BackendData>();
  const { slot } = props;
  const savedDescriptor = slot.descriptor ?? '';
  const [descriptorInput, setDescriptorInput] = useState(savedDescriptor);
  const trimmedDescriptor = descriptorInput.trim();
  const descriptorDirty = trimmedDescriptor !== savedDescriptor;
  const hasAccessory = slot.current_type && slot.current_type !== 'none';

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
        hasAccessory && (
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
      <LabeledList>
        <LabeledList.Item label="Type">
          <OptionDropdown
            options={slot.type_options}
            selected={slot.current_type || 'none'}
            onSelect={(option) =>
              act('select_type', {
                slot: slot.key,
                type: option.key,
              })
            }
          />
        </LabeledList.Item>

        {hasAccessory && (
          <LabeledList.Item label="Metal">
            <OptionDropdown
              options={slot.metal_options}
              selected={slot.current_metal}
              onSelect={(option) =>
                act('select_metal', {
                  slot: slot.key,
                  metal: option.key,
                })
              }
            />
          </LabeledList.Item>
        )}

        {hasAccessory && !!slot.can_bell && (
          <LabeledList.Item label="Bell">
            <Button.Checkbox
              checked={!!slot.has_bell}
              onClick={() =>
                act('set_bell', {
                  slot: slot.key,
                  enabled: !slot.has_bell,
                })
              }
            >
              Bell
            </Button.Checkbox>
          </LabeledList.Item>
        )}

        {hasAccessory && !!slot.show_bead_shape && (
          <LabeledList.Item label="Beads">
            <OptionDropdown
              options={slot.bead_shape_options}
              selected={slot.current_bead_shape}
              onSelect={(option) =>
                act('set_bead_shape', {
                  bead_shape: option.key,
                })
              }
            />
          </LabeledList.Item>
        )}

        {hasAccessory && !!slot.show_socket && (
          <LabeledList.Item label="Socket">
            <OptionDropdown
              options={slot.socket_options}
              selected={slot.current_socket || 'none'}
              onSelect={(option) =>
                act('select_socket', {
                  slot: slot.key,
                  socket: option.key,
                })
              }
            />
          </LabeledList.Item>
        )}

        {hasAccessory && !!slot.show_tail_picker && (
          <TailSocketPicker slot={slot} />
        )}

        {!!slot.can_customize_descriptor && (
          <LabeledList.Item label="Descriptor">
            <Stack align="center">
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
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
}

function TailSocketPicker(props: { slot: SlotData }) {
  const { act } = useBackend<BackendData>();
  const { slot } = props;
  const tailOptions = Array.isArray(slot.tail_options) ? slot.tail_options : [];

  return (
    <>
      <LabeledList.Item label="Tail Sprite">
        <OptionDropdown
          options={tailOptions}
          selected={slot.tail_current_type}
          onSelect={(option) =>
            act('set_tail_type', {
              slot: slot.key,
              tail_type: option.key,
            })
          }
        />
      </LabeledList.Item>

      <LabeledList.Item label="Item Icon">
        <OptionDropdown
          options={slot.tail_icon_options}
          selected={slot.tail_current_icon}
          onSelect={(option) =>
            act('set_tail_icon', {
              slot: slot.key,
              tail_icon: option.key,
            })
          }
        />
      </LabeledList.Item>

      <LabeledList.Item label="Colors">
        <Stack wrap>
          {(slot.tail_current_colors ?? []).map((color, index) => (
            <Stack.Item key={`${slot.key}-tail-color-${index + 1}`}>
              <TailColorInput
                slotKey={slot.key}
                colorIndex={index + 1}
                color={color}
              />
            </Stack.Item>
          ))}
        </Stack>
      </LabeledList.Item>
    </>
  );
}

function TailColorInput(props: {
  slotKey: string;
  colorIndex: number;
  color: string;
}) {
  const { act } = useBackend<BackendData>();
  const [value, setValue] = useState(props.color);
  const dirty = value.trim() !== props.color;

  useEffect(() => {
    setValue(props.color);
  }, [props.color, props.colorIndex, props.slotKey]);

  const saveColor = () => {
    if (!dirty) {
      return;
    }
    act('set_tail_color', {
      slot: props.slotKey,
      color_index: props.colorIndex,
      color: value.trim(),
    });
  };

  return (
    <Stack align="center">
      <Stack.Item>
        <ColorSwatch color={props.color} />
      </Stack.Item>
      <Stack.Item>
        <Input
          width="74px"
          value={value}
          onChange={setValue}
          onEnter={saveColor}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="save"
          disabled={!dirty}
          tooltip="Save color"
          onClick={saveColor}
        />
      </Stack.Item>
    </Stack>
  );
}
