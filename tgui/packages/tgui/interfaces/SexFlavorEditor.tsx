/**
 * SexFlavorEditor.tsx — TGUI interface for Custom Sex Flavor Text.
 *
 * Players write per-character, per-action, per-phase flavor strings that are
 * privately whispered to them during sex actions (additive — the existing
 * visible_message output is never replaced).
 *
 * Layout:
 *   Left panel  — searchable, filterable action list grouped by category.
 *   Right panel — phase tabs → string list → input row → dual preview → token buttons.
 */

import { useEffect, useMemo, useState } from 'react';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { useDebouncedCallback } from '../common/useDebouncedCallback';
import { Window } from '../layouts';
import { ChunkedExportImportSection } from './common/ChunkedExportImportSection';
import {
  ErpPreviewOptionsButton,
  type ErpPreviewProfileData,
  resolveErpPreviewTokens,
} from './common/ErpPreviewOptions';

// ── Types ────────────────────────────────────────────────────────────────────

type ActionEntry = {
  path: string;
  name: string;
  category: number;
  /** TRUE if the player has written custom text for any phase of this action. */
  has_custom: boolean;
  /** TRUE if the character's anatomy supports this action's user_sex_part. */
  can_use: boolean;
};

type CustomActionChoice = {
  key: string;
  label: string;
};

type CustomTemplate = {
  key: string;
  name: string;
  category: number;
  user_sex_part: number;
  target_sex_part: number;
  user_arousal: number;
  target_arousal: number;
  user_pain: number;
  target_pain: number;
  stamina_cost: number;
  requires_other: boolean;
  continuous: boolean;
  sound_course: string;
  animation_type: string;
};

type CustomAction = {
  slot: number;
  name: string;
  template: string;
  on_start_text: string;
  on_perform_text: string;
  on_finish_text: string;
  user_arousal: number;
  target_arousal: number;
  user_pain: number;
  target_pain: number;
  stamina_cost: number;
  category: number;
  user_sex_part: number;
  target_sex_part: number;
  requires_other: boolean;
  continuous: boolean;
  sound_course: string;
  animation_type: string;
  /** 0 = no requirement, 1 = must have chastity, 2 = must NOT have chastity */
  req_user_chastity: number;
  /** 0 = no requirement, 1 = must have chastity, 2 = must NOT have chastity */
  req_target_chastity: number;
  /** 0 = no requirement, 1 = held dildo, 2 = mounted dildo, 3 = any dildo */
  req_toy: number;
  /** User must have any intimate piercing equipped */
  req_user_piercing: boolean;
  /** 0 = no req, 1 = any plug, 2 = rear plug, 3 = anal beads, 4 = genital plug, 5 = sounding rod */
  req_user_plug: number;
  /** Target must have any intimate piercing equipped */
  req_target_piercing: boolean;
  /** 0 = no req, 1 = any plug, 2 = rear plug, 3 = anal beads, 4 = genital plug, 5 = sounding rod */
  req_target_plug: number;
  /** Target's anus must NOT be blocked by a rear plug */
  req_no_rear_plug: boolean;
  /** User must have a manticore tail organ */
  req_user_manticore_tail: boolean;
  /** Target must have a manticore tail organ */
  req_target_manticore_tail: boolean;
};

type BackendData = {
  invalid?: boolean;
  actions: ActionEntry[];
  selected_action: string | null;
  selected_phase: string;
  current_strings: string[];
  /** Parallel weight array (0–100); defaults to 100 for each string. */
  current_weights: number[];
  max_strings: number;
  max_length: number;
  phases: string[];
  /** Whether unsaved changes exist. */
  dirty?: boolean;
  /** Whether the default server-side text is suppressed per phase for the selected action. */
  suppress_defaults: Record<string, boolean>;
  /** Whether the "Show All" actions toggle is active. */
  show_all_actions: boolean;
  /** Custom action templates for the editor. */
  custom_templates: CustomTemplate[];
  /** Sound course choices for custom actions. */
  custom_sound_courses: CustomActionChoice[];
  /** Animation choices for custom actions. */
  custom_animation_types: CustomActionChoice[];
  /** Player's defined custom actions. */
  custom_actions: CustomAction[];
  /** Max custom actions allowed. */
  max_custom_actions: number;
  /** Currently selected custom action slot for editing. */
  selected_custom_slot: number;
  /** Currently selected perspective: "performer", "target", or "observer". */
  selected_perspective: string;
  /** Per-character local token profile for live previews. */
  preview_tokens?: ErpPreviewProfileData;
  export_text?: string;
  export_chunk_count?: number;
  export_payload_bytes?: number;
  status_text?: string;
  status_kind?: 'success' | 'danger' | 'info';
  max_import_text_bytes?: number;
};

// ── Constants ─────────────────────────────────────────────────────────────────

const CATEGORY_LABELS: Record<number, string> = {
  1: 'Miscellaneous',
  2: 'Manual',
  4: 'Penetration',
};

const PHASE_LABELS: Record<string, string> = {
  on_start: 'On Start',
  on_perform: 'During',
  on_finish: 'On Finish',
};

/** Basic tokens the player can insert; resolved server-side at runtime. */
const TOKENS = [
  '[USER]',
  '[TARGET]',
  '[THEY]',
  '[THEM]',
  '[THEIR]',
  '[TTHEY]',
  '[TTHEM]',
  '[TTHEIR]',
  '[FORCE]',
];

/**
 * Tokens that belong to the Intimate Reaction editor, NOT this one.
 * Maps each foreign token to the nearest local equivalent (if any) for the
 * inline "did you mean" hint. `null` means there's no direct analogue.
 */
const FOREIGN_TOKENS: Record<string, string | null> = {
  '[THEIR_CAP]': '[THEIR]',
  '[PENIS_TYPE]': '[UCOCK]',
  '[SHEATH]': '[USHAFT]',
  '[SIZEADJ]': '[USIZE]',
  '[COCKSIZE]': '[USIZE]',
  '[VAGADJ]': '[UVAG]',
  '[VAGTYPE]': '[UVAG]',
  '[CUPADJ]': '[UCUPSIZE]',
  '[CUPSIZE]': '[UCUPSIZE]',
  '[BREASTTYPE]': '[UBREASTTYPE]',
  '[TAUR]': null,
  '[GENITAL_DESC]': null,
  '[PLUG]': null,
};

