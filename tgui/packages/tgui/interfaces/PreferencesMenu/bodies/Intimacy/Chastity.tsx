/**
 * @file bodies/Intimacy/Chastity.tsx
 * @description Chastity row — inline round-start device controls.
 */

import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

const ROW_ID = 'chastity';

function boolValue(value: unknown): boolean {
  return !!value && value !== 0;
}

function ChastityToggle(props: {
  label: string;
  field: ReturnType<typeof usePrefField<number>>;
  disabled?: boolean;
}) {
  return (
    <Button.Checkbox
      checked={boolValue(props.field.value)}
      disabled={props.disabled}
      onClick={() => props.field.setValue(boolValue(props.field.value) ? 0 : 1)}
    >
      {props.label}
    </Button.Checkbox>
  );
}

function ChastityBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const [stashDraft, setStashDraft] = useState('');

  const enabled = usePrefField<number>(PREF_KEYS.CHASTITY_ENABLED, 0, {
    autosave: true,
  });
  const flat = usePrefField<number>(PREF_KEYS.CHASTITY_FLAT, 0, {
    autosave: true,
  });
  const anal = usePrefField<number>(PREF_KEYS.CHASTITY_ANAL, 0, {
    autosave: true,
  });
  const spiked = usePrefField<number>(PREF_KEYS.CHASTITY_SPIKED, 0, {
    autosave: true,
  });
  const locked = usePrefField<number>(PREF_KEYS.CHASTITY_LOCKED, 0, {
    autosave: true,
  });
  const spawnKey = usePrefField<number>(PREF_KEYS.CHASTITY_SPAWN_KEY, 1, {
    autosave: true,
  });
  const randomKeys = usePrefField<number>(PREF_KEYS.CHASTITY_RANDOM_KEYS, 0, {
    autosave: true,
  });
  const keyStashes = usePrefField<string[]>(
    PREF_KEYS.CHASTITY_KEY_STASHES,
    [],
    { autosave: true },
  );
  const hardmode = usePrefField<number>(PREF_KEYS.CHASTITY_HARDMODE, 0);
  const perCharHardmode = usePrefField<boolean>(
    PREF_KEYS.PER_CHAR_HARDMODE,
    false,
  );

  const canUseChastity = data.chastity_available !== 0;
  const hasPenis = data.chastity_has_penis !== 0;
  const hasVagina = data.chastity_has_vagina !== 0;
  const hasGenitals = hasPenis || hasVagina;
  const isCockCage = hasPenis && !hasVagina;
  const isIntersex = hasPenis && hasVagina;
  const extreme = boolValue(data.prefs?.[PREF_KEYS.EXTREME_ERP]);
  const stashes = Array.isArray(keyStashes.value) ? keyStashes.value : [];
  const deviceEnabled = boolValue(enabled.value);
  const canStartChastity = canUseChastity && hasGenitals;
  const showDeviceOptions = deviceEnabled && hasGenitals;

  const addStash = () => {
    const nextName = stashDraft.trim();
    if (!nextName || stashes.length >= 5) {
      return;
    }
    if (stashes.some((name) => name.toLowerCase() === nextName.toLowerCase())) {
      setStashDraft('');
      return;
    }
    keyStashes.setValue([...stashes, nextName]);
    setStashDraft('');
  };

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Chastity device">
          <Box mb={1} color="label">
            Round-start device and key behavior.
          </Box>
          {!canUseChastity && (
            <NoticeBox info>
              Enable chastity content in ERP preferences to use this menu.
            </NoticeBox>
          )}
          {canUseChastity && !hasGenitals && (
            <NoticeBox danger>
              Your character has no genitals configured. A chastity device
              cannot be equipped.
            </NoticeBox>
          )}
          <Stack vertical>
            <Stack.Item>
              <ChastityToggle
                label="Start with a chastity device"
                field={enabled}
                disabled={!canStartChastity}
              />
            </Stack.Item>
            {showDeviceOptions && (
              <>
                {isCockCage && (
                  <Stack.Item>
                    <ChastityToggle label="Flat cage" field={flat} />
                  </Stack.Item>
                )}
                {!isIntersex && (
                  <Stack.Item>
                    <ChastityToggle label="Anal shield" field={anal} />
                  </Stack.Item>
                )}
                <Stack.Item>
                  <ChastityToggle
                    label="Spiked device"
                    field={spiked}
                    disabled={!extreme}
                  />
                </Stack.Item>
                <Stack.Item>
                  <ChastityToggle label="Spawn locked" field={locked} />
                </Stack.Item>
                <Stack.Item>
                  <ChastityToggle label="Spawn with key" field={spawnKey} />
                </Stack.Item>
                <Stack.Item>
                  <ChastityToggle
                    label="Randomize spare keys"
                    field={randomKeys}
                  />
                </Stack.Item>
              </>
            )}
          </Stack>
        </Section>
        {showDeviceOptions && (
          <Section title="Key stashes" mt={1}>
            <Stack vertical>
              {stashes.map((name) => (
                <Stack.Item key={name}>
                  <Button
                    icon="times"
                    color="bad"
                    onClick={() =>
                      keyStashes.setValue(
                        stashes.filter((entry) => entry !== name),
                      )
                    }
                  />
                  <Box as="span" ml={0.5}>
                    {name}
                  </Box>
                </Stack.Item>
              ))}
              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Input
                      fluid
                      value={stashDraft}
                      placeholder="Character name"
                      maxLength={42}
                      onChange={setStashDraft}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="plus"
                      disabled={!stashDraft.trim() || stashes.length >= 5}
                      onClick={addStash}
                    >
                      Add
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>
        )}
        <Section title="Chastity hardmode" mt={1}>
          <Box mb={0.5} color="label">
            Chastity hardmode prevents you from removing your own device.
          </Box>
          <Button.Checkbox
            checked={!!hardmode.value && hardmode.value > 0}
            onClick={() => hardmode.setValue(hardmode.value ? 0 : 1)}
          >
            Account-wide chastity hardmode
          </Button.Checkbox>
          <Box mt={0.5}>
            <Button.Checkbox
              checked={!!perCharHardmode.value}
              onClick={() => perCharHardmode.setValue(!perCharHardmode.value)}
            >
              Per-character hardmode (this slot only)
            </Button.Checkbox>
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.INTIMACY,
  id: ROW_ID,
  label: 'Chastity',
  component: ChastityBody,
  visible: (data) => !data?.intimacy_gated,
});
