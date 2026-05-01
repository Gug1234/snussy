/**
 * @file bodies/Identity/Origin.tsx
 * @description Identity → Origin row body.
 *
 * Renders the Ratwood origin map (existing `rwmap1.png`) with a
 * clickable region per `/datum/origin` from server static data.
 * Selecting a region stages a single `set_pref('origin', typepath)`
 * write — the server's `set_pref_origin` setter resolves the
 * typepath to the canonical /datum/origin instance.
 */

import { Box, Input, Section } from 'tgui-core/components';

import { resolveAsset } from '../../../../assets';
import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { OriginMap } from '../../widgets';
import { usePrefField } from '../usePrefField';

// Source dimensions of the existing rwmap1.png map (see
// modular/origins/origins.dm:build_origin_map_html).
const MAP_SOURCE_W = 550;
const MAP_SOURCE_H = 400;
// Pin hit-rect; the map data only emits a center point, so we expand
// each point into a small clickable square centered on (x, y).
const PIN_HIT_PX = 22;

function OriginBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const origin = usePrefField<string>(PREF_KEYS.ORIGIN, '');
  const accent = usePrefField<string>(PREF_KEYS.CHAR_ACCENT, 'No accent', {
    autosave: true,
  });
  const regions = data.origin_regions ?? [];

  const overlay = regions.map((r) => ({
    id: r.id,
    label: r.label,
    rect: {
      x: r.x - PIN_HIT_PX / 2,
      y: r.y - PIN_HIT_PX / 2,
      w: PIN_HIT_PX,
      h: PIN_HIT_PX,
    },
  }));

  // The map asset is shipped via the existing browse_rsc path
  // (`html/rwmap1.png`); resolveAsset will pass the bare name through
  // when no explicit asset mapping has been registered.
  const mapUrl = resolveAsset('rwmap1.png');

  return (
    <Section title="Origin">
      <OriginMap
        imageUrl={mapUrl}
        sourceWidth={MAP_SOURCE_W}
        sourceHeight={MAP_SOURCE_H}
        regions={overlay}
        selected={origin.value ?? null}
        onSelect={(id: string) => origin.setValue(id)}
      />
      <Box mt={1}>
        Selected: {regions.find((r) => r.id === origin.value)?.label ?? 'None'}
      </Box>
      <Box mt={1.5} mb={0.5}>
        Accent
      </Box>
      <Input
        fluid
        value={accent.value ?? 'No accent'}
        onChange={(val: string) => accent.setValue(val)}
      />
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'origin',
  label: 'Origin',
  component: OriginBody,
});
