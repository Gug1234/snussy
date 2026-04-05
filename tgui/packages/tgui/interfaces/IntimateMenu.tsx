import { Box, Button, LabeledList, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ── Types ────────────────────────────────────────────────────────────────────

/** A slot the jelly can be repositioned into. */
type SwapOption = {
  slot: number;
  name: string;
};

/** Detailed data for a visible worn accessory (absent when slot is empty/concealed). */
type ItemData = {
  ref: string;
  name: string;
  metal: string;
  metal_color: string;
  has_socket: boolean;
  socket_desc: string | null;
  gem_color: string;
  is_insertable: boolean;
  is_piercing: boolean;
  is_beriddled: boolean;
  is_silver: boolean;
  can_remove: boolean;
  is_beads: boolean;
  beads_inserted: number;
  max_beads: number;
  can_push_beads: boolean;
  can_pull_beads: boolean;
  can_ripcord_beads: boolean;
  // ── Eora jelly fields ──────────────────────────────────────────────────
  is_eora_jelly: boolean;
  is_strange_jelly: boolean;
  current_slot: number;
  current_slot_name: string;
  is_internal_slot: boolean;
  swap_slot_options: SwapOption[];
  can_stimulate: boolean;
  can_eat_cum: boolean;
  // Strange-only fields (zero/false/null when not a strange jelly)
  need_level: number;
  max_need_level: number;
  need_state: string | null;
  neglect_level: number;
  max_neglect_level: number;
  neglect_state: string | null;
  bond_escalation_level: number;
  max_bond_escalation_level: number;
  bond_state: string | null;
  bond_progress: number;
  bond_progress_threshold: number;
  obsession_level: number;
  has_bonded_wearer: boolean;
  bonded_wearer_name: string | null;
  custom_jelly_name: string | null;
  is_cocooned: boolean;
  is_bonded_wearer: boolean;
  can_soothe: boolean;
  can_tend: boolean;
};

/** One inventory slot, always present in the data even when empty. */
type SlotEntry = {
  slot: number;
  slot_name: string;
  occupied: boolean;
  concealed: boolean;
  item: ItemData | null;
};

type Data = {
  invalid?: boolean;
  wearer_name: string;
  is_self: boolean;
  /** Mirrors the wearer's `intimate_visual_widgets` pref. Reserved for future paper-doll imagery. */
  show_visual_widgets: boolean;
  slots: SlotEntry[];
};

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Small inline colour swatch, used for metal and socket colours. */
const ColorSwatch = (props: { color: string; round?: boolean }) => (
  <Box
    inline
    style={{
      display: 'inline-block',
      width: '0.65em',
      height: '0.65em',
      background: props.color,
      border: '1px solid rgba(255,255,255,0.22)',
      borderRadius: props.round ? '50%' : '2px',
      marginRight: '0.35em',
      verticalAlign: 'middle',
    }}
  />
);

/** Comma-separated property tags for an item. */
function buildTags(item: ItemData): string {
  const tags: string[] = [];
  if (item.is_insertable) tags.push('Insertable');
  if (item.is_piercing) tags.push('Piercing');
  if (item.is_beriddled) tags.push('Beriddled');
  if (item.is_silver) tags.push('Silver');
  return tags.join(', ') || '—';
}

/** Human-readable label for the bead set size. */
const BEAD_SET_LABEL: Record<number, string> = {
  4: 'Short set',
  5: 'Medium set',
  6: 'Long set',
};

// ── Root component ────────────────────────────────────────────────────────────

export const IntimateMenu = () => {
  const { data } = useBackend<Data>();

  if (data.invalid) {
    return (
      <Window width={420} height={180} title="Intimate Accessories">
        <Window.Content>
          <NoticeBox danger>This panel is no longer available.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const title = data.is_self
    ? 'My Intimate Accessories'
    : `${data.wearer_name}'s Intimate Accessories`;

  return (
    <Window width={520} height={580} title={title}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {data.slots?.map((slot) => (
            <Stack.Item key={slot.slot}>
              <SlotCard slot={slot} />
            </Stack.Item>
          ))}
        </Stack>
      </Window.Content>
    </Window>
  );
};

// ── Slot card ─────────────────────────────────────────────────────────────────

/** Renders one inventory slot with its appropriate state (empty / concealed / occupied). */
const SlotCard = (props: { slot: SlotEntry }) => {
  const { slot } = props;

  // Empty slot — dim placeholder
  if (!slot.occupied) {
    return (
      <Section
        title={slot.slot_name}
        style={{ opacity: 0.45 }}
      >
        <Box italic color="label">
          Empty
        </Box>
      </Section>
    );
  }

  // Occupied but hidden by clothing
  if (slot.concealed) {
    return (
      <Section title={slot.slot_name}>
        <Box color="average" italic>
          ◈ Concealed — clothing is covering this slot.
        </Box>
      </Section>
    );
  }

  // Fully visible item
  return (
    <Section title={slot.slot_name}>
      <ItemCard item={slot.item!} />
    </Section>
  );
};

// ── Mini progress bar ────────────────────────────────────────────────────────

/**
 * Thin inline progress bar built from plain Box elements.
 * `value` and `max` map to [0, max]; `color` is a CSS colour string.
 */
const MiniBar = (props: {
  value: number;
  max: number;
  color: string;
  label: string;
  sublabel?: string;
}) => {
  const { value, max, color, label, sublabel } = props;
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0;
  return (
    <Box mb={0.5}>
      <Stack align="center">
        <Stack.Item width={7}>
          <Box color="label" fontSize="0.8em">
            {label}
          </Box>
        </Stack.Item>
        <Stack.Item grow>
          {/* Track */}
          <Box
            style={{
              position: 'relative',
              height: '0.6em',
              background: 'rgba(255,255,255,0.12)',
              borderRadius: '3px',
              overflow: 'hidden',
            }}
          >
            {/* Fill */}
            <Box
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                height: '100%',
                width: `${pct}%`,
                background: color,
                borderRadius: '3px',
                transition: 'width 0.3s ease',
              }}
            />
          </Box>
        </Stack.Item>
        <Stack.Item width={4} style={{ textAlign: 'right' }}>
          <Box color="label" fontSize="0.8em">
            {value}/{max}
            {sublabel ? ` — ${sublabel}` : ''}
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

// ── Jelly panel ───────────────────────────────────────────────────────────────

/** Bond escalation colour coding (0–4 scale). */
const ESCALATION_COLOR: Record<number, string> = {
  0: '#aaaaaa',
  1: '#88cc88',
  2: '#ddcc55',
  3: '#dd7722',
  4: '#cc3333',
};

/**
 * Expanded interaction panel rendered inside ItemCard when the accessory is an
 * Eora Jelly. Shows need / neglect bars for strange jellies, slot-swap buttons,
 * and command buttons (Eat, Stimulate, Soothe / Tend).
 */
const JellyPanel = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  const escalationColor = ESCALATION_COLOR[item.bond_escalation_level] ?? '#aaaaaa';

  return (
    <Box mt={1}>
      <Section title="Jelly Controls" style={{ borderTop: '1px solid rgba(255,255,255,0.15)' }}>
        <Stack vertical>

          {/* ── Strange-jelly identity & status ── */}
          {!!item.is_strange_jelly && (
            <Stack.Item>
              {/* ── Name & rename ── */}
              <Box mb={0.5}>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold fontSize="0.9em" color={escalationColor}>
                      {item.custom_jelly_name ?? item.name}
                    </Box>
                  </Stack.Item>
                  {!!item.is_bonded_wearer && (
                    <Stack.Item>
                      <Button
                        color="transparent"
                        tooltip="Give this jelly a name."
                        onClick={() => act('jelly_rename', { ref: item.ref })}
                      >
                        ✎ Rename
                      </Button>
                    </Stack.Item>
                  )}
                </Stack>
              </Box>

              <Box bold mb={0.5} color="label" fontSize="0.85em">
                Status
              </Box>
              <MiniBar
                value={item.need_level}
                max={item.max_need_level}
                color="#7799dd"
                label="Need"
                sublabel={item.need_state ?? undefined}
              />
              <MiniBar
                value={item.neglect_level}
                max={item.max_neglect_level}
                color="#cc6666"
                label="Neglect"
                sublabel={item.neglect_state ?? undefined}
              />
              {/* ── Bond level bar ── */}
              <MiniBar
                value={item.bond_escalation_level}
                max={item.max_bond_escalation_level || 4}
                color={escalationColor}
                label="Bond"
                sublabel={item.bond_state ?? undefined}
              />
              {item.bond_escalation_level < (item.max_bond_escalation_level || 4) &&
                item.bond_progress_threshold > 0 && (
                <Box mt={0.25} fontSize="0.75em" color="label">
                  Progress: {item.bond_progress} / {item.bond_progress_threshold}
                </Box>
              )}
              {item.obsession_level > 0 && (
                <Box mt={0.25} fontSize="0.8em" color="average">
                  Obsession level: {item.obsession_level}
                </Box>
              )}
              {/* Bonded wearer info */}
              {!!item.has_bonded_wearer && (
                <Box mt={0.5} color="label" fontSize="0.8em">
                  Bonded to:{' '}
                  <Box inline color="good">
                    {item.bonded_wearer_name ?? 'Unknown'}
                  </Box>
                </Box>
              )}
              {!!item.is_cocooned && (
                <Box mt={0.5} color="bad" italic fontSize="0.85em">
                  ⚠ Wearer is currently cocooned.
                </Box>
              )}
            </Stack.Item>
          )}

          {/* ── Slot position ── */}
          {item.swap_slot_options?.length > 0 && (
            <Stack.Item mt={item.is_strange_jelly ? 1 : 0}>
              <Box bold mb={0.5} color="label" fontSize="0.85em">
                Position — currently in{' '}
                <Box inline color="good">
                  {item.current_slot_name}
                </Box>
              </Box>
              <Stack wrap>
                {item.swap_slot_options.map((opt) => (
                  <Stack.Item key={opt.slot}>
                    <Button
                      color="transparent"
                      tooltip={`Move the jelly to the ${opt.name} slot.`}
                      onClick={() =>
                        act('jelly_swap_slot', { ref: item.ref, slot: opt.slot })
                      }
                    >
                      → {opt.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>
          )}

          {/* ── Commands ── */}
          <Stack.Item mt={1}>
            <Box bold mb={0.5} color="label" fontSize="0.85em">
              Commands
            </Box>
            <Stack wrap>
              {/* Stimulate — all eora jellies */}
              <Stack.Item>
                <Button
                  color="good"
                  disabled={!item.can_stimulate}
                  tooltip={
                    item.can_stimulate
                      ? 'Command the jelly to apply a stimulation burst.'
                      : 'The jelly needs a moment to settle.'
                  }
                  onClick={() => act('jelly_stimulate', { ref: item.ref })}
                >
                  Stimulate
                </Button>
              </Stack.Item>
              {/* Eat cum — only when in an internal slot */}
              {!!item.can_eat_cum && (
                <Stack.Item>
                  <Button
                    color="average"
                    tooltip="Command the jelly to eagerly consume retained internal fluids."
                    onClick={() => act('jelly_eat_cum', { ref: item.ref })}
                  >
                    Consume Fluids
                  </Button>
                </Stack.Item>
              )}
              {/* Soothe — bonded wearer only */}
              {!!item.is_strange_jelly && !!item.can_soothe && (
                <Stack.Item>
                  <Button
                    color="pink"
                    tooltip="Attend to the jelly, reducing its need and neglect."
                    onClick={() => act('jelly_soothe', { ref: item.ref })}
                  >
                    Soothe
                  </Button>
                </Stack.Item>
              )}
              {/* Tend / Comfort — adjacent non-bonded observer */}
              {!!item.is_strange_jelly && !!item.can_tend && (
                <Stack.Item>
                  <Button
                    color="blue"
                    tooltip="Gently comfort this jelly, partially easing its needs."
                    onClick={() => act('jelly_comfort', { ref: item.ref })}
                  >
                    Tend Jelly
                  </Button>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>

        </Stack>
      </Section>
    </Box>
  );
};

// ── Item card ─────────────────────────────────────────────────────────────────

/** Renders the detail view and action buttons for a visible worn accessory. */
const ItemCard = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  return (
    <Stack vertical>
      {/* Name row */}
      <Stack.Item>
        <Stack align="center">
          <Stack.Item grow>
            <Box bold>
              <ColorSwatch color={item.metal_color} />
              {item.name}
            </Box>
          </Stack.Item>
          {/* Remove button — always shown but disabled when access is blocked */}
          <Stack.Item>
            <Button
              color="bad"
              disabled={!item.can_remove}
              tooltip={!item.can_remove ? 'Cannot access this accessory right now.' : undefined}
              onClick={() => act('remove_accessory', { ref: item.ref })}
            >
              Remove
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Details */}
      <Stack.Item>
        <LabeledList>
          <LabeledList.Item label="Material">
            <ColorSwatch color={item.metal_color} />
            {item.metal}
          </LabeledList.Item>

          {!!item.has_socket && (
            <LabeledList.Item label="Socket">
              <ColorSwatch color={item.gem_color} round />
              {item.socket_desc ?? 'Unknown insert'}
            </LabeledList.Item>
          )}

          <LabeledList.Item label="Properties">
            {buildTags(item)}
          </LabeledList.Item>

          {/* Bead insertion counter + push/pull controls */}
          {!!item.is_beads && item.max_beads > 0 && (
            <LabeledList.Item label="Beads">
              <Stack align="center" wrap>
                <Stack.Item>
                  {item.beads_inserted} / {item.max_beads} inserted ({BEAD_SET_LABEL[item.max_beads] ?? `${item.max_beads} beads`})
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="good"
                    disabled={!item.can_push_beads}
                    tooltip={
                      !item.can_push_beads
                        ? 'All beads are already inserted.'
                        : 'Push one more bead in.'
                    }
                    onClick={() => act('push_beads', { ref: item.ref })}
                  >
                    Push In
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="average"
                    disabled={!item.can_pull_beads}
                    tooltip="Pull one bead out. At the last bead, removes them entirely."
                    onClick={() => act('pull_beads', { ref: item.ref })}
                  >
                    Pull Out
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="bad"
                    disabled={!item.can_ripcord_beads}
                    tooltip="Yank all beads out at once. On strong intent, this is violent."
                    onClick={() => act('ripcord_beads', { ref: item.ref })}
                  >
                    Ripcord
                  </Button>
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
          )}
        </LabeledList>
      </Stack.Item>

      {/* Jelly-specific controls rendered below the standard property list */}
      {!!item.is_eora_jelly && (
        <Stack.Item>
          <JellyPanel item={item} />
        </Stack.Item>
      )}
    </Stack>
  );
};

