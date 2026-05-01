/**
 * @file CharacterPreviewMapView.tsx
 * @description Phase 1 / Step 7 of the tgstation `map_view` preview port.
 *
 * Wraps `<ByondUi type="map">` so TGUI interfaces can surface the live
 * server-owned `/atom/movable/screen/map_view/char_preview` dummy without
 * paying for `getFlatIcon` flattening or base64 roundtrips.
 *
 * Contract:
 *   - `mapId` is the BYOND map control id emitted by the prefs datum via
 *     `ui_static_data` as `character_preview_view` (e.g. `"character_preview_ref[…]"`).
 *     The backing DM view sets its `assigned_map` to this id during
 *     `Initialize`, so BYOND can route screen updates to the right control.
 *   - Must be mounted EXACTLY ONCE per window. Remounting (e.g. by moving
 *     this component inside a tab switcher) forces BYOND to re-initialise
 *     the map control and defeats the live-preview optimisation. Callers
 *     keep it outside the tab tree and let server-side tab switches drive
 *     `update_body()` via the `act_set_active_tab` action.
 *   - Rotate + background-picker controls ship here so every consumer
 *     (lobby prefs menu, standalone admin editors) gets identical chrome
 *     without re-implementing the forwarders.
 *
 * This component is intentionally thin. Heavy lifting (dummy composition,
 * strip-pass, canvas rescale) lives in the DM `char_preview_view.dm` datum;
 * this file only owns the map mount + chrome buttons + swatch strip that
 * emit `rotate` / `update_background` actions back to the server.
 */

import { Fragment } from 'react';
import { Box, Button, ByondUi, Flex } from 'tgui-core/components';

import { useBackend } from '../../backend';

/**
 * The 8 background swatches that mirror `GLOB.appearance_preview_background_states`
 * (see `code/_globalvars/lists/appearance_preview.dm`). Ordering matches the
 * glob list so the Nth swatch in the UI resolves to the Nth icon_state on
 * the `template*.dmi` sheets.
 *
 * Phase 1 renders text labels inside the swatches (the batched spritesheet
 * that will eventually crop real tiles lands in Phase 2). Each entry carries
 * a CSS fallback color so the picker is still visibly different per-swatch
 * before Phase 2 ships.
 */
export const CHARACTER_PREVIEW_BACKGROUND_STATES: ReadonlyArray<{
  /** Matches the DM-side icon_state string. */
  readonly state: string;
  /** Human-readable label rendered inside the swatch. */
  readonly label: string;
  /** CSS fallback used until Phase 2 sheet-cropped swatches arrive. */
  readonly fallbackColor: string;
}> = [
  { state: '000', label: 'Black', fallbackColor: '#000000' },
  { state: 'midgrey', label: 'Grey', fallbackColor: '#7f7f7f' },
  { state: 'FFF', label: 'White', fallbackColor: '#ffffff' },
  { state: 'greenstone', label: 'Moss', fallbackColor: '#4f5a3d' },
  { state: 'wood', label: 'Wood', fallbackColor: '#6b4a2b' },
  { state: 'cobblestone', label: 'Cobble', fallbackColor: '#8a8576' },
  { state: 'sand', label: 'Sand', fallbackColor: '#c9b079' },
  { state: 'church', label: 'Church', fallbackColor: '#d8ccb4' },
];

/**
 * Shape of the static data fields this component pulls from its host
 * interface. Kept as a loose partial so the component can be dropped into
 * any TGUI interface whose backend emits the three fields — the prefs menu
 * shell in Step 8 is the first intended consumer, but standalone editor
 * windows can adopt it piecemeal during Steps 9/10.
 */
export interface CharacterPreviewMapViewBackendData {
  /** BYOND map control id; empty string disables the map mount. */
  readonly character_preview_view?: string;
  /** Current background icon_state from the DM-side `background_state` pref. */
  readonly background_state?: string;
}

type Props = {
  /**
   * BYOND map control id. Accepting this as a prop (rather than always
   * reading from backend) lets the prefs menu hoist the id once and pass
   * it through memoised so the underlying `ByondUi` never sees prop churn.
   */
  mapId: string;
  /**
   * Current background icon_state. Used purely for the swatch `selected`
   * affordance — server remains source of truth.
   */
  backgroundState?: string;
  /** Width in pixels. Default 96 (3 tiles × 32, matches the 3×3 lobby HUD). */
  width?: number;
  /** Height in pixels. Default 96. */
  height?: number;
  /** Show the rotate CCW/CW buttons row. */
  showRotateControls?: boolean;
  /** Show the 8-swatch background picker. */
  showBackgroundPicker?: boolean;
};

