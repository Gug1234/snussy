/**
 * IntimateReactionEditor.tsx — TGUI interface for Intimate Reaction Text.
 *
 * Allows players to write per-character flavor strings for movement
 * descriptions, body exposure, and sex-action reactions. These strings
 * are displayed via the character_flavor component even without intimate
 * accessories equipped.
 *
 * Layout:
 *   Left panel  — category sidebar with highlighted selection.
 *   Right panel — default strings, custom strings, input, preview, tokens.
 */

import { useState } from 'react';
import { Box, Button, NoticeBox, NumberInput, Section, Stack, TextArea } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ── Types ────────────────────────────────────────────────────────────────────

type Bank = {
  id: string;
  label: string;
  available: boolean;
  desc?: string;
};

type Category = {
  key: string;
  label: string;
  count: number;
  hidden?: boolean;
  group?: string;
  desc?: string;
};

type PresetOption = {
  id: string;
  label: string;
};

type PresetStage = {
  id: string;
  label: string;
  has_genital: BooleanLike;
  desc?: string;
};

type BackendData = {
  invalid?: boolean;
  selected_category: string;
  selected_bank: string;
  max_strings: number;
  max_length: number;
  banks: Bank[];
  categories: Category[];
  current_strings: string[];
  current_weights: number[];
  default_strings: string[];
  tokens: string[];
  preset_species?: PresetOption[];
  preset_stages?: PresetStage[];
  preset_genitals?: PresetOption[];
  preset_result?: string;
  preset_result_success?: BooleanLike;
  resolved_preview?: string;
};

// ── Component ────────────────────────────────────────────────────────────────

/** Static tooltip descriptions for each token. */
const TOKEN_DESCS: Record<string, string> = {
  '[USER]': 'Your character\'s name.',
  '[TARGET]': 'The other participant\'s name.',
  '[THEY]': 'Your pronoun (they/she/he).',
  '[THEM]': 'Your pronoun (them/her/him).',
  '[THEIR]': 'Your possessive (their/her/his).',
  '[THEIR_CAP]': 'Capitalized possessive (Their/Her/His) — use at sentence starts.',
  '[TTHEY]': 'Target\'s pronoun (they/she/he).',
  '[TTHEM]': 'Target\'s pronoun (them/her/him).',
  '[TTHEIR]': 'Target\'s possessive (their/her/his).',
  '[PENIS_TYPE]': 'Your penis noun (cock, shaft, member, etc.).',
  '[SHEATH]': 'Your sheath type (sheath, slit, foreskin, etc.).',
  '[SIZEADJ]': 'Single-word penis size adjective (e.g. "massive", "modest", "pitiful").',
  '[COCKSIZE]': 'Full descriptive phrase for penis size.',
  '[VAGADJ]': 'Single-word vagina type adjective (e.g. "smooth", "furred", "cloacal").',
  '[VAGTYPE]': 'Full descriptive phrase for vagina type.',
  '[CUPADJ]': 'Single-word breast size adjective (e.g. "heavy", "generous", "flat").',
  '[CUPSIZE]': 'Full descriptive phrase for breast size.',
  '[BREASTTYPE]': 'Full descriptive phrase for breast type.',
  '[TAUR]': 'Your taur body type name, if applicable.',
  '[GENITAL_DESC]': 'Full genital description string.',
  '[FORCE]': 'Force/intensity level of the current action.',
  '[JELLY]': 'Your jelly\'s name (Eora Jelly bank only).',
  '[PLUG]': 'Your plug\'s name (Plug bank only).',
};

