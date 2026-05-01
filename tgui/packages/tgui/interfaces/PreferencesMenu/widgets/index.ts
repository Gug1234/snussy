/**
 * @file widgets/index.ts
 * @description Barrel re-export for PreferencesMenu shared widgets.
 *
 * Consumers (category bodies in Steps 10-14) import from
 * `'./widgets'` rather than per-file paths, so introducing or
 * renaming a widget only touches this file.
 */

export type {
  AccessoryPickerProps,
  PrefCatalogManifest,
} from './AccessoryPicker';
export { AccessoryPicker } from './AccessoryPicker';
export type { BarkPreviewButtonProps } from './BarkPreviewButton';
export { BarkPreviewButton } from './BarkPreviewButton';
export type { BracketedValueSlotProps } from './BracketedValueSlot';
export { BracketedValueSlot } from './BracketedValueSlot';
export type { OriginMapProps, OriginRegion } from './OriginMap';
export { OriginMap } from './OriginMap';
export type { SheetPreviewTileProps } from './SheetPreviewTile';
export { SheetPreviewTile } from './SheetPreviewTile';
export type { StatMatrixProps } from './StatMatrix';
export { StatMatrix } from './StatMatrix';
export type { VoicePreviewButtonProps } from './VoicePreviewButton';
export { VoicePreviewButton } from './VoicePreviewButton';
