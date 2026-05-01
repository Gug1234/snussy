/**
 * @file bodies/Body/Genitals.tsx
 * @description Body → Genitals row body — inline toggle form (plan
 * addendum Turn 2, B7).
 *
 * Presence + simple scalar fields (size, functional, sheathed,
 * virility, lactating, fertility) for the four organ customizers
 * (penis / testicles / breasts / vagina) ride shadow prefs defined in
 * `modular/code/modules/client/prefs_categories/genital_toggles.dm`.
 * Variant/subtype selection (equine / knotted / etc.) lives under the
 * Intimacy → Accessories row; this body only covers presence + the
 * simple scalar fields the legacy HTML picker exposed inline.
 *
 * Availability: `data.genital_customizers_available[organ]` is the
 * server-side probe of `pref_species.customizers`. A species that
 * doesn't register a matching customizer hides the whole row; this is
 * the same gate the legacy HTML picker applies.
 */

import { useBackend } from 'tgui/backend';
import { Box, Button, Dropdown, Section, Stack } from 'tgui-core/components';

const Checkbox = Button.Checkbox;

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { AccessoryPicker } from '../../widgets';
import { usePrefField } from '../usePrefField';

type SizeOption = { id: number; label: string };

/**
 * Type picker bound to a single pref-catalog `customizer_choice` prefix.
 * Finds the matching manifest sheet (the manifest is keyed by a safe
 * encoding of the typepath, but each sheet exposes its real
 * `customizerChoiceType`), renders the AccessoryPicker, and dispatches
 * the existing `pref_catalog_select` envelope. Hidden when the manifest
 * is missing or no sheet matches the requested choice typepath — same
 * graceful fallback as the Customizer Catalog body.
 */
function TypePickerForChoice({ choiceTypePath }: { choiceTypePath: string }) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const manifest = data.pref_catalog_manifest;
  const selections = data.pref_catalog_selections ?? {};
  const colors = data.pref_catalog_colors ?? {};
  if (!manifest || !manifest.sheets) {
    return null;
  }
  const sheetName = Object.keys(manifest.sheets).find(
    (name) => manifest.sheets![name].customizerChoiceType === choiceTypePath,
  );
  if (!sheetName) {
    return null;
  }
  const selectedKey = selections[choiceTypePath] ?? null;
  const choiceColors = colors[choiceTypePath] ?? [];
  const tint =
    manifest.sheets![sheetName].allowsAccessoryColorCustomization &&
    choiceColors.length
      ? choiceColors[0]
      : undefined;
  return (
    <Box mt={0.5}>
      <Box mb={0.5}>Type</Box>
      <AccessoryPicker
        manifest={manifest}
        sheetName={sheetName}
        selectedKey={selectedKey}
        tint={tint}
        onSelect={(entryKey) =>
          act('pref_catalog_select', {
            choice_type: choiceTypePath,
            entry_key: entryKey,
          })
        }
      />
    </Box>
  );
}

function sizeDropdown(
  options: readonly SizeOption[],
  current: number,
  onPick: (value: number) => void,
) {
  if (!options || options.length === 0) {
    return (
      <Box italic color="label">
        No size options available.
      </Box>
    );
  }
  const labels = options.map((opt) => opt.label);
  const selectedOpt = options.find((opt) => opt.id === current);
  return (
    <Dropdown
      options={labels}
      selected={selectedOpt ? selectedOpt.label : labels[0]}
      onSelected={(label: string) => {
        const match = options.find((opt) => opt.label === label);
        if (match) {
          onPick(match.id);
        }
      }}
    />
  );
}

function GenitalsBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const available = data.genital_customizers_available ?? {
    penis: 0,
    testicles: 0,
    breasts: 0,
    vagina: 0,
  };

  // Presence toggles.
  const penisEnabled = usePrefField<number>(
    PREF_KEYS.GENITAL_PENIS_ENABLED,
    0,
    { autosave: true },
  );
  const testiclesEnabled = usePrefField<number>(
    PREF_KEYS.GENITAL_TESTICLES_ENABLED,
    0,
    { autosave: true },
  );
  const breastsEnabled = usePrefField<number>(
    PREF_KEYS.GENITAL_BREASTS_ENABLED,
    0,
    { autosave: true },
  );
  const vaginaEnabled = usePrefField<number>(
    PREF_KEYS.GENITAL_VAGINA_ENABLED,
    0,
    { autosave: true },
  );

  // Penis sub-options.
  const penisSize = usePrefField<number>(PREF_KEYS.GENITAL_PENIS_SIZE, 2, {
    autosave: true,
  });
  const penisFunctional = usePrefField<number>(
    PREF_KEYS.GENITAL_PENIS_FUNCTIONAL,
    1,
    { autosave: true },
  );
  const penisSheathed = usePrefField<number>(
    PREF_KEYS.GENITAL_PENIS_SHEATHED,
    1,
    { autosave: true },
  );

  // Testicles sub-options.
  const testiclesSize = usePrefField<number>(
    PREF_KEYS.GENITAL_TESTICLES_SIZE,
    2,
    { autosave: true },
  );
  const testiclesVirility = usePrefField<number>(
    PREF_KEYS.GENITAL_TESTICLES_VIRILITY,
    1,
    { autosave: true },
  );

  // Breasts sub-options.
  const breastsSize = usePrefField<number>(PREF_KEYS.GENITAL_BREASTS_SIZE, 3, {
    autosave: true,
  });
  const breastsLactating = usePrefField<number>(
    PREF_KEYS.GENITAL_BREASTS_LACTATING,
    0,
    { autosave: true },
  );

  // Vagina sub-options.
  const vaginaFertility = usePrefField<number>(
    PREF_KEYS.GENITAL_VAGINA_FERTILITY,
    1,
    { autosave: true },
  );

  const penisSizes = data.named_penis_sizes ?? [];
  const ballSizes = data.named_ball_sizes ?? [];
  const breastSizes = data.named_breast_sizes ?? [];

  const toBool = (v: number | undefined) => !!v && v !== 0;

  return (
    <Stack vertical>
      {available.penis ? (
        <Stack.Item>
          <Section title="Penis">
            <Stack vertical>
              <Stack.Item>
                <Checkbox
                  checked={toBool(penisEnabled.value)}
                  onClick={() =>
                    penisEnabled.setValue(toBool(penisEnabled.value) ? 0 : 1)
                  }
                >
                  Present
                </Checkbox>
              </Stack.Item>
              {toBool(penisEnabled.value) && (
                <>
                  <Stack.Item>
                    <Box mb={0.5}>Size</Box>
                    {sizeDropdown(penisSizes, penisSize.value ?? 2, (v) =>
                      penisSize.setValue(v),
                    )}
                  </Stack.Item>
                  <Stack.Item>
                    <TypePickerForChoice choiceTypePath="/datum/customizer_choice/organ/penis" />
                  </Stack.Item>
                  <Stack.Item>
                    <Checkbox
                      checked={toBool(penisFunctional.value)}
                      onClick={() =>
                        penisFunctional.setValue(
                          toBool(penisFunctional.value) ? 0 : 1,
                        )
                      }
                    >
                      Functional
                    </Checkbox>
                  </Stack.Item>
                  <Stack.Item>
                    <Checkbox
                      checked={toBool(penisSheathed.value)}
                      onClick={() =>
                        penisSheathed.setValue(
                          toBool(penisSheathed.value) ? 0 : 1,
                        )
                      }
                    >
                      Sheathed / slit morphology
                    </Checkbox>
                  </Stack.Item>
                </>
              )}
            </Stack>
          </Section>
        </Stack.Item>
      ) : null}

      {available.testicles ? (
        <Stack.Item>
          <Section title="Testicles">
            <Stack vertical>
              <Stack.Item>
                <Checkbox
                  checked={toBool(testiclesEnabled.value)}
                  onClick={() =>
                    testiclesEnabled.setValue(
                      toBool(testiclesEnabled.value) ? 0 : 1,
                    )
                  }
                >
                  Present
                </Checkbox>
              </Stack.Item>
              {toBool(testiclesEnabled.value) && (
                <>
                  <Stack.Item>
                    <Box mb={0.5}>Size</Box>
                    {sizeDropdown(ballSizes, testiclesSize.value ?? 2, (v) =>
                      testiclesSize.setValue(v),
                    )}
                  </Stack.Item>
                  <Stack.Item>
                    <TypePickerForChoice choiceTypePath="/datum/customizer_choice/organ/testicles" />
                  </Stack.Item>
                  <Stack.Item>
                    <Checkbox
                      checked={toBool(testiclesVirility.value)}
                      onClick={() =>
                        testiclesVirility.setValue(
                          toBool(testiclesVirility.value) ? 0 : 1,
                        )
                      }
                    >
                      Virile
                    </Checkbox>
                  </Stack.Item>
                </>
              )}
            </Stack>
          </Section>
        </Stack.Item>
      ) : null}

      {available.breasts ? (
        <Stack.Item>
          <Section title="Breasts">
            <Stack vertical>
              <Stack.Item>
                <Checkbox
                  checked={toBool(breastsEnabled.value)}
                  onClick={() =>
                    breastsEnabled.setValue(
                      toBool(breastsEnabled.value) ? 0 : 1,
                    )
                  }
                >
                  Present
                </Checkbox>
              </Stack.Item>
              {toBool(breastsEnabled.value) && (
                <>
                  <Stack.Item>
                    <Box mb={0.5}>Size</Box>
                    {sizeDropdown(breastSizes, breastsSize.value ?? 3, (v) =>
                      breastsSize.setValue(v),
                    )}
                  </Stack.Item>
                  <Stack.Item>
                    <TypePickerForChoice choiceTypePath="/datum/customizer_choice/organ/breasts" />
                  </Stack.Item>
                  <Stack.Item>
                    <Checkbox
                      checked={toBool(breastsLactating.value)}
                      onClick={() =>
                        breastsLactating.setValue(
                          toBool(breastsLactating.value) ? 0 : 1,
                        )
                      }
                    >
                      Lactating
                    </Checkbox>
                  </Stack.Item>
                </>
              )}
            </Stack>
          </Section>
        </Stack.Item>
      ) : null}

      {available.vagina ? (
        <Stack.Item>
          <Section title="Vagina">
            <Stack vertical>
              <Stack.Item>
                <Checkbox
                  checked={toBool(vaginaEnabled.value)}
                  onClick={() =>
                    vaginaEnabled.setValue(toBool(vaginaEnabled.value) ? 0 : 1)
                  }
                >
                  Present
                </Checkbox>
              </Stack.Item>
              {toBool(vaginaEnabled.value) && (
                <Stack.Item>
                  <Checkbox
                    checked={toBool(vaginaFertility.value)}
                    onClick={() =>
                      vaginaFertility.setValue(
                        toBool(vaginaFertility.value) ? 0 : 1,
                      )
                    }
                  >
                    Fertile
                  </Checkbox>
                </Stack.Item>
              )}
            </Stack>
          </Section>
        </Stack.Item>
      ) : null}
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'genitals',
  label: 'Genitals',
  component: GenitalsBody,
});
