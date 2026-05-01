/**
 * @file bodies/ClassStats/Loadout.tsx
 * @description Class & Stats → Loadout row body — inline picker
 * (plan addendum Turn 4 — C6).
 *
 * Replaces the earlier singleton-handshake stub with an inline
 * 10-slot grid and a filterable catalogue grouped by category.
 * Per-slot name/desc/hex overrides still live in the classic
 * LoadoutMenu window (Classic Editor button retained) — this turn
 * only owns slot assignment and clearing.
 *
 * Wire contract (server: modular/code/modules/client/prefs_categories/loadout.dm):
 *   set_loadout_slot     {slot: 1..10, path: "/datum/loadout_item/..." | null}
 *   clear_loadout_slot   {slot: 1..10}
 *
 * Server performs duplicate detection, donator gate, and point-budget
 * enforcement. Client only filters and renders disabled state; the
 * triumph-cost display uses loadout_points_total / loadout_points_spent
 * emitted in ui_data.
 */

import { useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { useDirtyLedger } from '../../DirtyLedger';
import { registerPrefsBody } from '../../MiddleColumn';
import type {
  LoadoutCatalogRow,
  LoadoutSlot,
  PreferencesMenuData,
} from '../../types';

function LoadoutBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const ledger = useDirtyLedger();
  // Loadout slot writes go through dedicated set_loadout_slot /
  // clear_loadout_slot envelopes (collection mutations, not setter
  // dispatch). Stage a sentinel ledger entry on every successful
  // dispatch so the Save / Discard buttons reflect the unsaved state.
  // The server's act_set_loadout_slot mirrors this with a `loadout`
  // entry in dirty_keys so prefs_persist_dirty fires on flush.
  const markDirty = (): void => {
    ledger.stage('__persist_only__', Date.now(), { autosave: false });
  };
  const catalog: readonly LoadoutCatalogRow[] = data.loadout_catalog ?? [];
  const slots: readonly LoadoutSlot[] = data.loadout_slots ?? [];
  const pointsTotal = data.loadout_points_total ?? 0;
  const pointsSpent = data.loadout_points_spent ?? 0;
  const pointsRemaining = pointsTotal - pointsSpent;
  const triumphs = data.triumphs_available ?? 0;

  const [filter, setFilter] = useState('');
  const [selectedSlot, setSelectedSlot] = useState<number>(1);

  const firstEmptySlot = slots.find((s) => !s.item_id)?.slot ?? null;
  const targetSlot = selectedSlot || firstEmptySlot || 1;

  // Bucket catalogue rows by category and apply filter in one pass.
  const filterLc = filter.trim().toLowerCase();
  const grouped = new Map<string, LoadoutCatalogRow[]>();
  for (const row of catalog) {
    if (
      filterLc &&
      !row.name.toLowerCase().includes(filterLc) &&
      !row.desc.toLowerCase().includes(filterLc)
    ) {
      continue;
    }
    const bucket = grouped.get(row.category) ?? [];
    bucket.push(row);
    grouped.set(row.category, bucket);
  }
  const categoryNames = Array.from(grouped.keys()).sort();

  return (
    <Section
      title="Loadout"
      buttons={
        <Button
          icon="suitcase"
          tooltip="Classic editor — per-slot name/desc/hex overrides"
          onClick={() =>
            act('launch_singleton', {
              editor: 'loadout',
              return_category: PREFS_CATEGORIES.CLASS_STATS,
              return_row: 'loadout',
            })
          }
        >
          Classic Editor
        </Button>
      }
    >
      <Stack vertical>
        <Stack.Item>
          <Box>
            <b>Points:</b> {pointsRemaining} / {pointsTotal} remaining
            {pointsSpent > 0 && <> ({pointsSpent} spent)</>}
            {'   '}
            <Box as="span" color="label">
              Triumphs: {triumphs}
            </Box>
          </Box>
        </Stack.Item>

        <Stack.Item>
          <Section title="Slots" fitted>
            <Stack vertical>
              {slots.map((s) => {
                const isTarget = targetSlot === s.slot;
                return (
                  <Stack.Item key={s.slot}>
                    <Button
                      selected={isTarget}
                      onClick={() => setSelectedSlot(s.slot)}
                      width="3em"
                    >
                      {s.slot}
                    </Button>
                    {'  '}
                    {s.item_id ? (
                      <>
                        <Box as="span">{s.name ?? '(unnamed)'}</Box>
                        {s.triumph_cost > 0 && (
                          <Box as="span" color="label">
                            {'  '}[{s.triumph_cost} pts]
                          </Box>
                        )}
                        {'  '}
                        <Button
                          color="bad"
                          icon="times"
                          onClick={() => {
                            act('clear_loadout_slot', { slot: s.slot });
                            markDirty();
                          }}
                        >
                          Clear
                        </Button>
                      </>
                    ) : (
                      <Box as="span" color="label" italic>
                        (empty)
                      </Box>
                    )}
                  </Stack.Item>
                );
              })}
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Input
            placeholder="Filter catalogue…"
            value={filter}
            onChange={setFilter}
            fluid
          />
        </Stack.Item>

        <Stack.Item>
          <Box mb={0.5} color="label">
            Clicking an item assigns it to slot <b>{targetSlot}</b> (select a
            slot above to change target). Server enforces duplicate and
            point-budget checks.
          </Box>
        </Stack.Item>

        {categoryNames.map((cat) => {
          const rows = grouped.get(cat) ?? [];
          return (
            <Stack.Item key={cat}>
              <Collapsible title={`${cat} (${rows.length})`}>
                <Stack vertical>
                  {rows.map((row) => {
                    const locked = row.accessible === 0;
                    const overBudget =
                      row.triumph_cost > 0 &&
                      row.triumph_cost > pointsRemaining;
                    return (
                      <Stack.Item key={row.id}>
                        <Button
                          disabled={locked}
                          color={overBudget ? 'bad' : undefined}
                          tooltip={
                            locked
                              ? 'Donator-locked'
                              : overBudget
                                ? 'Not enough points (server will reject)'
                                : row.desc || row.name
                          }
                          onClick={() => {
                            act('set_loadout_slot', {
                              slot: targetSlot,
                              path: row.id,
                            });
                            markDirty();
                          }}
                        >
                          {row.name}
                          {row.triumph_cost > 0 && (
                            <Box as="span" color="label">
                              {'  '}[{row.triumph_cost}]
                            </Box>
                          )}
                          {row.donator_locked === 1 && (
                            <Box as="span" color="label">
                              {'  '}(donator)
                            </Box>
                          )}
                        </Button>
                      </Stack.Item>
                    );
                  })}
                </Stack>
              </Collapsible>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.CLASS_STATS,
  id: 'loadout',
  label: 'Loadout',
  component: LoadoutBody,
});
