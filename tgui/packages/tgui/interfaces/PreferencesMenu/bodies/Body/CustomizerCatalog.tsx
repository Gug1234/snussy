/**
 * @file bodies/Body/CustomizerCatalog.tsx
 * @description Body → Customizer Catalog row body.
 *
 * Phase 4 entry point. Renders one `<AccessoryPicker>` per manifest
 * sheet so the player can swap any registered customizer accessory
 * (horns / wings / tails / breasts / penis / testicles / etc.) without
 * leaving the prefs window. Selecting a tile dispatches
 * `act('pref_catalog_select', { choice_type, entry_key })` — the
 * server-side handler resolves entry_key → /datum/sprite_accessory
 * typepath (+ size for size-driven families) and commits via the same
 * `set_accessory_type` path the legacy popup used.
 *
 * The grid is intentionally dumb: each sheet's
 * `customizerChoiceType` from the manifest is the wire token; we never
 * type-check it client-side. Stale or hostile keys are rejected
 * server-side and silently no-op.
 *
 * Tinting: when a sheet declares
 * `allowsAccessoryColorCustomization`, the picker forwards the first
 * per-customizer color slot from `pref_catalog_colors` as a CSS
 * multiply tint over each sprite preview.
 *
 * Per-slot color editing: when the server reports a non-empty
 * `pref_catalog_colors[choice_type]`, a row of `<input type="color">`
 * swatches renders next to the picker. Each swatch maps to one of
 * the accessory's `color_keys` slots (1-based server-side); editing
 * a swatch dispatches
 * `act('pref_catalog_set_color', { choice_type, color_index, hex })`.
 */

import { useBackend } from 'tgui/backend';
import { Box, Section, Stack } from 'tgui-core/components';

import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { AccessoryPicker } from '../../widgets';

/** Fallback when a slot's color string is missing or malformed. */
const FALLBACK_COLOR = '#ffffff';

interface ColorSwatchRowProps {
  choiceType: string;
  colors: readonly string[];
  onChange: (index: number, hex: string) => void;
}

/**
 * Per-slot color input row. One `<input type="color">` per
 * `color_keys` slot. The browser handles the actual picker chrome;
 * we just forward the result. Color slots are 1-based on the DM side
 * — the conversion happens here so act payloads match the API.
 */
function ColorSwatchRow(props: ColorSwatchRowProps) {
  const { choiceType, colors, onChange } = props;
  if (!colors.length) {
    return null;
  }
  return (
    <Box mt={0.5} style={{ display: 'flex', gap: '0.25rem' }}>
      {colors.map((color, idx) => {
        const value = color || FALLBACK_COLOR;
        const slot = idx + 1;
        return (
          <input
            key={`${choiceType}-${slot}`}
            type="color"
            value={value}
            title={`Color slot ${slot}`}
            style={{
              width: '24px',
              height: '24px',
              padding: 0,
              border: '1px solid #444',
              background: 'transparent',
              cursor: 'pointer',
            }}
            onChange={(e) => onChange(slot, e.target.value)}
          />
        );
      })}
    </Box>
  );
}

function CustomizerCatalogBody() {
  const { act, data } = useBackend<PreferencesMenuData>();

  const manifest = data.pref_catalog_manifest;
  const selections = data.pref_catalog_selections ?? {};
  const colors = data.pref_catalog_colors ?? {};

  if (!manifest || !manifest.sheets) {
    return (
      <Section title="Customizer catalog">
        <Box color="label">
          The pref-catalog asset bundle hasn’t been baked yet. Run the
          “Materialize Pref Catalog” admin verb (or restart the round) to
          generate the thumbnail sheets, then reopen this menu.
        </Box>
      </Section>
    );
  }

  // Sort sheets by displayName so the picker order is deterministic
  // across server restarts. Falls back to the manifest key when the
  // sheet has no display name.
  const sheetNames = Object.keys(manifest.sheets).sort((a, b) => {
    const an = manifest.sheets![a].displayName ?? a;
    const bn = manifest.sheets![b].displayName ?? b;
    return an.localeCompare(bn);
  });

  return (
    <Stack vertical>
      {sheetNames.map((sheetName) => {
        const sheet = manifest.sheets![sheetName];
        const choiceType = sheet.customizerChoiceType ?? '';
        const selectedKey = choiceType
          ? (selections[choiceType] ?? null)
          : null;
        // Use the first color slot as the picker tint preview when
        // available; fall back to white (multiply no-op) otherwise.
        const choiceColors = choiceType ? (colors[choiceType] ?? []) : [];
        const sheetTint =
          sheet.allowsAccessoryColorCustomization && choiceColors.length
            ? choiceColors[0]
            : undefined;
        return (
          <Stack.Item key={sheetName}>
            <Section title={sheet.displayName ?? sheetName}>
              <AccessoryPicker
                manifest={manifest}
                sheetName={sheetName}
                selectedKey={selectedKey}
                tint={sheetTint}
                onSelect={(entryKey) => {
                  if (!choiceType) {
                    return;
                  }
                  act('pref_catalog_select', {
                    choice_type: choiceType,
                    entry_key: entryKey,
                  });
                }}
              />
              {choiceType && choiceColors.length > 0 && (
                <ColorSwatchRow
                  choiceType={choiceType}
                  colors={choiceColors}
                  onChange={(slot, hex) => {
                    act('pref_catalog_set_color', {
                      choice_type: choiceType,
                      color_index: slot,
                      hex,
                    });
                  }}
                />
              )}
            </Section>
          </Stack.Item>
        );
      })}
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'customizer_catalog',
  label: 'Customizer catalog',
  component: CustomizerCatalogBody,
});
