import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

type DeviceOption = {
  label: string;
  value: string;
};

type SlotOption = {
  label: string;
  value: number;
};

type BackendData = {
  cursed_enabled: boolean;
  chastenable: boolean;
  intimate_enabled: boolean;
  device: string;
  device_options: DeviceOption[];
  gilded_recipient: string;
  gilded_recipient_options: DeviceOption[];
  piercing_slot: number;
  piercing_slot_options: SlotOption[];
  master_name: string;
  self_master: boolean;
  character_name: string;
};

const deviceIcons: Record<string, string> = {
  none: 'times',
  collar: 'link',
  chastity: 'lock',
  gilded_chastity: 'coins',
  piercing: 'gem',
};

export function CursedCollarPrefsMenu() {
  const { act, data } = useBackend<BackendData>();
  const cursedEnabled = !!data.cursed_enabled;
  const chastenable = !!data.chastenable;
  const intimateEnabled = !!data.intimate_enabled;
  const selectedDevice = data.device || 'none';
  const deviceOptions = Array.isArray(data.device_options)
    ? data.device_options
    : [];
  const gildedRecipient = data.gilded_recipient || 'master';
  const gildedRecipientOptions = Array.isArray(data.gilded_recipient_options)
    ? data.gilded_recipient_options
    : [];
  const piercingSlot = Number(data.piercing_slot) || 1;
  const piercingSlotOptions = Array.isArray(data.piercing_slot_options)
    ? data.piercing_slot_options
    : [];
  const selfMaster = !!data.self_master;
  const masterName = data.master_name || '';
  const characterName = data.character_name || 'this character';
  const [nameInput, setNameInput] = useState(masterName);

  useEffect(() => {
    setNameInput(masterName);
  }, [masterName]);

  const needsMaster = selectedDevice !== 'none';
  const savedMasterName = masterName.trim();
  const trimmedNameInput = nameInput.trim();
  const masterDirty =
    needsMaster && !selfMaster && trimmedNameInput !== savedMasterName;
  const missingMaster = needsMaster && !selfMaster && !savedMasterName;
  const setMasterName = () => {
    if (!selfMaster && trimmedNameInput) {
      act('set_master_name', { master_name: trimmedNameInput });
    }
  };
  const deviceRows = deviceOptions.length
    ? deviceOptions
    : [
        { label: 'None', value: 'none' },
        { label: 'Cursed Collar', value: 'collar' },
        { label: 'Cursed Chastity', value: 'chastity' },
        { label: 'Gilded Chastity', value: 'gilded_chastity' },
        { label: 'Cursed Piercing', value: 'piercing' },
      ];

  return (
    <Window>
      <Window.Content scrollable>
        {!cursedEnabled && (
          <NoticeBox info>
            Enable cursed collar content in the options menu to apply these
            round-start choices.
          </NoticeBox>
        )}

        <Section title="Cursed Binding">
          <Box mb={1} opacity={0.5} fontSize="11px" italic>
            Choose whether this character starts with a cursed collar, cursed
            chastity device, or cursed piercing. The selected master controls
            the cursed item when the round begins.
          </Box>

          <LabeledList>
            {deviceRows.map((option) => {
              const selected = selectedDevice === option.value;
              return (
                <LabeledList.Item key={option.value} label={option.label}>
                  <Button
                    icon={
                      selected ? 'check' : deviceIcons[option.value] || 'lock'
                    }
                    color={selected ? 'good' : 'bad'}
                    selected={selected}
                    onClick={() => act('set_device', { device: option.value })}
                  >
                    {selected ? 'Selected' : 'Select'}
                  </Button>
                </LabeledList.Item>
              );
            })}
          </LabeledList>

          {!needsMaster && (
            <Box mt={1} opacity={0.4} italic>
              No cursed round-start item configured.
            </Box>
          )}

          {(selectedDevice === 'chastity' ||
            selectedDevice === 'gilded_chastity') &&
            !chastenable && (
              <NoticeBox danger>
                Enable chastity content in the options menu to spawn with cursed
                chastity.
              </NoticeBox>
            )}

          {selectedDevice === 'piercing' && !intimateEnabled && (
            <NoticeBox danger>
              Enable intimate accessories in the options menu to spawn with a
              cursed piercing.
            </NoticeBox>
          )}
        </Section>

        {selectedDevice === 'gilded_chastity' && (
          <Section title="Coin Destination">
            <LabeledList>
              {gildedRecipientOptions.map((option) => {
                const selected = gildedRecipient === option.value;
                return (
                  <LabeledList.Item key={option.value} label={option.label}>
                    <Button
                      icon={selected ? 'check' : 'coins'}
                      color={selected ? 'good' : 'bad'}
                      selected={selected}
                      onClick={() =>
                        act('set_gilded_recipient', {
                          recipient: option.value,
                        })
                      }
                    >
                      {selected ? 'Selected' : 'Select'}
                    </Button>
                  </LabeledList.Item>
                );
              })}
            </LabeledList>
          </Section>
        )}

        {selectedDevice === 'piercing' && (
          <Section title="Starting Location">
            <LabeledList>
              {piercingSlotOptions.map((option) => {
                const selected = piercingSlot === Number(option.value);
                return (
                  <LabeledList.Item key={option.value} label={option.label}>
                    <Button
                      icon={selected ? 'check' : 'gem'}
                      color={selected ? 'good' : 'bad'}
                      selected={selected}
                      onClick={() =>
                        act('set_piercing_slot', { slot: option.value })
                      }
                    >
                      {selected ? 'Selected' : 'Select'}
                    </Button>
                  </LabeledList.Item>
                );
              })}
            </LabeledList>
          </Section>
        )}

        {needsMaster && (
          <Section title="Master">
            <Box mb={1} opacity={0.5} fontSize="11px" italic>
              Choose the character who controls the cursed item. Self-master
              assigns control to this character.
            </Box>

            <LabeledList>
              <LabeledList.Item label="Self-master">
                <Button
                  icon={selfMaster ? 'check' : 'times'}
                  color={selfMaster ? 'good' : 'bad'}
                  onClick={() => act('toggle_self_master')}
                >
                  {selfMaster ? 'Yes' : 'No'}
                </Button>
              </LabeledList.Item>
              <LabeledList.Item label="Master name">
                <Stack align="center">
                  <Stack.Item grow>
                    <Input
                      fluid
                      disabled={selfMaster}
                      placeholder="Character name..."
                      value={selfMaster ? characterName : nameInput}
                      onEnter={setMasterName}
                      onChange={setNameInput}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="save"
                      disabled={selfMaster || !trimmedNameInput || !masterDirty}
                      onClick={setMasterName}
                    >
                      Set
                    </Button>
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
              <LabeledList.Item label="Saved Master">
                {selfMaster ? (
                  characterName
                ) : savedMasterName ? (
                  savedMasterName
                ) : (
                  <Box color="bad">None set</Box>
                )}
              </LabeledList.Item>
            </LabeledList>

            {masterDirty && (
              <Box mt={1} color="average">
                Typed master name is not saved yet.
              </Box>
            )}
            {missingMaster && (
              <Box mt={1} color="bad">
                Select self-master or set a master character name.
              </Box>
            )}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
}