/** Anatomy-aware tokens resolved from the user/target's actual genitals. */
const ANATOMY_TOKENS: { token: string; tip: string }[] = [
  { token: '[UCOCK]', tip: 'User\'s penis type (e.g. "knotted cock")' },
  { token: '[TCOCK]', tip: "Target's penis type" },
  { token: '[USHAFT]', tip: 'User\'s shaft variant (e.g. "barbed shaft")' },
  { token: '[TSHAFT]', tip: "Target's shaft variant" },
  { token: '[USIZE]', tip: 'User\'s penis size (e.g. "impressive")' },
  { token: '[TSIZE]', tip: "Target's penis size" },
  { token: '[UVAG]', tip: 'User\'s vagina type (e.g. "a delicate slit")' },
  { token: '[TVAG]', tip: "Target's vagina type" },
  { token: '[UCUPSIZE]', tip: 'User\'s breast size (e.g. "plump")' },
  { token: '[TCUPSIZE]', tip: "Target's breast size" },
  {
    token: '[UBREASTTYPE]',
    tip: 'User\'s breast descriptor (e.g. "a perky pair")',
  },
  { token: '[TBREASTTYPE]', tip: "Target's breast descriptor" },
];

/** Phase → preview color mapping (matches in-game span colors). */
const PHASE_COLORS: Record<string, string> = {
  on_start: '#ff5555', // red — span_warning
  on_perform: '#ff88cc', // pink — spanify_force
  on_finish: '#ff5555', // red — span_warning
};

/** Bitflag → label for sex_part display. */
const SEX_PART_FLAGS: { flag: number; label: string }[] = [
  { flag: 1, label: 'Cock' },
  { flag: 2, label: 'Cunt' },
  { flag: 4, label: 'Anus' },
  { flag: 8, label: 'Mouth' },
  { flag: 16, label: 'Slit/Sheath' },
];

/** Category options for custom actions. */
const CATEGORY_OPTIONS: { value: number; label: string }[] = [
  { value: 1, label: 'Miscellaneous' },
  { value: 2, label: 'Manual' },
  { value: 4, label: 'Penetration' },
];

/** Chastity requirement options. */
const CHASTITY_OPTIONS: { value: number; label: string }[] = [
  { value: 0, label: 'No Requirement' },
  { value: 1, label: 'Must Have' },
  { value: 2, label: 'Must NOT Have' },
];

/** Toy requirement options. */
const TOY_OPTIONS: { value: number; label: string }[] = [
  { value: 0, label: 'No Requirement' },
  { value: 1, label: 'Held Dildo' },
  { value: 2, label: 'Mounted Dildo' },
  { value: 3, label: 'Any Dildo' },
];

/** Plug / insertable requirement options. */
const PLUG_OPTIONS: { value: number; label: string }[] = [
  { value: 0, label: 'No Requirement' },
  { value: 1, label: 'Any Plug' },
  { value: 2, label: 'Rear Plug' },
  { value: 3, label: 'Anal Beads' },
  { value: 4, label: 'Genital Plug' },
  { value: 5, label: 'Sounding Rod' },
];

// ── Bitflag toggle helper ─────────────────────────────────────────────────────

function toggleFlag(current: number, flag: number): number {
  return current & flag ? current & ~flag : current | flag;
}

// ── Custom Actions Tab ───────────────────────────────────────────────────────

