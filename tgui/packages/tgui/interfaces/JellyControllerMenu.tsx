import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ── Types ────────────────────────────────────────────────────────────────────

type SwapOption = {
  slot: number;
  name: string;
};

type ControllerRequest = {
  id: number;
  type: string;
  summary: string;
  expires_in: string;
};

type ControllerActivityEntry = {
  time: string;
  actor: string;
  event: string;
  summary: string;
  severity: string;
};

type Data = {
  invalid?: boolean;
  ref: string;
  name: string;
  custom_jelly_name: string | null;
  // Emotional state
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
  // Wearer info
  has_bonded_wearer: boolean;
  bonded_wearer_name: string | null;
  is_cocooned: boolean;
  cocoon_stage_name: string | null;
  // Doppelganger info
  has_doppelganger: boolean;
  doppel_is_player_controlled: boolean;
  // Controller state
  controller_state: string | null;
  controller_state_name: string | null;
  is_controller_viewer: boolean;
  controller_view_mode: string | null;
  controller_wearer_ready: boolean;
  controller_wearer_status: string | null;
  controller_direct_control_enabled: boolean;
  controller_force_enabled: boolean;
  controller_speech_enabled: boolean;
  controller_emote_enabled: boolean;
  controller_manifest_enabled: boolean;
  // Permission flags
  controller_can_speak: boolean;
  controller_can_emote: boolean;
  controller_can_preset_action: boolean;
  controller_can_manifest: boolean;
  controller_can_stimulate: boolean;
  controller_stimulate_cooldown: number;
  controller_can_force: boolean;
  controller_force_cooldown: number;
  controller_can_return: boolean;
  controller_can_reposition: boolean;
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
  // Slot reposition
  current_slot: number;
  current_slot_name: string;
  swap_slot_options: SwapOption[];
  // Dropdown options
  controller_preset_actions: string[];
  controller_force_emote_options: Record<string, string>;
  controller_wearer_voice_presets: string[];
  controller_force_posture_options: string[];
  // Pending requests
  controller_pending_requests: ControllerRequest[];
  // Activity log
  controller_activity_log: ControllerActivityEntry[];
};

// ── Constants ────────────────────────────────────────────────────────────────

const ESCALATION_COLOR: Record<number, string> = {
  0: '#aaaaaa',
  1: '#88cc88',
  2: '#ddcc55',
  3: '#dd7722',
  4: '#cc3333',
};

const ACTIVITY_ACTOR_COLOR: Record<string, string> = {
  wearer: '#88bbee',
  controller: '#cc88dd',
  admin: '#ee9944',
  system: '#aaaaaa',
};

const ACTIVITY_SEVERITY_COLOR: Record<string, string> = {
  normal: '#cccccc',
  important: '#eebb44',
  warning: '#dd6655',
};

// ── Helpers ──────────────────────────────────────────────────────────────────

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
          <Box
            style={{
              position: 'relative',
              height: '0.6em',
              background: 'rgba(255,255,255,0.12)',
              borderRadius: '3px',
              overflow: 'hidden',
            }}
          >
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

// ── Root component ───────────────────────────────────────────────────────────

