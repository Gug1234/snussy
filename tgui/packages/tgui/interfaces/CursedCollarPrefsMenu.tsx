import { useState } from 'react';
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

const getDeviceIcon = (device: string, selected: boolean) => {
  if (!selected) {
    return 'circle';
  }
  return deviceIcons[device] || 'check';
};

const getDeviceColor = (device: string, selected: boolean) => {
  if (!selected) {
    return 'default';
  }
  return device === 'none' ? 'bad' : 'good';
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

  const needsMaster = selectedDevice !== 'none';
  const missingMaster = needsMaster && !selfMaster && !nameInput.trim();

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
            <LabeledList.Item label="Round-start Device">
              <Stack align="center" wrap>
                {deviceOptions.map((option) => {
                  const selected = selectedDevice === option.value;
                  return (
                    <Stack.Item key={option.value}>
                      <Button
                        icon={getDeviceIcon(option.value, selected)}
                        color={getDeviceColor(option.value, selected)}
                        selected={selected}
                        onClick={() =>
                          act('set_device', { device: option.value })
                        }
                      >
                        {option.label}
                      </Button>
                    </Stack.Item>
                  );
                })}
              </Stack>
            </LabeledList.Item>
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
                      onChange={setNameInput}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="save"
                      disabled={selfMaster}
                      onClick={() =>
                        act('set_master_name', { name: nameInput.trim() })
                      }
                    >
                      Set
                    </Button>
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
            </LabeledList>

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