/**
 * Live character preview + optional rotate/background chrome.
 *
 * Rendering layers (top to bottom):
 *   1. `<ByondUi type="map" id={mapId}>` — the native BYOND map control
 *      that streams the server dummy's appearance.
 *   2. Rotate CCW / CW buttons — dispatch `rotate` with the `backwards`
 *      flag. Server handler is `/datum/preferences/proc/act_rotate` which
 *      walks `GLOB.appearance_preview_rotation_cw` (S→W→N→E) and calls
 *      `character_preview_view.setDir(new_dir)`.
 *   3. Background swatch strip — dispatches `update_background` with the
 *      chosen state; server validates against
 *      `GLOB.appearance_preview_background_states`, persists, and triggers
 *      `update_body()` so the canvas sheet swaps icon_state in place.
 */
export function CharacterPreviewMapView(props: Props) {
  const {
    mapId,
    backgroundState,
    width = 96,
    height = 96,
    showRotateControls = true,
    showBackgroundPicker = true,
  } = props;
  // `act` is the only backend surface we need — the map id is already a
  // prop, and the backend isn't parameterised per-interface here.
  const { act } = useBackend();

  // Guard against a missing map id (e.g. prefs not yet allocated the view).
  // Rendering an empty `ByondUi` would still mount a BYOND map control
  // with an empty assigned_map, which is harmless but confusing; short-
  // circuiting keeps the DOM clean during that short window.
  const hasMap = typeof mapId === 'string' && mapId.length > 0;

  return (
    <Box
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '4px',
      }}
    >
      {hasMap ? (
        <ByondUi
          params={{
            id: mapId,
            type: 'map',
            // BYOND map controls default to native 32x32 tiles rendered
            // in the top-left of the control. For the single-tile
            // character preview we want the one visible tile to fill
            // the entire ByondUi box. `icon-size` alone is insufficient
            // because `zoom-mode` defaults to "normal" (1:1 pixel
            // mapping regardless of icon-size). Pinning zoom-mode to
            // "distort" lets BYOND rescale the tile to the requested
            // pixel dimensions without smoothing artefacts.
            'icon-size': width,
            'zoom-mode': 'distort',
            zoom: 0,
          }}
          style={{
            width: `${width}px`,
            height: `${height}px`,
          }}
        />
      ) : (
        <Box
          style={{
            width: `${width}px`,
            height: `${height}px`,
            background: '#111',
            border: '1px dashed #444',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#888',
            fontSize: '11px',
          }}
        >
          no preview
        </Box>
      )}

      {showRotateControls ? (
        <Flex align="center" justify="center">
          <Flex.Item>
            <Button
              icon="undo"
              tooltip="Rotate counter-clockwise"
              onClick={() => act('rotate', { backwards: true })}
            />
          </Flex.Item>
          <Flex.Item ml={1}>
            <Button
              icon="redo"
              tooltip="Rotate clockwise"
              onClick={() => act('rotate', { backwards: false })}
            />
          </Flex.Item>
        </Flex>
      ) : null}

      {showBackgroundPicker ? (
        <Flex
          align="center"
          wrap="wrap"
          style={{ gap: '2px', maxWidth: `${Math.max(width, 192)}px` }}
        >
          {CHARACTER_PREVIEW_BACKGROUND_STATES.map((sw) => {
            const selected = backgroundState === sw.state;
            return (
              <Fragment key={sw.state}>
                <Flex.Item>
                  <Button
                    selected={selected}
                    tooltip={sw.label}
                    // Phase 1: small square with the fallback color + 1-char
                    // label. Phase 2 will replace the style with a sheet
                    // crop via the batched spritesheet runtime.
                    style={{
                      width: '18px',
                      height: '18px',
                      padding: 0,
                      background: sw.fallbackColor,
                      border: selected ? '2px solid #f2c94c' : '1px solid #222',
                      color: sw.fallbackColor === '#ffffff' ? '#000' : '#fff',
                      fontSize: '9px',
                      lineHeight: '16px',
                      textAlign: 'center',
                    }}
                    onClick={() =>
                      act('update_background', { state: sw.state })
                    }
                  >
                    {sw.label.charAt(0)}
                  </Button>
                </Flex.Item>
              </Fragment>
            );
          })}
        </Flex>
      ) : null}
    </Box>
  );
}
