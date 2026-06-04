/**
 * IntimateReactionEditor.tsx â€” TGUI interface for Intimate Reaction Text.
 *
 * Allows players to write per-character flavor strings for movement
 * descriptions, body exposure, and sex-action reactions. These strings
 * are displayed via the character_flavor component even without intimate
 * accessories equipped.
 *
 * Layout:
 *   Top bar     â€” save / export / import.
 *   Left panel  â€” bank selector, category list, visibility info.
 *   Right panel â€” default strings, input row, dual preview, token reference,
 *                 custom strings list.
 */

import { useState } from 'react';
import {
  Box,
  Button,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { useDebouncedCallback } from '../common/useDebouncedCallback';
import { Window } from '../layouts';
import { ChunkedExportImportSection } from './common/ChunkedExportImportSection';
import {
  ErpPreviewOptionsButton,
  type ErpPreviewProfileData,
} from './common/ErpPreviewOptions';
import { resolveIntimateReactionPreviewTokens } from './IntimateReactionEditorUtils';

// ______ Types ____________________________________________________________________________________________________________________________________________________________________________________________________________

type Bank = {
  id: string;
  label: string;
  available: boolean;
  desc?: string;
};

type AudienceOption = {
  id: string;
  label: string;
  desc?: string;
};

type Category = {
  key: string;
  label: string;
  count: number;
  hidden?: boolean;
  group?: string;
  desc?: string;
  enabled?: BooleanLike;
};

type BackendData = {
  invalid?: boolean;
  selected_category: string;
  selected_bank: string;
  max_strings: number;
  max_length: number;
  dirty?: BooleanLike;
  banks: Bank[];
  categories: Category[];
  audience_options?: AudienceOption[];
  current_audience?: string;
  current_audience_default?: string;
  current_category_enabled?: BooleanLike;
  current_strings: string[];
  current_weights: number[];
  default_strings: string[];
  tokens: string[];
  export_text?: string;
  export_chunk_count?: number;
  export_payload_bytes?: number;
  status_text?: string;
  status_kind?: 'success' | 'danger' | 'info';
  max_import_text_bytes?: number;
  preview_tokens?: ErpPreviewProfileData;
};

// ______ Constants ________________________________________________________________________________________________________________________________________________________________________________________________

/** Static tooltip descriptions for each token. */
const TOKEN_DESCS: Record<string, string> = {
  '[USER]': 'Your character as you/name.',
  '[USERPOS]': "Your character as your/name's.",
  '[TARGET]': "The other participant's name.",
  '[THEY]': 'Your pronoun (they/she/he).',
  '[THEM]': 'Your pronoun (them/her/him).',
  '[THEIR]': 'Your possessive (their/her/his).',
  '[THEIR_CAP]':
    'Capitalized possessive (Their/Her/His) â€” use at sentence starts.',
  '[TTHEY]': "Target's pronoun (they/she/he).",
  '[TTHEM]': "Target's pronoun (them/her/him).",
  '[TTHEIR]': "Target's possessive (their/her/his).",
  '[PENIS_TYPE]': 'Your penis noun (cock, shaft, member, etc.).',
  '[SHEATH]': 'Your sheath type (sheath, slit, foreskin, etc.).',
  '[SIZEADJ]':
    'Single-word penis size adjective (e.g. "massive", "modest", "pitiful").',
  '[COCKSIZE]': 'Full descriptive phrase for penis size.',
  '[VAGADJ]':
    'Single-word vagina type adjective (e.g. "smooth", "furred", "cloacal").',
  '[VAGTYPE]': 'Full descriptive phrase for vagina type.',
  '[CUPADJ]':
    'Single-word breast size adjective (e.g. "heavy", "generous", "flat").',
  '[CUPSIZE]': 'Full descriptive phrase for breast size.',
  '[BREASTTYPE]': 'Full descriptive phrase for breast type.',
  '[TAUR]': 'Your taur body type name, if applicable.',
  '[GENITAL_DESC]': 'Full genital description string.',
  '[FORCE]': 'Force/intensity level of the current action.',
  '[PLUG]': "Your plug's name (Plug bank only).",
};

// ______ Sidebar (banks + categories + info) ____________________________________________________________________________________

function Sidebar() {
  const { act, data } = useBackend<BackendData>();
  const {
    selected_bank,
    selected_category,
    banks,
    categories,
    audience_options,
    current_audience,
    current_audience_default,
    current_category_enabled,
  } = data;

  const [collapsedGroups, setCollapsedGroups] = useState<Set<string>>(
    new Set(),
  );
  const visibleCategories = categories.filter((cat) => !cat.hidden);
  const hasGroups = visibleCategories.some((c) => c.group);
  const currentBank = banks.find((bank) => bank.id === selected_bank);
  const currentCategory = categories.find(
    (cat) => cat.key === selected_category,
  );
  const currentAudienceOption = audience_options?.find(
    (opt) => opt.id === current_audience,
  );
  const categoryEnabled = !!current_category_enabled;
  function toggleGroup(name: string) {
    setCollapsedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(name)) {
        next.delete(name);
      } else {
        next.add(name);
      }
      return next;
    });
  }

  const activeOutline = {
    outline: '2px solid rgba(255,255,255,0.65)',
    outlineOffset: '-2px',
    fontWeight: 'bold' as const,
  };

  const flatCategoryButtons = visibleCategories.map((cat) => {
    const isActive = cat.key === selected_category;
    const catEnabled = cat.enabled !== false && cat.enabled !== 0;
    return (
      <Button
        key={cat.key}
        fluid
        selected={isActive}
        tooltip={cat.desc}
        tooltipPosition="right"
        onClick={() => act('select_category', { category: cat.key })}
        style={{
          opacity: catEnabled ? 1 : 0.55,
          ...(isActive ? activeOutline : {}),
        }}
      >
        {cat.label}
        {!catEnabled && (
          <Box inline ml={0.5} opacity={0.75} style={{ fontSize: '10px' }}>
            off
          </Box>
        )}
        <Box inline ml={0.5} opacity={0.5} style={{ fontSize: '10px' }}>
          ({cat.count})
        </Box>
      </Button>
    );
  });

  const groupedCategoryBlocks = (() => {
    const groups: { name: string; cats: Category[] }[] = [];
    let currentGroup: { name: string; cats: Category[] } | null = null;
    for (const cat of visibleCategories) {
      const g = cat.group || 'Other';
      if (!currentGroup || currentGroup.name !== g) {
        currentGroup = { name: g, cats: [] };
        groups.push(currentGroup);
      }
      currentGroup.cats.push(cat);
    }
    return groups.map((group) => {
      const isCollapsed = collapsedGroups.has(group.name);
      const groupCount = group.cats.reduce((s, c) => s + c.count, 0);
      const hasActive = group.cats.some((c) => c.key === selected_category);
      return (
        <Box key={group.name} mt={0.5}>
          <Button
            fluid
            color="transparent"
            icon={isCollapsed ? 'chevron-right' : 'chevron-down'}
            onClick={() => toggleGroup(group.name)}
            style={{
              background: 'rgba(255,255,255,0.07)',
              borderRadius: '3px',
              fontWeight: 'bold',
              fontSize: '11px',
              ...(hasActive
                ? { outline: '1px solid rgba(79,195,247,0.6)' }
                : {}),
            }}
          >
            {group.name}
            <Box inline ml={0.5} opacity={0.5} style={{ fontSize: '10px' }}>
              ({groupCount})
            </Box>
          </Button>
          {!isCollapsed &&
            group.cats.map((cat) => {
              const isActive = cat.key === selected_category;
              const catEnabled = cat.enabled !== false && cat.enabled !== 0;
              return (
                <Button
                  key={cat.key}
                  fluid
                  selected={isActive}
                  tooltip={cat.desc}
                  tooltipPosition="right"
                  onClick={() => act('select_category', { category: cat.key })}
                  style={{
                    marginLeft: '8px',
                    fontSize: '11px',
                    opacity: catEnabled ? 1 : 0.55,
                    ...(isActive ? activeOutline : {}),
                  }}
                >
                  {cat.label}
                  {!catEnabled && (
                    <Box
                      inline
                      ml={0.5}
                      opacity={0.75}
                      style={{ fontSize: '10px' }}
                    >
                      off
                    </Box>
                  )}
                  <Box
                    inline
                    ml={0.5}
                    opacity={0.5}
                    style={{ fontSize: '10px' }}
                  >
                    ({cat.count})
                  </Box>
                </Button>
              );
            })}
        </Box>
      );
    });
  })();

  const bankButtons = banks
    .filter((b) => b.available)
    .map((b) => {
      const isActive = b.id === selected_bank;
      return (
        <Button
          key={b.id}
          fluid
          selected={isActive}
          tooltip={b.desc}
          tooltipPosition="right"
          onClick={() => act('change_bank', { bank: b.id })}
          style={isActive ? activeOutline : undefined}
        >
          {b.label}
        </Button>
      );
    });

  return (
    <Stack.Item
      width="240px"
      style={{
        display: 'flex',
        flexDirection: 'column',
        borderRight: '1px solid rgba(255,255,255,0.15)',
        paddingRight: '6px',
      }}
    >
      <Section title="String Bank">
        <Box fontSize="10px" opacity={0.6} mb={0.5}>
          Which pool of reactions are you editing?
        </Box>
        {bankButtons}
      </Section>

      <Section title="Categories">
        {hasGroups ? groupedCategoryBlocks : flatCategoryButtons}
      </Section>

      <Section title="Who Sees This?">
        <Box fontSize="11px" opacity={0.8}>
          <b>{currentBank?.label || 'Bank'}</b>
          {currentCategory ? ` / ${currentCategory.label}` : ''}
        </Box>
        {currentCategory?.desc && (
          <Box fontSize="10px" opacity={0.65} mt={0.5}>
            {currentCategory.desc}
          </Box>
        )}
        {!!audience_options?.length && (
          <Stack wrap mt={0.75}>
            {audience_options.map((opt) => (
              <Stack.Item key={opt.id} mr={0.25} mb={0.25}>
                <Button
                  compact
                  selected={opt.id === current_audience}
                  tooltip={opt.desc}
                  tooltipPosition="right"
                  onClick={() => act('set_audience', { audience: opt.id })}
                >
                  {opt.label}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        )}
        <Box mt={0.75}>
          <Button.Checkbox
            checked={categoryEnabled}
            onClick={() =>
              act('set_category_enabled', { enabled: !categoryEnabled })
            }
          >
            Category enabled
          </Button.Checkbox>
        </Box>
        <Box fontSize="11px" opacity={0.8} mt={0.5}>
          Movement banks can be visible to bystanders when configured for it;
          chastity jingles are the common example.
        </Box>
        {currentAudienceOption && (
          <Box fontSize="10px" opacity={0.6} mt={0.5}>
            Current: <b>{currentAudienceOption.label}</b>
            {current_audience === current_audience_default
              ? ' (bank default)'
              : ''}
          </Box>
        )}
        <Box fontSize="10px" opacity={0.6} mt={0.5}>
          Viewers still need the matching ERP filters:{' '}
          <em>Intimate Reactions</em> plus <em>Accessory-Free Flavor</em> for
          character banks, or the relevant accessory/chastity filters for item
          banks.
        </Box>
      </Section>
    </Stack.Item>
  );
}

// ______ Default strings Section ______________________________________________________________________________________________________________________________________________________

function DefaultStringRow({
  str,
  atLimit,
  onAdopt,
  onPreview,
}: {
  str: string;
  atLimit: boolean;
  onAdopt: (str: string) => void;
  onPreview: (str: string) => void;
}) {
  return (
    <Stack align="center" mb={0.5}>
      <Stack.Item grow>
        <Box
          p={0.5}
          italic
          style={{
            background: 'rgba(0,0,0,0.35)',
            borderRadius: '3px',
            border: '1px solid rgba(255,255,255,0.08)',
            fontSize: '12px',
            color: '#d8d8d8',
            wordBreak: 'break-word',
          }}
        >
          {str}
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="plus"
          color="good"
          disabled={atLimit}
          tooltip="Add to custom strings"
          onClick={() => onAdopt(str)}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="search"
          tooltip="Preview this string"
          onClick={() => onPreview(str)}
        />
      </Stack.Item>
    </Stack>
  );
}

function DefaultStringsSection({
  strings,
  show,
  onToggleShow,
  atLimit,
  onAdopt,
  onPreview,
}: {
  strings: string[];
  show: boolean;
  onToggleShow: () => void;
  atLimit: boolean;
  onAdopt: (str: string) => void;
  onPreview: (str: string) => void;
}) {
  return (
    <Section
      title="Default Strings"
      buttons={
        <Button
          compact
          icon={show ? 'eye-slash' : 'eye'}
          onClick={onToggleShow}
        >
          {show ? 'Hide' : 'Show'}
        </Button>
      }
    >
      {show && (
        <>
          <Box fontSize="10px" opacity={0.6} mb={0.5}>
            Built-in fallback strings. Click <b>+</b> to adopt one into your
            custom pool, or the magnifier to preview it. If you have no custom
            strings, these are used automatically.
          </Box>
          {strings.map((str, idx) => (
            <DefaultStringRow
              key={idx}
              str={str}
              atLimit={atLimit}
              onAdopt={onAdopt}
              onPreview={onPreview}
            />
          ))}
        </>
      )}
    </Section>
  );
}

// ______ Input Section ____________________________________________________________________________________________________________________________________________________________________________________

function InputButtons({
  isEditing,
  inputText,
  atLimit,
  onAddOrUpdate,
  onCancel,
  onPreview,
}: {
  isEditing: boolean;
  inputText: string;
  atLimit: boolean;
  onAddOrUpdate: () => void;
  onCancel: () => void;
  onPreview: () => void;
}) {
  if (isEditing) {
    return (
      <>
        <Button
          icon="check"
          color="good"
          disabled={!inputText.trim()}
          onClick={onAddOrUpdate}
        >
          Update
        </Button>
        <Button icon="times" onClick={onCancel}>
          Cancel
        </Button>
        <Button
          icon="search"
          disabled={!inputText.trim()}
          tooltip="Preview with token resolution"
          onClick={onPreview}
        >
          Preview
        </Button>
      </>
    );
  }
  return (
    <>
      <Button
        icon="plus"
        color="good"
        disabled={atLimit || !inputText.trim()}
        onClick={onAddOrUpdate}
      >
        Add
      </Button>
      <Button
        icon="search"
        disabled={!inputText.trim()}
        tooltip="Preview with token resolution"
        onClick={onPreview}
      >
        Preview
      </Button>
    </>
  );
}

function TokenRow({
  tokens,
  onAppend,
}: {
  tokens: string[];
  onAppend: (token: string) => void;
}) {
  return (
    <Stack wrap>
      {tokens.map((token) => (
        <Stack.Item key={token}>
          <Button
            compact
            color="transparent"
            tooltip={TOKEN_DESCS[token]}
            onClick={() => onAppend(token)}
          >
            {token}
          </Button>
        </Stack.Item>
      ))}
    </Stack>
  );
}

function InputSection({
  isEditing,
  editingIndex,
  inputText,
  setInputText,
  atLimit,
  maxLength,
  maxStrings,
  tokens,
  showTokens,
  toggleTokens,
  onAppendToken,
  onAddOrUpdate,
  onCancel,
  onPreview,
  previewProfile,
  act,
}: {
  isEditing: boolean;
  editingIndex: number;
  inputText: string;
  setInputText: (v: string) => void;
  atLimit: boolean;
  maxLength: number;
  maxStrings: number;
  tokens: string[];
  showTokens: boolean;
  toggleTokens: () => void;
  onAppendToken: (token: string) => void;
  onAddOrUpdate: () => void;
  onCancel: () => void;
  onPreview: () => void;
  previewProfile?: ErpPreviewProfileData;
  act: (action: string, payload?: Record<string, string>) => void;
}) {
  const placeholder = isEditing
    ? 'Edit this stringâ€¦'
    : atLimit
      ? 'Limit reached â€” remove a string before adding another.'
      : `Write a flavor stringâ€¦ (max ${maxLength} chars)`;

  return (
    <Section
      title={isEditing ? `Editing String #${editingIndex + 1}` : 'Add String'}
    >
      <Stack>
        <Stack.Item grow>
          <TextArea
            fluid
            height="5rem"
            maxLength={maxLength}
            placeholder={placeholder}
            disabled={!isEditing && atLimit}
            value={inputText}
            onChange={(val) => setInputText(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <InputButtons
            isEditing={isEditing}
            inputText={inputText}
            atLimit={atLimit}
            onAddOrUpdate={onAddOrUpdate}
            onCancel={onCancel}
            onPreview={onPreview}
          />
        </Stack.Item>
      </Stack>

      <Stack align="center" mt={0.5} mb={0.25}>
        <Stack.Item grow>
          <Box opacity={0.7} fontSize="10px">
            Tokens (click to insert; resolved at runtime):
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            compact
            color="transparent"
            icon={showTokens ? 'chevron-up' : 'chevron-down'}
            onClick={toggleTokens}
          >
            {showTokens ? 'Hide' : 'Show'}
          </Button>
        </Stack.Item>
      </Stack>
      {showTokens && <TokenRow tokens={tokens} onAppend={onAppendToken} />}

      <Box fontSize="10px" opacity={0.5} mt={0.5}>
        Max {maxLength} characters per string Â· {maxStrings} strings per
        category.
      </Box>

      <LivePreviewBoxes text={inputText} profile={previewProfile} />
      <ErpPreviewOptionsButton profile={previewProfile} act={act} />
    </Section>
  );
}

// ______ Preview Section ______________________________________________________________________________________________________________________________________________________________________________

function LivePreviewBoxes({
  text,
  profile,
}: {
  text: string;
  profile?: ErpPreviewProfileData;
}) {
  const trimmed = text.trim();
  if (!trimmed) {
    return null;
  }
  return (
    <Stack mt={0.75}>
      <Stack.Item grow basis="50%">
        <Box opacity={0.7} fontSize="10px" mb={0.25}>
          Preview (Wearer):
        </Box>
        <Box
          p={0.5}
          italic
          style={{
            background: 'rgba(0,0,0,0.4)',
            borderRadius: '3px',
            border: '1px solid rgba(255,255,255,0.1)',
            fontSize: '12px',
            color: '#ff88cc',
            wordBreak: 'break-word',
          }}
        >
          {resolveIntimateReactionPreviewTokens(trimmed, 'wearer', profile)}
        </Box>
      </Stack.Item>
      <Stack.Item grow basis="50%" ml={0.5}>
        <Box opacity={0.7} fontSize="10px" mb={0.25}>
          Preview (Bystander):
        </Box>
        <Box
          p={0.5}
          italic
          style={{
            background: 'rgba(0,0,0,0.4)',
            borderRadius: '3px',
            border: '1px solid rgba(255,255,255,0.1)',
            fontSize: '12px',
            color: '#d8d8d8',
            wordBreak: 'break-word',
          }}
        >
          {resolveIntimateReactionPreviewTokens(trimmed, 'bystander', profile)}
        </Box>
      </Stack.Item>
    </Stack>
  );
}

function PreviewSection({
  previewText,
  onClose,
  profile,
}: {
  previewText: string;
  onClose: () => void;
  profile?: ErpPreviewProfileData;
}) {
  return (
    <Section
      title="Live Preview"
      buttons={<Button compact icon="times" onClick={onClose} />}
    >
      <Stack>
        <Stack.Item grow basis="50%">
          <Box opacity={0.7} fontSize="10px" mb={0.25}>
            Raw template:
          </Box>
          <Box
            p={0.5}
            italic
            style={{
              background: 'rgba(0,0,0,0.4)',
              borderRadius: '3px',
              border: '1px solid rgba(255,255,255,0.1)',
              fontSize: '12px',
              color: '#d8d8d8',
              wordBreak: 'break-word',
            }}
          >
            {previewText}
          </Box>
        </Stack.Item>
      </Stack>
      <LivePreviewBoxes text={previewText} profile={profile} />
    </Section>
  );
}

// ______ Custom strings Section _________________________________________________________________________________________________________________________________________________________

/**
 * Per-row NumberInput that debounces the `onCommit` act call so rapid drags
 * fire exactly one server-side update ~300 ms after the last change instead
 * of one per tick. The useDebouncedCallback hook flushes any pending call on
 * unmount so the trailing edit is not lost on category/bank switch.
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

function CustomStringRow({
  idx,
  str,
  weight,
  isEditing,
  onStartEdit,
  onPreview,
  onWeight,
  onRemove,
}: {
  idx: number;
  str: string;
  weight: number;
  isEditing: boolean;
  onStartEdit: (idx: number, str: string) => void;
  onPreview: (str: string) => void;
  onWeight: (idx: number, weight: number) => void;
  onRemove: (idx: number) => void;
}) {
  return (
    <Stack
      align="center"
      mb={0.5}
      style={
        isEditing
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
            padding: '0.5em',
            background: 'rgba(255,255,255,0.06)',
            borderRadius: '3px',
            fontSize: '11px',
            cursor: 'pointer',
            wordBreak: 'break-word',
          }}
          onClick={() => onStartEdit(idx, str)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault();
              onStartEdit(idx, str);
            }
          }}
        >
          {idx + 1}. {str}
        </div>
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="pencil"
          tooltip="Edit this string"
          onClick={() => onStartEdit(idx, str)}
        />
      </Stack.Item>
      <Stack.Item>
        <DebouncedWeightInput
          value={weight}
          onCommit={(next) => onWeight(idx, next)}
        />
      </Stack.Item>
      <Stack.Item>
        <Box fontSize="10px" opacity={0.6}>
          %
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="search"
          tooltip="Preview this string"
          onClick={() => onPreview(str)}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="times"
          color="bad"
          onClick={() => onRemove(idx)}
        />
      </Stack.Item>
    </Stack>
  );
}

function CustomStringsSection({
  strings,
  weights,
  maxStrings,
  editingIndex,
  onStartEdit,
  onPreview,
  onWeight,
  onRemove,
  onClearAll,
}: {
  strings: string[];
  weights: number[];
  maxStrings: number;
  editingIndex: number;
  onStartEdit: (idx: number, str: string) => void;
  onPreview: (str: string) => void;
  onWeight: (idx: number, weight: number) => void;
  onRemove: (idx: number) => void;
  onClearAll: () => void;
}) {
  const [confirmClear, setConfirmClear] = useState(false);
  return (
    <Section
      title={`Your Strings (${strings.length}/${maxStrings})`}
      buttons={
        confirmClear ? (
          <>
            <Button
              compact
              icon="check"
              color="bad"
              onClick={() => {
                onClearAll();
                setConfirmClear(false);
              }}
            >
              Confirm Clear
            </Button>
            <Button compact icon="times" onClick={() => setConfirmClear(false)}>
              Cancel
            </Button>
          </>
        ) : (
          <Button
            compact
            icon="trash"
            color="bad"
            disabled={strings.length === 0}
            onClick={() => setConfirmClear(true)}
          >
            Clear
          </Button>
        )
      }
    >
      {strings.length === 0 ? (
        <Box opacity={0.5} italic fontSize="11px">
          No custom strings for this category. Add one above, or adopt a default
          string when this bank provides one.
        </Box>
      ) : (
        strings.map((str, idx) => (
          <CustomStringRow
            key={idx}
            idx={idx}
            str={str}
            weight={weights[idx] ?? 100}
            isEditing={editingIndex === idx}
            onStartEdit={onStartEdit}
            onPreview={onPreview}
            onWeight={onWeight}
            onRemove={onRemove}
          />
        ))
      )}
    </Section>
  );
}

// ______ Editor panel (right side) ________________________________________________________________________________________________________________________________________________

function EditorPanel() {
  const { act, data } = useBackend<BackendData>();
  const {
    max_strings,
    max_length,
    current_strings,
    current_weights = [],
    default_strings,
    tokens,
    preview_tokens,
  } = data;

  const [inputText, setInputText] = useState('');
  const [editingIndex, setEditingIndex] = useState(-1);
  const [showTokens, setShowTokens] = useState(false);
  const [showDefaults, setShowDefaults] = useState(true);
  const [previewText, setPreviewText] = useState('');

  const atLimit = current_strings.length >= max_strings;
  const isEditing = editingIndex >= 0;

  function adoptDefault(str: string) {
    if (!atLimit) {
      act('add_string', { text: str });
    }
  }

  function appendToken(token: string) {
    setInputText((prev) => prev + token);
  }

  function handleAddOrUpdate() {
    const trimmed = inputText.trim();
    if (!trimmed) return;
    if (isEditing) {
      act('update_string', { index: editingIndex + 1, text: trimmed });
      setEditingIndex(-1);
    } else {
      if (atLimit) return;
      act('add_string', { text: trimmed });
    }
    setInputText('');
  }

  function cancelEdit() {
    setEditingIndex(-1);
    setInputText('');
  }

  function handlePreview(text: string) {
    const trimmed = text.trim();
    if (!trimmed) return;
    setPreviewText(trimmed);
  }

  function startEditing(idx: number, str: string) {
    setEditingIndex(idx);
    setInputText(str);
  }

  return (
    <Stack.Item grow style={{ display: 'flex', flexDirection: 'column' }}>
      <Stack vertical fill>
        {default_strings && default_strings.length > 0 && (
          <Stack.Item>
            <DefaultStringsSection
              strings={default_strings}
              show={showDefaults}
              onToggleShow={() => setShowDefaults(!showDefaults)}
              atLimit={atLimit}
              onAdopt={adoptDefault}
              onPreview={handlePreview}
            />
          </Stack.Item>
        )}

        <Stack.Item>
          <InputSection
            isEditing={isEditing}
            editingIndex={editingIndex}
            inputText={inputText}
            setInputText={setInputText}
            atLimit={atLimit}
            maxLength={max_length}
            maxStrings={max_strings}
            tokens={tokens}
            showTokens={showTokens}
            toggleTokens={() => setShowTokens(!showTokens)}
            onAppendToken={appendToken}
            onAddOrUpdate={handleAddOrUpdate}
            onCancel={cancelEdit}
            onPreview={() => handlePreview(inputText)}
            previewProfile={preview_tokens}
            act={act}
          />
        </Stack.Item>

        {previewText && (
          <Stack.Item>
            <PreviewSection
              previewText={previewText}
              onClose={() => setPreviewText('')}
              profile={preview_tokens}
            />
          </Stack.Item>
        )}

        <Stack.Item grow style={{ overflowY: 'auto', minHeight: 0 }}>
          <CustomStringsSection
            strings={current_strings}
            weights={current_weights}
            maxStrings={max_strings}
            editingIndex={editingIndex}
            onStartEdit={startEditing}
            onPreview={handlePreview}
            onWeight={(idx, weight) =>
              act('set_weight', { index: idx + 1, weight })
            }
            onRemove={(idx) => {
              if (editingIndex === idx) {
                setEditingIndex(-1);
                setInputText('');
              }
              act('remove_string', { index: idx + 1 });
            }}
            onClearAll={() => act('clear_category')}
          />
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
}

// ______ Main Component _________________________________________________________________________________________________________________________________________________________________________________

export function IntimateReactionEditor() {
  const { act, data } = useBackend<BackendData>();
  const [showTransfer, setShowTransfer] = useState(false);

  if (data.invalid) {
    return (
      <Window title="Intimate Reaction Editor" width={960} height={760}>
        <Window.Content>
          <NoticeBox danger>
            Session invalid. Close and reopen the editor.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  // Remount editor panel when bank/category changes so input/editing state resets cleanly.
  const editorKey = `${data.selected_bank}|${data.selected_category}`;

  return (
    <Window title="Intimate Reaction Editor" width={960} height={760}>
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Box bold fontSize="13px">
                  Intimate Reactions
                  <Box inline ml={1} opacity={0.5} fontSize="10px">
                    Private flavor text shown to you and partners.
                  </Box>
                </Box>
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
                exportAriaLabel="Intimate reaction export text"
                importAriaLabel="Intimate reaction import text"
                exportDescription="Generated intimate reaction exports stay in this panel instead of being printed into chat."
                importDescription="Import overwrites your current intimate reaction strings. Generate an export first if you want a backup."
                importPlaceholder="Paste intimate reaction export text here"
                overwriteLabel="Overwrite intimate reactions"
              />
            </Stack.Item>
          )}

          <Stack.Item grow>
            <Stack fill>
              <Sidebar />
              <EditorPanel key={editorKey} />
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
