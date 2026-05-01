/**
 * @file PrefsRouter.tsx
 * @description React context exposing the pref-menu router (active
 * category + row + setters) to body components.
 *
 * Why: body components live deep inside `<MiddleColumn />` and have
 * no prop-drilling path to the shell's `setActiveCategory` /
 * `setActiveRow`. Server round-trips to switch tabs are wasteful and
 * also miss the dirty-modal handoff that the shell already implements
 * for in-shell navigation. A small context lets bodies say
 * `usePrefsRouter().go(category, row)` and reuse the shell's flow.
 *
 * Scope: this hook is intended for in-shell navigation only. For
 * launching standalone editors, bodies still dispatch
 * `act('launch_singleton', ...)` because that path closes the prefs
 * window entirely and stashes return state on /client.
 */

import { createContext, useContext } from 'react';

import type { PrefsCategoryId } from './constants';

export interface PrefsRouter {
  /** Switch to (category, row). row=null clears row selection. */
  go: (category: PrefsCategoryId, row: string | null) => void;
}

const noop: PrefsRouter = {
  go: () => {
    // Bodies rendered outside the menu shell (storybook, tests) get
    // a noop. Loud failure here would break those harnesses.
  },
};

export const PrefsRouterContext = createContext<PrefsRouter>(noop);

/** Hook for body components to navigate the shell. */
export function usePrefsRouter(): PrefsRouter {
  return useContext(PrefsRouterContext);
}
