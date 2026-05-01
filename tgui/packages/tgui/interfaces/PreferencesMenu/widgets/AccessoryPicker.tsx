/**
 * @file widgets/AccessoryPicker.tsx
 * @description Grid picker for pre-baked /datum/customizer_choice catalogs.
 *
 * The DM side (`pref_catalog_materialize.dm`) bakes one manifest + a set of
 * per-variant PNGs into SSassets via `/datum/asset/simple/pref_catalog`.
 * The manifest is surfaced to TGUI through `ui_static_data` under
 * `pref_catalog_manifest`. This widget:
 *
 *   1. Looks up a sheet by name from `data.pref_catalog_manifest.sheets`.
 *   2. Emits one clickable `<SheetPreviewTile>` per entry, across every
 *      canonical size variant ({32,48,64}×{32,48,64}) the materializer
 *      kept for that sheet.
 *   3. Calls `onSelect(entryKey)` when the user clicks a tile.
 *
 * Entry key convention:
 *   - Non-sized choices: `sprite_accessory__...` (stable typepath slug).
 *   - Size-driven choices (breasts/penis/testicles): the entry key is
 *     suffixed with `__sizeN` (e.g. `sprite_accessory__breasts__pair__size3`).
 *     The caller owns how to map that back to a runtime selection — the
 *     picker treats the key as opaque.
 *
 * The entries list is variant-agnostic from the caller's perspective: we
 * flatten `variants["32x32"].entries` + `variants["32x48"].entries` + …
 * into a single grid. Each tile uses the outputPath of its own variant so
 * mixed-size sheets (e.g. horns with some 32x32 and some 32x48 accessories)
 * render each at native tile size.
 */

import { useMemo } from 'react';
import { Box, Stack, Tooltip } from 'tgui-core/components';

import { SheetPreviewTile } from './SheetPreviewTile';

