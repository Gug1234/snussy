/**
 * @file HybridOffsetOverlay.test.tsx
 * @description Focused Step 7/9 coverage for the shared hybrid offset overlay
 * shell. These tests lock the renderer-agnostic pieces that every editor will
 * depend on before taur/custom/intimate migrations add editor-specific
 * fixtures: BYOND-to-CSS transform conversion, descriptor field gating, local
 * drag math, hidden guide state, descriptor layer rendering, and the map-only
 * fallback when the server cannot provide a guide descriptor.
 */

import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
} from 'bun:test';
import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';

import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type AppearancePreviewManifestV2,
  type HybridGuideDescriptor,
  type HybridOffsetField,
  type OffsetTransformProps,
} from './shared';

type HybridOffsetOverlayModule = typeof import('./HybridOffsetOverlay');
type HybridOffsetOverlayProps = Parameters<
  HybridOffsetOverlayModule['HybridOffsetOverlay']
>[0];

let overlayModule: HybridOffsetOverlayModule;

beforeAll(async () => {
  (
    globalThis as unknown as { IS_REACT_ACT_ENVIRONMENT: boolean }
  ).IS_REACT_ACT_ENVIRONMENT = true;
  const byondStub = {
    windowId: 'hybrid-offset-overlay-test',
    call: () => undefined,
    winget: () => '',
    winset: () => undefined,
    subscribe: () => undefined,
  };
  (globalThis as unknown as { Byond: unknown }).Byond = byondStub;
  if ('window' in globalThis) {
    (window as unknown as { Byond: unknown }).Byond = byondStub;
  }
  overlayModule = await import('./HybridOffsetOverlay');
});

const ALL_FIELDS: readonly HybridOffsetField[] = [
  'x',
  'y',
  'turn',
  'flip',
  'hide',
  'shrink',
  'above',
];

const manifest: AppearancePreviewManifestV2 = {
  version: APPEARANCE_PREVIEW_MANIFEST_VERSION,
  backend: APPEARANCE_PREVIEW_BACKEND_ID,
  layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
  canonicalLookupKey: 'icon_state',
  categoryOrder: ['custom_piercing'],
  categories: {
    custom_piercing: {
      key: 'custom_piercing',
      scope: 'catalog',
      states: ['stud_metal', 'stud_gem'],
    },
  },
  sheets: {
    pack: {
      id: 'pack',
      family: 'custom_piercings',
      path: 'sheets/pack.png',
      width: 64,
      height: 32,
      tileWidth: 32,
      tileHeight: 32,
      contentHash: 'hash',
    },
  },
  states: {
    stud_metal: {
      iconState: 'stud_metal',
      family: 'custom_piercings',
      sheetId: 'pack',
      crops: { s: { x: 0, y: 0, width: 32, height: 32 } },
    },
    stud_gem: {
      iconState: 'stud_gem',
      family: 'custom_piercings',
      sheetId: 'pack',
      crops: { s: { x: 32, y: 0, width: 32, height: 32 } },
    },
  },
  build: {
    builtAt: '1970-01-01T00:00:00.000Z',
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    sourceFingerprint: 'fp',
    adapterVersions: { custom_piercings: '1.0.0' },
  },
};

const descriptor: HybridGuideDescriptor = {
  id: 'custom_piercing:stud:s',
  family: 'custom_piercings',
  targetKey: 'stud',
  manifestCategory: 'custom_piercing',
  direction: 's',
  layers: [
    { iconState: 'stud_metal', role: 'metal' },
    { iconState: 'stud_gem', role: 'gem' },
  ],
  nativeWidth: 32,
  nativeHeight: 32,
  allowedFields: ALL_FIELDS,
  approximateColor: true,
};

const draft: OffsetTransformProps = {
  x: 3,
  y: 4,
  turn: 0,
  flip: false,
  hide: false,
  shrink: 1,
};

let container: HTMLDivElement | null = null;
let root: Root | null = null;

beforeEach(() => {
  container = document.createElement('div');
  document.body.appendChild(container);
  root = createRoot(container);
});

afterEach(() => {
  if (root) {
    act(() => {
      root!.unmount();
    });
    root = null;
  }
  if (container) {
    container.remove();
    container = null;
  }
});

function renderOverlay(props: Partial<HybridOffsetOverlayProps>): void {
  const Overlay = overlayModule.HybridOffsetOverlay;
  act(() => {
    root!.render(
      <Overlay
        manifest={manifest}
        descriptor={descriptor}
        draftProps={draft}
        onDraftChange={() => undefined}
        mapView={<div data-testid="map-backdrop">map</div>}
        {...props}
      />,
    );
  });
}

