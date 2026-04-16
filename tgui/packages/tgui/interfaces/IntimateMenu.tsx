import { useState } from 'react';
import { Box, Button, Dropdown, LabeledList, NoticeBox, Section, Stack, Tooltip } from 'tgui-core/components';

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
  stimulate_cooldown: number;
  can_eat_cum: boolean;
  // Strange-only fields (zero/false/null when not a strange jelly)
  need_level: number;
  max_need_level: number;
  need_state: string | null;
  jealousy_level: number;
  max_jealousy_level: number;
  jealousy_state: string | null;
  resentment_level: number;
  max_resentment_level: number;
  resentment_state: string | null;
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
  cocoon_stage: number;
  cocoon_stage_name: string | null;
  cocoon_tick_count: number;
  cocoon_next_stage_ticks: number;
  cocoon_tick_interval: number;
  is_bonded_wearer: boolean;
  can_soothe: boolean;
  can_tend: boolean;
  // Mood log (strange-only)
  mood_log: MoodLogEntry[];
  // Doppelganger state
  has_doppelganger: boolean;
  doppel_is_player_controlled: boolean;
  can_project_doppel: boolean;
  has_bound_controller: boolean;
  bound_controller_name: string | null;
  controller_applications_open: boolean;
  pending_controller_application_count: number;
  controller_state: string | null;
  controller_state_name: string | null;
  controller_speech_enabled: boolean;
  controller_emote_enabled: boolean;
  controller_manifest_enabled: boolean;
  controller_direct_control_enabled: boolean;
  controller_force_enabled: boolean;
  is_controller_viewer: boolean;
  controller_view_mode: string | null;
  controller_wearer_ready: boolean;
  controller_wearer_status: string | null;
  controller_pending_requests: ControllerRequest[];
  controller_can_speak: boolean;
  controller_can_emote: boolean;
  controller_can_preset_action: boolean;
  controller_can_manifest: boolean;
  controller_can_stimulate: boolean;
  controller_stimulate_cooldown: number;
  controller_can_reposition: boolean;
  controller_can_force: boolean;
  controller_can_return: boolean;
  controller_can_cocoon_command: boolean;
  controller_can_cocoon_tighten: boolean;
  controller_can_cocoon_tendril: boolean;
  controller_can_start_cocoon: boolean;
  controller_cocoon_stage: number;
  controller_cocoon_stage_name: string;
  controller_cocoon_tick_count: number;
  controller_cocoon_next_stage_ticks: number;
  controller_cocoon_tick_interval: number;
  controller_emotion_blocks_speech: boolean;
  controller_emotion_needs_force: boolean;
  controller_emotion_needs_jealousy: boolean;
  controller_preset_actions: string[];
  controller_force_emote_options: Record<string, string>;
  controller_wearer_voice_presets: string[];
  controller_force_posture_options: string[];
  // Activity history
  controller_activity_log: ControllerActivityEntry[];
  // Invitations
  controller_pending_invitations: ControllerInvitation[];
  // Transfer trauma
  transfer_traumatized: boolean;
  // Feeding
  feeding_satiation: number;
  sated_reward_tier: number;
  // Rivalry
  has_rival: boolean;
  rival_name: string | null;
  // Player command state
  can_command_tendril: boolean;
  can_review_controller_volunteers: boolean;
  can_toggle_controller_applications: boolean;
  can_manage_bound_controller: boolean;
  can_invite_controller: boolean;
  can_request_cocoon: boolean;
  tendril_command_ready: boolean;
  provoke_ready: boolean;
};

/** A single entry in the jelly's mood log. */
type MoodLogEntry = {
  time: string;
  type: string;
  msg: string;
};

type ControllerRequest = {
  id: number;
  type: string;
  summary: string;
  expires_in: string;
};

/** A single entry in the controller relationship activity history. */
type ControllerActivityEntry = {
  time: string;
  actor: string;
  event: string;
  summary: string;
  severity: string;
};

