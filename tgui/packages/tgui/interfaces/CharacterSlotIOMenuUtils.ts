export const IMPORT_UPLOAD_CHUNK_SIZE = 12000;

export const splitImportTextForUpload = (
  rawText: string,
  chunkSize = IMPORT_UPLOAD_CHUNK_SIZE,
) => {
  const chunks: string[] = [];
  for (let start = 0; start < rawText.length; start += chunkSize) {
    chunks.push(rawText.slice(start, start + chunkSize));
  }
  return chunks;
};

export const getImportTransferPlan = (
  rawText: string,
  maxImportTextBytes = 0,
  chunkSize = IMPORT_UPLOAD_CHUNK_SIZE,
) => {
  const trimmedText = rawText.trim();
  const hasImport = !!trimmedText;
  const importTooLarge =
    !!maxImportTextBytes && trimmedText.length > maxImportTextBytes;

  return {
    trimmedText,
    hasImport,
    importTooLarge,
    chunks:
      hasImport && !importTooLarge
        ? splitImportTextForUpload(trimmedText, chunkSize)
        : [],
  };
};
