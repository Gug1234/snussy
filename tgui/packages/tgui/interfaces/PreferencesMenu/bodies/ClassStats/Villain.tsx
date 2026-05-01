/**
 * @file bodies/ClassStats/Villain.tsx
 * @description Class & Stats → Villain row body (Addendum Turn 3 C2).
 *
 * Inline antagonist-role grid. Renders one checkbox per ROLE_* in
 * GLOB.special_roles_rogue. Banned rows disable the checkbox and show
 * a red "BANNED" pill; a syndicate-wide jobban paints all rows as
 * banned (matching the legacy HTML wipe at preferences.dm:992).
 *
 * Dispatch: `act('set_villain_role', { role, enabled })`. Rate-limited
 * and re-validated server-side against GLOB.special_roles_rogue +
 * is_banned_from.
 *
 * Data source: `villain_role_options` (static) + `villain_roles_enabled`
 * (dynamic). Legacy launcher retained as a secondary entry point.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';

function VillainBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const options = data.villain_role_options ?? [];
  const enabled = data.villain_roles_enabled ?? [];
  const enabledSet = new Set(enabled);

  if (!options.length) {
    return (
      <Section title="Villain">
        <Box mb={1}>Loading antagonist roster…</Box>
        <Button
          icon="skull"
          onClick={() =>
            act('launch_singleton', {
              editor: 'villain_prefs',
              return_category: PREFS_CATEGORIES.CLASS_STATS,
              return_row: 'villain',
            })
          }
        >
          Open Classic Picker
        </Button>
      </Section>
    );
  }

  // All-rows-banned implies either a syndicate-wide jobban or a server
  // without any enabled antag roles. Either way, show the banner.
  const allBanned = options.every((r) => r.banned);

  return (
    <Section
      title="Villain"
      buttons={
        <Button
          icon="skull"
          tooltip="Open legacy HTML picker"
          onClick={() =>
            act('launch_singleton', {
              editor: 'villain_prefs',
              return_category: PREFS_CATEGORIES.CLASS_STATS,
              return_row: 'villain',
            })
          }
        >
          Classic
        </Button>
      }
    >
      <Stack vertical>
        {allBanned && (
          <Stack.Item>
            <Box
              p={1}
              style={{
                background: '#3a0000',
                color: '#ff6060',
                border: '1px solid #800',
                fontWeight: 'bold',
              }}
            >
              You are banned from antagonist roles.
            </Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Box
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
              gap: 4,
            }}
          >
            {options.map((role) => {
              const on = enabledSet.has(role.id);
              const selectable = !role.banned && role.selectable !== 0;
              return (
                <Button
                  key={role.id}
                  disabled={!selectable}
                  selected={on}
                  icon={on ? 'check-square' : 'square'}
                  onClick={() =>
                    act('set_villain_role', {
                      role: role.id,
                      enabled: on ? 0 : 1,
                    })
                  }
                >
                  {role.label}
                  {!!role.banned && (
                    <Box inline color="bad" ml={1}>
                      [BANNED]
                    </Box>
                  )}
                  {!role.banned && role.unavailable_reason ? (
                    <Box inline color="bad" ml={1}>
                      [{role.unavailable_reason}]
                    </Box>
                  ) : null}
                </Button>
              );
            })}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.CLASS_STATS,
  id: 'villain',
  label: 'Villain',
  component: VillainBody,
});
