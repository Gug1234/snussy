/**
 * Runtime intimate accessory management panel.
 *
 * This first-PR panel intentionally handles only base accessories and anal
 * bead controls. Shelved decoration editors stay outside this surface.
 */

import { useEffect, useState } from 'react';

import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type ItemData = {
  ref: string;
  name: string;
  metal: string;
  metal_color: string;
  has_socket: boolean;
  socket_desc: string | null;
  gem_color: string;
  is_insertable: boolean;
  is_piercing: boolean;
  is_beriddled: boolean;
  is_silver: boolean;
  can_remove: boolean;
  can_customize_descriptor: boolean;
  custom_descriptor: string;
  is_beads: boolean;
  beads_inserted: number;
  max_beads: number;
  can_push_beads: boolean;
  can_pull_beads: boolean;
  can_ripcord_beads: boolean;
};

type SlotEntry = {
  slot: number;
  slot_name: string;
  occupied: boolean;
  concealed: boolean;
  item: ItemData | null;
};

type Data = {
  invalid?: boolean;
  wearer_name: string;
  is_self: boolean;
  show_visual_widgets: boolean;
  slots: SlotEntry[];
};

const ColorSwatch = (props: { color: string; round?: boolean }) => (
  <Box
    inline
    style={{
      display: 'inline-block',
      width: '0.65em',
      height: '0.65em',
      background: props.color,
      border: '1px solid rgba(255,255,255,0.22)',
      borderRadius: props.round ? '50%' : '2px',
      marginRight: '0.35em',
      verticalAlign: 'middle',
    }}
  />
);

function buildTags(item: ItemData): string {
  const tags: string[] = [];
  if (item.is_insertable) {
    tags.push('Insertable');
  }
  if (item.is_piercing) {
    tags.push('Piercing');
  }
  if (item.is_beriddled) {
    tags.push('Beriddled');
  }
  if (item.is_silver) {
    tags.push('Silver');
  }
  return tags.join(', ') || '-';
}

export const IntimateMenu = () => {
  const { data } = useBackend<Data>();

  if (data.invalid) {
    return (
      <Window width={420} height={180} title="Intimate Accessories">
        <Window.Content>
          <NoticeBox danger>This panel is no longer available.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const title = data.is_self
    ? 'My Intimate Accessories'
    : `${data.wearer_name}'s Intimate Accessories`;

  return (
    <Window width={520} height={580} title={title}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {(data.slots ?? []).map((slot) => (
            <Stack.Item key={`${slot.slot}-${slot.slot_name}`}>
              <SlotCard slot={slot} />
            </Stack.Item>
          ))}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SlotCard = (props: { slot: SlotEntry }) => {
  const { slot } = props;

  if (!slot.occupied) {
    return (
      <Section title={slot.slot_name} style={{ opacity: 0.45 }}>
        <Box italic color="label">
          Empty
        </Box>
      </Section>
    );
  }

  if (slot.concealed) {
    return (
      <Section title={slot.slot_name}>
        <Box color="average" italic>
          Concealed by clothing.
        </Box>
      </Section>
    );
  }

  return (
    <Section title={slot.slot_name}>
      <ItemCard item={slot.item!} />
    </Section>
  );
};

const ItemCard = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;
  const savedDescriptor = item.custom_descriptor ?? '';
  const [descriptorInput, setDescriptorInput] = useState(savedDescriptor);
  const trimmedDescriptor = descriptorInput.trim();
  const descriptorDirty = trimmedDescriptor !== savedDescriptor;

  useEffect(() => {
    setDescriptorInput(savedDescriptor);
  }, [savedDescriptor, item.ref]);

  const saveDescriptor = () => {
    if (!descriptorDirty) {
      return;
    }
    act('set_piercing_descriptor', {
      ref: item.ref,
      descriptor: trimmedDescriptor,
    });
  };

  return (
    <Stack vertical>
      <Stack.Item>
        <Stack align="center">
          <Stack.Item grow>
            <Box bold>
              <ColorSwatch color={item.metal_color} />
              {item.name}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="bad"
              disabled={!item.can_remove}
              tooltip={
                !item.can_remove
                  ? 'Cannot access this accessory right now.'
                  : undefined
              }
              onClick={() => act('remove_accessory', { ref: item.ref })}
            >
              Remove
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      <Stack.Item>
        <LabeledList>
          <LabeledList.Item label="Material">
            <ColorSwatch color={item.metal_color} />
            {item.metal}
          </LabeledList.Item>

          {!!item.has_socket && (
            <LabeledList.Item label="Socket">
              <ColorSwatch color={item.gem_color} round />
              {item.socket_desc ?? 'Unknown insert'}
            </LabeledList.Item>
          )}

          <LabeledList.Item label="Properties">
            {buildTags(item)}
          </LabeledList.Item>

          {!!item.can_customize_descriptor && (
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
                      act('set_piercing_descriptor', {
                        ref: item.ref,
                        descriptor: '',
                      })
                    }
                  />
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
          )}

          {!!item.is_beads && item.max_beads > 0 && (
            <LabeledList.Item label="Beads">
              <Stack align="center" wrap>
                <Stack.Item>
                  {item.beads_inserted} / {item.max_beads} inserted
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="good"
                    disabled={!item.can_push_beads}
                    tooltip="Push one more bead in."
                    onClick={() => act('push_beads', { ref: item.ref })}
                  >
                    Push In
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="average"
                    disabled={!item.can_pull_beads}
                    tooltip="Pull one bead out."
                    onClick={() => act('pull_beads', { ref: item.ref })}
                  >
                    Pull Out
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="bad"
                    disabled={!item.can_ripcord_beads}
                    tooltip="Pull all inserted beads out at once."
                    onClick={() => act('ripcord_beads', { ref: item.ref })}
                  >
                    Ripcord
                  </Button>
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
          )}
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
};
