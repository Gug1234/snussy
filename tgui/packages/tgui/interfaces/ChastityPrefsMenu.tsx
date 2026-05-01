/**
 * @file ChastityPrefsMenu.tsx
 * @description Lobby-side TGUI panel for configuring chastity device
 * preferences via toggles. The actual device typepath is resolved server-side
 * based on the character's genitals and these toggle states. Key stashes
 * use character names (not ckeys).
 */

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

type BackendData = {
  chastenable: boolean;
  extreme_erp: boolean;
  enabled: boolean;
  flat: boolean;
  anal: boolean;
  spiked: boolean;
  locked: boolean;
  spawn_key: boolean;
  has_penis: boolean;
  has_vagina: boolean;
  key_stashes: string[];
  random_keys: boolean;
};

export function ChastityPrefsMenu() {
  const { act, data } = useBackend<BackendData>();
  // BYOND sends 0/1 instead of true/false — coerce with !! so React
  // conditional rendering never leaks a literal "0" into the DOM.
  const chastenable = !!data.chastenable;
  const extreme_erp = !!data.extreme_erp;
  const enabled = !!data.enabled;
  const flat = !!data.flat;
  const anal = !!data.anal;
  const spiked = !!data.spiked;
  const locked = !!data.locked;
  const spawn_key = data.spawn_key !== undefined ? !!data.spawn_key : true;
  const has_penis = !!data.has_penis;
  const has_vagina = !!data.has_vagina;
  const key_stashes: string[] = Array.isArray(data.key_stashes)
    ? data.key_stashes
    : [];
  const random_keys = !!data.random_keys;

  const [stashInput, setStashInput] = useState('');

  if (!chastenable) {
    return (
      <Window>
        <Window.Content>
          <NoticeBox info>
            Enable chastity content in ERP Preferences to use this menu.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const hasGenitals = has_penis || has_vagina;
  // Cock cage = penis only (not intersex)
  const isCockCage = has_penis && !has_vagina;
  // Intersex devices don't support flat or anal toggles
  const isIntersex = has_penis && has_vagina;

  return (
    <Window>
      <Window.Content scrollable>
        <Section title="Chastity Device">
          <Box mb={1} opacity={0.5} fontSize="11px" italic>
            Enable a chastity device to equip at round start. The device type is
            automatically selected based on your character{"'"}s genitals.
            Spiked devices require extreme ERP to be enabled.
          </Box>

          {!hasGenitals && (
            <NoticeBox danger>
              Your character has no genitals configured. A chastity device
              cannot be equipped.
            </NoticeBox>
          )}

          <LabeledList>
            <LabeledList.Item label="Chastity Device">
              <Button
                icon={enabled ? 'check' : 'times'}
                color={enabled ? 'good' : 'bad'}
                disabled={!hasGenitals}
                onClick={() => act('toggle_enabled')}
              >
                {enabled ? 'On' : 'Off'}
              </Button>
            </LabeledList.Item>

            {enabled && isCockCage && (
              <LabeledList.Item label="Cage Style">
                <Button
                  icon={flat ? 'compress-alt' : 'expand-alt'}
                  onClick={() => act('toggle_flat')}
                >
                  {flat ? 'Flat' : 'Standard'}
                </Button>
              </LabeledList.Item>
            )}

            {enabled && !isIntersex && (
              <LabeledList.Item label="Anal Shield">
                <Button
                  icon={anal ? 'shield-alt' : 'times'}
                  color={anal ? 'good' : 'bad'}
                  onClick={() => act('toggle_anal')}
                >
                  {anal ? 'Yes' : 'No'}
                </Button>
              </LabeledList.Item>
            )}

            {enabled && (
              <LabeledList.Item label="Spikes">
                <Button
                  icon={spiked ? 'exclamation-triangle' : 'times'}
                  color={spiked ? 'bad' : 'default'}
                  disabled={!extreme_erp}
                  tooltip={
                    !extreme_erp
                      ? 'Requires extreme ERP to be enabled'
                      : undefined
                  }
                  onClick={() => act('toggle_spiked')}
                >
                  {spiked ? 'Yes' : 'No'}
                </Button>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>

        {enabled && hasGenitals && (
          <>
            <Section title="Lock & Key">
              <LabeledList>
                <LabeledList.Item label="Spawn Locked">
                  <Button
                    icon={locked ? 'lock' : 'lock-open'}
                    color={locked ? 'bad' : 'good'}
                    onClick={() => act('toggle_locked')}
                  >
                    {locked ? 'Yes' : 'No'}
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Spawn with Key">
                  <Button
                    icon={spawn_key ? 'key' : 'times'}
                    color={spawn_key ? 'good' : 'bad'}
                    onClick={() => act('toggle_spawn_key')}
                  >
                    {spawn_key ? 'Yes' : 'No'}
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </Section>

            <Section title="Random Key Distribution">
              <Box mb={1} opacity={0.5} fontSize="11px" italic>
                Send a copy of your chastity key to a random player who has
                chastity content enabled and is not already in your key stash
                list.
              </Box>
              <LabeledList>
                <LabeledList.Item label="Random Keys">
                  <Button
                    icon={random_keys ? 'dice' : 'times'}
                    color={random_keys ? 'good' : 'bad'}
                    onClick={() => act('toggle_random_keys')}
                  >
                    {random_keys ? 'On' : 'Off'}
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </Section>

            <Section title="Key Stashes">
              <Box mb={1} opacity={0.5} fontSize="11px" italic>
                Enter character names to give copies of your chastity key to
                when the round starts. If the character is not online yet, the
                key will be delivered when they join. Maximum 5.
              </Box>

              <Stack mb={1}>
                <Stack.Item grow>
                  <Input
                    fluid
                    placeholder="Character name..."
                    value={stashInput}
                    onChange={setStashInput}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="plus"
                    disabled={!stashInput.trim()}
                    onClick={() => {
                      act('add_stash', { name: stashInput.trim() });
                      setStashInput('');
                    }}
                  >
                    Add
                  </Button>
                </Stack.Item>
              </Stack>

              {key_stashes.length > 0 ? (
                <Stack vertical>
                  {key_stashes.map((name) => (
                    <Stack.Item key={name}>
                      <Stack align="center">
                        <Stack.Item grow>{name}</Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="trash"
                            color="bad"
                            compact
                            onClick={() => act('remove_stash', { name: name })}
                          />
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>
                  ))}
                </Stack>
              ) : (
                <Box opacity={0.4} italic>
                  No key stash targets configured.
                </Box>
              )}
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
}
