import { useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { getImportTransferPlan } from './CharacterSlotIOMenuUtils';

type BackendData = {
  slot: number;
  max_slots: number;
  export_text: string;
  export_chunk_count: number;
  export_payload_bytes: number;
  export_text_length: number;
  status_text: string;
  status_kind: 'success' | 'danger' | 'info';
  max_import_bytes: number;
  max_import_text_bytes: number;
};

function renderStatusNotice(
  statusKind: BackendData['status_kind'],
  statusText: string,
) {
  switch (statusKind) {
    case 'success':
      return <NoticeBox success>{statusText}</NoticeBox>;
    case 'danger':
      return <NoticeBox danger>{statusText}</NoticeBox>;
    default:
      return <NoticeBox info>{statusText}</NoticeBox>;
  }
}

export function CharacterSlotIOMenu() {
  const { act, data } = useBackend<BackendData>();
  const exportRef = useRef<HTMLTextAreaElement>(null);
  const [importText, setImportText] = useState('');
  const [confirmed, setConfirmed] = useState(false);
  const [isSendingImport, setIsSendingImport] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadTotal, setUploadTotal] = useState(0);

  const hasExport = !!data.export_text;
  const importPlan = getImportTransferPlan(
    importText,
    data.max_import_text_bytes,
  );

  const selectExportText = () => {
    exportRef.current?.focus();
    exportRef.current?.select();
  };

  const submitImport = async () => {
    if (!importPlan.hasImport || importPlan.importTooLarge || isSendingImport) {
      return;
    }

    const chunks = importPlan.chunks;
    setIsSendingImport(true);
    setUploadProgress(0);
    setUploadTotal(chunks.length);
    act('begin_import_payload', {
      chunk_count: chunks.length,
      text_length: importPlan.trimmedText.length,
    });

    for (let index = 0; index < chunks.length; index++) {
      act('append_import_payload_chunk', {
        chunk_index: index + 1,
        chunk_count: chunks.length,
        chunk: chunks[index],
      });
      setUploadProgress(index + 1);
      if (index % 4 === 3) {
        await new Promise((resolve) => setTimeout(resolve, 25));
      }
    }

    setConfirmed(false);
    setIsSendingImport(false);
  };

  return (
    <Window width={720} height={620}>
      <Window.Content scrollable>
        <Stack vertical>
          {!!data.status_text && (
            <Stack.Item>
              {renderStatusNotice(data.status_kind, data.status_text)}
            </Stack.Item>
          )}

          <Stack.Item>
            <Section
              title="Current Slot"
              buttons={
                <Button icon="sync" onClick={() => act('generate_export')}>
                  Generate Export
                </Button>
              }
            >
              <LabeledList>
                <LabeledList.Item label="Slot">
                  {data.slot} / {data.max_slots}
                </LabeledList.Item>
                <LabeledList.Item label="Payload">
                  {data.export_payload_bytes
                    ? `${data.export_payload_bytes} bytes`
                    : 'Not generated'}
                </LabeledList.Item>
                <LabeledList.Item label="Chunks">
                  {data.export_chunk_count || 'None'}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section
              title="Export"
              buttons={
                <Stack>
                  <Stack.Item>
                    <Button
                      icon="copy"
                      disabled={!hasExport}
                      onClick={selectExportText}
                    >
                      Select All
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="times"
                      disabled={!hasExport}
                      onClick={() => act('clear_export')}
                    >
                      Clear
                    </Button>
                  </Stack.Item>
                </Stack>
              }
            >
              <Box mb={1} opacity={0.65} fontSize="11px">
                Generated exports stay in this panel instead of being printed
                into chat.
              </Box>
              <textarea
                ref={exportRef}
                aria-label="Character slot export text"
                className="Input TextArea Input--fluid"
                readOnly
                spellCheck={false}
                value={data.export_text || ''}
                style={{
                  height: '11rem',
                  resize: 'vertical',
                  whiteSpace: 'pre',
                  fontFamily: 'monospace',
                }}
              />
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Import">
              <Box mb={1} opacity={0.65} fontSize="11px">
                Import overwrites the currently selected character slot.
              </Box>
              <textarea
                aria-label="Character slot import text"
                className="Input TextArea Input--fluid"
                spellCheck={false}
                placeholder="Paste character slot export text here"
                value={importText}
                onChange={(event) => setImportText(event.currentTarget.value)}
                style={{
                  height: '9rem',
                  resize: 'vertical',
                  whiteSpace: 'pre',
                  fontFamily: 'monospace',
                }}
              />
              {importPlan.importTooLarge && (
                <NoticeBox danger mt={1}>
                  Import text is too large for this panel.
                </NoticeBox>
              )}
              {isSendingImport && (
                <Box mt={1} opacity={0.75} fontSize="11px">
                  Sending import data {uploadProgress} / {uploadTotal}
                </Box>
              )}
              <Stack mt={1} align="center">
                <Stack.Item grow>
                  <Button.Checkbox
                    checked={confirmed}
                    disabled={isSendingImport}
                    onClick={() => setConfirmed(!confirmed)}
                  >
                    Overwrite slot {data.slot}
                  </Button.Checkbox>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="file-import"
                    color="bad"
                    disabled={
                      !importPlan.hasImport ||
                      !confirmed ||
                      importPlan.importTooLarge ||
                      isSendingImport
                    }
                    onClick={submitImport}
                  >
                    {isSendingImport ? 'Sending' : 'Import'}
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
