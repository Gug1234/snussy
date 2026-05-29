import { useRef, useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { getImportTransferPlan } from '../CharacterSlotIOMenuUtils';

type StatusKind = 'success' | 'danger' | 'info';

type ChunkedExportImportSectionProps = {
  act: (action: string, payload?: Record<string, unknown>) => void;
  exportText?: string;
  exportChunkCount?: number;
  exportPayloadBytes?: number;
  statusText?: string;
  statusKind?: StatusKind;
  maxImportTextBytes?: number;
  exportAriaLabel: string;
  importAriaLabel: string;
  exportDescription: string;
  importDescription: string;
  importPlaceholder: string;
  overwriteLabel: string;
};

function renderStatusNotice(statusKind: StatusKind, statusText: string) {
  switch (statusKind) {
    case 'success':
      return <NoticeBox success>{statusText}</NoticeBox>;
    case 'danger':
      return <NoticeBox danger>{statusText}</NoticeBox>;
    default:
      return <NoticeBox info>{statusText}</NoticeBox>;
  }
}

export function ChunkedExportImportSection(
  props: ChunkedExportImportSectionProps,
) {
  const {
    act,
    exportText = '',
    exportChunkCount = 0,
    exportPayloadBytes = 0,
    statusText = '',
    statusKind = 'info',
    maxImportTextBytes = 0,
    exportAriaLabel,
    importAriaLabel,
    exportDescription,
    importDescription,
    importPlaceholder,
    overwriteLabel,
  } = props;

  const exportRef = useRef<HTMLTextAreaElement>(null);
  const [importText, setImportText] = useState('');
  const [confirmed, setConfirmed] = useState(false);
  const [isSendingImport, setIsSendingImport] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [uploadTotal, setUploadTotal] = useState(0);

  const hasExport = !!exportText;
  const importPlan = getImportTransferPlan(importText, maxImportTextBytes);

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

    setImportText('');
    setConfirmed(false);
    setIsSendingImport(false);
  };

  return (
    <Stack vertical>
      {!!statusText && (
        <Stack.Item>{renderStatusNotice(statusKind, statusText)}</Stack.Item>
      )}

      <Stack.Item>
        <Section
          title="Export"
          buttons={
            <Stack>
              <Stack.Item>
                <Button icon="sync" onClick={() => act('generate_export')}>
                  Generate Export
                </Button>
              </Stack.Item>
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
            {exportDescription}
          </Box>
          <Box mb={1}>
            <LabeledList>
              <LabeledList.Item label="Payload">
                {exportPayloadBytes
                  ? `${exportPayloadBytes} bytes`
                  : 'Not generated'}
              </LabeledList.Item>
              <LabeledList.Item label="Chunks">
                {exportChunkCount || 'None'}
              </LabeledList.Item>
            </LabeledList>
          </Box>
          <textarea
            ref={exportRef}
            aria-label={exportAriaLabel}
            className="Input TextArea Input--fluid"
            readOnly
            spellCheck={false}
            value={exportText}
            style={{
              height: '9rem',
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
            {importDescription}
          </Box>
          <textarea
            aria-label={importAriaLabel}
            className="Input TextArea Input--fluid"
            spellCheck={false}
            placeholder={importPlaceholder}
            value={importText}
            onChange={(event) => setImportText(event.currentTarget.value)}
            style={{
              height: '8rem',
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
                {overwriteLabel}
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
  );
}
