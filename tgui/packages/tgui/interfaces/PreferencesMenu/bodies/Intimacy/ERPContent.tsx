/**
 * @file bodies/Intimacy/ERPContent.tsx
 * @description ERP-gated content row. Server-side `build_prefs_snapshot`
 * is the source of truth for whether the underlying pref keys are
 * exposed to this client; this row reads them through the snapshot like
 * any other body. When the keys are absent (extreme_erp disabled
 * server-wide or per-account), the inputs render in a disabled state
 * with an explanatory notice.
 *
 * Step 14 ships the row as ERP-toggle UI only — the actual ERP toggles
 * still flow through the legacy ooc-prefs window. This row exists as a
 * stable mount point so Step 17 can move the toggles in without
 * reshuffling the row order again.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

function ERPContentBody() {
  const cursed = usePrefField<boolean>(PREF_KEYS.CURSED_ENABLED, false);
  const extreme = usePrefField<boolean>(PREF_KEYS.EXTREME_ERP, false);
  const edging = usePrefField<boolean>(PREF_KEYS.EDGING, false);
  const intimate = usePrefField<boolean>(PREF_KEYS.INTIMATE_ENABLED, false);
  const reactions = usePrefField<boolean>(PREF_KEYS.INTIMATE_REACTION, false);
  const showExamine = usePrefField<boolean>(
    PREF_KEYS.SHOW_INTIMATE_EXAMINE,
    false,
  );
  const jelly = usePrefField<boolean>(PREF_KEYS.JELLY_ENABLED, false);

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="ERP content opt-ins">
          <Box mb={0.5} color="label">
            These toggles gate other Intimacy rows. Leave them off to hide
            ERP-related rows entirely.
          </Box>
          <Stack vertical>
            <Stack.Item>
              <Button.Checkbox
                checked={!!cursed.value}
                onClick={() => cursed.setValue(!cursed.value)}
              >
                Cursed collars &amp; chastity devices
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!intimate.value}
                onClick={() => intimate.setValue(!intimate.value)}
              >
                Intimate accessories (piercings, plugs, …)
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!reactions.value}
                onClick={() => reactions.setValue(!reactions.value)}
              >
                Intimate reaction text (flavor, exposure, sex actions)
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!showExamine.value}
                onClick={() => showExamine.setValue(!showExamine.value)}
              >
                Show intimate accessories on examine
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!extreme.value}
                onClick={() => extreme.setValue(!extreme.value)}
              >
                Extreme ERP content
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!edging.value}
                onClick={() => edging.setValue(!edging.value)}
              >
                Edging / stamina gameplay
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!!jelly.value}
                onClick={() => jelly.setValue(!jelly.value)}
              >
                Jelly controller roles
              </Button.Checkbox>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.INTIMACY,
  id: 'erp_content',
  label: 'ERP Content',
  component: ERPContentBody,
});
