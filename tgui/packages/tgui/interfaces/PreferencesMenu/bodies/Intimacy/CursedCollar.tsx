/**
 * @file bodies/Intimacy/CursedCollar.tsx
 * @description Cursed-collar round-start equip path. Three pref keys:
 *   - `cursed_collar_opt`           : NONE | COLLAR | CHASTITY_DEVICE
 *   - `cursed_collar_master_mode`   : SELF | RANDOM | SPECIFIED
 *   - `cursed_collar_specified_name`: free-text, only when SPECIFIED
 *
 * Master-mode + specified-name controls render only when `opt` is set
 * to a real device (i.e. not NONE).
 *
 * Setter for `cursed_collar_opt` is owned by the Step 3 dispatch seed;
 * the other two are owned by `prefs_categories/intimacy.dm`.
 */

import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

// Mirror of code/__DEFINES/preferences_tgui.dm enums.
const COLLAR_OPT_NONE = 0;
const COLLAR_OPT_COLLAR = 1;
const COLLAR_OPT_CHASTITY = 2;
const MASTER_SELF = 0;
const MASTER_RANDOM = 1;
const MASTER_SPECIFIED = 2;

const OPT_OPTIONS = [
  { value: COLLAR_OPT_NONE, displayText: 'None' },
  { value: COLLAR_OPT_COLLAR, displayText: 'Collar' },
  { value: COLLAR_OPT_CHASTITY, displayText: 'Chastity Device' },
];

const MASTER_OPTIONS = [
  { value: MASTER_SELF, displayText: 'Self (own the key)' },
  { value: MASTER_RANDOM, displayText: 'Random other player' },
  { value: MASTER_SPECIFIED, displayText: 'Specific player' },
];

function CursedCollarBody() {
  const opt = usePrefField<number>(
    PREF_KEYS.CURSED_COLLAR_OPT,
    COLLAR_OPT_NONE,
  );
  const master = usePrefField<number>(
    PREF_KEYS.CURSED_COLLAR_MASTER_MODE,
    MASTER_SELF,
  );
  const specified = usePrefField<string>(
    PREF_KEYS.CURSED_COLLAR_SPECIFIED_NAME,
    '',
    { autosave: true },
  );

  const optValue = (opt.value ?? COLLAR_OPT_NONE) as number;
  const masterValue = (master.value ?? MASTER_SELF) as number;
  const enabled = optValue !== COLLAR_OPT_NONE;

  const optLabel =
    OPT_OPTIONS.find((o) => o.value === optValue)?.displayText ?? '';
  const masterLabel =
    MASTER_OPTIONS.find((o) => o.value === masterValue)?.displayText ?? '';

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Cursed collar">
          <Box mb={1} color="label">
            Round-start equip path. The key holder receives the key; you cannot
            remove the device without their cooperation.
          </Box>
          <Stack vertical>
            <Stack.Item>
              <Box mb={0.5}>Device</Box>
              <Dropdown
                width="20em"
                selected={String(optValue)}
                displayText={optLabel}
                options={OPT_OPTIONS.map((o) => ({
                  value: String(o.value),
                  displayText: o.displayText,
                }))}
                onSelected={(value: string) => opt.setValue(Number(value))}
              />
            </Stack.Item>
            {enabled && (
              <Stack.Item>
                <Box mb={0.5}>Key holder</Box>
                <Dropdown
                  width="20em"
                  selected={String(masterValue)}
                  displayText={masterLabel}
                  options={MASTER_OPTIONS.map((o) => ({
                    value: String(o.value),
                    displayText: o.displayText,
                  }))}
                  onSelected={(value: string) => master.setValue(Number(value))}
                />
              </Stack.Item>
            )}
            {enabled && masterValue === MASTER_SPECIFIED && (
              <Stack.Item>
                <Box mb={0.5}>Specified character name</Box>
                <Input
                  fluid
                  value={specified.value ?? ''}
                  onChange={(val: string) => specified.setValue(val)}
                  maxLength={64}
                />
              </Stack.Item>
            )}
            {enabled && masterValue === MASTER_SPECIFIED && (
              <Stack.Item>
                <Button icon="eraser" onClick={() => specified.setValue('')}>
                  Clear name
                </Button>
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
  id: 'cursed_collar',
  label: 'Cursed Collar',
  component: CursedCollarBody,
  visible: (data) => !data?.intimacy_gated,
});
