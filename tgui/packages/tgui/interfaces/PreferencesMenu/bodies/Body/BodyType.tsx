/**
 * @file bodies/Body/BodyType.tsx
 * @description Body → BodyType row body.
 *
 * Mannequin body model. Server writes the same /datum/preferences
 * `gender` var that Identity → Name's gender dropdown also writes —
 * only one register site (BODY here) owns the `body_type` key, so
 * dispatch is unambiguous. Two surfaces, same underlying var, by
 * design (the spec separates social gender presentation from the body
 * geometry preview).
 */

import { useBackend } from 'tgui/backend';
import { Box, Dropdown, Section, Slider, Stack } from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

const BODY_TYPE_OPTIONS = ['male', 'female'];

function BodyTypeBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const bodyType = usePrefField<string>(PREF_KEYS.BODY_TYPE, 'male');
  const minPct = data.body_size_min_x100 ?? 90;
  const maxPct = data.body_size_max_x100 ?? 115;
  const bodySize = usePrefField<number>(PREF_KEYS.BODY_SIZE_X100, 100);

  return (
    <Section title="Body type">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Body model</Box>
          <Dropdown
            options={BODY_TYPE_OPTIONS}
            selected={bodyType.value ?? 'male'}
            onSelected={(val: string) => bodyType.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Sprite scale</Box>
          <Slider
            minValue={minPct}
            maxValue={maxPct}
            step={1}
            value={bodySize.value ?? 100}
            onChange={(_e, val: number) => bodySize.setValue(val)}
            unit="%"
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'body_type',
  label: 'Body type',
  component: BodyTypeBody,
});
