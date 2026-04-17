/**
 * @file ExtremeOffsetReview.tsx
 * @description Phase 5 admin review panel for players flagged by the
 * extreme-offset round-join vetting pipeline.
 *
 * View-only — not an approval gate. The left column is a scrollable list of
 * pending/past tickets (metadata only); the right column shows the currently
 * selected ticket in full with a single-direction naked render the admin can
 * cycle between the dirs flagged on that character.
 *
 * The render is a base64 PNG from getFlatIcon at 32x32 native; CSS
 * transform: scale() + image-rendering: pixelated upscales it client-side
 * while preserving pixel-perfect edges. getFlatIcon does NOT bake scale or
 * matrix transforms, so the admin sees offsets but not the player's scale
 * value — the numeric scale is shown in the flagged-entries table instead.
 */

import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

type DirStr = 'north' | 'south' | 'east' | 'west';

type TicketSummary = {
  ckey: string;
  flagged_count: number;
  aggregate: BooleanLike;
  acknowledged: BooleanLike;
  status: 'pending' | 'dismissed' | 'noted' | 'reverted';
  note_present: BooleanLike;
  created_at: number;
};

type FlaggedEntry = {
  customizer_type: string;
  accessory_type: string;
  pixel_x: number;
  pixel_y: number;
  scale: number;
  flags: number;
  flagged_dirs: number;
};

type SelectedTicket = {
  ckey: string;
  character_slot: number;
  aggregate_used: number;
  aggregate_exceeded: BooleanLike;
  acknowledged: BooleanLike;
  created_at: number;
  status: 'pending' | 'dismissed' | 'noted' | 'reverted';
  note: string;
  flagged_entries: FlaggedEntry[];
  visible_dirs: DirStr[];
  selected_dir: DirStr;
  render_b64: string;
  subject_alive: BooleanLike;
  subject_connected: BooleanLike;
};

type BackendData = {
  tickets: TicketSummary[];
  selected: SelectedTicket | null;
  now: number;
  aggregate_budget: number;
};

const PREVIEW_SCALE = 2;

const STATUS_COLOR: Record<TicketSummary['status'], string> = {
  pending: 'orange',
  dismissed: 'gray',
  noted: 'blue',
  reverted: 'green',
};

const DIR_LABEL: Record<DirStr, string> = {
  north: 'N',
  south: 'S',
  east: 'E',
  west: 'W',
};

function formatAgo(now: number, then: number): string {
  // world.time is in deciseconds.
  const ds = Math.max(0, now - then);
  const minutes = Math.floor(ds / 600);
  if (minutes < 1) {
    return 'just now';
  }
  if (minutes < 60) {
    return `${minutes}m ago`;
  }
  const hours = Math.floor(minutes / 60);
  return `${hours}h${minutes % 60}m ago`;
}

