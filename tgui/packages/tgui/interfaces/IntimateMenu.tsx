import { Box, Button, LabeledList, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ── Types ────────────────────────────────────────────────────────────────────

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
  bead_depth: 'short' | 'medium' | 'long' | null;
  can_push_beads: boolean;
  can_pull_beads: boolean;
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

/** Human-readable label for the bead depth. */
const BEAD_DEPTH_LABEL: Record<string, string> = {
  short: 'Short (4 beads)',
  medium: 'Medium (5 beads)',
  long: 'Long (6 beads)',
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

          {item.has_socket && (
            <LabeledList.Item label="Socket">
              <ColorSwatch color={item.gem_color} round />
              {item.socket_desc ?? 'Unknown insert'}
            </LabeledList.Item>
          )}

          <LabeledList.Item label="Properties">
            {buildTags(item)}
          </LabeledList.Item>

          {/* Bead depth row + push/pull controls */}
          {item.is_beads && item.bead_depth && (
            <LabeledList.Item label="Depth">
              <Stack align="center" wrap>
                <Stack.Item>{BEAD_DEPTH_LABEL[item.bead_depth] ?? item.bead_depth}</Stack.Item>
                <Stack.Item>
                  <Button
                    color="good"
                    disabled={!item.can_push_beads}
                    tooltip={
                      !item.can_push_beads
                        ? 'Beads are already at maximum depth.'
                        : 'Push the beads in one step deeper.'
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
                    tooltip="Pull the beads out one step. At minimum depth they are removed entirely."
                    onClick={() => act('pull_beads', { ref: item.ref })}
                  >
                    Pull Out
                  </Button>
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
          )}
        </LabeledList>
      </Stack.Item>
    </Stack>
  );
};

