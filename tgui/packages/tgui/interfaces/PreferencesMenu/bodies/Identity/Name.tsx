/**
 * @file bodies/Identity/Name.tsx
 * @description Identity → Name row body.
 *
 * Surfaces the character's real name, nickname, and nickname color.
 * Body type lives in the Body category; pronouns have their own row
 * (Identity → Pronouns).
 */

import { Box, Input, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { BracketedValueSlot } from '../../widgets';
import { usePrefField } from '../usePrefField';

function NameBody() {
  const { data } = useBackend<PreferencesMenuData>();
  // tgui-core's <Input> caches its DOM value internally and doesn't
  // re-sync from the `value` prop until a focus/blur cycle. When the
  // active character slot changes, the snapshot value updates but the
  // input keeps showing whatever it had, so the player has to click
  // in/out before the new slot's name appears. Remounting the field
  // with a slot-scoped key forces a fresh DOM input bound to the new
  // snapshot.
  const slotKey = data.active_slot ?? 0;

  const realName = usePrefField<string>(PREF_KEYS.REAL_NAME, '', {
    autosave: true,
  });
  const nickname = usePrefField<string>(PREF_KEYS.NICKNAME, '', {
    autosave: true,
  });
  const nicknameColor = usePrefField<string>(
    PREF_KEYS.NICKNAME_COLOR,
    '#ffffff',
  );

  return (
    <Section title="Name">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Character name</Box>
          <Input
            key={`real-${slotKey}`}
            fluid
            value={realName.value ?? ''}
            onChange={(val: string) => realName.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Nickname</Box>
          <Input
            key={`nick-${slotKey}`}
            fluid
            value={nickname.value ?? ''}
            onChange={(val: string) => nickname.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Nickname color</Box>
          <Input
            key={`nickcolor-${slotKey}`}
            value={nicknameColor.value ?? '#ffffff'}
            onChange={(val: string) => nicknameColor.setValue(val)}
          />
          <BracketedValueSlot>{nicknameColor.value ?? '—'}</BracketedValueSlot>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'name',
  label: 'Name',
  component: NameBody,
});