describe('hybrid offset transform helpers', () => {
  it('converts BYOND positive-y offsets into CSS negative-y translation', () => {
    const transformDraft: OffsetTransformProps = {
      x: 4,
      y: 7,
      turn: 90,
      flip: true,
      hide: false,
      shrink: 2,
      above: true,
    };

    expect(
      overlayModule.buildHybridOffsetCssTransform(transformDraft, ALL_FIELDS),
    ).toBe('translate(4px, -7px) rotate(90deg) scale(-2, 2)');
  });

  it('scales BYOND pixel offsets for zoomed guide displays', () => {
    const transformDraft: OffsetTransformProps = {
      x: 4,
      y: 7,
      turn: 0,
      flip: false,
      hide: false,
      shrink: 1,
    };

    expect(
      overlayModule.buildHybridOffsetCssTransform(
        transformDraft,
        ALL_FIELDS,
        3,
      ),
    ).toBe('translate(12px, -21px) rotate(0deg) scale(1, 1)');
  });

  it('drops transform props not allowed by the server descriptor', () => {
    const transformDraft: OffsetTransformProps = {
      x: 4,
      y: 7,
      turn: 90,
      flip: true,
      hide: true,
      shrink: 2,
      above: true,
    };

    expect(
      overlayModule.normaliseHybridOffsetTransform(transformDraft, ['x', 'y']),
    ).toEqual({
      x: 4,
      y: 7,
      turn: 0,
      flip: false,
      hide: false,
      shrink: 1,
      above: undefined,
    });
  });

  it('translates pointer movement into a local draft without server actions', () => {
    const dragDraft: OffsetTransformProps = {
      x: 1,
      y: 2,
      turn: 0,
      flip: false,
      hide: false,
      shrink: 1,
    };

    expect(
      overlayModule.resolveHybridOffsetDragDraft(dragDraft, {
        startClientX: 50,
        startClientY: 50,
        currentClientX: 54,
        currentClientY: 47,
      }),
    ).toEqual({
      x: 5,
      y: 5,
      turn: 0,
      flip: false,
      hide: false,
      shrink: 1,
    });
  });

  it('keeps drag math inert for axes the descriptor does not allow', () => {
    expect(
      overlayModule.resolveHybridOffsetDragDraft(
        draft,
        {
          startClientX: 50,
          startClientY: 50,
          currentClientX: 70,
          currentClientY: 20,
        },
        ['hide'],
      ),
    ).toEqual(draft);

    expect(
      overlayModule.resolveHybridOffsetDragDraft(
        draft,
        {
          startClientX: 50,
          startClientY: 50,
          currentClientX: 70,
          currentClientY: 20,
        },
        ['x'],
      ),
    ).toEqual({
      ...draft,
      x: 23,
    });
  });
});

describe('HybridOffsetOverlay rendering', () => {
  it('renders the map backdrop without a guide when the descriptor is missing', () => {
    renderOverlay({ descriptor: null });

    expect(container!.querySelector('[data-hybrid-offset-map]')).not.toBeNull();
    expect(container!.querySelector('[data-hybrid-offset-guide]')).toBeNull();
    expect(container!.textContent).toContain('map');
  });

  it('renders one guide layer for each server descriptor layer', () => {
    renderOverlay({});
    const guide = container!.querySelector(
      '[data-hybrid-offset-guide]',
    ) as HTMLDivElement;
    const layers = container!.querySelectorAll('[data-hybrid-offset-layer]');

    expect(guide).not.toBeNull();
    expect(guide.dataset.hidden).toBe('false');
    expect(guide.style.transform).toContain('translate(3px, -4px)');
    expect(layers).toHaveLength(2);
    expect(layers[0].getAttribute('data-hybrid-offset-layer')).toBe('metal');
    expect(layers[1].getAttribute('data-hybrid-offset-layer')).toBe('gem');
  });

  it('keeps hidden guides in the DOM but disables pointer interaction', () => {
    renderOverlay({
      draftProps: {
        ...draft,
        hide: true,
      },
    });
    const guide = container!.querySelector(
      '[data-hybrid-offset-guide]',
    ) as HTMLDivElement;

    expect(guide.dataset.hidden).toBe('true');
    expect(guide.style.opacity).toBe('0');
    expect(guide.style.pointerEvents).toBe('none');
  });
});