export const JellyControllerMenu = () => {
  const { data } = useBackend<Data>();

  if (data.invalid) {
    return (
      <Window width={480} height={200} title="Jelly Communion">
        <Window.Content>
          <NoticeBox danger>The jelly is no longer available.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const escalationColor =
    ESCALATION_COLOR[data.bond_escalation_level] ?? '#aaaaaa';

  return (
    <Window width={480} height={560} title="Jelly Communion">
      <Window.Content scrollable>
        <Stack vertical fill>
          {/* ── Status ── */}
          <Stack.Item>
            <Section title={data.custom_jelly_name ?? data.name}>
              <StatusBars data={data} escalationColor={escalationColor} />
            </Section>
          </Stack.Item>

          {/* ── Communion controls ── */}
          <Stack.Item>
            <Section title="Communion Interface">
              <CommunionHeader data={data} />
              {data.controller_view_mode === 'shell' && <ShellControls />}
              {data.controller_view_mode === 'doppel' && <DoppelControls />}
            </Section>
          </Stack.Item>

          {/* ── Cocoon controls (visible from any view mode) ── */}
          {(!!data.controller_can_cocoon_command ||
            !!data.controller_can_start_cocoon) && (
            <Stack.Item>
              <Section title="Cocoon">
                <CocoonControls />
              </Section>
            </Stack.Item>
          )}

          {/* ── Pending requests ── */}
          {(data.controller_pending_requests?.length ?? 0) > 0 && (
            <Stack.Item>
              <PendingRequests data={data} />
            </Stack.Item>
          )}

          {/* ── Activity log ── */}
          {(data.controller_activity_log?.length ?? 0) > 0 && (
            <Stack.Item>
              <ActivityLog entries={data.controller_activity_log} />
            </Stack.Item>
          )}

          {/* ── Indicators ── */}
          <Stack.Item>
            <Indicators data={data} />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// ── Status bars ──────────────────────────────────────────────────────────────

const StatusBars = (props: { data: Data; escalationColor: string }) => {
  const { data, escalationColor } = props;
  return (
    <>
      <MiniBar
        value={data.need_level}
        max={data.max_need_level}
        color="#7799dd"
        label="Need"
        sublabel={data.need_state ?? undefined}
        tooltip="Grows over time. Reduced by feeding (creampie absorption, eating cum, wearer orgasm, cocoon tendrils). High need triggers punishments and cocoon."
      />
      <MiniBar
        value={data.jealousy_level}
        max={data.max_jealousy_level}
        color="#cc6666"
        label="Jealousy"
        sublabel={data.jealousy_state ?? undefined}
        tooltip="Grows when the wearer has sex that doesn't feed the jelly, or when another jelly is involved. Reduced when fully sated. High jealousy triggers stripping and cocoon."
      />
      <MiniBar
        value={data.resentment_level}
        max={data.max_resentment_level}
        color="#9966cc"
        label="Resentment"
        sublabel={data.resentment_state ?? undefined}
        tooltip="Grows from cocoon breakout, arousal denial during sex, and over-soothing at high bond. Decays slowly while sated. High resentment causes pain and sabotages feeding."
      />
      <MiniBar
        value={data.bond_escalation_level}
        max={data.max_bond_escalation_level || 4}
        color={escalationColor}
        label="Bond"
        sublabel={data.bond_state ?? undefined}
        tooltip="Grows from consensual sex acts with the wearer. Unlocks tendril commands, voluntary cocoon, and doppelganger manifestation. Never decreases."
      />
      {data.bond_escalation_level < (data.max_bond_escalation_level || 4) &&
        data.bond_progress_threshold > 0 && (
          <Box mt={0.25} fontSize="0.75em" color="label">
            Progress: {data.bond_progress} / {data.bond_progress_threshold}
          </Box>
        )}
      {data.obsession_level > 0 && (
        <Box mt={0.25} fontSize="0.8em" color="average">
          Obsession level: {data.obsession_level}
        </Box>
      )}
      {!!data.has_bonded_wearer && (
        <Box mt={0.5} color="label" fontSize="0.8em">
          Bonded to:{' '}
          <Box inline color="good">
            {data.bonded_wearer_name ?? 'Unknown'}
          </Box>
        </Box>
      )}
      {!!data.is_cocooned && (
        <Box mt={0.5} color="bad" italic fontSize="0.85em">
          ⚠ Host is cocooned
          {data.cocoon_stage_name && data.cocoon_stage_name !== 'none' && (
            <Box inline color="#ccaa44" ml={0.5}>
              — {data.cocoon_stage_name}
            </Box>
          )}
          <Box inline color="label" ml={0.5}>
            (
            {Math.round(
              (data.controller_cocoon_tick_count || 0) *
                (data.controller_cocoon_tick_interval || 3),
            )}
            s)
          </Box>
        </Box>
      )}
    </>
  );
};

// ── Mode header ──────────────────────────────────────────────────────────────

const CommunionHeader = (props: { data: Data }) => {
  const { data } = props;
  return (
    <>
      <Box fontSize="0.8em" color="label" mb={0.4}>
        Mode:{' '}
        <Box inline color="good">
          {data.controller_view_mode === 'doppel'
            ? 'Shaped flesh'
            : data.controller_view_mode === 'shell'
              ? 'Within my body'
              : 'Unavailable'}
        </Box>
      </Box>
      {!!data.controller_state_name && (
        <Box fontSize="0.8em" color="label" mb={0.4}>
          State:{' '}
          <Box
            inline
            color={data.controller_state === 'suspended' ? 'average' : 'good'}
          >
            {data.controller_state_name}
          </Box>
        </Box>
      )}
      {!!data.controller_wearer_status && (
        <NoticeBox danger={!data.controller_wearer_ready}>
          {data.controller_wearer_status}
        </NoticeBox>
      )}
      {data.controller_view_mode === 'shell' && (
        <NoticeBox>
          {data.controller_direct_control_enabled
            ? 'The host has lowered the ward. My will flows freely through them.'
            : "The host's ward holds firm. I must petition before acting upon their flesh."}
        </NoticeBox>
      )}
    </>
  );
};

// ── Shell-mode controls ──────────────────────────────────────────────────────

const ShellControls = () => {
  const { act, data } = useBackend<Data>();

  const defaultPreset = data.controller_preset_actions?.[0] ?? '';
  const [selectedPreset, setSelectedPreset] = useState(defaultPreset);
  const activePreset = data.controller_preset_actions?.includes(selectedPreset)
    ? selectedPreset
    : defaultPreset;

  const repositionOptions = data.swap_slot_options ?? [];
  const defaultReposition = repositionOptions[0]?.name ?? '';
  const [selectedReposition, setSelectedReposition] =
    useState(defaultReposition);
  const activeReposition =
    repositionOptions.find((o) => o.name === selectedReposition) ??
    repositionOptions[0];

  return (
    <Stack wrap mt={0.4}>
      {/* ── Communication ── */}
      <Stack.Item>
        <Button
          color="good"
          disabled={!data.controller_can_speak}
          tooltip={
            data.controller_can_speak
              ? 'Let my voice rise through the host.'
              : data.controller_emotion_blocks_speech
                ? 'My body writhes with resentment. I cannot shape words.'
                : 'Speech is sealed while the bond wavers or the host forbids it.'
          }
          onClick={() => act('controller_speak')}
        >
          Speak
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button
          color="teal"
          disabled={!data.controller_can_speak}
          tooltip={
            data.controller_can_speak
              ? 'Murmur privately to the host — only they will feel it.'
              : data.controller_emotion_blocks_speech
                ? 'My body writhes with resentment. I cannot shape words.'
                : 'Speech is sealed while the bond wavers or the host forbids it.'
          }
          onClick={() => act('controller_whisper')}
        >
          Whisper
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button
          color="average"
          disabled={!data.controller_can_emote}
          tooltip={
            data.controller_can_emote
              ? 'Express a gesture through my host.'
              : data.controller_emotion_blocks_speech
                ? 'My body writhes with resentment. I cannot convey intent.'
                : 'Gestures are sealed while the bond wavers or the host forbids it.'
          }
          onClick={() => act('controller_emote')}
        >
          Emote
        </Button>
      </Stack.Item>

      {/* ── Preset actions ── */}
      {!!data.controller_preset_actions?.length && (
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Dropdown
                width="170px"
                selected={activePreset || 'Preset Action'}
                options={data.controller_preset_actions}
                onSelected={(label: string) => setSelectedPreset(label)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="blue"
                disabled={!data.controller_can_preset_action || !activePreset}
                tooltip={
                  data.controller_can_preset_action
                    ? 'Express a preset intent through my host.'
                    : data.controller_emotion_blocks_speech
                      ? 'My body writhes with resentment. Preset stirrings will not take.'
                      : 'Preset stirrings are sealed while the bond wavers or the host forbids it.'
                }
                onClick={() =>
                  act('controller_preset', { preset_action: activePreset })
                }
              >
                Send Preset
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}

      {/* ── Manifest ── */}
      <Stack.Item>
        <Button
          color="purple"
          disabled={!data.controller_can_manifest}
          tooltip={
            data.controller_can_manifest
              ? data.controller_direct_control_enabled
                ? 'Take shape at once.'
                : 'Petition the host to let me take shape.'
              : 'Taking shape is sealed while the bond wavers or the host forbids it.'
          }
          onClick={() => act('controller_manifest')}
        >
          {data.controller_direct_control_enabled
            ? 'Take Shape'
            : 'Request Shape'}
        </Button>
      </Stack.Item>

      {/* ── Stimulate ── */}
      <Stack.Item>
        <Button
          color="orange"
          disabled={
            !data.controller_can_stimulate ||
            !!data.controller_stimulate_cooldown
          }
          tooltip={
            !data.controller_can_stimulate
              ? data.controller_emotion_needs_force
                ? 'I am too sated for stimulation. My hunger must grow first.'
                : 'Stimulation is sealed while the bond wavers.'
              : data.controller_stimulate_cooldown
                ? `Building pressure\u2026 ${data.controller_stimulate_cooldown}s`
                : data.controller_direct_control_enabled
                  ? 'Drive my body into a pulse of raw stimulation.'
                  : 'Petition the host to let me stimulate them.'
          }
          onClick={() => act('controller_stimulate')}
        >
          {data.controller_stimulate_cooldown
            ? `Stimulate (${data.controller_stimulate_cooldown}s)`
            : data.controller_direct_control_enabled
              ? 'Stimulate Host'
              : 'Request Stimulation'}
        </Button>
      </Stack.Item>

      {/* ── Reposition ── */}
      {!!repositionOptions.length && (
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>
              <Dropdown
                width="170px"
                selected={activeReposition?.name || 'Target Slot'}
                options={repositionOptions.map((o) => o.name)}
                onSelected={(label: string) => setSelectedReposition(label)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                color="blue"
                disabled={!data.controller_can_reposition || !activeReposition}
                tooltip={
                  data.controller_can_reposition
                    ? data.controller_direct_control_enabled
                      ? 'Shift my body to the chosen place at once.'
                      : 'Petition the host to let me resettle.'
                    : 'Repositioning is sealed while the bond wavers.'
                }
                onClick={() =>
                  activeReposition &&
                  act('controller_reposition', { slot: activeReposition.slot })
                }
              >
                {data.controller_direct_control_enabled
                  ? 'Shift Body'
                  : 'Request Shift'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}

      {/* ── Force controls ── */}
      <ForceControls />
    </Stack>
  );
};

// ── Force controls ───────────────────────────────────────────────────────────

const ForceControls = () => {
  const { act, data } = useBackend<Data>();

  const forceEmoteKeys = Object.keys(data.controller_force_emote_options ?? {});
  const defaultForceEmote = forceEmoteKeys[0] ?? '';
  const [selectedForceEmote, setSelectedForceEmote] =
    useState(defaultForceEmote);

  const voicePresets = data.controller_wearer_voice_presets ?? [];
  const defaultVoicePreset = voicePresets[0] ?? '';
  const [selectedVoicePreset, setSelectedVoicePreset] =
    useState(defaultVoicePreset);
  const activeVoicePreset = voicePresets.includes(selectedVoicePreset)
    ? selectedVoicePreset
    : defaultVoicePreset;

  const postureOptions = data.controller_force_posture_options ?? [];
  const defaultPosture = postureOptions[0] ?? '';
  const [selectedPosture, setSelectedPosture] = useState(defaultPosture);
  const activePosture = postureOptions.includes(selectedPosture)
    ? selectedPosture
    : defaultPosture;

  return (
    <>
      {/* ── Force speech ── */}
      <Stack.Item>
        <Button
          color="red"
          disabled={
            !data.controller_can_force || !!data.controller_force_cooldown
          }
          tooltip={
            !data.controller_can_force
              ? data.controller_emotion_needs_force
                ? "I am too sated to puppet the host's voice. My hunger must grow first."
                : 'Forced speech is sealed \u2014 the host must yield this power.'
              : data.controller_force_cooldown
                ? `My grip is still settling\u2026 ${data.controller_force_cooldown}s`
                : data.controller_direct_control_enabled
                  ? "Force words from the host's mouth."
                  : "Petition to force words from the host's mouth."
          }
          onClick={() => act('controller_force_speech')}
        >
          {data.controller_force_cooldown
            ? `Force Speech (${data.controller_force_cooldown}s)`
            : data.controller_direct_control_enabled
              ? 'Force Speech'
              : 'Request Force Speech'}
        </Button>
      </Stack.Item>

      {/* ── Force emote ── */}
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
                disabled={
                  !data.controller_can_force || !!data.controller_force_cooldown
                }
                tooltip={
                  !data.controller_can_force
                    ? data.controller_emotion_needs_force
                      ? "I am too sated to puppet the host's body. My hunger must grow first."
                      : 'Forced gestures are sealed \u2014 the host must yield this power.'
                    : data.controller_force_cooldown
                      ? `My grip is still settling\u2026 ${data.controller_force_cooldown}s`
                      : data.controller_direct_control_enabled
                        ? "Wring the chosen reaction from the host's body."
                        : 'Petition to wring the chosen reaction from the host.'
                }
                onClick={() =>
                  act('controller_force_emote', {
                    emote_label: selectedForceEmote,
                  })
                }
              >
                {data.controller_force_cooldown
                  ? `Force Emote (${data.controller_force_cooldown}s)`
                  : data.controller_direct_control_enabled
                    ? 'Force Emote'
                    : 'Request Force Emote'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}

      {/* ── Voice presets ── */}
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
                disabled={
                  !data.controller_can_force ||
                  !activeVoicePreset ||
                  !!data.controller_force_cooldown
                }
                tooltip={
                  !data.controller_can_force
                    ? data.controller_emotion_needs_force
                      ? 'I am too sated to puppet voice presets. My hunger must grow first.'
                      : 'Forced speech is sealed — the host must yield this power.'
                    : data.controller_force_cooldown
                      ? `My grip is still settling… ${data.controller_force_cooldown}s`
                      : data.controller_direct_control_enabled
                        ? 'Force the host to utter the chosen preset.'
                        : 'Petition to force the host to utter the chosen preset.'
                }
                onClick={() =>
                  act('controller_wearer_voice_preset', {
                    preset_label: activeVoicePreset,
                  })
                }
              >
                {data.controller_force_cooldown
                  ? `Force Voice Preset (${data.controller_force_cooldown}s)`
                  : data.controller_direct_control_enabled
                    ? 'Force Voice Preset'
                    : 'Request Voice Preset'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}

      {/* ── Force posture ── */}
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
                disabled={
                  !data.controller_can_force ||
                  !activePosture ||
                  !!data.controller_force_cooldown
                }
                tooltip={
                  !data.controller_can_force
                    ? data.controller_emotion_needs_force
                      ? 'I am too sated to puppeteer postures. My hunger must grow first.'
                      : 'Forced postures are sealed \u2014 the host must yield this power.'
                    : data.controller_force_cooldown
                      ? `My grip is still settling\u2026 ${data.controller_force_cooldown}s`
                      : data.controller_direct_control_enabled
                        ? 'Force the host into the chosen posture.'
                        : 'Petition to force the host into the chosen posture.'
                }
                onClick={() =>
                  act('controller_force_posture', {
                    posture_label: activePosture,
                  })
                }
              >
                {data.controller_force_cooldown
                  ? `Force Posture (${data.controller_force_cooldown}s)`
                  : data.controller_direct_control_enabled
                    ? 'Force Posture'
                    : 'Request Force Posture'}
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}
    </>
  );
};

// ── Doppel-mode controls ─────────────────────────────────────────────────────

const DoppelControls = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Stack wrap mt={0.4}>
      <Stack.Item>
        <Button
          color="average"
          disabled={!data.controller_can_return}
          tooltip="Collapse this shape and return to my resting body."
          onClick={() => act('controller_return')}
        >
          Return To Body
        </Button>
      </Stack.Item>
    </Stack>
  );
};

// ── Cocoon controls (shared across shell & doppel modes) ─────────────────────

const COCOON_STAGE_DESCRIPTIONS: Record<number, string> = {
  0: 'The cocoon gently wraps around the host, exploring and settling in.',
  1: 'A steady rhythm builds. The cocoon pulses insistently around the host.',
  2: 'The cocoon grips tightly, ravenous. Stamina drains with each pulse.',
  3: 'Total domination. The host is overwhelmed — drowsy and utterly consumed.',
};

const CocoonControls = () => {
  const { act, data } = useBackend<Data>();

  // Cocoon already active — show management controls + progression info
  if (data.controller_can_cocoon_command) {
    const tickCount = data.controller_cocoon_tick_count || 0;
    const nextStageTicks = data.controller_cocoon_next_stage_ticks || 0;
    const tickInterval = data.controller_cocoon_tick_interval || 3;
    const timeInCocoon = Math.round(tickCount * tickInterval);
    const timeToNextStage =
      nextStageTicks > tickCount
        ? Math.round((nextStageTicks - tickCount) * tickInterval)
        : 0;

    return (
      <Stack vertical>
        {/* Stage header + description */}
        <Stack.Item>
          <Box bold color="#ccaa44" fontSize="0.85em">
            Stage: {data.controller_cocoon_stage_name || 'Unknown'}
            <Box inline color="label" ml={1} bold={false} fontSize="0.85em">
              ({timeInCocoon}s elapsed)
            </Box>
          </Box>
          <Box color="label" fontSize="0.8em" mt={0.25} italic>
            {COCOON_STAGE_DESCRIPTIONS[data.controller_cocoon_stage] || ''}
          </Box>
        </Stack.Item>

        {/* Progression info */}
        {nextStageTicks > 0 && (
          <Stack.Item mt={0.4}>
            <Box fontSize="0.8em" color="label">
              Next stage in ~{timeToNextStage}s
              <Box inline color="#ccaa44" ml={0.5}>
                (tick {tickCount} / {nextStageTicks})
              </Box>
            </Box>
          </Stack.Item>
        )}
        {nextStageTicks === 0 && data.controller_cocoon_stage >= 3 && (
          <Stack.Item mt={0.4}>
            <Box fontSize="0.8em" color="average" italic>
              Maximum stage reached — the cocoon will not escalate further.
            </Box>
          </Stack.Item>
        )}

        {/* Feeding info */}
        <Stack.Item mt={0.4}>
          <Box fontSize="0.8em" color="label">
            The cocoon automatically feeds the ooze every ~60s, soothing need.
            Tendril Pulse triggers a manual feed on a 30s cooldown.
          </Box>
        </Stack.Item>

        {/* Action buttons */}
        <Stack.Item mt={0.5}>
          <Stack wrap>
            <Stack.Item>
              <Button
                color="red"
                disabled={
                  !data.controller_can_cocoon_tighten ||
                  data.controller_cocoon_stage >= 3
                }
                tooltip={
                  data.controller_cocoon_stage >= 3
                    ? 'The cocoon is already at its deepest stage.'
                    : !data.controller_can_cocoon_tighten
                      ? 'I am not possessive enough to tighten my grip. My jealousy must grow first.'
                      : 'Will the cocoon tighter, skipping the wait and advancing it to the next stage immediately.'
                }
                onClick={() => act('controller_cocoon_tighten')}
              >
                Tighten Cocoon
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="orange"
                tooltip="Command the cocoon to release the host."
                onClick={() => act('controller_cocoon_release')}
              >
                Release Host
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="purple"
                disabled={!data.controller_can_cocoon_tendril}
                tooltip={
                  !data.controller_can_cocoon_tendril
                    ? 'I am not possessive enough to command my tendrils. My jealousy must grow first.'
                    : 'Surge my tendrils through the cocoon, triggering a manual feed and flavor pulse.'
                }
                onClick={() => act('controller_cocoon_tendril_pulse')}
              >
                Tendril Pulse
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    );
  }

  // No cocoon active — offer to start one
  if (data.controller_can_start_cocoon) {
    return (
      <Stack vertical>
        <Stack.Item>
          <Box fontSize="0.8em" color="label" italic>
            No cocoon is active. The ooze can seal its host inside a cocoon,
            which feeds the ooze over time and escalates through four stages.
          </Box>
        </Stack.Item>
        <Stack.Item mt={0.5}>
          <Button
            color="average"
            tooltip="Command the ooze to wrap around and seal its host in a cocoon."
            onClick={() => act('controller_start_cocoon')}
          >
            Start Cocoon
          </Button>
        </Stack.Item>
      </Stack>
    );
  }

  return null;
};

// ── Pending requests ─────────────────────────────────────────────────────────

const PendingRequests = (props: { data: Data }) => {
  const { data } = props;
  const pending = data.controller_pending_requests ?? [];

  return (
    <Section title="Pending Petitions">
      <Stack vertical>
        {pending.map((request) => (
          <Stack.Item key={request.id}>
            <Box mb={0.3}>
              <Box bold>{request.summary}</Box>
              <Box fontSize="0.8em" color="label">
                Expires in {request.expires_in}
              </Box>
            </Box>
            <Box fontSize="0.8em" color="label" italic>
              Awaiting the host&apos;s answer.
            </Box>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

// ── Activity log ─────────────────────────────────────────────────────────────

const ActivityLog = (props: { entries: ControllerActivityEntry[] }) => {
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
    >
      <Box
        style={{ maxHeight: expanded ? '200px' : '120px', overflowY: 'auto' }}
      >
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
            <Box
              inline
              color={ACTIVITY_ACTOR_COLOR[entry.actor] ?? '#aaaaaa'}
              bold
              mr={0.5}
            >
              {entry.actor}
            </Box>
            <Box
              inline
              color={ACTIVITY_SEVERITY_COLOR[entry.severity] ?? '#cccccc'}
            >
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

// ── Status indicators ────────────────────────────────────────────────────────

const Indicators = (props: { data: Data }) => {
  const { data } = props;
  return (
    <Box mt={0.5}>
      {!!data.has_doppelganger && (
        <Box
          fontSize="0.8em"
          color={data.doppel_is_player_controlled ? 'good' : 'average'}
          italic
        >
          ◆ My shaped form is manifest
          {data.doppel_is_player_controlled ? ' and I walk within it.' : '.'}
        </Box>
      )}
      <Box fontSize="0.8em" color="label" italic>
        ◆ Permissions:{' '}
        <Box inline color={data.controller_speech_enabled ? 'good' : 'bad'}>
          speech {data.controller_speech_enabled ? 'on' : 'off'}
        </Box>{' '}
        <Box inline color={data.controller_emote_enabled ? 'good' : 'bad'}>
          emotes {data.controller_emote_enabled ? 'on' : 'off'}
        </Box>{' '}
        <Box inline color={data.controller_manifest_enabled ? 'good' : 'bad'}>
          manifest {data.controller_manifest_enabled ? 'on' : 'off'}
        </Box>
      </Box>
      <Box
        fontSize="0.8em"
        color={data.controller_direct_control_enabled ? 'bad' : 'good'}
        italic
      >
        ◆ Approval wards:{' '}
        {data.controller_direct_control_enabled
          ? 'Lowered by host'
          : 'Host approval required'}
      </Box>
    </Box>
  );
};