/** Shape of one entry rect in the manifest. Matches the DM writer. */
interface PrefCatalogEntry {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface PrefCatalogVariant {
  outputPath: string;
  tileWidth: number;
  tileHeight: number;
  sheetWidth: number;
  sheetHeight: number;
  entries: Record<string, PrefCatalogEntry>;
}

interface PrefCatalogSheet {
  displayName?: string;
  customizerChoiceType?: string;
  allowsAccessoryColorCustomization?: boolean | number;
  variants: Record<string, PrefCatalogVariant>;
}

export interface PrefCatalogManifest {
  version?: number;
  speciesTargets?: string[];
  sheets?: Record<string, PrefCatalogSheet>;
}

export interface AccessoryPickerProps {
  /** Parsed manifest from `data.pref_catalog_manifest`. */
  manifest: PrefCatalogManifest | null | undefined;
  /**
   * Sheet name to render. Matches a top-level key under `manifest.sheets`
   * (e.g. `"customizer_choice__organ__horns__anthro"`).
   */
  sheetName: string;
  /** Currently selected entry key, or null for no selection. */
  selectedKey?: string | null;
  /** Click handler. Called with the entry key the user picked. */
  onSelect?: (entryKey: string) => void;
  /** Integer scale factor for tile rendering (default 2 for readability). */
  scale?: number;
  /** Max grid columns. Defaults to 6. */
  columns?: number;
  /**
   * Optional tint color (CSS string). Forwarded to every tile when the
   * sheet's `allowsAccessoryColorCustomization` flag is truthy. Lets
   * the picker preview the player's chosen accessory color directly
   * on the catalog grid without a server round-trip.
   */
  tint?: string;
}

/** Internal flattened-entry shape used when rendering the grid. */
interface FlatEntry {
  key: string;
  sheetAsset: string;
  rect: PrefCatalogEntry;
}

/** Flatten every variant's entries into one list, preserving DMI order. */
function flattenEntries(sheet: PrefCatalogSheet | undefined): FlatEntry[] {
  if (!sheet || !sheet.variants) {
    return [];
  }
  const out: FlatEntry[] = [];
  for (const sizeId of Object.keys(sheet.variants)) {
    const variant = sheet.variants[sizeId];
    if (!variant || !variant.entries || !variant.outputPath) {
      continue;
    }
    // Asset keys registered by pref_catalog_asset.dm use the
    // `pref_catalog/<outputPath>` prefix. `outputPath` here is the
    // manifest-relative path (e.g. `sheets/foo__32x32.png`).
    const sheetAsset = `pref_catalog/${variant.outputPath}`;
    for (const entryKey of Object.keys(variant.entries)) {
      const rect = variant.entries[entryKey];
      if (!rect) continue;
      out.push({ key: entryKey, sheetAsset, rect });
    }
  }
  return out;
}

/**
 * Humanize an entry key for the accessory label. Strips the common
 * `sprite_accessory__` prefix and converts `__` to spaces.
 */
function humanizeEntryKey(key: string): string {
  let label = key;
  if (label.startsWith('sprite_accessory__')) {
    label = label.slice('sprite_accessory__'.length);
  }
  // Size-variant suffix — keep as a trailing `(size N)` badge so users
  // can distinguish breast sizes etc.
  const sizeMatch = label.match(/^(.+)__size(\d+)$/);
  let sizeSuffix = '';
  if (sizeMatch) {
    label = sizeMatch[1];
    sizeSuffix = ` (size ${sizeMatch[2]})`;
  }
  return label.replace(/__/g, ' ').replace(/_/g, ' ') + sizeSuffix;
}

export function AccessoryPicker(props: AccessoryPickerProps) {
  const {
    manifest,
    sheetName,
    selectedKey = null,
    onSelect,
    scale = 2,
    columns = 6,
    tint,
  } = props;

  const sheet = manifest?.sheets?.[sheetName];
  const entries = useMemo(() => flattenEntries(sheet), [sheet]);
  // Only forward the tint to tiles when this sheet actually supports
  // per-accessory color customization. Painting a tint on a fixed-color
  // sheet would be visually misleading and contradict the DM model.
  const allowTint = !!sheet?.allowsAccessoryColorCustomization;
  const effectiveTint = allowTint ? tint : undefined;

  if (!sheet) {
    return (
      <Box color="label">
        No pref catalog sheet named <code>{sheetName}</code>. Run the
        “Materialize Pref Catalog” verb to regenerate the bundle.
      </Box>
    );
  }
  if (!entries.length) {
    return (
      <Box color="label">
        No entries baked for “{sheet.displayName ?? sheetName}”.
      </Box>
    );
  }

  // Simple flex grid. One row per `columns` entries. We don't use a CSS
  // Grid so the flow can wrap naturally if the pane is narrow.
  const rows: FlatEntry[][] = [];
  for (let i = 0; i < entries.length; i += columns) {
    rows.push(entries.slice(i, i + columns));
  }

  return (
    <Stack vertical>
      {rows.map((row, rowIdx) => (
        <Stack.Item key={rowIdx}>
          <Stack>
            {row.map((entry) => {
              const selected = entry.key === selectedKey;
              return (
                <Stack.Item key={entry.key}>
                  <Tooltip content={humanizeEntryKey(entry.key)}>
                    <Box
                      style={{
                        display: 'inline-block',
                        padding: '2px',
                        border: selected
                          ? '2px solid #ffb54a'
                          : '2px solid transparent',
                        background: selected ? '#33261a' : 'transparent',
                        cursor: onSelect ? 'pointer' : undefined,
                        textAlign: 'center',
                      }}
                      onClick={onSelect ? () => onSelect(entry.key) : undefined}
                    >
                      <SheetPreviewTile
                        sheetAsset={entry.sheetAsset}
                        x={entry.rect.x}
                        y={entry.rect.y}
                        width={entry.rect.width}
                        height={entry.rect.height}
                        scale={scale}
                        tint={effectiveTint}
                      />
                    </Box>
                  </Tooltip>
                </Stack.Item>
              );
            })}
          </Stack>
        </Stack.Item>
      ))}
    </Stack>
  );
}