/** A pending wearer-to-candidate invitation. */
type ControllerInvitation = {
  id: number;
  candidate_ckey: string;
  candidate_name: string;
  expires_in: string;
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
  tooltip?: string;
}) => {
  const { value, max, color, label, sublabel, tooltip } = props;
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0;
  const bar = (
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
  if (tooltip) {
    return <Tooltip content={tooltip}>{bar}</Tooltip>;
  }
  return bar;
};

/** Colour mapping for mood log event types. */
const LOG_TYPE_COLOR: Record<string, string> = {
  feeding: '#7799dd',
  jealousy: '#cc6666',
  resentment: '#9966cc',
  bond: '#66cc77',
  rivalry: '#cc6666',
  transfer: '#cc8833',
  cocoon: '#ccaa44',
  need: '#7799dd',
};

/** Wearer-facing cocoon stage descriptions. */
const WEARER_COCOON_STAGE_DESCRIPTIONS: Record<number, string> = {
  0: 'The cocoon wraps gently around you, exploring and settling in.',
  1: 'A steady rhythm builds. The cocoon pulses insistently.',
  2: 'The cocoon grips tightly. You can feel your stamina draining.',
  3: 'Total domination. You feel drowsy and utterly consumed.',
};

/** Collapsible mood log showing recent emotional events. */
const MoodLog = (props: { entries: MoodLogEntry[] }) => {
  const [expanded, setExpanded] = useState(false);
  const { entries } = props;
  // Show last 5 when collapsed, all when expanded.
  const visible = expanded ? entries : entries.slice(-5);

  return (
    <Section
      title={
        <Box
          inline
          style={{ cursor: 'pointer' }}
          onClick={() => setExpanded(!expanded)}
        >
          Mood Log {expanded ? '▾' : '▸'}
          <Box inline color="label" ml={1} fontSize="0.8em">
            ({entries.length} events)
          </Box>
        </Box>
      }
      style={{ borderTop: '1px solid rgba(255,255,255,0.1)' }}
    >
      <Box style={{ maxHeight: expanded ? '200px' : '120px', overflowY: 'auto' }}>
        {visible.map((entry, i) => (
          <Box
            key={i}
            fontSize="0.78em"
            mb={0.15}
            style={{ lineHeight: '1.3' }}
          >
            <Box inline color="label" mr={0.5}>
              [{entry.time}]
            </Box>
            <Box inline color={LOG_TYPE_COLOR[entry.type] ?? '#aaaaaa'} bold mr={0.5}>
              {entry.type}
            </Box>
            <Box inline color="white">
              {entry.msg}
            </Box>
          </Box>
        ))}
      </Box>
      {!expanded && entries.length > 5 && (
        <Box
          fontSize="0.75em"
          color="label"
          italic
          mt={0.3}
          style={{ cursor: 'pointer' }}
          onClick={() => setExpanded(true)}
        >
          ...{entries.length - 5} older events — click to expand
        </Box>
      )}
    </Section>
  );
};

// ── Controller activity log ───────────────────────────────────────────────────

/** Colour mapping for activity log actor sides. */
const ACTIVITY_ACTOR_COLOR: Record<string, string> = {
  wearer: '#88bbee',
  controller: '#cc88dd',
  admin: '#ee9944',
  system: '#aaaaaa',
};

/** Colour mapping for activity log severity. */
const ACTIVITY_SEVERITY_COLOR: Record<string, string> = {
  normal: '#cccccc',
  important: '#eebb44',
  warning: '#dd6655',
};

/** Collapsible activity log showing the shared controller relationship history. */
const ControllerActivityLog = (props: { entries: ControllerActivityEntry[] }) => {
  const [expanded, setExpanded] = useState(false);
  const { entries } = props;
  const visible = expanded ? entries : entries.slice(-5);

  return (
    <Section
      title={
        <Box
          inline
          style={{ cursor: 'pointer' }}
          onClick={() => setExpanded(!expanded)}
        >
          Activity History {expanded ? '▾' : '▸'}
          <Box inline color="label" ml={1} fontSize="0.8em">
            ({entries.length} events)
          </Box>
        </Box>
      }
      style={{ borderTop: '1px solid rgba(255,255,255,0.1)' }}
    >
      <Box style={{ maxHeight: expanded ? '200px' : '120px', overflowY: 'auto' }}>
        {visible.map((entry, i) => (
          <Box
            key={i}
            fontSize="0.78em"
            mb={0.15}
            style={{ lineHeight: '1.3' }}
          >
            <Box inline color="label" mr={0.5}>
              [{entry.time}]
            </Box>
            <Box inline color={ACTIVITY_ACTOR_COLOR[entry.actor] ?? '#aaaaaa'} bold mr={0.5}>
              {entry.actor}
            </Box>
            <Box inline color={ACTIVITY_SEVERITY_COLOR[entry.severity] ?? '#cccccc'}>
              {entry.summary}
            </Box>
          </Box>
        ))}
      </Box>
      {!expanded && entries.length > 5 && (
        <Box
          fontSize="0.75em"
          color="label"
          italic
          mt={0.3}
          style={{ cursor: 'pointer' }}
          onClick={() => setExpanded(true)}
        >
          ...{entries.length - 5} older events — click to expand
        </Box>
      )}
    </Section>
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

const TENDRIL_ACTION_LABELS: Record<string, string> = {
  multi: 'Any / Multi',
  anal: 'Anal',
  throat: 'Throat',
  through: 'Through',
  ear: 'Ear',
  asphyxiation: 'Asphyxiation',
  sounding: 'Sounding',
};

const TENDRIL_ACTION_OPTIONS = Object.values(TENDRIL_ACTION_LABELS);

const JellyIndicators = (props: { item: ItemData }) => {
  const { item } = props;

  return (
    <Stack.Item mt={0.5}>
      {!!item.has_doppelganger && (
        <Box
          fontSize="0.8em"
          color={item.doppel_is_player_controlled ? 'good' : 'average'}
          italic
        >
          ◆ Slime-born shape is manifest
          {item.doppel_is_player_controlled ? ' and inhabited.' : '.'}
        </Box>
      )}
      {!!item.has_bound_controller && (
        <Box fontSize="0.8em" color="good" italic>
          ◆ Bound inhabitant: {item.bound_controller_name ?? 'Unknown'}
        </Box>
      )}
      {!!item.has_bound_controller && (
        <Box fontSize="0.8em" color="label" italic>
          ◆ Inhabitant state: {item.controller_state_name ?? 'Unknown'}
        </Box>
      )}
      {!!item.has_bound_controller && (
        <Box
          fontSize="0.8em"
          color={item.controller_direct_control_enabled ? 'bad' : 'good'}
          italic
        >
          ◆ Approval wards: {item.controller_direct_control_enabled ? 'Lowered by host' : 'Host approval required'}
        </Box>
      )}
      {!!item.has_bound_controller && (
        <Box fontSize="0.8em" color="label">
          Inhabitant permissions:
          <Box inline ml={0.5} color={item.controller_speech_enabled ? 'good' : 'bad'}>
            speech {item.controller_speech_enabled ? 'on' : 'off'}
          </Box>
          <Box inline ml={0.5} color={item.controller_emote_enabled ? 'good' : 'bad'}>
            emotes {item.controller_emote_enabled ? 'on' : 'off'}
          </Box>
          <Box inline ml={0.5} color={item.controller_manifest_enabled ? 'good' : 'bad'}>
            manifest {item.controller_manifest_enabled ? 'on' : 'off'}
          </Box>
        </Box>
      )}
      {!item.has_bound_controller && item.is_bonded_wearer && (
        <Box
          fontSize="0.8em"
          color={item.controller_applications_open ? 'good' : 'average'}
          italic
        >
          ◆ Petitions: {item.controller_applications_open ? 'Open' : 'Sealed'}
          {` (${item.pending_controller_application_count ?? 0} pending)`}
        </Box>
      )}
      {!!item.transfer_traumatized && (
        <Box fontSize="0.8em" color="bad" italic>
          ◆ Transfer trauma active — wrong wearer!
        </Box>
      )}
      {!!item.has_rival && (
        <Box fontSize="0.8em" color="#cc6666" italic>
          ◆ Rival fixation: {item.rival_name ?? 'Unknown'}
        </Box>
      )}
      {item.feeding_satiation > 0 && (
        <Box fontSize="0.8em" color="label">
          Lifetime satiation: {item.feeding_satiation}
          {item.sated_reward_tier > 0 && (
            <Box inline color="#66cc77" ml={0.5}>
              (reward tier {item.sated_reward_tier})
            </Box>
          )}
        </Box>
      )}
    </Stack.Item>
  );
};

const JellyControllerControls = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  if (!item.is_strange_jelly || !item.can_manage_bound_controller) {
    return null;
  }

  return (
    <>
      <Stack.Item>
        <Stack align="center">
          <Stack.Item>
            <Button
              color={item.controller_speech_enabled ? 'average' : 'good'}
              tooltip={item.controller_speech_enabled ? 'Seal the ooze against the inhabitant\'s voice.' : 'Unseal the ooze so the inhabitant may speak again.'}
              onClick={() =>
                act('jelly_toggle_controller_permission', {
                  ref: item.ref,
                  permission: 'speech',
                  enabled: item.controller_speech_enabled ? 0 : 1,
                })
              }
            >
              {item.controller_speech_enabled ? 'Mute Speech' : 'Allow Speech'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color={item.controller_emote_enabled ? 'average' : 'good'}
              tooltip={item.controller_emote_enabled ? 'Seal the ooze against the inhabitant\'s gestures.' : 'Unseal the ooze so the inhabitant may emote again.'}
              onClick={() =>
                act('jelly_toggle_controller_permission', {
                  ref: item.ref,
                  permission: 'emote',
                  enabled: item.controller_emote_enabled ? 0 : 1,
                })
              }
            >
              {item.controller_emote_enabled ? 'Mute Emotes' : 'Allow Emotes'}
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center">
          <Stack.Item>
            <Button
              color={item.controller_manifest_enabled ? 'average' : 'good'}
              tooltip={item.controller_manifest_enabled ? 'Forbid the inhabitant from taking shape outside the ooze.' : 'Allow the inhabitant to take shape outside the ooze again.'}
              onClick={() =>
                act('jelly_toggle_controller_permission', {
                  ref: item.ref,
                  permission: 'manifest',
                  enabled: item.controller_manifest_enabled ? 0 : 1,
                })
              }
            >
              {item.controller_manifest_enabled ? 'Block Manifest' : 'Allow Manifest'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color={item.controller_direct_control_enabled ? 'bad' : 'good'}
              tooltip={
                item.controller_direct_control_enabled
                  ? 'Raise the ward again — the inhabitant must petition before acting.'
                  : 'Lower the ward — let the inhabitant act upon you without asking.'
              }
              onClick={() =>
                act('jelly_toggle_controller_direct_control', {
                  ref: item.ref,
                  enabled: item.controller_direct_control_enabled ? 0 : 1,
                })
              }
            >
              {item.controller_direct_control_enabled ? 'Require Approval' : 'Allow Direct Control'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color={item.controller_force_enabled ? 'bad' : 'good'}
              tooltip={
                item.controller_force_enabled
                  ? 'Revoke the inhabitant\'s power to puppet your voice and body.'
                  : 'Yield to the ooze — let its inhabitant force words and gestures from your flesh.'
              }
              onClick={() =>
                act('jelly_toggle_controller_force', {
                  ref: item.ref,
                  enabled: item.controller_force_enabled ? 0 : 1,
                })
              }
            >
              {item.controller_force_enabled ? 'Block Forcing' : 'Allow Forcing'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              color="bad"
              tooltip="Banish the inhabitant from the ooze."
              onClick={() => act('jelly_dismiss_controller', { ref: item.ref })}
            >
              Banish Inhabitant
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </>
  );
};

const JellyControllerPanel = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  if (!item.is_strange_jelly || !item.is_controller_viewer) {
    return null;
  }

  const defaultPreset = item.controller_preset_actions?.[0] ?? '';
  const [selectedPreset, setSelectedPreset] = useState(defaultPreset);
  const activePreset = item.controller_preset_actions?.includes(selectedPreset)
    ? selectedPreset
    : defaultPreset;
  const repositionOptions = item.swap_slot_options ?? [];
  const defaultReposition = repositionOptions[0]?.name ?? '';
  const [selectedReposition, setSelectedReposition] = useState(defaultReposition);
  const activeReposition = repositionOptions.find((option) => option.name === selectedReposition)
    ?? repositionOptions[0];

  return (
    <Stack.Item mt={1}>
      <Box bold mb={0.5} color="label" fontSize="0.85em">
        Communion Interface
      </Box>
      <Box fontSize="0.8em" color="label" mb={0.4}>
        Mode:{' '}
        <Box inline color="good">
          {item.controller_view_mode === 'doppel'
            ? 'Borrowed flesh'
            : item.controller_view_mode === 'shell'
              ? 'Within the ooze'
              : 'Unavailable'}
        </Box>
      </Box>
      {!!item.controller_state_name && (
        <Box fontSize="0.8em" color="label" mb={0.4}>
          State:{' '}
          <Box inline color={item.controller_state === 'suspended' ? 'average' : 'good'}>
            {item.controller_state_name}
          </Box>
        </Box>
      )}
      {!!item.controller_wearer_status && (
        <NoticeBox danger={!item.controller_wearer_ready}>
          {item.controller_wearer_status}
        </NoticeBox>
      )}
      {item.controller_view_mode === 'shell' && (
        <NoticeBox>
          {item.controller_direct_control_enabled
            ? 'The host has lowered the ward. The ooze answers your will without question.'
            : 'The host\'s ward holds firm. You must petition before acting upon their flesh.'}
        </NoticeBox>
      )}
      <Stack wrap mt={0.4}>
        {item.controller_view_mode === 'shell' && (
          <>
            <Stack.Item>
              <Button
                color="good"
                disabled={!item.controller_can_speak}
                tooltip={
                  item.controller_can_speak
                    ? 'Speak through the ooze from within its core.'
                    : item.controller_emotion_blocks_speech
                      ? 'The ooze writhes with resentment and refuses to carry words.'
                      : 'Speech is sealed while the bond wavers or the host forbids it.'
                }
                onClick={() => act('jelly_controller_speak', { ref: item.ref })}
              >
                Speak
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="teal"
                disabled={!item.controller_can_speak}
                tooltip={
                  item.controller_can_speak
                    ? 'Murmur privately through the ooze — only the host will feel it.'
                    : item.controller_emotion_blocks_speech
                      ? 'The ooze writhes with resentment and refuses to carry words.'
                      : 'Speech is sealed while the bond wavers or the host forbids it.'
                }
                onClick={() => act('jelly_controller_whisper', { ref: item.ref })}
              >
                Whisper
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="average"
                disabled={!item.controller_can_emote}
                tooltip={
                  item.controller_can_emote
                    ? 'Will a gesture through the ooze from within its core.'
                    : item.controller_emotion_blocks_speech
                      ? 'The ooze writhes with resentment and refuses to convey your will.'
                      : 'Gestures are sealed while the bond wavers or the host forbids it.'
                }
                onClick={() => act('jelly_controller_emote', { ref: item.ref })}
              >
                Emote
              </Button>
            </Stack.Item>
            {!!item.controller_preset_actions?.length && (
              <Stack.Item>
                <Stack align="center">
                  <Stack.Item grow>
                    <Dropdown
                      width="170px"
                      selected={activePreset || 'Preset Action'}
                      options={item.controller_preset_actions}
                      onSelected={(label: string) => setSelectedPreset(label)}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="blue"
                      disabled={!item.controller_can_preset_action || !activePreset}
                      tooltip={
                        item.controller_can_preset_action
                          ? 'Stir the ooze into a preset gesture.'
                          : item.controller_emotion_blocks_speech
                            ? 'The ooze writhes with resentment and refuses preset stirrings.'
                            : 'Preset stirrings are sealed while the bond wavers or the host forbids it.'
                      }
                      onClick={() =>
                        act('jelly_controller_preset', {
                          ref: item.ref,
                          preset_action: activePreset,
                        })
                      }
                    >
                      Send Preset
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            )}
            <Stack.Item>
              <Button
                color="purple"
                disabled={!item.controller_can_manifest}
                tooltip={
                  item.controller_can_manifest
                    ? item.controller_direct_control_enabled
                      ? 'Pour yourself into borrowed flesh at once.'
                      : 'Petition the host to let you take shape.'
                    : 'Taking shape is sealed while the bond wavers or the host forbids it.'
                }
                onClick={() => act('jelly_controller_manifest', { ref: item.ref })}
              >
                {item.controller_direct_control_enabled ? 'Take Shape' : 'Request Shape'}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="orange"
                disabled={!item.controller_can_stimulate || !!item.controller_stimulate_cooldown}
                tooltip={
                  !item.controller_can_stimulate
                    ? item.controller_emotion_needs_force
                      ? 'The ooze is too sated to allow stimulation. Its hunger must grow first.'
                      : 'Stimulation is sealed while the bond wavers.'
                    : item.controller_stimulate_cooldown
                      ? `Building pressure\u2026 ${item.controller_stimulate_cooldown}s`
                      : item.controller_direct_control_enabled
                        ? 'Drive the ooze into a pulse of raw stimulation.'
                        : 'Petition the host to let the ooze stimulate them.'
                }
                onClick={() => act('jelly_controller_stimulate', { ref: item.ref })}
              >
                {item.controller_stimulate_cooldown
                  ? `Stimulate (${item.controller_stimulate_cooldown}s)`
                  : item.controller_direct_control_enabled
                    ? 'Stimulate Host'
                    : 'Request Stimulation'}
              </Button>
            </Stack.Item>
            {!!repositionOptions.length && (
              <Stack.Item>
                <Stack align="center">
                  <Stack.Item grow>
                    <Dropdown
                      width="170px"
                      selected={activeReposition?.name || 'Target Slot'}
                      options={repositionOptions.map((option) => option.name)}
                      onSelected={(label: string) => setSelectedReposition(label)}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="blue"
                      disabled={!item.controller_can_reposition || !activeReposition}
                      tooltip={
                        item.controller_can_reposition
                          ? item.controller_direct_control_enabled
                            ? 'Shift the ooze to the chosen place at once.'
                            : 'Petition the host to let the ooze resettle.'
                          : 'Repositioning is sealed while the bond wavers.'
                      }
                      onClick={() =>
                        activeReposition && act('jelly_controller_reposition', {
                          ref: item.ref,
                          slot: activeReposition.slot,
                        })
                      }
                    >
                      {item.controller_direct_control_enabled ? 'Shift Ooze' : 'Request Shift'}
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            )}
            <JellyForceControls item={item} />
          </>
        )}
        {item.controller_view_mode === 'doppel' && (
            <Stack.Item>
              <Button
                color="average"
                disabled={!item.controller_can_return}
                tooltip="Collapse the borrowed flesh and sink back into the ooze's core."
                onClick={() => act('jelly_controller_return', { ref: item.ref })}
              >
                Return To Ooze
              </Button>
            </Stack.Item>
        )}
        {/* ── Cocoon controls (visible from any view mode) ── */}
        <JellyCocoonControls item={item} />
      </Stack>
    </Stack.Item>
  );
};

const COCOON_STAGE_DESCRIPTIONS: Record<number, string> = {
  0: 'The cocoon gently wraps around the host, exploring and settling in.',
  1: 'A steady rhythm builds. The cocoon pulses insistently around the host.',
  2: 'The cocoon grips tightly, ravenous. Stamina drains with each pulse.',
  3: 'Total domination. The host is overwhelmed — drowsy and utterly consumed.',
};

const JellyCocoonControls = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  // Cocoon already active — show management controls + progression info
  if (item.controller_can_cocoon_command) {
    const tickCount = item.controller_cocoon_tick_count || 0;
    const nextStageTicks = item.controller_cocoon_next_stage_ticks || 0;
    const tickInterval = item.controller_cocoon_tick_interval || 3;
    const timeInCocoon = Math.round(tickCount * tickInterval);
    const timeToNextStage = nextStageTicks > tickCount
      ? Math.round((nextStageTicks - tickCount) * tickInterval)
      : 0;

    return (
      <>
        <Stack.Item basis="100%" mt={0.5}>
          <Box bold color="#ccaa44" fontSize="0.85em">
            Cocoon — Stage: {item.controller_cocoon_stage_name || 'Unknown'}
            <Box inline color="label" ml={1} bold={false} fontSize="0.85em">
              ({timeInCocoon}s elapsed)
            </Box>
          </Box>
          <Box color="label" fontSize="0.8em" mt={0.25} italic>
            {COCOON_STAGE_DESCRIPTIONS[item.controller_cocoon_stage] || ''}
          </Box>
        </Stack.Item>

        {/* Progression info */}
        {nextStageTicks > 0 && (
          <Stack.Item>
            <Box fontSize="0.8em" color="label">
              Next stage in ~{timeToNextStage}s
              <Box inline color="#ccaa44" ml={0.5}>
                (tick {tickCount} / {nextStageTicks})
              </Box>
            </Box>
          </Stack.Item>
        )}
        {nextStageTicks === 0 && item.controller_cocoon_stage >= 3 && (
          <Stack.Item>
            <Box fontSize="0.8em" color="average" italic>
              Maximum stage reached — the cocoon will not escalate further.
            </Box>
          </Stack.Item>
        )}

        {/* Feeding info */}
        <Stack.Item>
          <Box fontSize="0.8em" color="label">
            The cocoon automatically feeds the ooze every ~60s, soothing need.
            Tendril Pulse triggers a manual feed on a 30s cooldown.
          </Box>
        </Stack.Item>

        {/* Action buttons */}
        <Stack.Item mt={0.25}>
          <Stack wrap>
            <Stack.Item>
              <Button
                color="red"
                disabled={!item.controller_can_cocoon_tighten || item.controller_cocoon_stage >= 3}
                tooltip={
                  item.controller_cocoon_stage >= 3
                    ? 'The cocoon is already at its deepest stage.'
                    : !item.controller_can_cocoon_tighten
                      ? 'The ooze is not possessive enough to tighten its grip. Jealousy must grow first.'
                      : 'Will the cocoon tighter, skipping the wait and advancing it to the next stage immediately.'
                }
                onClick={() => act('jelly_controller_cocoon_tighten', { ref: item.ref })}
              >
                Tighten Cocoon
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="orange"
                tooltip="Command the cocoon to release the host."
                onClick={() => act('jelly_controller_cocoon_release', { ref: item.ref })}
              >
                Release Host
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="purple"
                disabled={!item.controller_can_cocoon_tendril}
                tooltip={
                  !item.controller_can_cocoon_tendril
                    ? 'The ooze is not possessive enough to command its tendrils. Jealousy must grow first.'
                    : 'Surge the tendrils through the cocoon, triggering a manual feed and flavor pulse.'
                }
                onClick={() => act('jelly_controller_cocoon_tendril_pulse', { ref: item.ref })}
              >
                Tendril Pulse
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </>
    );
  }

  // No cocoon active — offer to start one
  if (item.controller_can_start_cocoon) {
    return (
      <>
        <Stack.Item basis="100%" mt={0.5}>
          <Box fontSize="0.8em" color="label" italic>
            No cocoon is active. The ooze can seal its host inside a cocoon,
            which feeds the ooze over time and escalates through four stages.
          </Box>
        </Stack.Item>
        <Stack.Item mt={0.25}>
          <Button
            color="average"
            tooltip="Command the ooze to wrap around and seal its host in a cocoon."
            onClick={() => act('jelly_controller_start_cocoon', { ref: item.ref })}
          >
            Start Cocoon
          </Button>
        </Stack.Item>
      </>
    );
  }

  return null;
};

const JellyForceControls = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  const forceEmoteKeys = Object.keys(item.controller_force_emote_options ?? {});
  const defaultForceEmote = forceEmoteKeys[0] ?? '';
  const [selectedForceEmote, setSelectedForceEmote] = useState(defaultForceEmote);

  const voicePresets = item.controller_wearer_voice_presets ?? [];
  const defaultVoicePreset = voicePresets[0] ?? '';
  const [selectedVoicePreset, setSelectedVoicePreset] = useState(defaultVoicePreset);
  const activeVoicePreset = voicePresets.includes(selectedVoicePreset)
    ? selectedVoicePreset
    : defaultVoicePreset;

  const postureOptions = item.controller_force_posture_options ?? [];
  const defaultPosture = postureOptions[0] ?? '';
  const [selectedPosture, setSelectedPosture] = useState(defaultPosture);
  const activePosture = postureOptions.includes(selectedPosture)
    ? selectedPosture
    : defaultPosture;

  return (
    <>
      <Stack.Item>
        <Button
          color="red"
          disabled={!item.controller_can_force}
          tooltip={
            item.controller_can_force
              ? item.controller_direct_control_enabled
                ? 'Force words from the host\'s mouth.'
                : 'Petition to force words from the host\'s mouth.'
              : item.controller_emotion_needs_force
                ? 'The ooze is too sated to puppet the host\'s voice. Its hunger must grow first.'
                : 'Forced speech is sealed — the host must yield this power.'
          }
          onClick={() => act('jelly_controller_force_speech', { ref: item.ref })}
        >
          {item.controller_direct_control_enabled ? 'Force Speech' : 'Request Force Speech'}
        </Button>
      </Stack.Item>
      {!!forceEmoteKeys.length && (
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Dropdown
                width="130px"
                selected={selectedForceEmote || 'Emote'}
                options={forceEmoteKeys}
                onSelected={(label: string) => setSelectedForceEmote(label)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="red"
                disabled={!item.controller_can_force}
                tooltip={
                  item.controller_can_force
                    ? item.controller_direct_control_enabled
                      ? 'Wring the chosen reaction from the host\'s body.'
                      : 'Petition to wring the chosen reaction from the host.'
                    : item.controller_emotion_needs_force
                      ? 'The ooze is too sated to puppet the host\'s body. Its hunger must grow first.'
                      : 'Forced gestures are sealed — the host must yield this power.'
                }
                onClick={() =>
                  act('jelly_controller_force_emote', {
                    ref: item.ref,
                    emote_label: selectedForceEmote,
                  })
                }
              >
                {item.controller_direct_control_enabled ? 'Force Emote' : 'Request Force Emote'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}
      {!!voicePresets.length && (
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Dropdown
                width="170px"
                selected={activeVoicePreset || 'Voice Preset'}
                options={voicePresets}
                onSelected={(label: string) => setSelectedVoicePreset(label)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="red"
                disabled={!item.controller_can_force || !activeVoicePreset}
                tooltip={
                  item.controller_can_force
                    ? item.controller_direct_control_enabled
                      ? 'Force the host to utter the chosen preset.'
                      : 'Petition to force the host to utter the chosen preset.'
                    : item.controller_emotion_needs_force
                      ? 'The ooze is too sated to puppet voice presets. Its hunger must grow first.'
                      : 'Forced speech is sealed — the host must yield this power.'
                }
                onClick={() =>
                  act('jelly_controller_wearer_voice_preset', {
                    ref: item.ref,
                    preset_label: activeVoicePreset,
                  })
                }
              >
                {item.controller_direct_control_enabled ? 'Force Voice Preset' : 'Request Voice Preset'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}
      {!!postureOptions.length && (
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Dropdown
                width="150px"
                selected={activePosture || 'Posture'}
                options={postureOptions}
                onSelected={(label: string) => setSelectedPosture(label)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="red"
                disabled={!item.controller_can_force || !activePosture}
                tooltip={
                  item.controller_can_force
                    ? item.controller_direct_control_enabled
                      ? 'Force the host into the chosen posture.'
                      : 'Petition to force the host into the chosen posture.'
                    : item.controller_emotion_needs_force
                      ? 'The ooze is too sated to puppeteer postures. Its hunger must grow first.'
                      : 'Forced postures are sealed — the host must yield this power.'
                }
                onClick={() =>
                  act('jelly_controller_force_posture', {
                    ref: item.ref,
                    posture_label: activePosture,
                  })
                }
              >
                {item.controller_direct_control_enabled ? 'Force Posture' : 'Request Force Posture'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}
    </>
  );
};

const JellyControllerRequests = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  if (!item.is_strange_jelly) {
    return null;
  }

  const visibleToWearer = item.can_manage_bound_controller;
  const visibleToController = item.is_controller_viewer;

  if (!visibleToWearer && !visibleToController) {
    return null;
  }

  const pendingRequests = item.controller_pending_requests ?? [];

  if (!pendingRequests.length) {
    return null;
  }

  return (
    <Stack.Item mt={1}>
      <Section title="Pending Petitions" style={{ borderTop: '1px solid rgba(255,255,255,0.15)' }}>
        <Stack vertical>
          {pendingRequests.map((request) => (
            <Stack.Item key={request.id}>
              <Box mb={0.3}>
                <Box bold>{request.summary}</Box>
                <Box fontSize="0.8em" color="label">
                  Expires in {request.expires_in}
                </Box>
              </Box>
              {visibleToWearer ? (
                <Stack>
                  <Stack.Item>
                    <Button
                      color="good"
                      onClick={() =>
                        act('jelly_controller_respond_request', {
                          ref: item.ref,
                          request_id: request.id,
                          accepted: 1,
                        })
                      }
                    >
                      Accept
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      color="bad"
                      onClick={() =>
                        act('jelly_controller_respond_request', {
                          ref: item.ref,
                          request_id: request.id,
                          accepted: 0,
                        })
                      }
                    >
                      Deny
                    </Button>
                  </Stack.Item>
                </Stack>
              ) : (
                <Box fontSize="0.8em" color="label" italic>
                  Awaiting the host&apos;s answer.
                </Box>
              )}
            </Stack.Item>
          ))}
        </Stack>
      </Section>
    </Stack.Item>
  );
};

/** Pending wearer-to-candidate invitations with cancel/accept/decline controls. */
const JellyInvitations = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  if (!item.is_strange_jelly) {
    return null;
  }

  const isWearer = item.is_bonded_wearer;
  const pending = item.controller_pending_invitations ?? [];

  // Nothing to show if no invitations pending and wearer can't send new ones.
  if (!pending.length && !item.can_invite_controller) {
    return null;
  }

  return (
    <Stack.Item mt={1}>
      <Section title="Beckonings" style={{ borderTop: '1px solid rgba(255,255,255,0.15)' }}>
        {!!isWearer && !!item.can_invite_controller && (
          <Box mb={0.5}>
            <Button
              color="blue"
              tooltip="Beckon an attuned spirit into the ooze. They will feel the call and may accept or refuse."
              onClick={() => act('jelly_send_invitation', { ref: item.ref })}
            >
              Beckon Spirit
            </Button>
          </Box>
        )}
        {pending.length > 0 && (
          <Stack vertical>
            {pending.map((invite) => (
              <Stack.Item key={invite.id}>
                <Box mb={0.3}>
                  <Box bold>{invite.candidate_name}</Box>
                  <Box fontSize="0.8em" color="label">
                    Expires in {invite.expires_in}
                  </Box>
                </Box>
                {isWearer ? (
                  <Button
                    color="bad"
                    onClick={() =>
                      act('jelly_cancel_invitation', {
                        ref: item.ref,
                        invitation_id: invite.id,
                      })
                    }
                  >
                    Cancel
                  </Button>
                ) : (
                  <Stack>
                    <Stack.Item>
                      <Button
                        color="good"
                        onClick={() =>
                          act('jelly_respond_invitation', {
                            ref: item.ref,
                            invitation_id: invite.id,
                            accepted: 1,
                          })
                        }
                      >
                        Accept
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="bad"
                        onClick={() =>
                          act('jelly_respond_invitation', {
                            ref: item.ref,
                            invitation_id: invite.id,
                            accepted: 0,
                          })
                        }
                      >
                        Decline
                      </Button>
                    </Stack.Item>
                  </Stack>
                )}
              </Stack.Item>
            ))}
          </Stack>
        )}
      </Section>
    </Stack.Item>
  );
};

/**
 * Expanded interaction panel rendered inside ItemCard when the accessory is an
 * Eora Jelly. Shows need / jealousy / resentment bars for strange jellies, slot-swap buttons,
 * and command buttons (Eat, Stimulate, Soothe / Tend).
 */
/** Strange-jelly identity, bond bars, and status indicators. */
const JellyStatusBlock = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;
  const escalationColor = ESCALATION_COLOR[item.bond_escalation_level] ?? '#aaaaaa';

  return (
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
        tooltip="Grows over time. Reduced by feeding (creampie absorption, eating cum, wearer orgasm, cocoon tendrils). High need triggers punishments and cocoon."
      />
      <MiniBar
        value={item.jealousy_level}
        max={item.max_jealousy_level}
        color="#cc6666"
        label="Jealousy"
        sublabel={item.jealousy_state ?? undefined}
        tooltip="Grows when the wearer has sex that doesn't feed the jelly, or when another jelly is involved. Reduced when fully sated. High jealousy triggers stripping and cocoon."
      />
      <MiniBar
        value={item.resentment_level}
        max={item.max_resentment_level}
        color="#9966cc"
        label="Resentment"
        sublabel={item.resentment_state ?? undefined}
        tooltip="Grows from cocoon breakout, arousal denial during sex, and over-soothing at high bond. Decays slowly while sated. High resentment causes pain and sabotages feeding."
      />
      {/* ── Bond level bar ── */}
      <MiniBar
        value={item.bond_escalation_level}
        max={item.max_bond_escalation_level || 4}
        color={escalationColor}
        label="Bond"
        sublabel={item.bond_state ?? undefined}
        tooltip="Grows from consensual sex acts with the wearer. Unlocks tendril commands, voluntary cocoon, and doppelganger manifestation. Never decreases."
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
      {!!item.is_cocooned && (() => {
        const tickCount = item.cocoon_tick_count || 0;
        const nextStageTicks = item.cocoon_next_stage_ticks || 0;
        const tickInterval = item.cocoon_tick_interval || 3;
        const timeInCocoon = Math.round(tickCount * tickInterval);
        const timeToNextStage = nextStageTicks > tickCount
          ? Math.round((nextStageTicks - tickCount) * tickInterval)
          : 0;
        const stageDesc = WEARER_COCOON_STAGE_DESCRIPTIONS[item.cocoon_stage];
        return (
          <Box mt={0.5}>
            <Box color="bad" italic fontSize="0.85em">
              ⚠ Cocooned
              {item.cocoon_stage_name && item.cocoon_stage_name !== 'none' && (
                <Box inline color="#ccaa44" ml={0.5}>
                  — {item.cocoon_stage_name}
                </Box>
              )}
              <Box inline color="label" ml={0.5}>
                ({timeInCocoon}s)
              </Box>
            </Box>
            {stageDesc && (
              <Box color="label" fontSize="0.75em" mt={0.15} italic>
                {stageDesc}
              </Box>
            )}
            {nextStageTicks > 0 && (
              <Box fontSize="0.75em" color="label" mt={0.15}>
                Escalates in ~{timeToNextStage}s
              </Box>
            )}
            {nextStageTicks === 0 && item.cocoon_stage >= 3 && (
              <Box fontSize="0.75em" color="average" mt={0.15} italic>
                The cocoon has reached peak intensity.
              </Box>
            )}
            <Box fontSize="0.75em" color="label" mt={0.15}>
              The cocoon feeds the ooze periodically, soothing its need.
              Resist to break free, or surrender and let it run its course.
            </Box>
          </Box>
        );
      })()}
    </Stack.Item>
  );
};

const JellyPanel = (props: { item: ItemData }) => {
  const { act } = useBackend<Data>();
  const { item } = props;

  const [selectedTendrilAction, setSelectedTendrilAction] = useState('multi');

  return (
    <Box mt={1}>
      <Section title="Ooze Controls" style={{ borderTop: '1px solid rgba(255,255,255,0.15)' }}>
        <Stack vertical>

          {/* ── Strange-jelly identity & status ── */}
          {!!item.is_strange_jelly && <JellyStatusBlock item={item} />}

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
                      tooltip={`Shift the ooze to the ${opt.name} slot.`}
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
                      ? 'Command the ooze to send a stimulation surge.'
                      : `Building pressure\u2026 ${item.stimulate_cooldown || 0}s`
                  }
                  onClick={() => act('jelly_stimulate', { ref: item.ref })}
                >
                  {item.can_stimulate
                    ? 'Stimulate'
                    : `Stimulate (${item.stimulate_cooldown || 0}s)`}
                </Button>
              </Stack.Item>
              {/* Eat cum — only when in an internal slot */}
              {!!item.can_eat_cum && (
                <Stack.Item>
                  <Button
                    color="average"
                    tooltip="Command the ooze to eagerly consume retained fluids."
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
                    tooltip="Attend to the ooze, easing its hunger and jealousy."
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
                    tooltip="Gently comfort this ooze, partially easing its cravings."
                    onClick={() => act('jelly_comfort', { ref: item.ref })}
                  >
                    Tend Ooze
                  </Button>
                </Stack.Item>
              )}
              {/* Command Tendril — bonded wearer, bond level 1+ */}
              {!!item.is_strange_jelly && !!item.can_command_tendril && (
                <Stack.Item>
                  <Stack align="center">
                    <Stack.Item grow>
                      <Dropdown
                        width="140px"
                        selected={TENDRIL_ACTION_LABELS[selectedTendrilAction]}
                        options={TENDRIL_ACTION_OPTIONS}
                        onSelected={(label: string) => {
                          const match = Object.entries(TENDRIL_ACTION_LABELS).find(
                            ([, value]) => value === label,
                          );
                          setSelectedTendrilAction(match?.[0] ?? 'multi');
                        }}
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="purple"
                        disabled={!item.tendril_command_ready}
                        tooltip={
                          item.tendril_command_ready
                            ? `Direct the ooze toward a ${TENDRIL_ACTION_LABELS[selectedTendrilAction]} action.`
                            : 'The ooze is still carrying out the last command.'
                        }
                        onClick={() =>
                          act('jelly_tendril_command', {
                            ref: item.ref,
                            action_key: selectedTendrilAction,
                          })
                        }
                      >
                        Command Tendril
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              )}
              {/* Request Cocoon — bonded wearer, bond level 2+ */}
              {!!item.is_strange_jelly && !!item.can_request_cocoon && (
                <Stack.Item>
                  <Button
                    color="average"
                    tooltip="Surrender to the ooze's embrace — request cocooning."
                    onClick={() =>
                      act('jelly_request_cocoon', { ref: item.ref })
                    }
                  >
                    Request Cocoon
                  </Button>
                </Stack.Item>
              )}
              {/* Provoke — bonded wearer, raises jealousy/resentment */}
              {!!item.is_strange_jelly && !!item.is_bonded_wearer && (
                <Stack.Item>
                  <Button
                    color="bad"
                    disabled={!item.provoke_ready}
                    tooltip={
                      item.provoke_ready
                        ? 'Deliberately antagonize the ooze, goading its jealousy and resentment.'
                        : 'The ooze is already agitated — wait before pushing further.'
                    }
                    onClick={() =>
                      act('jelly_provoke', { ref: item.ref })
                    }
                  >
                    Provoke
                  </Button>
                </Stack.Item>
              )}
              {/* Project Double — actual player-controlled slime mode */}
              {!!item.is_strange_jelly && !!item.is_bonded_wearer && !!item.can_project_doppel && (
                <Stack.Item>
                  <Button
                    color="average"
                    tooltip="Project your awareness into the slime-born shape. Limited radius, no combat, and no burden-bearing."
                    onClick={() => act('jelly_project_doppel', { ref: item.ref })}
                  >
                    Project Shape
                  </Button>
                </Stack.Item>
              )}
              {!!item.is_strange_jelly && !!item.can_review_controller_volunteers && (
                <Stack.Item>
                  <Stack align="center">
                    {!!item.can_toggle_controller_applications && (
                      <Stack.Item>
                        <Button
                          color={item.controller_applications_open ? 'good' : 'average'}
                          tooltip={item.controller_applications_open ? 'Seal the ooze against new petitioners.' : 'Open the ooze to those who would answer its call.'}
                          onClick={() =>
                            act('jelly_toggle_controller_applications', {
                              ref: item.ref,
                              open: item.controller_applications_open ? 0 : 1,
                            })
                          }
                        >
                          {item.controller_applications_open ? 'Seal Petitions' : 'Open Petitions'}
                        </Button>
                      </Stack.Item>
                    )}
                    <Stack.Item>
                      <Button
                        color="blue"
                        disabled={(item.pending_controller_application_count ?? 0) <= 0}
                        tooltip={
                          (item.pending_controller_application_count ?? 0) > 0
                            ? 'Review those who offer themselves to the ooze and accept one.'
                            : 'No petitioners have come forward yet.'
                        }
                        onClick={() => act('jelly_review_volunteers', { ref: item.ref })}
                      >
                        {(item.pending_controller_application_count ?? 0) > 0
                          ? `Review Petitioners (${item.pending_controller_application_count})`
                          : 'Review Petitioners'}
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              )}
              <JellyControllerPanel item={item} />
              <JellyControllerControls item={item} />
              <JellyControllerRequests item={item} />
              <JellyInvitations item={item} />
            </Stack>
          </Stack.Item>

          {/* ── Extra status indicators ── */}
          {!!item.is_strange_jelly && <JellyIndicators item={item} />}

          {/* ── Activity history ── */}
          {!!item.is_strange_jelly && (item.controller_activity_log?.length ?? 0) > 0 && (
            <Stack.Item mt={1}>
              <ControllerActivityLog entries={item.controller_activity_log} />
            </Stack.Item>
          )}

          {/* ── Mood log ── */}
          {!!item.is_strange_jelly && item.mood_log?.length > 0 && (
            <Stack.Item mt={1}>
              <MoodLog entries={item.mood_log} />
            </Stack.Item>
          )}

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

