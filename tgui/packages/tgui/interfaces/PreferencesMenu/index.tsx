/**
 * @file index.tsx
 * @description PreferencesMenu shell — Step 8 wiring of the
 * client-side DirtyLedger into the existing Step 7 3-column layout.
 *
 * Behavior change vs Step 7:
 *   - `hasPendingDirty()` now consults `ledger.hasPending(false)` —
 *     non-autosave keys only, per spec §4.3 ("DirtyModal does not fire
 *     for autosave keys").
 *   - On confirmed Save (modal): `ledger.flushBatch()` then apply the
 *     pending route change.
 *   - On confirmed Discard (modal): `ledger.discardAll()` then apply.
 *   - On Cancel: nothing — pending changes remain, route stays put.
 *   - On unmount: best-effort `flushBatch()` so navigating away
 *     doesn't strand a buffer of explicit non-autosave dirt. Autosave
 *     debounces are also flushed by virtue of being included in
 *     flushBatch().
 *
 * Performance: the ledger hook subscribes only to its own revision
 * counter; the shell re-renders on dirty-state transitions but the
 * heavy `<RightColumn/>` (preview) is unaffected because it doesn't
 * read the ledger.
 */

// Side-effect imports — each barrel registers its category's body
// modules into the MiddleColumn registry at module load time. Adding a
// new category = one more line here.
import './bodies/Identity';
import './bodies/Body';
import './bodies/ClassStats';
import './bodies/Intimacy';
import './bodies/Options';
import './bodies/Keybindings';

import { useEffect, useMemo, useState } from 'react';
import { Flex } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { BottomBar } from './BottomBar';
import { ClassPreviewProvider } from './ClassPreviewContext';
import { PREFS_CATEGORIES, type PrefsCategoryId } from './constants';
import { useDirtyLedger } from './DirtyLedger';
import { DirtyModal } from './DirtyModal';
import { LeftColumn } from './LeftColumn';
import { getCategoryRows, MiddleColumn } from './MiddleColumn';
import { type PrefsRouter, PrefsRouterContext } from './PrefsRouter';
import { RightColumn } from './RightColumn';
import { type PrefsFrameSkin, type PrefsTopbarSkin, TopBar } from './TopBar';
import type { PreferencesMenuData } from './types';

/**
 * In-flight route switch awaiting DirtyModal resolution.
 */
interface PendingSwitch {
  fromCategory: PrefsCategoryId;
  toCategory: PrefsCategoryId;
  fromRow: string | null;
  toRow: string | null;
}