export const ExtremeOffsetReview = () => {
  const { data } = useBackend<BackendData>();
  const { tickets, selected, now } = data;

  return (
    <Window title="Extreme Offset Review" width={820} height={640}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="30%">
            <TicketList tickets={tickets} now={now} selectedCkey={selected?.ckey} />
          </Stack.Item>
          <Stack.Item grow>
            {selected ? (
              <SelectedPanel ticket={selected} now={now} budget={data.aggregate_budget} />
            ) : (
              <Section fill title="Selected Ticket">
                <NoticeBox>Select a ticket from the left panel.</NoticeBox>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const TicketList = (props: {
  tickets: TicketSummary[];
  now: number;
  selectedCkey: string | undefined;
}) => {
  const { act } = useBackend<BackendData>();
  const { tickets, now, selectedCkey } = props;
  return (
    <Section fill scrollable title={`Pending Reviews (${tickets.length})`}>
      {!tickets.length && (
        <NoticeBox>No extreme-offset flags this round.</NoticeBox>
      )}
      {tickets.map((t) => {
        const isSel = t.ckey === selectedCkey;
        return (
          <Button
            key={t.ckey}
            fluid
            color={isSel ? 'good' : STATUS_COLOR[t.status]}
            onClick={() => act('select_ticket', { ckey: t.ckey })}
            style={{ marginBottom: '4px' }}
          >
            <Box bold>{t.ckey}</Box>
            <Box fontSize="0.85em">
              {t.flagged_count} entr{t.flagged_count === 1 ? 'y' : 'ies'}
              {' · '}
              {t.status}
              {t.aggregate ? ' · AGG' : ''}
              {t.acknowledged ? ' · ack' : ''}
              {t.note_present ? ' · note' : ''}
            </Box>
            <Box fontSize="0.75em" color="label">
              {formatAgo(now, t.created_at)}
            </Box>
          </Button>
        );
      })}
    </Section>
  );
};

const SelectedPanel = (props: {
  ticket: SelectedTicket;
  now: number;
  budget: number;
}) => {
  const { act } = useBackend<BackendData>();
  const { ticket, now, budget } = props;
  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title={`Ticket: ${ticket.ckey}`}>
          <LabeledList>
            <LabeledList.Item label="Status">{ticket.status}</LabeledList.Item>
            <LabeledList.Item label="Acknowledged">
              {ticket.acknowledged ? 'YES' : 'NO'}
            </LabeledList.Item>
            <LabeledList.Item label="Aggregate">
              {ticket.aggregate_used} / {budget}
              {ticket.aggregate_exceeded ? ' (EXCEEDED)' : ''}
            </LabeledList.Item>
            <LabeledList.Item label="Slot">{ticket.character_slot}</LabeledList.Item>
            <LabeledList.Item label="Flagged">
              {formatAgo(now, ticket.created_at)}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Preview (naked, no-scale)">
          <Stack>
            <Stack.Item>
              <PreviewBox ticket={ticket} />
            </Stack.Item>
            <Stack.Item grow>
              <Box mb={1}>
                Direction:
                <Box inline ml={1}>
                  {(['south', 'north', 'east', 'west'] as DirStr[]).map((d) => {
                    const enabled = ticket.visible_dirs.includes(d);
                    const isSel = ticket.selected_dir === d;
                    return (
                      <Button
                        key={d}
                        disabled={!enabled}
                        selected={isSel}
                        onClick={() => act('cycle_dir', { dir: d })}
                      >
                        {DIR_LABEL[d]}
                      </Button>
                    );
                  })}
                </Box>
              </Box>
              <Box color="label" fontSize="0.85em">
                getFlatIcon bakes pixel_x/pixel_y but NOT scale. The render
                above is rotation/scale-free; see the table below for the
                player&apos;s raw scale value.
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section fill scrollable title="Flagged Entries">
          <FlaggedTable entries={ticket.flagged_entries} />
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Note">
          <TextArea
            height="4em"
            value={ticket.note}
            onChange={(v) => act('note', { text: v })}
          />
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Actions">
          <Button
            icon="comment"
            disabled={!ticket.subject_connected}
            onClick={() => act('pm')}
          >
            PM
          </Button>
          <Button
            icon="life-ring"
            disabled={!ticket.subject_connected}
            onClick={() => act('ahelp')}
          >
            Ahelp (bwoink)
          </Button>
          <Button
            icon="street-view"
            disabled={!ticket.subject_alive}
            onClick={() => act('follow')}
          >
            Follow
          </Button>
          <Button
            color="bad"
            icon="times"
            onClick={() => act('dismiss')}
          >
            Dismiss
          </Button>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const PreviewBox = (props: { ticket: SelectedTicket }) => {
  const { ticket } = props;
  const containerSize = 32 * PREVIEW_SCALE;
  return (
    <Box
      style={{
        width: `${containerSize}px`,
        height: `${containerSize}px`,
        border: '1px dashed #666',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      {ticket.render_b64 ? (
        <img
          src={`data:image/png;base64,${ticket.render_b64}`}
          alt=""
          style={{
            width: '32px',
            height: '32px',
            transform: `scale(${PREVIEW_SCALE})`,
            transformOrigin: 'top left',
            imageRendering: 'pixelated',
            display: 'block',
          }}
        />
      ) : (
        <Box color="bad" p={1} fontSize="0.8em">
          No render
        </Box>
      )}
    </Box>
  );
};

const FlaggedTable = (props: { entries: FlaggedEntry[] }) => {
  const { act } = useBackend<BackendData>();
  const { entries } = props;
  if (!entries.length) {
    return <NoticeBox>Snapshot has no flagged entries.</NoticeBox>;
  }
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Customizer</Table.Cell>
        <Table.Cell>Accessory</Table.Cell>
        <Table.Cell>pixel</Table.Cell>
        <Table.Cell>scale</Table.Cell>
        <Table.Cell>flags</Table.Cell>
        <Table.Cell>dirs</Table.Cell>
        <Table.Cell>action</Table.Cell>
      </Table.Row>
      {entries.map((e) => (
        <Table.Row key={e.customizer_type}>
          <Table.Cell>{e.customizer_type}</Table.Cell>
          <Table.Cell>{e.accessory_type}</Table.Cell>
          <Table.Cell>
            ({e.pixel_x}, {e.pixel_y})
          </Table.Cell>
          <Table.Cell>{e.scale}</Table.Cell>
          <Table.Cell>0x{e.flags.toString(16)}</Table.Cell>
          <Table.Cell>{e.flagged_dirs}</Table.Cell>
          <Table.Cell>
            <Button
              color="bad"
              icon="undo"
              tooltip="Reset this entry's pixel_x/y/scale to 0/0/1"
              onClick={() =>
                act('revert_entry', { customizer_type: e.customizer_type })
              }
            >
              Revert
            </Button>
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};
