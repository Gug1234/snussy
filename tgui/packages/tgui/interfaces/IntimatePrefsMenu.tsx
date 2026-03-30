/**
 * @file IntimatePrefsMenu.tsx
 * @description Lobby-side TGUI panel for selecting intimate accessories
 * before spawning. Shows all four slots with a dropdown selector and
 * clear button for each.
 */

import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, Dropdown, Section, Stack } from 'tgui-core/components';

type SlotData = {
  key: string;
  label: string;
  current: string;
  options: string[];
};

type BackendData = {
  slots: SlotData[];
};

export function IntimatePrefsMenu(props) {
  const { act, data } = useBackend<BackendData>();
  const { slots = [] } = data;

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
            Genital plugs require vaginal anatomy. Silver items are
            skipped for silver-weak races.
          </Box>

          <Stack vertical fill>
            {slots.map((slot) => (
              <Stack.Item key={slot.key}>
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
                  <Stack align="center">
                    <Stack.Item grow>
                      <Dropdown
                        width="100%"
                        selected={slot.current}
                        options={slot.options}
                        onSelected={(val: string) =>
                          act('select', {
                            slot: slot.key,
                            option: val,
                          })
                        }
                      />
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
}