function CustomActionsTab() {
  const { act, data } = useBackend<BackendData>();
  const templates = data.custom_templates || [];
  const actions = data.custom_actions || [];
  const maxActions = data.max_custom_actions || 5;
  const selectedSlot = data.selected_custom_slot || 0;

  return (
    <Stack vertical>
      {/* ── Create New: template row ── */}
      <Stack.Item>
        <Section
          title={`Create New (${actions.length}/${maxActions} slots used)`}
        >
          <Box fontSize="10px" opacity={0.6} mb={0.5}>
            Pick a template archetype. Body parts and category are pre-filled
            but you can change them after creation.
          </Box>
          <Stack wrap>
            {templates.map((t) => (
              <Stack.Item key={t.key} mr={0.5} mb={0.5}>
                <Button
                  compact
                  icon="plus"
                  disabled={actions.length >= maxActions}
                  onClick={() =>
                    act('create_action', {
                      template: t.key,
                      name: 'My ' + t.name,
                      category: t.category,
                      user_sex_part: t.user_sex_part,
                      target_sex_part: t.target_sex_part,
                      user_arousal: t.user_arousal,
                      target_arousal: t.target_arousal,
                      user_pain: t.user_pain,
                      target_pain: t.target_pain,
                      stamina_cost: t.stamina_cost,
                      requires_other: t.requires_other,
                      continuous: t.continuous,
                      sound_course: t.sound_course,
                      animation_type: t.animation_type,
                    })
                  }
                >
                  {t.name}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Stack.Item>

      {/* ── Action cards: each action gets its own expandable row ── */}
      {actions.length === 0 ? (
        <Stack.Item>
          <NoticeBox>
            No custom actions yet. Pick a template above to get started.
          </NoticeBox>
        </Stack.Item>
      ) : (
        actions.map((a) => (
          <Stack.Item key={a.slot}>
            <Section
              title={
                <Stack align="center">
                  <Stack.Item grow>
                    <Box inline bold>
                      {a.name}
                    </Box>
                    <Box inline opacity={0.5} ml={1} fontSize="10px">
                      Slot {a.slot} &middot;{' '}
                      {CATEGORY_LABELS[a.category] ?? 'Unknown'} &middot; from
                      &ldquo;{a.template}&rdquo;
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      compact
                      icon={
                        a.slot === selectedSlot ? 'chevron-up' : 'chevron-down'
                      }
                      onClick={() =>
                        act('select_custom_slot', {
                          slot: a.slot === selectedSlot ? 0 : a.slot,
                        })
                      }
                    >
                      {a.slot === selectedSlot ? 'Collapse' : 'Edit'}
                    </Button>
                  </Stack.Item>
                </Stack>
              }
            >
              {a.slot === selectedSlot && <CustomActionEditor action={a} />}
            </Section>
          </Stack.Item>
        ))
      )}
    </Stack>
  );
}

// ── Custom Action Editor (inline card) ───────────────────────────────────────

function CustomActionEditor({ action }: { action: CustomAction }) {
  const { act, data } = useBackend<BackendData>();

  // Local state for text fields to avoid spamming backend on every keystroke.
  const [name, setName] = useState(action.name);
  const [startText, setStartText] = useState(action.on_start_text);
  const [performText, setPerformText] = useState(action.on_perform_text);
  const [finishText, setFinishText] = useState(action.on_finish_text);
  const [previewPhase, setPreviewPhase] = useState<
    'on_start' | 'on_perform' | 'on_finish'
  >('on_perform');

  // Sync local state when switching between actions.
  const [lastSlot, setLastSlot] = useState(action.slot);
  if (action.slot !== lastSlot) {
    setName(action.name);
    setStartText(action.on_start_text);
    setPerformText(action.on_perform_text);
    setFinishText(action.on_finish_text);
    setLastSlot(action.slot);
  }

  const previewTextMap: Record<string, string> = {
    on_start: startText,
    on_perform: performText,
    on_finish: finishText,
  };
  const previewText = previewTextMap[previewPhase] || '';
  const soundCourses = data.custom_sound_courses || [];
  const animationTypes = data.custom_animation_types || [];

  /** Push a partial update to backend and save. */
  function update(fields: Record<string, any>) {
    act('update_action', { slot: action.slot, ...fields });
  }

  /** Append a token to the currently-previewed phase's text field. */
  function appendCustomToken(token: string) {
    if (previewPhase === 'on_start') {
      setStartText((prev) => prev + token);
    } else if (previewPhase === 'on_perform') {
      setPerformText((prev) => prev + token);
    } else {
      setFinishText((prev) => prev + token);
    }
  }

  return (
    <Stack vertical>
      {/* ── Row 1: Name ── */}
      <Stack.Item>
        <Stack align="center">
          <Stack.Item grow>
            <Box fontSize="11px" bold mb={0.25}>
              Action Name
            </Box>
            <Input
              fluid
              value={name}
              maxLength={80}
              onChange={(v) => setName(v)}
              onBlur={() => update({ name })}
            />
          </Stack.Item>
          <Stack.Item ml={1}>
            <Button
              icon="trash"
              color="bad"
              onClick={() => act('delete_action', { slot: action.slot })}
            >
              Delete
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* ── Row 2: Stats + Category + Options — all in one row ── */}
      <Stack.Item mt={0.5}>
        <Box fontSize="11px" bold mb={0.25}>
          Stats &amp; Options
        </Box>
        <Stack wrap align="center">
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7}>
              User Arousal
            </Box>
            <NumberInput
              width="55px"
              value={action.user_arousal}
              minValue={0}
              maxValue={5}
              step={1}
              onChange={(v) => update({ user_arousal: v })}
            />
          </Stack.Item>
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7}>
              Target Arousal
            </Box>
            <NumberInput
              width="55px"
              value={action.target_arousal}
              minValue={0}
              maxValue={5}
              step={1}
              onChange={(v) => update({ target_arousal: v })}
            />
          </Stack.Item>
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7}>
              User Pain
            </Box>
            <NumberInput
              width="55px"
              value={action.user_pain}
              minValue={0}
              maxValue={15}
              step={1}
              onChange={(v) => update({ user_pain: v })}
            />
          </Stack.Item>
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7}>
              Target Pain
            </Box>
            <NumberInput
              width="55px"
              value={action.target_pain}
              minValue={0}
              maxValue={15}
              step={1}
              onChange={(v) => update({ target_pain: v })}
            />
          </Stack.Item>
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7}>
              Stamina Cost
            </Box>
            <NumberInput
              width="55px"
              value={action.stamina_cost}
              minValue={0}
              maxValue={3}
              step={1}
              onChange={(v) => update({ stamina_cost: v })}
            />
          </Stack.Item>
          <Stack.Item mr={0.5} mb={0.5}>
            <Box inline opacity={0.2}>
              |
            </Box>
          </Stack.Item>
          {CATEGORY_OPTIONS.map((opt) => (
            <Stack.Item key={opt.value} mr={0.5} mb={0.5}>
              <Button
                compact
                selected={action.category === opt.value}
                onClick={() => update({ category: opt.value })}
              >
                {opt.label}
              </Button>
            </Stack.Item>
          ))}
          <Stack.Item mr={0.5} mb={0.5}>
            <Box inline opacity={0.2}>
              |
            </Box>
          </Stack.Item>
          <Stack.Item mr={0.5} mb={0.5}>
            <Button
              compact
              color={action.requires_other ? 'default' : 'transparent'}
              selected={!!action.requires_other}
              onClick={() => update({ requires_other: !action.requires_other })}
            >
              {action.requires_other ? '✓ Requires Partner' : '✗ Solo OK'}
            </Button>
          </Stack.Item>
          <Stack.Item mb={0.5}>
            <Button
              compact
              color={action.continuous ? 'default' : 'transparent'}
              selected={!!action.continuous}
              onClick={() => update({ continuous: !action.continuous })}
            >
              {action.continuous ? '✓ Continuous' : '✗ One-shot'}
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Row 3: Feedback */}
      <Stack.Item mt={0.5}>
        <Box fontSize="11px" bold mb={0.25}>
          Feedback
        </Box>
        <Stack wrap align="center">
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Sound
            </Box>
            {soundCourses.map((opt) => (
              <Button
                key={opt.key}
                compact
                selected={action.sound_course === opt.key}
                color={
                  action.sound_course === opt.key ? 'default' : 'transparent'
                }
                onClick={() => update({ sound_course: opt.key })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
          <Stack.Item mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Animation
            </Box>
            {animationTypes.map((opt) => (
              <Button
                key={opt.key}
                compact
                selected={action.animation_type === opt.key}
                color={
                  action.animation_type === opt.key ? 'default' : 'transparent'
                }
                onClick={() => update({ animation_type: opt.key })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Row 4: Body Parts */}
      <Stack.Item mt={0.5}>
        <Box fontSize="11px" bold mb={0.25}>
          Body Parts
        </Box>
        <Stack wrap align="center">
          <Stack.Item mr={2}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              User uses:
            </Box>
            {SEX_PART_FLAGS.map((sp) => (
              <Button
                key={sp.flag}
                compact
                color={
                  action.user_sex_part & sp.flag ? 'default' : 'transparent'
                }
                selected={!!(action.user_sex_part & sp.flag)}
                onClick={() =>
                  update({
                    user_sex_part: toggleFlag(action.user_sex_part, sp.flag),
                  })
                }
              >
                {action.user_sex_part & sp.flag ? '✓' : '–'} {sp.label}
              </Button>
            ))}
          </Stack.Item>
          <Stack.Item>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Target uses:
            </Box>
            {SEX_PART_FLAGS.map((sp) => (
              <Button
                key={sp.flag}
                compact
                color={
                  action.target_sex_part & sp.flag ? 'default' : 'transparent'
                }
                selected={!!(action.target_sex_part & sp.flag)}
                onClick={() =>
                  update({
                    target_sex_part: toggleFlag(
                      action.target_sex_part,
                      sp.flag,
                    ),
                  })
                }
              >
                {action.target_sex_part & sp.flag ? '✓' : '–'} {sp.label}
              </Button>
            ))}
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Row 5: Requirements */}
      <Stack.Item mt={0.5}>
        <Box fontSize="11px" bold mb={0.25}>
          Requirements
        </Box>
        <Box fontSize="10px" opacity={0.5} mb={0.5}>
          These restrict when the action appears in the menu. &ldquo;No
          Req&rdquo; means no restriction.
        </Box>
        <Stack wrap align="center">
          {/* Chastity tri-state selectors */}
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              User Chastity:
            </Box>
            {CHASTITY_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                compact
                selected={action.req_user_chastity === opt.value}
                color={
                  action.req_user_chastity === opt.value
                    ? opt.value === 1
                      ? 'good'
                      : opt.value === 2
                        ? 'bad'
                        : 'default'
                    : 'transparent'
                }
                onClick={() => update({ req_user_chastity: opt.value })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Target Chastity:
            </Box>
            {CHASTITY_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                compact
                selected={action.req_target_chastity === opt.value}
                color={
                  action.req_target_chastity === opt.value
                    ? opt.value === 1
                      ? 'good'
                      : opt.value === 2
                        ? 'bad'
                        : 'default'
                    : 'transparent'
                }
                onClick={() => update({ req_target_chastity: opt.value })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
          <Stack.Item mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Toy Requirement:
            </Box>
            {TOY_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                compact
                selected={action.req_toy === opt.value}
                color={
                  action.req_toy === opt.value
                    ? opt.value > 0
                      ? 'good'
                      : 'default'
                    : 'transparent'
                }
                onClick={() => update({ req_toy: opt.value })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
        </Stack>
        {/* Boolean accessory requirements — green = required, transparent = not */}
        <Stack wrap align="center" mt={0.5}>
          <Stack.Item mr={1} mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              User Plug/Insertable:
            </Box>
            {PLUG_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                compact
                selected={action.req_user_plug === opt.value}
                color={
                  action.req_user_plug === opt.value
                    ? opt.value > 0
                      ? 'good'
                      : 'default'
                    : 'transparent'
                }
                onClick={() => update({ req_user_plug: opt.value })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
          <Stack.Item mb={0.5}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Target Plug/Insertable:
            </Box>
            {PLUG_OPTIONS.map((opt) => (
              <Button
                key={opt.value}
                compact
                selected={action.req_target_plug === opt.value}
                color={
                  action.req_target_plug === opt.value
                    ? opt.value > 0
                      ? 'good'
                      : 'default'
                    : 'transparent'
                }
                onClick={() => update({ req_target_plug: opt.value })}
              >
                {opt.label}
              </Button>
            ))}
          </Stack.Item>
        </Stack>
        <Stack wrap align="center" mt={0.5}>
          <Stack.Item mr={1}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              User must have:
            </Box>
            <Button
              compact
              color={action.req_user_piercing ? 'good' : 'transparent'}
              onClick={() =>
                update({ req_user_piercing: !action.req_user_piercing })
              }
            >
              {action.req_user_piercing ? '✓ Piercing' : '– Piercing'}
            </Button>
            <Button
              compact
              color={action.req_user_manticore_tail ? 'good' : 'transparent'}
              onClick={() =>
                update({
                  req_user_manticore_tail: !action.req_user_manticore_tail,
                })
              }
            >
              {action.req_user_manticore_tail
                ? '✓ Manticore Tail'
                : '– Manticore Tail'}
            </Button>
          </Stack.Item>
          <Stack.Item mr={1}>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Target must have:
            </Box>
            <Button
              compact
              color={action.req_target_piercing ? 'good' : 'transparent'}
              onClick={() =>
                update({ req_target_piercing: !action.req_target_piercing })
              }
            >
              {action.req_target_piercing ? '✓ Piercing' : '– Piercing'}
            </Button>
            <Button
              compact
              color={action.req_target_manticore_tail ? 'good' : 'transparent'}
              onClick={() =>
                update({
                  req_target_manticore_tail: !action.req_target_manticore_tail,
                })
              }
            >
              {action.req_target_manticore_tail
                ? '✓ Manticore Tail'
                : '– Manticore Tail'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Box fontSize="10px" opacity={0.7} mb={0.25}>
              Blocking:
            </Box>
            <Button
              compact
              color={action.req_no_rear_plug ? 'bad' : 'transparent'}
              onClick={() =>
                update({ req_no_rear_plug: !action.req_no_rear_plug })
              }
            >
              {action.req_no_rear_plug
                ? '✗ Target Rear Must Be FREE'
                : '– Rear Plug OK'}
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Row 6: Flavor Text + Live Preview */}
      <Stack.Item mt={0.5}>
        <Box fontSize="11px" bold mb={0.25}>
          Flavor Text
        </Box>
        <Box fontSize="10px" opacity={0.5} mb={0.5}>
          Tokens are resolved at runtime from the actual characters. Click a
          token below to insert it into the active phase.
        </Box>
        {/* Phase tabs for selecting which text to preview */}
        <Tabs>
          <Tabs.Tab
            selected={previewPhase === 'on_start'}
            onClick={() => setPreviewPhase('on_start')}
          >
            On Start
          </Tabs.Tab>
          <Tabs.Tab
            selected={previewPhase === 'on_perform'}
            onClick={() => setPreviewPhase('on_perform')}
          >
            During (Each Cycle)
          </Tabs.Tab>
          <Tabs.Tab
            selected={previewPhase === 'on_finish'}
            onClick={() => setPreviewPhase('on_finish')}
          >
            On Finish
          </Tabs.Tab>
        </Tabs>
        <Stack vertical>
          <Stack.Item mb={0.5}>
            <TextArea
              fluid
              height="4rem"
              value={startText}
              onChange={(v) => setStartText(v)}
              onBlur={() => update({ on_start_text: startText })}
              style={
                previewPhase === 'on_start'
                  ? { border: '1px solid #4fc3f7' }
                  : undefined
              }
            />
            <Box fontSize="9px" opacity={0.4}>
              On Start
            </Box>
          </Stack.Item>
          <Stack.Item mb={0.5}>
            <TextArea
              fluid
              height="4rem"
              value={performText}
              onChange={(v) => setPerformText(v)}
              onBlur={() => update({ on_perform_text: performText })}
              style={
                previewPhase === 'on_perform'
                  ? { border: '1px solid #4fc3f7' }
                  : undefined
              }
            />
            <Box fontSize="9px" opacity={0.4}>
              During
            </Box>
          </Stack.Item>
          <Stack.Item mb={0.5}>
            <TextArea
              fluid
              height="4rem"
              value={finishText}
              onChange={(v) => setFinishText(v)}
              onBlur={() => update({ on_finish_text: finishText })}
              style={
                previewPhase === 'on_finish'
                  ? { border: '1px solid #4fc3f7' }
                  : undefined
              }
            />
            <Box fontSize="9px" opacity={0.4}>
              On Finish
            </Box>
          </Stack.Item>
          {/* Token insertion buttons */}
          <Stack.Item>
            <Box opacity={0.7} fontSize="10px" mb={0.25}>
              Basic:
            </Box>
            <Stack wrap>
              {TOKENS.map((token) => (
                <Stack.Item key={token}>
                  <Button
                    compact
                    color="transparent"
                    onClick={() => appendCustomToken(token)}
                  >
                    {token}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
          <Stack.Item>
            <Box opacity={0.7} fontSize="10px" mb={0.25}>
              Anatomy (resolves from character):
            </Box>
            <Stack wrap>
              {ANATOMY_TOKENS.map(({ token, tip }) => (
                <Stack.Item key={token}>
                  <Button
                    compact
                    color="transparent"
                    tooltip={tip}
                    onClick={() => appendCustomToken(token)}
                  >
                    {token}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
          {/* Live preview */}
          {previewText.trim().length > 0 && (
            <Stack.Item mt={0.5}>
              <Stack>
                <Stack.Item grow basis="50%">
                  <Box opacity={0.7} fontSize="10px" mb={0.25}>
                    Preview (Giving):
                  </Box>
                  <Box
                    p={0.5}
                    italic
                    style={{
                      background: 'rgba(0,0,0,0.4)',
                      borderRadius: '3px',
                      border: '1px solid rgba(255,255,255,0.1)',
                      fontSize: '12px',
                      color: PHASE_COLORS[previewPhase] ?? '#fff',
                    }}
                  >
                    {resolveErpPreviewTokens(
                      previewText,
                      'sex-giving',
                      data.preview_tokens,
                    )}
                  </Box>
                </Stack.Item>
                <Stack.Item grow basis="50%" ml={0.5}>
                  <Box opacity={0.7} fontSize="10px" mb={0.25}>
                    Preview (Receiving):
                  </Box>
                  <Box
                    p={0.5}
                    italic
                    style={{
                      background: 'rgba(0,0,0,0.4)',
                      borderRadius: '3px',
                      border: '1px solid rgba(255,255,255,0.1)',
                      fontSize: '12px',
                      color: PHASE_COLORS[previewPhase] ?? '#fff',
                    }}
                  >
                    {resolveErpPreviewTokens(
                      previewText,
                      'sex-receiving',
                      data.preview_tokens,
                    )}
                  </Box>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          )}
          <Stack.Item>
            <ErpPreviewOptionsButton profile={data.preview_tokens} act={act} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}

// ── Main Component ───────────────────────────────────────────────────────────

/**
 * Per-row NumberInput that debounces the `onCommit` act call so rapid drags
 * fire exactly one server-side update ~300 ms after the last change instead
 * of one per tick. Instantiated per list row so each row has its own timer.
 */
function DebouncedWeightInput({
  value,
  onCommit,
}: {
  value: number;
  onCommit: (weight: number) => void;
}) {
  const debounced = useDebouncedCallback(onCommit, 300);
  return (
    <NumberInput
      width="55px"
      step={5}
      stepPixelSize={4}
      value={value}
      minValue={0}
      maxValue={100}
      onChange={(next) => debounced(next)}
    />
  );
}

export function SexFlavorEditor() {
  const { act, data } = useBackend<BackendData>();

  const [inputText, setInputText] = useState('');
  const [searchText, setSearchText] = useState('');
  const [mainTab, setMainTab] = useState<'flavors' | 'custom'>('flavors');
  const [showTransfer, setShowTransfer] = useState(false);
  /** Index (0-based) of the custom string being edited, or -1 for "add new" mode. */
  const [editingIndex, setEditingIndex] = useState(-1);
  /** Which category sections are expanded in the action list. */
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(
    new Set(),
  );

  // Reset in-progress edit state when the user switches action, phase, or
  // perspective so a stale Update fire can't overwrite the wrong row in the
  // new context (current_strings identity changes on perspective switch too).
  useEffect(() => {
    setEditingIndex(-1);
    setInputText('');
  }, [data.selected_action, data.selected_phase, data.selected_perspective]);

  if (data.invalid) {
    return (
      <Window title="Sex Flavor Text Editor" width={960} height={760}>
        <Window.Content>
          <NoticeBox danger>
            Session invalid. Close and reopen the editor.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const {
    actions = [],
    selected_action,
    selected_phase,
    current_strings = [],
    current_weights = [],
    max_strings,
    max_length,
    phases,
    suppress_defaults = {},
    show_all_actions = false,
  } = data;

  // Filter actions: hide unusable actions unless Show All is on, then apply search.
  const filteredActions = useMemo(() => {
    const q = searchText.trim().toLowerCase();
    return actions
      .filter((a) => {
        if (!show_all_actions && !a.can_use) return false;
        if (q && !a.name.toLowerCase().includes(q)) return false;
        return true;
      })
      .sort((a, b) => {
        // Modified actions first, then alphabetical.
        if (a.has_custom !== b.has_custom) return a.has_custom ? -1 : 1;
        return a.name.localeCompare(b.name);
      });
  }, [actions, searchText, show_all_actions]);

  // Group filtered actions by category.
  const grouped: Record<string, ActionEntry[]> = {};
  for (const entry of filteredActions) {
    const label = CATEGORY_LABELS[entry.category] ?? 'Other';
    if (!grouped[label]) grouped[label] = [];
    grouped[label].push(entry);
  }

  const isEditing = editingIndex >= 0;
  const canAdd =
    inputText.trim().length > 0 &&
    (isEditing || current_strings.length < max_strings);

  function handleAddOrUpdate() {
    const trimmed = inputText.trim();
    if (!trimmed || !selected_action) return;
    if (isEditing) {
      act('update_string', { index: editingIndex + 1, text: trimmed });
      setEditingIndex(-1);
    } else {
      act('add_string', { text: trimmed });
    }
    setInputText('');
  }

  function cancelEdit() {
    setEditingIndex(-1);
    setInputText('');
  }

  function appendToken(token: string) {
    setInputText((prev) => prev + token);
  }

  return (
    <Window title="Sex Flavor Text Editor" width={960} height={760}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {/* ── Main tab bar ─────────────────────────────────────────────── */}
          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Tabs>
                  <Tabs.Tab
                    selected={mainTab === 'flavors'}
                    onClick={() => setMainTab('flavors')}
                  >
                    Flavor Text
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={mainTab === 'custom'}
                    onClick={() => setMainTab('custom')}
                  >
                    Custom Actions ({(data.custom_actions || []).length}/
                    {data.max_custom_actions || 5})
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="save"
                  color={data.dirty ? 'caution' : 'green'}
                  onClick={() => act('save')}
                >
                  {data.dirty ? 'Save' : 'Saved'}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="file-export"
                  onClick={() => {
                    setShowTransfer(true);
                    act('generate_export');
                  }}
                >
                  Export
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="file-import"
                  selected={showTransfer}
                  onClick={() => setShowTransfer(!showTransfer)}
                >
                  Import
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          {/* Export / import panel (toggled) */}
          {showTransfer && (
            <Stack.Item>
              <ChunkedExportImportSection
                act={act}
                exportText={data.export_text}
                exportChunkCount={data.export_chunk_count}
                exportPayloadBytes={data.export_payload_bytes}
                statusText={data.status_text}
                statusKind={data.status_kind}
                maxImportTextBytes={data.max_import_text_bytes}
                exportAriaLabel="Sex flavor export text"
                importAriaLabel="Sex flavor import text"
                exportDescription="Generated custom sex editor exports stay in this panel instead of being printed into chat."
                importDescription="Import overwrites your current sex flavor text and custom actions. Generate an export first if you want a backup."
                importPlaceholder="Paste custom sex editor export text here"
                overwriteLabel="Overwrite sex flavor data"
              />
            </Stack.Item>
          )}

          {mainTab === 'custom' ? (
            <Stack.Item grow>
              <CustomActionsTab />
            </Stack.Item>
          ) : (
            <Stack.Item grow>
              <Stack fill>
                {/* ── Left: action list ─────────────────────────────────────────── */}
                <Stack.Item
                  width="240px"
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    borderRight: '1px solid rgba(255,255,255,0.15)',
                    paddingRight: '6px',
                  }}
                >
                  {/* Search filter */}
                  <Box mb={0.5}>
                    <Input
                      fluid
                      placeholder="Search actions…"
                      value={searchText}
                      onChange={(val) => setSearchText(val)}
                    />
                  </Box>
                  {/* Show All toggle */}
                  <Box mb={0.5}>
                    <Button
                      fluid
                      icon={show_all_actions ? 'eye' : 'eye-slash'}
                      color={show_all_actions ? 'default' : 'transparent'}
                      onClick={() => act('toggle_show_all')}
                    >
                      {show_all_actions
                        ? 'Showing All Actions'
                        : 'Showing Available Only'}
                    </Button>
                  </Box>
                  {/* Scrollable action list — collapsible categories */}
                  <Box style={{ flex: 1, overflowY: 'auto' }}>
                    {Object.entries(grouped).map(([category, entries]) => {
                      // Auto-expand the category containing the selected action.
                      const containsSelected = entries.some(
                        (e) => e.path === selected_action,
                      );
                      const isExpanded =
                        containsSelected || expandedCategories.has(category);
                      const customCount = entries.filter(
                        (e) => e.has_custom,
                      ).length;
                      return (
                        <Box key={category} mt={0.5}>
                          <Button
                            fluid
                            color="transparent"
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              padding: '4px 6px',
                              background: 'rgba(255,255,255,0.07)',
                              borderRadius: '3px',
                              fontWeight: 'bold',
                              fontSize: '11px',
                            }}
                            onClick={() =>
                              setExpandedCategories((prev) => {
                                const next = new Set(prev);
                                if (next.has(category)) {
                                  next.delete(category);
                                } else {
                                  next.add(category);
                                }
                                return next;
                              })
                            }
                          >
                            <Box
                              inline
                              mr={0.5}
                              style={{
                                fontSize: '10px',
                                width: '1em',
                                textAlign: 'center',
                              }}
                            >
                              {isExpanded ? '▾' : '▸'}
                            </Box>
                            {category}
                            <Box
                              inline
                              ml={0.5}
                              opacity={0.5}
                              style={{ fontSize: '10px' }}
                            >
                              ({entries.length})
                            </Box>
                            {customCount > 0 && (
                              <span
                                aria-label={`${customCount} modified`}
                                style={{
                                  color: '#5eff5e',
                                  marginLeft: '4px',
                                  fontSize: '10px',
                                }}
                              >
                                ✎{customCount}
                              </span>
                            )}
                          </Button>
                          {isExpanded &&
                            entries.map((entry) => {
                              const isSelected = entry.path === selected_action;
                              return (
                                <Button
                                  key={entry.path}
                                  fluid
                                  selected={isSelected}
                                  color={
                                    !entry.can_use ? 'transparent' : undefined
                                  }
                                  style={{
                                    marginLeft: '8px',
                                    ...(isSelected
                                      ? {
                                          outline:
                                            '2px solid rgba(255,255,255,0.65)',
                                          outlineOffset: '-2px',
                                          fontWeight: 'bold',
                                        }
                                      : {}),
                                    ...(!entry.can_use ? { opacity: 0.5 } : {}),
                                  }}
                                  onClick={() =>
                                    act('select_action', { path: entry.path })
                                  }
                                >
                                  {!!entry.has_custom && (
                                    <span
                                      aria-label="modified"
                                      title="Modified from default"
                                      style={{
                                        color: '#5eff5e',
                                        marginRight: '4px',
                                        fontSize: '10px',
                                      }}
                                    >
                                      ✎
                                    </span>
                                  )}
                                  {entry.name}
                                </Button>
                              );
                            })}
                        </Box>
                      );
                    })}
                  </Box>
                </Stack.Item>

                {/* ── Right: editor panel ───────────────────────────────────────── */}
                <Stack.Item
                  grow
                  style={{ display: 'flex', flexDirection: 'column' }}
                >
                  {!selected_action ? (
                    <NoticeBox mt={2}>
                      Select an action on the left to begin editing.
                    </NoticeBox>
                  ) : (
                    <Stack vertical fill>
                      {/* Phase tabs */}
                      <Stack.Item>
                        <Tabs>
                          {phases.map((phase) => (
                            <Tabs.Tab
                              key={phase}
                              selected={phase === selected_phase}
                              onClick={() => act('select_phase', { phase })}
                            >
                              {PHASE_LABELS[phase] ?? phase}
                            </Tabs.Tab>
                          ))}
                        </Tabs>
                      </Stack.Item>

                      {/* Suppress default text toggle */}
                      <Stack.Item>
                        <Section>
                          <Stack align="center">
                            <Stack.Item grow>
                              <Box fontSize="11px">
                                {suppress_defaults[selected_phase]
                                  ? 'Default game text for this phase is suppressed — only your custom strings fire.'
                                  : 'Default game text for this phase is active alongside your custom strings.'}
                              </Box>
                            </Stack.Item>
                            <Stack.Item>
                              <Button
                                icon={
                                  suppress_defaults[selected_phase]
                                    ? 'eye-slash'
                                    : 'eye'
                                }
                                color={
                                  suppress_defaults[selected_phase]
                                    ? 'bad'
                                    : 'default'
                                }
                                onClick={() =>
                                  act('toggle_suppress', {
                                    phase: selected_phase,
                                  })
                                }
                              >
                                {suppress_defaults[selected_phase]
                                  ? 'Default: OFF'
                                  : 'Default: ON'}
                              </Button>
                            </Stack.Item>
                          </Stack>
                        </Section>
                      </Stack.Item>

                      {/* ── Perspective selector ── */}
                      <Stack.Item>
                        <Section title="Perspective">
                          {/* Perspective toggle */}
                          <Box mb={0.5}>
                            <Box fontSize="10px" opacity={0.6} mb={0.25}>
                              Perspective:
                            </Box>
                            <Stack>
                              <Stack.Item>
                                <Button
                                  icon="user"
                                  selected={
                                    data.selected_perspective === 'performer'
                                  }
                                  onClick={() =>
                                    act('select_perspective', {
                                      perspective: 'performer',
                                    })
                                  }
                                >
                                  As Performer
                                </Button>
                              </Stack.Item>
                              <Stack.Item>
                                <Button
                                  icon="bullseye"
                                  selected={
                                    data.selected_perspective === 'target'
                                  }
                                  onClick={() =>
                                    act('select_perspective', {
                                      perspective: 'target',
                                    })
                                  }
                                >
                                  As Target
                                </Button>
                              </Stack.Item>
                              <Stack.Item>
                                <Button
                                  icon="eye"
                                  selected={
                                    data.selected_perspective === 'observer'
                                  }
                                  onClick={() =>
                                    act('select_perspective', {
                                      perspective: 'observer',
                                    })
                                  }
                                >
                                  As Observer
                                </Button>
                              </Stack.Item>
                              <Stack.Item grow>
                                <Box
                                  inline
                                  opacity={0.5}
                                  fontSize="10px"
                                  ml={1}
                                  mt={0.5}
                                >
                                  {data.selected_perspective === 'performer'
                                    ? 'Text YOUR TARGET sees when you perform this action on them.'
                                    : data.selected_perspective === 'target'
                                      ? 'Text THE PERFORMER sees when someone does this action to you.'
                                      : 'Text BYSTANDERS see (only when you suppress defaults).'}
                                </Box>
                              </Stack.Item>
                            </Stack>
                          </Box>
                        </Section>
                      </Stack.Item>

                      {/* ── Input area + preview (FIXED AT TOP) ── */}
                      <Stack.Item>
                        <Section
                          title={
                            isEditing
                              ? `Editing String #${editingIndex + 1}`
                              : undefined
                          }
                        >
                          <Stack vertical>
                            {/* TextArea for writing flavor strings */}
                            <Stack.Item>
                              <Stack>
                                <Stack.Item grow>
                                  <TextArea
                                    fluid
                                    height="5rem"
                                    maxLength={max_length}
                                    placeholder={
                                      isEditing
                                        ? 'Edit this string…'
                                        : `Write a flavor string… (max ${max_length} chars)`
                                    }
                                    value={inputText}
                                    onChange={(val) => setInputText(val)}
                                  />
                                </Stack.Item>
                                <Stack.Item>
                                  {isEditing ? (
                                    <>
                                      <Button
                                        icon="check"
                                        color="good"
                                        disabled={!canAdd}
                                        onClick={handleAddOrUpdate}
                                      >
                                        Update
                                      </Button>
                                      <Button icon="times" onClick={cancelEdit}>
                                        Cancel
                                      </Button>
                                    </>
                                  ) : (
                                    <Button
                                      icon="plus"
                                      color="good"
                                      disabled={!canAdd}
                                      onClick={handleAddOrUpdate}
                                    >
                                      Add
                                    </Button>
                                  )}
                                </Stack.Item>
                              </Stack>
                            </Stack.Item>

                            {/* Foreign-token hint (non-blocking): warn if user typed IR-only tokens */}
                            {(() => {
                              const foreignHits = Object.keys(
                                FOREIGN_TOKENS,
                              ).filter((t) => inputText.includes(t));
                              if (!foreignHits.length) return null;
                              return (
                                <Stack.Item>
                                  <Box fontSize="10px" color="average">
                                    {foreignHits.map((t) => {
                                      const suggested = FOREIGN_TOKENS[t];
                                      return (
                                        <Box key={t}>
                                          {suggested
                                            ? `Did you mean ${suggested}? ${t} is for the Intimate Reaction editor.`
                                            : `${t} is for the Intimate Reaction editor and won't resolve here.`}
                                        </Box>
                                      );
                                    })}
                                  </Box>
                                </Stack.Item>
                              );
                            })()}

                            {/* Token buttons */}
                            <Stack.Item>
                              <Box opacity={0.7} fontSize="10px" mb={0.25}>
                                Basic:
                              </Box>
                              <Stack wrap>
                                {TOKENS.map((token) => (
                                  <Stack.Item key={token}>
                                    <Button
                                      compact
                                      color="transparent"
                                      onClick={() => appendToken(token)}
                                    >
                                      {token}
                                    </Button>
                                  </Stack.Item>
                                ))}
                              </Stack>
                            </Stack.Item>
                            <Stack.Item>
                              <Box opacity={0.7} fontSize="10px" mb={0.25}>
                                Anatomy (resolves from character):
                              </Box>
                              <Stack wrap>
                                {ANATOMY_TOKENS.map(({ token, tip }) => (
                                  <Stack.Item key={token}>
                                    <Button
                                      compact
                                      color="transparent"
                                      tooltip={tip}
                                      onClick={() => appendToken(token)}
                                    >
                                      {token}
                                    </Button>
                                  </Stack.Item>
                                ))}
                              </Stack>
                            </Stack.Item>

                            {/* Live dual preview — giving & receiving */}
                            {inputText.trim().length > 0 && (
                              <Stack.Item>
                                <Stack>
                                  <Stack.Item grow basis="50%">
                                    <Box
                                      opacity={0.7}
                                      fontSize="10px"
                                      mb={0.25}
                                    >
                                      Preview (Giving):
                                    </Box>
                                    <Box
                                      p={0.5}
                                      italic
                                      style={{
                                        background: 'rgba(0,0,0,0.4)',
                                        borderRadius: '3px',
                                        border:
                                          '1px solid rgba(255,255,255,0.1)',
                                        fontSize: '12px',
                                        color:
                                          PHASE_COLORS[selected_phase] ??
                                          '#ffffff',
                                      }}
                                    >
                                      {resolveErpPreviewTokens(
                                        inputText,
                                        'sex-giving',
                                        data.preview_tokens,
                                      )}
                                    </Box>
                                  </Stack.Item>
                                  <Stack.Item grow basis="50%" ml={0.5}>
                                    <Box
                                      opacity={0.7}
                                      fontSize="10px"
                                      mb={0.25}
                                    >
                                      Preview (Receiving):
                                    </Box>
                                    <Box
                                      p={0.5}
                                      italic
                                      style={{
                                        background: 'rgba(0,0,0,0.4)',
                                        borderRadius: '3px',
                                        border:
                                          '1px solid rgba(255,255,255,0.1)',
                                        fontSize: '12px',
                                        color:
                                          PHASE_COLORS[selected_phase] ??
                                          '#ffffff',
                                      }}
                                    >
                                      {resolveErpPreviewTokens(
                                        inputText,
                                        'sex-receiving',
                                        data.preview_tokens,
                                      )}
                                    </Box>
                                  </Stack.Item>
                                </Stack>
                              </Stack.Item>
                            )}
                            <Stack.Item>
                              <ErpPreviewOptionsButton
                                profile={data.preview_tokens}
                                act={act}
                              />
                            </Stack.Item>
                          </Stack>
                        </Section>
                      </Stack.Item>

                      {/* ── String list (SCROLLS INDEPENDENTLY) ── */}
                      <Stack.Item
                        grow
                        style={{ overflowY: 'auto', minHeight: 0 }}
                      >
                        <Section
                          title={`Custom Strings (${current_strings.length}/${max_strings})`}
                        >
                          {current_strings.length === 0 ? (
                            <Box opacity={0.5} italic>
                              No custom strings for this phase yet.
                            </Box>
                          ) : (
                            current_strings.map((str, idx) => (
                              <Stack
                                key={idx}
                                align="center"
                                mb={0.5}
                                style={
                                  editingIndex === idx
                                    ? {
                                        background: 'rgba(79,195,247,0.15)',
                                        borderRadius: '3px',
                                        padding: '2px 4px',
                                      }
                                    : undefined
                                }
                              >
                                <Stack.Item grow>
                                  <div
                                    role="button"
                                    tabIndex={0}
                                    aria-label={`Edit string ${idx + 1}`}
                                    style={{
                                      padding: '4px',
                                      background: 'rgba(255,255,255,0.06)',
                                      borderRadius: '3px',
                                      fontSize: '11px',
                                      cursor: 'pointer',
                                    }}
                                    onClick={() => {
                                      setEditingIndex(idx);
                                      setInputText(str);
                                    }}
                                    onKeyDown={(e) => {
                                      if (e.key === 'Enter' || e.key === ' ') {
                                        e.preventDefault();
                                        setEditingIndex(idx);
                                        setInputText(str);
                                      }
                                    }}
                                  >
                                    {str}
                                  </div>
                                </Stack.Item>
                                <Stack.Item>
                                  <Button
                                    icon="pencil"
                                    compact
                                    tooltip="Edit this string"
                                    onClick={() => {
                                      setEditingIndex(idx);
                                      setInputText(str);
                                    }}
                                  />
                                </Stack.Item>
                                <Stack.Item>
                                  <DebouncedWeightInput
                                    value={current_weights[idx] ?? 100}
                                    onCommit={(value) =>
                                      act('set_weight', {
                                        index: idx + 1,
                                        weight: value,
                                      })
                                    }
                                  />
                                </Stack.Item>
                                <Stack.Item>
                                  <Box fontSize="10px" opacity={0.6}>
                                    %
                                  </Box>
                                </Stack.Item>
                                <Stack.Item>
                                  <Button
                                    icon="times"
                                    color="bad"
                                    compact
                                    onClick={() => {
                                      if (editingIndex === idx) {
                                        setEditingIndex(-1);
                                        setInputText('');
                                      }
                                      act('remove_string', { index: idx + 1 });
                                    }}
                                  />
                                </Stack.Item>
                              </Stack>
                            ))
                          )}
                          {/* Clear all button at the bottom of the list */}
                          {current_strings.length > 0 && (
                            <Box mt={1}>
                              <Button
                                icon="trash"
                                color="bad"
                                compact
                                onClick={() => act('clear_action')}
                              >
                                Clear all strings for this action
                              </Button>
                            </Box>
                          )}
                        </Section>
                      </Stack.Item>
                    </Stack>
                  )}
                </Stack.Item>
              </Stack>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
}
