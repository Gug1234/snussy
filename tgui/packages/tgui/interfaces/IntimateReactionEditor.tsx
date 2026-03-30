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
import { Box, Button, Input, NoticeBox, Section, Stack, TextArea } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

// ── Types ────────────────────────────────────────────────────────────────────

type Bank = {
  id: string;
  label: string;
  available: boolean;
};

type Category = {
  key: string;
  label: string;
  count: number;
};

type Preset = {
  id: string;
  label: string;
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
  default_strings: string[];
  tokens: string[];
  presets?: Preset[];
};

// ── Component ────────────────────────────────────────────────────────────────

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
    default_strings,
    tokens,
    presets,
  } = data;
  const atLimit = current_strings.length >= max_strings;

  /** Adds a default string to the player's custom pool. */
  const adoptDefault = (str: string) => {
    if (!atLimit) {
      act('add_string', { text: str });
    }
  };

  return (
    <Window title="Intimate Reaction Editor" width={780} height={700}>
      <Window.Content scrollable>
        <Stack fill>
          {/* ── Left sidebar: bank + categories ── */}
          <Stack.Item
            width="210px"
            style={{
              borderRight: '1px solid rgba(255,255,255,0.15)',
              paddingRight: '6px',
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
              {categories.map((cat) => {
                const isActive = cat.key === selected_category;
                return (
                  <Button
                    key={cat.key}
                    fluid
                    selected={isActive}
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
              })}
            </Section>

            {/* ── Species/Biology presets (character bank only) ── */}
            {presets && presets.length > 0 && (
              <Section title="Presets">
                <Box fontSize="11px" opacity={0.6} mb={0.5}>
                  Load a species template into Movement &amp; Sex Received.
                  <b> Replaces</b> existing strings in those categories.
                </Box>
                {presets.map((p) => (
                  <Button
                    key={p.id}
                    fluid
                    icon="palette"
                    onClick={() => act('load_preset', { preset: p.id })}
                  >
                    {p.label}
                  </Button>
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
            style={{ display: 'flex', flexDirection: 'column' }}
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
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
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
                        onEnter={() => {
                          if (!inputText.trim()) return;
                          if (editingIndex >= 0) {
                            act('update_string', {
                              index: editingIndex + 1,
                              text: inputText.trim(),
                            });
                            setEditingIndex(-1);
                            setInputText('');
                          } else {
                            act('add_string', { text: inputText.trim() });
                            setInputText('');
                          }
                        }}
                      />
                    </Stack.Item>
                    <Stack.Item>
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
                    </Stack.Item>
                    <Stack.Item>
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
                    </Stack.Item>
                  </Stack>
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
                      The resolved preview is printed to your chat. Raw
                      template shown here:
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