export function IntimateReactionEditor() {
  const { act, data } = useBackend<BackendData>();

  const [inputText, setInputText] = useState('');
  const [showImport, setShowImport] = useState(false);
  const [importText, setImportText] = useState('');
  const [showTokens, setShowTokens] = useState(false);
  const [showDefaults, setShowDefaults] = useState(true);
  const [previewText, setPreviewText] = useState('');
  /** Index (0-based) of the custom string being edited, or -1 for "add new" mode. */
  const [editingIndex, setEditingIndex] = useState(-1);
  /** Preset dropdown state */
  const [selectedSpecies, setSelectedSpecies] = useState('');
  const [selectedStage, setSelectedStage] = useState('');
  const [selectedGenital, setSelectedGenital] = useState('');
  /** Set of group names that are currently collapsed in the sidebar. */
  const [collapsedGroups, setCollapsedGroups] = useState<Set<string>>(
    new Set(),
  );

  if (data.invalid) {
    return (
      <Window title="Intimate Reaction Editor" width={780} height={700}>
        <Window.Content>
          <NoticeBox danger>
            Session invalid. Close and reopen the editor.
          </NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const {
    selected_category,
    selected_bank,
    max_strings,
    max_length,
    banks,
    categories,
    current_strings,
    current_weights = [],
    default_strings,
    tokens,
    preset_species,
    preset_stages,
    preset_genitals,
    preset_result,
    preset_result_success,
    resolved_preview,
  } = data;
  const atLimit = current_strings.length >= max_strings;

  // Filter hidden categories from the sidebar display.
  const visibleCategories = categories.filter((cat) => !cat.hidden);

  // Determine if the currently selected stage needs a genital selection.
  const currentStageInfo = preset_stages?.find(
    (s) => s.id === selectedStage,
  );
  const needsGenital = !!currentStageInfo?.has_genital;
  const canLoadPreset =
    !!selectedSpecies &&
    !!selectedStage &&
    (!needsGenital || !!selectedGenital);

  /** Adds a default string to the player's custom pool. */
  const adoptDefault = (str: string) => {
    if (!atLimit) {
      act('add_string', { text: str });
    }
  };

  return (
    <Window title="Intimate Reaction Editor" width={780} height={750}>
      <Window.Content>
        <Stack fill>
          {/* ── Left sidebar: bank + categories ── */}
          <Stack.Item
            width="210px"
            style={{
              borderRight: '1px solid rgba(255,255,255,0.15)',
              paddingRight: '6px',
              overflowY: 'auto',
              overflowX: 'hidden',
            }}
          >
            {/* Bank selector dropdown */}
            <Section title="String Bank">
              {banks
                .filter((b) => b.available)
                .map((b) => (
                  <Button
                    key={b.id}
                    fluid
                    selected={b.id === selected_bank}
                    tooltip={b.desc}
                    tooltipPosition="right"
                    onClick={() => {
                      act('change_bank', { bank: b.id });
                      setEditingIndex(-1);
                      setInputText('');
                    }}
                    style={
                      b.id === selected_bank
                        ? {
                            borderLeft: '3px solid #81c784',
                            fontWeight: 'bold',
                          }
                        : { borderLeft: '3px solid transparent' }
                    }
                  >
                    {b.label}
                  </Button>
                ))}
            </Section>

            <Section title="Categories">
              {(() => {
                // Check if categories have group metadata.
                const hasGroups = visibleCategories.some((c) => c.group);
                if (!hasGroups) {
                  // Flat list (non-jelly banks).
                  return visibleCategories.map((cat) => {
                    const isActive = cat.key === selected_category;
                    return (
                      <Button
                        key={cat.key}
                        fluid
                        selected={isActive}
                        tooltip={cat.desc}
                        tooltipPosition="right"
                        onClick={() => {
                          act('select_category', { category: cat.key });
                          setEditingIndex(-1);
                          setInputText('');
                        }}
                        style={
                          isActive
                            ? {
                                borderLeft: '3px solid #4fc3f7',
                                fontWeight: 'bold',
                              }
                            : { borderLeft: '3px solid transparent' }
                        }
                      >
                        {cat.label} ({cat.count})
                      </Button>
                    );
                  });
                }
                // Grouped rendering (jelly bank).
                const groups: { name: string; cats: Category[] }[] = [];
                let currentGroup: { name: string; cats: Category[] } | null =
                  null;
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
                  const groupCount = group.cats.reduce(
                    (s, c) => s + c.count,
                    0,
                  );
                  const hasActive = group.cats.some(
                    (c) => c.key === selected_category,
                  );
                  return (
                    <Box key={group.name} mb={0.5}>
                      <Button
                        fluid
                        icon={isCollapsed ? 'chevron-right' : 'chevron-down'}
                        onClick={() => {
                          setCollapsedGroups((prev) => {
                            const next = new Set(prev);
                            if (next.has(group.name)) {
                              next.delete(group.name);
                            } else {
                              next.add(group.name);
                            }
                            return next;
                          });
                        }}
                        style={{
                          fontWeight: 'bold',
                          fontSize: '11px',
                          borderLeft: hasActive
                            ? '3px solid #4fc3f7'
                            : '3px solid transparent',
                          background: 'rgba(255,255,255,0.04)',
                        }}
                      >
                        {group.name} ({groupCount})
                      </Button>
                      {!isCollapsed &&
                        group.cats.map((cat) => {
                          const isActive = cat.key === selected_category;
                          return (
                            <Button
                              key={cat.key}
                              fluid
                              selected={isActive}
                              tooltip={cat.desc}
                              tooltipPosition="right"
                              onClick={() => {
                                act('select_category', {
                                  category: cat.key,
                                });
                                setEditingIndex(-1);
                                setInputText('');
                              }}
                              style={{
                                paddingLeft: '16px',
                                fontSize: '11px',
                                borderLeft: isActive
                                  ? '3px solid #4fc3f7'
                                  : '3px solid transparent',
                                fontWeight: isActive ? 'bold' : 'normal',
                              }}
                            >
                              {cat.label} ({cat.count})
                            </Button>
                          );
                        })}
                    </Box>
                  );
                });
              })()}
            </Section>

            {/* ── Species/Biology presets (character bank only) ── */}
            {preset_species && preset_stages && (
              <Section title="Load Preset">
                <Box fontSize="11px" opacity={0.6} mb={0.5}>
                  Populate categories with pre-written strings for a given
                  species and arousal tier. This will{' '}
                  <b>replace all existing strings</b> in the affected
                  categories (Movement, Sex Received, and Anal Received
                  where applicable).
                </Box>

                {/* Species */}
                <Box mb={0.5} fontSize="11px" opacity={0.8}>
                  Species:
                </Box>
                {preset_species.map((sp) => {
                  const active = sp.id === selectedSpecies;
                  return (
                    <Button
                      key={sp.id}
                      compact
                      selected={active}
                      onClick={() => setSelectedSpecies(sp.id)}
                      style={{
                        borderBottom: active
                          ? '2px solid #81c784'
                          : '2px solid transparent',
                        fontWeight: active ? 'bold' : 'normal',
                      }}
                    >
                      {sp.label}
                    </Button>
                  );
                })}

                {/* Stage */}
                <Box mt={0.5} mb={0.5} fontSize="11px" opacity={0.8}>
                  Stage:
                </Box>
                {preset_stages.map((st) => {
                  const active = st.id === selectedStage;
                  return (
                    <Button
                      key={st.id}
                      compact
                      selected={active}
                      tooltip={st.desc}
                      tooltipPosition="right"
                      onClick={() => {
                        setSelectedStage(st.id);
                        if (!st.has_genital) {
                          setSelectedGenital('');
                        }
                      }}
                      style={{
                        borderBottom: active
                          ? '2px solid #81c784'
                          : '2px solid transparent',
                        fontWeight: active ? 'bold' : 'normal',
                      }}
                    >
                      {st.label}
                    </Button>
                  );
                })}

                {/* Genital (shown when any stage needs it; disabled when current stage doesn't) */}
                {preset_genitals && (
                  <>
                    <Box
                      mt={0.5}
                      mb={0.5}
                      fontSize="11px"
                      opacity={needsGenital ? 0.8 : 0.4}
                    >
                      Genital:
                      {!needsGenital && selectedStage && (
                        <Box as="span" ml={0.5} italic>
                          (not needed for this stage)
                        </Box>
                      )}
                    </Box>
                    {preset_genitals.map((g) => {
                      const active = g.id === selectedGenital && needsGenital;
                      return (
                        <Button
                          key={g.id}
                          compact
                          selected={active}
                          disabled={!needsGenital}
                          onClick={() => setSelectedGenital(g.id)}
                          style={{
                            borderBottom: active
                              ? '2px solid #81c784'
                              : '2px solid transparent',
                            fontWeight: active ? 'bold' : 'normal',
                          }}
                        >
                          {g.label}
                        </Button>
                      );
                    })}
                  </>
                )}

                {/* Load buttons */}
                <Box mt={1}>
                  <Button
                    fluid
                    icon="download"
                    color="good"
                    disabled={!canLoadPreset}
                    onClick={() =>
                      act('load_preset', {
                        species: selectedSpecies,
                        stage: selectedStage,
                        genital: needsGenital ? selectedGenital : null,
                      })
                    }
                  >
                    Load Preset
                  </Button>
                  <Button
                    fluid
                    icon="download"
                    color="average"
                    disabled={!selectedSpecies}
                    tooltip="Load ALL tiers for this species (replaces all character bank strings)"
                    onClick={() =>
                      act('load_all_presets', {
                        species: selectedSpecies,
                      })
                    }
                    mt={0.5}
                  >
                    Apply All ({selectedSpecies || '…'})
                  </Button>
                </Box>

                {/* Inline feedback after loading */}
                {!!preset_result &&
                  (preset_result_success ? (
                    <NoticeBox mt={1} success>
                      {preset_result}
                    </NoticeBox>
                  ) : (
                    <NoticeBox mt={1} danger>
                      {preset_result}
                    </NoticeBox>
                  ))}
              </Section>
            )}

            <Section title="Data">
              <Button
                fluid
                icon="file-export"
                onClick={() => act('export_data')}
              >
                Export All
              </Button>
              <Button
                fluid
                icon="file-import"
                selected={showImport}
                onClick={() => setShowImport(!showImport)}
              >
                Import
              </Button>
            </Section>

            {/* ── Visibility info ── */}
            <Section title="Who Sees This?">
              <Box fontSize="11px" opacity={0.8}>
                <b>Movement text</b> is shown only to <em>you</em> (the
                wearer).
              </Box>
              <Box fontSize="11px" opacity={0.8} mt={0.5}>
                <b>Sex Received text</b> is shown only to <em>you</em> when
                another player performs a sex action on you.
              </Box>
              <Box fontSize="11px" opacity={0.6} mt={0.5}>
                Viewers must have <em>Intimate Reactions</em> and{' '}
                <em>Accessory-Free Flavor</em> enabled in their ERP
                preferences to see any output.
              </Box>
            </Section>
          </Stack.Item>

          {/* ── Right panel: string editor ── */}
          <Stack.Item
            grow
            style={{
              display: 'flex',
              flexDirection: 'column',
              overflowY: 'auto',
              overflowX: 'hidden',
            }}
          >
            <Stack vertical fill>
              {/* Import panel (toggled) */}
              {showImport && (
                <Stack.Item>
                  <Section title="Import Data">
                    <Box fontSize="11px" opacity={0.7} mb={1}>
                      Paste an exported data string below.{' '}
                      <b>This replaces all existing data</b> — export first
                      for a backup.
                    </Box>
                    <Stack>
                      <Stack.Item grow>
                        <TextArea
                          fluid
                          height="3rem"
                          placeholder="Paste exported string here…"
                          value={importText}
                          onChange={(val) => setImportText(val)}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="check"
                          color="good"
                          disabled={!importText.trim()}
                          onClick={() => {
                            act('import_data', {
                              payload: importText.trim(),
                            });
                            setImportText('');
                            setShowImport(false);
                          }}
                        >
                          Import
                        </Button>
                      </Stack.Item>
                    </Stack>
                  </Section>
                </Stack.Item>
              )}

              {/* ── Default strings (from JSON banks) ── */}
              {default_strings && default_strings.length > 0 && (
                <Stack.Item>
                  <Section
                    title="Default Strings"
                    buttons={
                      <Button
                        icon={showDefaults ? 'eye-slash' : 'eye'}
                        onClick={() => setShowDefaults(!showDefaults)}
                      >
                        {showDefaults ? 'Hide' : 'Show'}
                      </Button>
                    }
                  >
                    {showDefaults && (
                      <Box>
                        <Box fontSize="11px" opacity={0.6} mb={0.5}>
                          These are the built-in fallback strings. Click the{' '}
                          <b>+</b> button to copy one into your custom pool
                          for editing. If you have no custom strings, these
                          are used automatically.
                        </Box>
                        {default_strings.map((str, idx) => (
                          <Box
                            key={idx}
                            mb={0.5}
                            style={{
                              display: 'flex',
                              alignItems: 'flex-start',
                              gap: '4px',
                            }}
                          >
                            <Box
                              opacity={0.7}
                              fontSize="11px"
                              italic
                              style={{
                                wordBreak: 'break-word',
                                flexGrow: 1,
                              }}
                            >
                              {str}
                            </Box>
                            <Button
                              compact
                              icon="plus"
                              color="good"
                              disabled={atLimit}
                              tooltip="Add to custom strings"
                              onClick={() => adoptDefault(str)}
                            />
                            <Button
                              compact
                              icon="search"
                              tooltip="Preview this string"
                              onClick={() => {
                                setPreviewText(str);
                                act('preview_string', { text: str });
                              }}
                            />
                          </Box>
                        ))}
                      </Box>
                    )}
                  </Section>
                </Stack.Item>
              )}

              {/* ── Custom strings ── */}
              <Stack.Item grow>
                <Section
                  title={`Your Strings (${current_strings.length}/${max_strings})`}
                  buttons={
                    <Button
                      icon="trash"
                      color="bad"
                      disabled={current_strings.length === 0}
                      onClick={() => act('clear_category')}
                    >
                      Clear
                    </Button>
                  }
                >
                  {current_strings.length === 0 ? (
                    <NoticeBox>
                      No custom strings for this category. Add one below, or
                      adopt a default string above.
                    </NoticeBox>
                  ) : (
                    current_strings.map((str, idx) => (
                      <Box
                        key={idx}
                        mb={0.5}
                        style={{
                          display: 'flex',
                          alignItems: 'flex-start',
                          gap: '4px',
                          background:
                            editingIndex === idx
                              ? 'rgba(79,195,247,0.15)'
                              : 'transparent',
                          borderRadius: '3px',
                          padding: '2px 4px',
                        }}
                      >
                        <Box
                          opacity={0.9}
                          fontSize="12px"
                          style={{
                            wordBreak: 'break-word',
                            flexGrow: 1,
                            cursor: 'pointer',
                          }}
                          onClick={() => {
                            setEditingIndex(idx);
                            setInputText(str);
                          }}
                        >
                          {idx + 1}. {str}
                        </Box>
                        <Box
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '2px',
                            flexShrink: 0,
                          }}
                        >
                          <NumberInput
                            width="50px"
                            step={5}
                            stepPixelSize={4}
                            value={current_weights[idx] ?? 100}
                            minValue={0}
                            maxValue={100}
                            onChange={(value) =>
                              act('set_weight', {
                                index: idx + 1,
                                weight: value,
                              })
                            }
                          />
                          <Box fontSize="10px" opacity={0.5}>
                            %
                          </Box>
                        </Box>
                        <Button
                          compact
                          icon="pencil"
                          tooltip="Edit this string"
                          onClick={() => {
                            setEditingIndex(idx);
                            setInputText(str);
                          }}
                        />
                        <Button
                          compact
                          icon="search"
                          tooltip="Preview this string"
                          onClick={() => {
                            setPreviewText(str);
                            act('preview_string', { text: str });
                          }}
                        />
                        <Button
                          compact
                          icon="times"
                          color="bad"
                          onClick={() => {
                            if (editingIndex === idx) {
                              setEditingIndex(-1);
                              setInputText('');
                            }
                            act('remove_string', { index: idx + 1 });
                          }}
                        />
                      </Box>
                    ))
                  )}
                </Section>
              </Stack.Item>

              {/* ── Add / Edit string ── */}
              <Stack.Item>
                <Section
                  title={
                    editingIndex >= 0
                      ? `Editing String #${editingIndex + 1}`
                      : 'Add String'
                  }
                >
                  <TextArea
                    fluid
                    height="4rem"
                    maxLength={max_length}
                    placeholder={
                      editingIndex >= 0
                        ? 'Edit this string…'
                        : atLimit
                          ? 'Limit reached'
                          : 'Type a new flavor string…'
                    }
                    disabled={editingIndex < 0 && atLimit}
                    value={inputText}
                    onChange={(val) => setInputText(val)}
                  />
                  <Box mt={0.5}>
                    {editingIndex >= 0 ? (
                      <>
                        <Button
                          icon="check"
                          color="good"
                          disabled={!inputText.trim()}
                          onClick={() => {
                            act('update_string', {
                              index: editingIndex + 1,
                              text: inputText.trim(),
                            });
                            setEditingIndex(-1);
                            setInputText('');
                          }}
                        >
                          Update
                        </Button>
                        <Button
                          icon="times"
                          onClick={() => {
                            setEditingIndex(-1);
                            setInputText('');
                          }}
                        >
                          Cancel
                        </Button>
                      </>
                    ) : (
                      <Button
                        icon="plus"
                        disabled={atLimit || !inputText.trim()}
                        onClick={() => {
                          act('add_string', { text: inputText.trim() });
                          setInputText('');
                        }}
                      >
                        Add
                      </Button>
                    )}
                    <Button
                      icon="search"
                      disabled={!inputText.trim()}
                      tooltip="Preview with token resolution"
                      onClick={() => {
                        setPreviewText(inputText.trim());
                        act('preview_string', { text: inputText.trim() });
                      }}
                    >
                      Preview
                    </Button>
                  </Box>
                  <Box fontSize="10px" opacity={0.5} mt={0.5}>
                    Max {max_length} characters per string. {max_strings}{' '}
                    strings per category.
                  </Box>
                </Section>
              </Stack.Item>

              {/* ── Live preview ── */}
              {previewText && (
                <Stack.Item>
                  <Section
                    title="Live Preview"
                    buttons={
                      <Button
                        icon="times"
                        compact
                        onClick={() => setPreviewText('')}
                      />
                    }
                  >
                    <Box fontSize="11px" opacity={0.6} mb={0.5}>
                      Raw template:
                    </Box>
                    <Box
                      fontSize="12px"
                      italic
                      style={{
                        padding: '6px',
                        background: 'rgba(255,255,255,0.05)',
                        borderRadius: '3px',
                        wordBreak: 'break-word',
                      }}
                    >
                      {previewText}
                    </Box>
                    {resolved_preview && (
                      <>
                        <Box fontSize="11px" opacity={0.6} mt={0.5} mb={0.5}>
                          Resolved:
                        </Box>
                        <Box
                          fontSize="12px"
                          bold
                          style={{
                            padding: '6px',
                            background: 'rgba(129,199,132,0.1)',
                            borderRadius: '3px',
                            wordBreak: 'break-word',
                          }}
                        >
                          {resolved_preview}
                        </Box>
                      </>
                    )}
                  </Section>
                </Stack.Item>
              )}

              {/* ── Token reference ── */}
              <Stack.Item>
                <Section
                  title="Token Reference"
                  buttons={
                    <Button
                      icon={showTokens ? 'chevron-up' : 'chevron-down'}
                      onClick={() => setShowTokens(!showTokens)}
                    >
                      {showTokens ? 'Hide' : 'Show'}
                    </Button>
                  }
                >
                  {showTokens && (
                    <Box>
                      <Box fontSize="11px" opacity={0.7} mb={0.5}>
                        Click a token to insert it at the end of your input.
                        Tokens are replaced at runtime with character-specific
                        values.
                      </Box>
                      <Box
                        style={{
                          display: 'flex',
                          flexWrap: 'wrap',
                          gap: '4px',
                        }}
                      >
                        {tokens.map((token) => (
                          <Button
                            key={token}
                            compact
                            fontSize="11px"
                            tooltip={TOKEN_DESCS[token]}
                            onClick={() =>
                              setInputText((prev) => prev + token)
                            }
                          >
                            {token}
                          </Button>
                        ))}
                      </Box>
                    </Box>
                  )}
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}

