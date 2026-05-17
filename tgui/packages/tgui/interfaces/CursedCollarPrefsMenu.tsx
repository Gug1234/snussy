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

type BackendData = {
  cursed_enabled: boolean;
  chastenable: boolean;
  device: string;
  device_options: DeviceOption[];
  master_name: string;
  self_master: boolean;
  character_name: string;
};

const deviceIcons: Record<string, string> = {
  none: 'times',
  collar: 'link',
  chastity: 'lock',
};

export function CursedCollarPrefsMenu() {
  const { act, data } = useBackend<BackendData>();
  const cursedEnabled = !!data.cursed_enabled;
  const chastenable = !!data.chastenable;
  const selectedDevice = data.device || 'none';
  const deviceOptions = Array.isArray(data.device_options)
    ? data.device_options
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
  const getDeviceLabel = (value: string, fallback: string) =>
    deviceOptions.find((option) => option.value === value)?.label || fallback;
  const deviceRows = [
    {
      label: getDeviceLabel('none', 'None'),
      value: 'none',
    },
    {
      label: getDeviceLabel('collar', 'Cursed Collar'),
      value: 'collar',
    },
    {
      label: getDeviceLabel('chastity', 'Cursed Chastity'),
      value: 'chastity',
    },
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
            Choose whether this character starts with a cursed collar or a
            cursed chastity device. The selected master controls the cursed item
            when the round begins.
          </Box>

          <LabeledList>
            {deviceRows.map((option) => {
              const selected = selectedDevice === option.value;
              return (
                <LabeledList.Item key={option.value} label={option.label}>
                  <Button
                    icon={selected ? 'check' : deviceIcons[option.value]}
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

          {selectedDevice === 'chastity' && !chastenable && (
            <NoticeBox danger>
              Enable chastity content in the options menu to spawn with cursed
              chastity.
            </NoticeBox>
          )}
        </Section>

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
                      disabled={
                        selfMaster || !trimmedNameInput || !masterDirty
                      }
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
