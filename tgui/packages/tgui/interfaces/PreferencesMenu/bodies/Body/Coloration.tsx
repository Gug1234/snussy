/**
 * @file bodies/Body/Coloration.tsx
 * @description Body → Coloration row body.
 *
 * Skin tone (enum) + eye colour only. Hair and facial-hair colours
 * moved to Hair.tsx and detail colour moved to Head.tsx per B3/B4/B5
 * deviations so each colour lives next to the row that owns its asset.
 */

import { useBackend } from 'tgui/backend';
import { Box, Button, Section, Stack } from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData, PrefsOption } from '../../types';
import { usePrefField } from '../usePrefField';

const FALLBACK_COLOR = '#ffffff';

function normalizeColor(
  value: string | null | undefined,
  fallback = FALLBACK_COLOR,
) {
  if (!value) {
    return fallback;
  }
  let color = String(value).trim();
  if (!color.startsWith('#')) {
    color = `#${color}`;
  }
  const shortMatch = color.match(/^#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$/);
  if (shortMatch) {
    color = `#${shortMatch[1]}${shortMatch[1]}${shortMatch[2]}${shortMatch[2]}${shortMatch[3]}${shortMatch[3]}`;
  }
  if (!/^#[0-9a-fA-F]{6}$/.test(color)) {
    return fallback;
  }
  return color.toUpperCase();
}

interface ColorInputRowProps {
  label: string;
  value: string | null | undefined;
  fallback?: string;
  onChange: (value: string) => void;
}

function ColorInputRow(props: ColorInputRowProps) {
  const color = normalizeColor(props.value, props.fallback ?? FALLBACK_COLOR);
  return (
    <Stack align="center">
      <Stack.Item width="150px">{props.label}</Stack.Item>
      <Stack.Item>
        <input
          type="color"
          value={color}
          title={props.label}
          style={{
            width: '32px',
            height: '24px',
            padding: 0,
            border: '1px solid #444',
            background: 'transparent',
            cursor: 'pointer',
          }}
          onChange={(event) => props.onChange(event.target.value)}
        />
      </Stack.Item>
      <Stack.Item>
        <Box color="label">{color}</Box>
      </Stack.Item>
    </Stack>
  );
}

function ColorationBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const skinOptions: readonly PrefsOption[] = data.skin_tone_options ?? [];
  const skinTone = usePrefField<string>(
    PREF_KEYS.SKIN_TONE,
    skinOptions[0]?.id ?? '',
  );
  const eyeColor = usePrefField<string>(PREF_KEYS.EYE_COLOR, '#000000', {
    autosave: true,
  });
  // Addendum Turn 4 B3 — heterochromia + second eye colour.
  // Gated on data.eye_heterochromia_allowed, a species-level probe. Some
  // eye customizers (e.g. moth compound eyes) opt out of heterochromia
  // via allows_heterochromia=FALSE on their customizer_choice; server
  // setters reject the write there anyway but hiding the row avoids
  // misleading UI.
  const heterochromiaAllowed = data.eye_heterochromia_allowed === 1;
  const heterochromia = usePrefField<number>(
    PREF_KEYS.HETEROCHROMIA_ENABLED,
    0,
  );
  const secondEyeColor = usePrefField<string>(
    PREF_KEYS.SECOND_EYE_COLOR,
    '#111111',
    { autosave: true },
  );
  const mcolor1 = usePrefField<string>(PREF_KEYS.MUTANT_COLOR_1, '#FFFFFF', {
    autosave: true,
  });
  const mcolor2 = usePrefField<string>(PREF_KEYS.MUTANT_COLOR_2, '#FFFFFF', {
    autosave: true,
  });
  const mcolor3 = usePrefField<string>(PREF_KEYS.MUTANT_COLOR_3, '#FFFFFF', {
    autosave: true,
  });
  const showSkinTones = data.skin_tone_enabled === 1 && skinOptions.length > 0;
  const showMutantColors =
    data.mutant_color_enabled === 1 ||
    data.mutant_color_partsonly_enabled === 1;
  const selectedSkin = normalizeColor(skinTone.value, skinOptions[0]?.color);

  return (
    <Section title="Coloration">
      <Stack vertical>
        {showSkinTones && (
          <Stack.Item>
            <Box mb={0.5}>{data.skin_tone_label ?? 'Skin tone'}</Box>
            <Stack wrap align="center">
              {skinOptions.map((option) => {
                const optionColor = normalizeColor(option.color ?? option.id);
                const selected = selectedSkin === optionColor;
                return (
                  <Stack.Item key={`${option.label}-${option.id}`}>
                    <Button
                      selected={selected}
                      tooltip={option.label}
                      onClick={() => skinTone.setValue(option.id)}
                    >
                      <Stack align="center">
                        <Stack.Item>
                          <Box
                            inline
                            style={{
                              display: 'inline-block',
                              width: '18px',
                              height: '18px',
                              border: '1px solid #444',
                              backgroundColor: optionColor,
                            }}
                          />
                        </Stack.Item>
                        <Stack.Item>{option.label}</Stack.Item>
                      </Stack>
                    </Button>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Stack.Item>
        )}
        {showMutantColors && (
          <Stack.Item>
            <Stack vertical>
              <Stack.Item>
                <ColorInputRow
                  label="Mutant color 1"
                  value={mcolor1.value}
                  onChange={(value) => mcolor1.setValue(value)}
                />
              </Stack.Item>
              <Stack.Item>
                <ColorInputRow
                  label="Mutant color 2"
                  value={mcolor2.value}
                  onChange={(value) => mcolor2.setValue(value)}
                />
              </Stack.Item>
              <Stack.Item>
                <ColorInputRow
                  label="Mutant color 3"
                  value={mcolor3.value}
                  onChange={(value) => mcolor3.setValue(value)}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        )}
        <Stack.Item>
          <ColorInputRow
            label="Eye colour"
            value={eyeColor.value ?? '#000000'}
            fallback="#000000"
            onChange={(value) => eyeColor.setValue(value)}
          />
        </Stack.Item>
        {heterochromiaAllowed && (
          <>
            <Stack.Item>
              <Button.Checkbox
                checked={heterochromia.value === 1}
                onClick={() =>
                  heterochromia.setValue(heterochromia.value === 1 ? 0 : 1)
                }
              >
                Heterochromia
              </Button.Checkbox>
            </Stack.Item>
            {heterochromia.value === 1 && (
              <Stack.Item>
                <ColorInputRow
                  label="Second eye colour"
                  value={secondEyeColor.value ?? '#111111'}
                  fallback="#111111"
                  onChange={(value) => secondEyeColor.setValue(value)}
                />
              </Stack.Item>
            )}
          </>
        )}
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'coloration',
  label: 'Coloration',
  component: ColorationBody,
});