export function PreferencesMenu() {
  const { data } = useBackend<PreferencesMenuData>();
  const ledger = useDirtyLedger();

  const [activeCategory, setActiveCategory] = useState<PrefsCategoryId>(
    PREFS_CATEGORIES.IDENTITY,
  );
  const [activeRow, setActiveRow] = useState<string | null>(null);
  const [frameSkin, setFrameSkin] = useState<PrefsFrameSkin>('leather');
  const [topbarSkin, setTopbarSkin] = useState<PrefsTopbarSkin>('wide');
  const [pending, setPending] = useState<PendingSwitch | null>(null);
  const [classPreviewTitle, setClassPreviewTitle] = useState<string | null>(
    null,
  );

  /**
   * Step 14 resume handshake: when the server re-opens the window
   * after a singleton editor close, `ui_static_data` emits
   * `resume_category` / `resume_row` once. Consume them to restore
   * the route. The server clears its copy after emitting, so this
   * fires at most once per reopen.
   */
  const resumeCategory = data.resume_category;
  const resumeRow = data.resume_row;
  const resumeToken = data.resume_token;
  useEffect(() => {
    if (resumeCategory) {
      setActiveCategory(resumeCategory as PrefsCategoryId);
    }
    if (resumeRow !== undefined) {
      setActiveRow(resumeRow ?? null);
    }
    // Token-driven: server bumps resume_token on every emission so
    // relaunching the same singleton re-triggers the effect even
    // when category/row strings match a prior hint.
  }, [resumeCategory, resumeRow, resumeToken]);

  /**
   * Flush any leftover ledger state on unmount. Autosave debounces
   * that haven't fired are forced through here too because
   * flushBatch() includes autosave keys in the commit.
   */
  useEffect(
    () => () => {
      if (ledger.hasPending(true)) {
        ledger.flushBatch();
      }
    },
    // ledger handle is referentially stable across renders for the
    // method members; only `revision` mutates and we don't read it.
    [],
  );

  const hasPendingDirty = (): boolean => ledger.hasPending(false);

  const onCategoryChange = (next: PrefsCategoryId) => {
    if (next === activeCategory) {
      return;
    }
    if (hasPendingDirty()) {
      setPending({
        fromCategory: activeCategory,
        toCategory: next,
        fromRow: activeRow,
        toRow: null,
      });
      return;
    }
    setActiveCategory(next);
    setActiveRow(null);
  };

  const onRowClick = (rowId: string) => {
    if (rowId === activeRow) {
      return;
    }
    if (hasPendingDirty()) {
      setPending({
        fromCategory: activeCategory,
        toCategory: activeCategory,
        fromRow: activeRow,
        toRow: rowId,
      });
      return;
    }
    setActiveRow(rowId);
  };

  /** Resolve an in-flight DirtyModal decision. */
  const resolveDirty = (mode: 'save' | 'discard' | 'cancel') => {
    if (!pending) {
      return;
    }
    const target = pending;
    setPending(null);
    if (mode === 'cancel') {
      return;
    }
    if (mode === 'save') {
      ledger.flushBatch();
    } else {
      ledger.discardAll();
    }
    setActiveCategory(target.toCategory);
    setActiveRow(target.toRow);
  };

  const rows = getCategoryRows(activeCategory, data);
  const classPreviewValue = useMemo(
    () => ({ classPreviewTitle, setClassPreviewTitle }),
    [classPreviewTitle],
  );
  const rightColumnBasis =
    activeCategory === PREFS_CATEGORIES.CLASS_STATS && activeRow === 'class'
      ? '380px'
      : '240px';

  // Router exposed to body components so they can navigate the
  // shell without a server round-trip. Honors the same dirty-modal
  // gate as in-shell category/row clicks.
  const router: PrefsRouter = {
    go: (cat, row) => {
      if (cat === activeCategory && row === activeRow) {
        return;
      }
      if (hasPendingDirty()) {
        setPending({
          fromCategory: activeCategory,
          toCategory: cat,
          fromRow: activeRow,
          toRow: row,
        });
        return;
      }
      setActiveCategory(cat);
      setActiveRow(row);
    },
  };

  const shellClassName =
    `PrefsMenu PrefsMenu--frame-${frameSkin}` +
    ` PrefsMenu--topbar-${topbarSkin}`;

  return (
    <Window
      title="Appearance & Preferences"
      theme="ratwood_prefs"
      width={1280}
      height={800}
    >
      <Window.Content>
        <PrefsRouterContext.Provider value={router}>
          <ClassPreviewProvider value={classPreviewValue}>
            <Flex direction="column" height="100%" className={shellClassName}>
              <Flex.Item shrink={0}>
                <TopBar
                  frameSkin={frameSkin}
                  topbarSkin={topbarSkin}
                  onFrameSkinChange={setFrameSkin}
                  onTopbarSkinChange={setTopbarSkin}
                />
              </Flex.Item>
              <Flex.Item grow={1} className="PrefsMenu__mainArea">
                <Flex height="100%" className="PrefsMenu__columns">
                  <Flex.Item shrink={0} basis="240px" mr={1}>
                    <LeftColumn
                      activeCategory={activeCategory}
                      activeRow={activeRow}
                      rows={rows}
                      onCategoryChange={onCategoryChange}
                      onRowClick={onRowClick}
                    />
                  </Flex.Item>
                  <Flex.Item grow={1} mr={1} className="PrefsMenu__middlePane">
                    <MiddleColumn
                      activeCategory={activeCategory}
                      activeRow={activeRow}
                    />
                  </Flex.Item>
                  <Flex.Item shrink={0} basis={rightColumnBasis}>
                    <RightColumn
                      activeCategory={activeCategory}
                      activeRow={activeRow}
                    />
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              {/* BottomBar lands in Step 15. */}
              <Flex.Item shrink={0}>
                <BottomBar />
              </Flex.Item>
            </Flex>

            {pending && (
              <div
                style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'rgba(0,0,0,0.6)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  zIndex: 10,
                }}
              >
                <div style={{ background: '#181818' }}>
                  <DirtyModal
                    variant="tab-switch"
                    fromTabLabel={pending.fromCategory}
                    toTabLabel={pending.toCategory}
                    onSave={() => resolveDirty('save')}
                    onDiscard={() => resolveDirty('discard')}
                    onCancel={() => resolveDirty('cancel')}
                  />
                </div>
              </div>
            )}
          </ClassPreviewProvider>
        </PrefsRouterContext.Provider>
      </Window.Content>
    </Window>
  );
}
