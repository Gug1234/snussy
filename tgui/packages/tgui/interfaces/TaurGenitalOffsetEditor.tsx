/**
 * @file TaurGenitalOffsetEditor.tsx
 * @description Taur genital sprite-offset editor rebuilt on the v2 shared
 * appearance-preview runtime (Step 10 of the RustG-First refactor).
 *
 * ## Client-first contract
 *
 * The editor owns all draft state from the moment the panel opens. No
 * server round-trips happen during editing -- every control mutates local
 * React state and the preview updates immediately. On Save the client posts
 * a single `commit` action carrying the full draft snapshot. On Close the
 * client posts `commit` first if dirty, then `close`.
 *
 * ## Preview pipeline
 *
 * The active guide sprite is rendered through `<HybridOffsetOverlay>` from
 * server-provided `hybrid_descriptors`. TGUI no longer composes taur DMI
 * icon-state names locally; it only adapts the existing per-direction draft
 * props into the shared overlay transform shape.
 */

import {
  type CSSProperties,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import {
  type AppearancePreviewManifestV2,
  AppearancePreviewProvider,
  DirectionControls,
  EditorShell,
  type HybridGuideDescriptor,
  HybridOffsetOverlay,
  type OffsetTransformProps,
  useAppearancePreview,
  useCommitController,
} from '../components/appearance-preview';
import { Window } from '../layouts';
import {
  applyField,
  applyTaurHybridDraftToPartProps,
  defaultPartProps,
  type DirKey,
  type FieldKey,
  getActiveTaurHybridDescriptor,
  type PartKey,
  type PartProps,
  partPropsToTaurHybridDraft,
  SHRINK_MAX,
  SHRINK_MIN,
  type TaurHybridDescriptorMap,
  TURN_MAX,
  TURN_MIN,
  XY_MAX,
  XY_MIN,
} from './TaurGenitalOffsetEditorLogic';

type BackendData = {
  initial_part: PartKey;
  initial_erect_state: number;
  part_keys: PartKey[];
  erect_state_keys: number[];
  erect_state_labels: Record<string, string>;
  dir_keys: DirKey[];
  field_keys: FieldKey[];
  hybrid_descriptors?: TaurHybridDescriptorMap;
  initial_snapshot: {
    penis_state_props: Record<string, PartProps>;
    testicles_props: PartProps;
    vagina_props: PartProps;
    global_hide: Record<DirKey, number>;
  };
  /** Commit envelope metadata echoed back on every `commit` action. */
  commit_contract: CommitContract;
  /** Outcome of the most recent commit, or null before the first attempt. */
  last_commit_result: LastCommitResult;
  /**
   * Per-direction base64 PNG snapshots of the owning client's character
   * mannequin, built server-side by `build_mannequin_previews()`. Used as
   * a background layer so the genital offset can be judged against the
   * real body silhouette. Missing directions fall back to the bare
   * checkerboard.
   */
  mannequin_previews?: Partial<Record<DirKey, string>>;
};

/** Commit envelope metadata contract (Step 12). */
type CommitContract = {
  editor_kind: string;
  pref_key: string;
  family_id: string;
  revision_token: number;
};

/** Server-reported commit outcome. */
type LastCommitResult = {
  ok: boolean;
  code: string;
  message: string | null;
  revision_token: number;
} | null;

/** Commit payload shape mirrored in `_apply_snapshot` on the DM side. */
type CommitSnapshot = {
  penis_state_props: Record<string, PartProps>;
  testicles_props: PartProps;
  vagina_props: PartProps;
  global_hide: Record<DirKey, number>;
};

const DIR_LABELS: Record<DirKey, string> = {
  s: 'South',
  n: 'North',
  e: 'East',
  w: 'West',
};

const PART_LABELS: Record<PartKey, string> = {
  penis: 'Penis',
  testicles: 'Testicles',
  vagina: 'Vagina',
};

// Preview canvas sizing. The source tile is 32x32; we display at scale=3
// (96x96) inside a 288x288 frame so offsets up to +/-64 stay on-screen.
const PREVIEW_SCALE = 3;
const PREVIEW_TILE_PX = 32 * PREVIEW_SCALE;
const PREVIEW_FRAME_PX = 288;

/** Outer component: wraps the v2 provider around the inner editor. */
export function TaurGenitalOffsetEditor() {
  return (
    <Window theme="rogue" width={560} height={640}>
      <Window.Content scrollable>
        <AppearancePreviewProvider>
          <TaurGenitalOffsetEditorInner />
        </AppearancePreviewProvider>
      </Window.Content>
    </Window>
  );
}

function TaurGenitalOffsetEditorInner() {
  const { act, data } = useBackend<BackendData>();
  const {
    initial_part,
    initial_erect_state,
    part_keys = ['penis', 'testicles', 'vagina'],
    erect_state_keys = [0, 1, 2],
    erect_state_labels = {},
    dir_keys = ['s', 'n', 'e', 'w'],
    hybrid_descriptors,
    initial_snapshot,
  } = data;
  const { manifest, loading, error } = useAppearancePreview();

  // ── Local draft state ────────────────────────────────────────────────
  // Seeded once from the initial snapshot; subsequent edits never touch
  // the server until commit. useState initializer runs once per mount.
  const [penisStateProps, setPenisStateProps] = useState<
    Record<string, PartProps>
  >(() => ({ ...(initial_snapshot?.penis_state_props ?? {}) }));
  const [testiclesProps, setTesticlesProps] = useState<PartProps>(() => ({
    ...(initial_snapshot?.testicles_props ?? defaultPartProps('testicles')),
  }));
  const [vaginaProps, setVaginaProps] = useState<PartProps>(() => ({
    ...(initial_snapshot?.vagina_props ?? defaultPartProps('vagina')),
  }));
  const [globalHide, setGlobalHide] = useState<Record<DirKey, number>>(() => ({
    ...(initial_snapshot?.global_hide ?? { s: 0, n: 0, e: 0, w: 0 }),
  }));

  // ── Active tab state (local only; server never sees these) ───────────
  const [activePart, setActivePart] = useState<PartKey>(
    initial_part ?? 'penis',
  );
  const [activeErectState, setActiveErectState] = useState<number>(
    initial_erect_state ?? 0,
  );
  const [activeDir, setActiveDir] = useState<DirKey>('s');

  const [dirty, setDirty] = useState(false);
  // Commit lifecycle is owned by the shared controller so Close cannot tear
  // the window down before the server confirms persistence. EditorShell
  // consumes the controller + renders DirtyIndicator/CommitBar/banner.
  const commitController = useCommitController<CommitSnapshot>({
    act,
    contract: data.commit_contract,
    lastCommitResult: data.last_commit_result,
  });

  // ── Refocus sync (Remediation Step 8) ────────────────────────────────
  // The server updates `initial_part` / `initial_erect_state` when the user
  // re-invokes the editor verb on a different part or erection stage. If
  // our local draft is clean, reseed the active tab immediately; if dirty,
  // queue the reseed and surface an aria-live notice so the refocus is
  // never silently dropped and the unsaved edits are never silently lost.
  //
  // `pendingRefocusRef` preserves the latest targets across dirty-window
  // ticks so the reseed fires exactly once when dirty flips back to false.
  const [refocusNotice, setRefocusNotice] = useState<string | null>(null);
  const pendingRefocusRef = useRef<{
    part: PartKey;
    erect: number;
  } | null>(null);
  // Tracks the last server-sourced target we actually consumed, so we only
  // react to genuine server-side changes (not our own setActivePart calls).
  const lastSeenInitialRef = useRef<{ part: PartKey; erect: number }>({
    part: initial_part ?? 'penis',
    erect: initial_erect_state ?? 0,
  });

  useEffect(() => {
    const nextPart = initial_part ?? 'penis';
    const nextErect = initial_erect_state ?? 0;
    const prev = lastSeenInitialRef.current;
    if (prev.part === nextPart && prev.erect === nextErect) return;
    lastSeenInitialRef.current = { part: nextPart, erect: nextErect };

    if (!dirty) {
      // Clean draft: reseed in place.
      setActivePart(nextPart);
      setActiveErectState(nextErect);
      setRefocusNotice(null);
      pendingRefocusRef.current = null;
      return;
    }

    // Dirty draft: queue + announce. Do not touch the active tabs.
    pendingRefocusRef.current = { part: nextPart, erect: nextErect };
    setRefocusNotice(
      'Another open request was ignored to protect your unsaved edits.',
    );
  }, [initial_part, initial_erect_state, dirty]);

  // Drain a queued refocus the moment the draft goes clean (commit success
  // or user manually reset). `status` is included because a commit that
  // resolves via the controller transitions status before `dirty` is
  // cleared by our onCommitted callback.
  useEffect(() => {
    if (dirty) return;
    const pending = pendingRefocusRef.current;
    if (!pending) return;
    pendingRefocusRef.current = null;
    setActivePart(pending.part);
    setActiveErectState(pending.erect);
    setRefocusNotice(null);
  }, [dirty]);

  // ── Helpers for the currently-active part's props ────────────────────
  const currentProps: PartProps = useMemo(() => {
    switch (activePart) {
      case 'penis':
        return (
          penisStateProps[String(activeErectState)] ?? defaultPartProps('penis')
        );
      case 'testicles':
        return testiclesProps;
      case 'vagina':
        return vaginaProps;
    }
  }, [
    activePart,
    activeErectState,
    penisStateProps,
    testiclesProps,
    vaginaProps,
  ]);

  /** Writes an updated props map back into the right draft state slot. */
  const writeCurrentProps = useCallback(
    (next: PartProps) => {
      switch (activePart) {
        case 'penis':
          setPenisStateProps((prev) => ({
            ...prev,
            [String(activeErectState)]: next,
          }));
          break;
        case 'testicles':
          setTesticlesProps(next);
          break;
        case 'vagina':
          setVaginaProps(next);
          break;
      }
      setDirty(true);
    },
    [activePart, activeErectState],
  );

  const val = (field: FieldKey, fallback = 0): number => {
    const v = currentProps[`${activeDir}${field}`];
    return typeof v === 'number' ? v : fallback;
  };

  const setField = (field: FieldKey, raw: number | boolean) => {
    writeCurrentProps(applyField(currentProps, activeDir, field, raw));
  };

  const toggleField = (field: FieldKey) => {
    setField(field, !val(field));
  };

  const resetDir = () => {
    const defaults = defaultPartProps(activePart);
    const next = { ...currentProps };
    for (const f of [
      'x',
      'y',
      'turn',
      'flip',
      'above',
      'hide',
      'shrink',
    ] as FieldKey[]) {
      next[`${activeDir}${f}`] = defaults[`${activeDir}${f}`];
    }
    writeCurrentProps(next);
  };

  const resetPart = () => {
    if (activePart === 'penis') {
      setPenisStateProps(() => {
        const out: Record<string, PartProps> = {};
        for (const state of erect_state_keys) {
          out[String(state)] = defaultPartProps('penis');
        }
        return out;
      });
    } else if (activePart === 'testicles') {
      setTesticlesProps(defaultPartProps('testicles'));
    } else {
      setVaginaProps(defaultPartProps('vagina'));
    }
    setDirty(true);
  };

  const mirrorEastToWest = () => {
    const next = { ...currentProps };
    for (const field of [
      'x',
      'y',
      'turn',
      'flip',
      'above',
      'hide',
      'shrink',
    ] as FieldKey[]) {
      const source = currentProps[`e${field}`];
      let mirrored: number | boolean;
      if (field === 'x' || field === 'turn') {
        mirrored = -Number(source || 0);
      } else {
        mirrored = source;
      }
      next[`w${field}`] = applyField(next, 'w', field, mirrored)[`w${field}`];
    }
    writeCurrentProps(next);
  };

  const toggleGlobalHide = (dir: DirKey) => {
    setGlobalHide((prev) => ({ ...prev, [dir]: prev[dir] ? 0 : 1 }));
    setDirty(true);
  };

  // ── Commit snapshot builder ──────────────────────────────────────────
  // Pure closure over current draft state; the shell invokes this at the
  // moment of Save/Close so the latest state is captured.
  const buildSnapshot = (): CommitSnapshot => ({
    penis_state_props: penisStateProps,
    testicles_props: testiclesProps,
    vagina_props: vaginaProps,
    global_hide: globalHide,
  });

  // ── Preview tile lookup ──────────────────────────────────────────────
  const hybridDescriptor = useMemo(
    () =>
      getActiveTaurHybridDescriptor(
        hybrid_descriptors,
        activePart,
        activeErectState,
        activeDir,
      ),
    [hybrid_descriptors, activePart, activeErectState, activeDir],
  );

  const activeDraft = useMemo(
    () => partPropsToTaurHybridDraft(currentProps, activeDir, globalHide),
    [currentProps, activeDir, globalHide],
  );

  const handlePreviewDraftChange = useCallback(
    (nextDraft: OffsetTransformProps) => {
      writeCurrentProps(
        applyTaurHybridDraftToPartProps(currentProps, activeDir, nextDraft),
      );
    },
    [activeDir, currentProps, writeCurrentProps],
  );

  const activeStateLabel =
    activePart === 'penis'
      ? (erect_state_labels[String(activeErectState)] ?? 'Arousal')
      : null;

  // ── Render ───────────────────────────────────────────────────────────
  return (
    <EditorShell<CommitSnapshot>
      title="Taur Genital Offsets"
      dirty={dirty}
      commitController={commitController}
      buildSnapshot={buildSnapshot}
      onCommitted={() => setDirty(false)}
      onCloseClean={() => act('close')}
    >
      {refocusNotice && (
        <div
          role="status"
          aria-live="polite"
          style={{
            marginBottom: '0.5rem',
            padding: '0.25rem 0.5rem',
            background: 'rgba(180, 140, 60, 0.15)',
            border: '1px solid rgba(180, 140, 60, 0.45)',
            borderRadius: '2px',
            fontSize: '11px',
          }}
        >
          {refocusNotice}
        </div>
      )}
      <Box mb={1} opacity={0.6} fontSize="11px" italic>
        Tune per-direction sprite placement for each taur genital. The preview
        updates locally; the lobby mannequin only changes on explicit commit.
      </Box>

      <Tabs>
        {part_keys.map((part) => (
          <Tabs.Tab
            key={part}
            selected={part === activePart}
            onClick={() => setActivePart(part)}
          >
            {PART_LABELS[part]}
          </Tabs.Tab>
        ))}
      </Tabs>

      {activePart === 'penis' && (
        <Tabs mb={1}>
          {erect_state_keys.map((state) => (
            <Tabs.Tab
              key={state}
              selected={state === activeErectState}
              onClick={() => setActiveErectState(state)}
            >
              {erect_state_labels[String(state)] ?? `State ${state}`}
            </Tabs.Tab>
          ))}
        </Tabs>
      )}

      <Section
        title="Preview"
        buttons={
          <DirectionControls
            activeDir={activeDir}
            dirKeys={dir_keys}
            onChange={setActiveDir}
          />
        }
      >
        <TaurPreview
          loading={loading}
          error={error}
          manifest={manifest}
          descriptor={hybridDescriptor}
          direction={activeDir}
          draftProps={activeDraft}
          onDraftChange={handlePreviewDraftChange}
          mannequinPreviews={data.mannequin_previews}
        />
      </Section>

      <Section
        title={`${PART_LABELS[activePart]}${activeStateLabel ? ` - ${activeStateLabel}` : ''} - ${DIR_LABELS[activeDir]}`}
        buttons={
          <>
            <Button
              icon="undo"
              compact
              tooltip={
                activePart === 'penis'
                  ? 'Reset this direction in the current arousal state to defaults'
                  : 'Reset this direction to defaults'
              }
              onClick={resetDir}
            >
              Reset Dir
            </Button>
            <Button
              icon="undo-alt"
              color="bad"
              compact
              tooltip={
                activePart === 'penis'
                  ? 'Reset all directions in every arousal state to defaults'
                  : 'Reset ALL directions of this part to defaults'
              }
              onClick={resetPart}
            >
              Reset Part
            </Button>
            <Button
              compact
              tooltip="Copy East to West with X and rotation mirrored, Y preserved"
              onClick={mirrorEastToWest}
            >
              Mirror E -&gt; W
            </Button>
          </>
        }
      >
        <LabeledList>
          <LabeledList.Item label="Offset X">
            <NumberInput
              width="60px"
              step={1}
              stepPixelSize={4}
              value={val('x')}
              minValue={XY_MIN}
              maxValue={XY_MAX}
              onChange={(value) => setField('x', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
          </LabeledList.Item>
          <LabeledList.Item label="Offset Y">
            <NumberInput
              width="60px"
              step={1}
              stepPixelSize={4}
              value={val('y')}
              minValue={XY_MIN}
              maxValue={XY_MAX}
              onChange={(value) => setField('y', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
          </LabeledList.Item>
          <LabeledList.Item label="Rotation">
            <NumberInput
              width="60px"
              step={5}
              stepPixelSize={4}
              value={val('turn')}
              minValue={TURN_MIN}
              maxValue={TURN_MAX}
              onChange={(value) => setField('turn', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>deg</span>
          </LabeledList.Item>
          <LabeledList.Item label="Scale">
            <NumberInput
              width="70px"
              step={0.05}
              stepPixelSize={4}
              value={val('shrink', 1.0)}
              minValue={SHRINK_MIN}
              maxValue={SHRINK_MAX}
              onChange={(value) => setField('shrink', value)}
            />
            <span style={{ opacity: 0.4, marginLeft: '6px' }}>x</span>
            {(activePart === 'penis' || activePart === 'testicles') &&
              val('shrink', 1) >= 3 && (
                <span
                  style={{
                    marginLeft: '8px',
                    fontSize: '11px',
                    fontStyle: 'italic',
                    color: '#c97a7a',
                    opacity: 0.85,
                  }}
                >
                  very mature.
                </span>
              )}
          </LabeledList.Item>
          <LabeledList.Item label="Horizontal Flip">
            <Button.Checkbox
              checked={!!val('flip')}
              onClick={() => toggleField('flip')}
            >
              {val('flip') ? 'Flipped' : 'Normal'}
            </Button.Checkbox>
          </LabeledList.Item>
          <LabeledList.Item label="Layer">
            <Button.Checkbox
              checked={!!val('above')}
              onClick={() => toggleField('above')}
            >
              {val('above') ? 'Over Body' : 'Under Body'}
            </Button.Checkbox>
          </LabeledList.Item>
          <LabeledList.Item label="Hide">
            <Button.Checkbox
              checked={!!val('hide')}
              color={val('hide') ? 'bad' : undefined}
              onClick={() => toggleField('hide')}
            >
              {val('hide') ? 'Hidden this direction' : 'Visible'}
            </Button.Checkbox>
          </LabeledList.Item>
        </LabeledList>
      </Section>

      <Section title="Global Per-Direction Hide">
        <Box mb={1} opacity={0.6} fontSize="11px" italic>
          Hides ALL taur genital sprites (not just this part) when the character
          faces the toggled direction. Stacks on top of per-part hide.
        </Box>
        <Stack>
          {dir_keys.map((dir) => (
            <Stack.Item key={dir} grow>
              <Button.Checkbox
                fluid
                checked={!!globalHide[dir]}
                color={globalHide[dir] ? 'bad' : undefined}
                onClick={() => toggleGlobalHide(dir)}
              >
                {DIR_LABELS[dir]}
              </Button.Checkbox>
            </Stack.Item>
          ))}
        </Stack>
      </Section>
    </EditorShell>
  );
}

/**
 * Static map-view substitute for the standalone taur editor.
 *
 * The parent `HybridOffsetOverlay` owns guide rendering and drag logic. This
 * node only paints the server-rendered mannequin snapshot behind it while the
 * broader preferences shell continues to own the live BYOND map_view.
 */
function MannequinBackdrop(props: {
  mannequinPreviews?: Partial<Record<DirKey, string>>;
  direction: DirKey;
}) {
  const { mannequinPreviews, direction } = props;
  const b64 = mannequinPreviews?.[direction];
  const frameStyle: CSSProperties = {
    position: 'relative',
    width: '100%',
    height: '100%',
    background:
      'repeating-conic-gradient(#222 0 25%, #2a2a2a 0 50%) 50% / 16px 16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    overflow: 'hidden',
  };
  const style: CSSProperties = {
    position: 'absolute',
    left: '50%',
    top: '50%',
    width: `${PREVIEW_TILE_PX}px`,
    height: `${PREVIEW_TILE_PX}px`,
    marginLeft: `${-PREVIEW_TILE_PX / 2}px`,
    marginTop: `${-PREVIEW_TILE_PX / 2}px`,
    backgroundImage: `url(data:image/png;base64,${b64})`,
    backgroundRepeat: 'no-repeat',
    backgroundPosition: 'center',
    backgroundSize: 'contain',
    imageRendering: 'pixelated',
    pointerEvents: 'none',
  };
  return (
    <Box style={frameStyle}>
      {b64 ? <div style={style} aria-hidden /> : null}
    </Box>
  );
}

function TaurPreview(props: {
  loading: boolean;
  error: Error | null;
  manifest: AppearancePreviewManifestV2 | null;
  descriptor: HybridGuideDescriptor | null;
  direction: DirKey;
  draftProps: OffsetTransformProps;
  onDraftChange: (nextProps: OffsetTransformProps) => void;
  mannequinPreviews?: Partial<Record<DirKey, string>>;
}) {
  const {
    loading,
    error,
    manifest,
    descriptor,
    direction,
    draftProps,
    onDraftChange,
    mannequinPreviews,
  } = props;

  const frameStyle = {
    position: 'relative' as const,
    width: `${PREVIEW_FRAME_PX}px`,
    height: `${PREVIEW_FRAME_PX}px`,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background:
      'repeating-conic-gradient(#222 0 25%, #2a2a2a 0 50%) 50% / 16px 16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
  };

  if (loading || !manifest) {
    return (
      <Box style={frameStyle}>
        <Box opacity={0.65} italic>
          Loading preview assets...
        </Box>
      </Box>
    );
  }

  if (error) {
    return (
      <Box style={frameStyle}>
        <Box color="bad" italic>
          Preview manifest failed to load: {error.message}
        </Box>
      </Box>
    );
  }

  const hidden = !!draftProps.hide;

  return (
    <Box style={{ position: 'relative', width: PREVIEW_FRAME_PX }}>
      <HybridOffsetOverlay
        manifest={manifest}
        descriptor={descriptor}
        direction={direction}
        draftProps={draftProps}
        onDraftChange={onDraftChange}
        mapView={
          <MannequinBackdrop
            mannequinPreviews={mannequinPreviews}
            direction={direction}
          />
        }
        previewWidth={PREVIEW_FRAME_PX}
        previewHeight={PREVIEW_FRAME_PX}
        guideScale={PREVIEW_SCALE}
        dragPixelRatio={PREVIEW_SCALE}
        transformPixelRatio={PREVIEW_SCALE}
      />
      {hidden && (
        <Box
          style={{
            position: 'absolute',
            bottom: '8px',
            right: '8px',
            padding: '2px 6px',
            borderRadius: '3px',
            background: 'rgba(0, 0, 0, 0.6)',
            color: '#c97a7a',
            fontSize: '11px',
            fontStyle: 'italic',
          }}
        >
          hidden
        </Box>
      )}
    </Box>
  );
}
