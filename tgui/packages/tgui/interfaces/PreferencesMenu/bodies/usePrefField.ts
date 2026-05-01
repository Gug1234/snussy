/**
 * @file bodies/usePrefField.ts
 * @description Per-row state binding helper for category bodies.
 *
 * Each pref row binds an individual key to a control. The pattern is
 * always:
 *   1. Read the staged-or-snapshot value (peek > snapshot, so the
 *      uncommitted value wins until the server acks).
 *   2. Stage the new value into the DirtyLedger on edit.
 *   3. Optionally route through the autosave debounce path.
 *
 * Keeping this in a shared hook means 30+ row components don't have to
 * re-derive the snapshot/peek precedence logic, and unit-testing the
 * binding is one surface instead of N.
 *
 * Performance: the hook is a thin wrapper around `useBackend` +
 * `useDirtyLedger`; both are already subscribed by the shell, so no
 * extra subscription work happens per row.
 */

import { useCallback } from 'react';

import { useBackend } from '../../../backend';
import { useDirtyLedger } from '../DirtyLedger';
import type { PreferencesMenuData } from '../types';

export interface UsePrefFieldOptions {
  /** Mark the key as autosave-eligible (debounced flush per spec §4.3). */
  autosave?: boolean;
}

export interface PrefFieldBinding<T> {
  /** Effective current value (staged value preferred over snapshot). */
  value: T | undefined;
  /** Stage a new value. Mirror of `ledger.stage()`. */
  setValue: (next: T) => void;
}

/**
 * Bind a single pref key to a row control.
 *
 * @param key  PREF_KEYS.* string.
 * @param fallback Optional value returned when neither snapshot nor
 *   ledger has anything yet (used for the cold first-paint window
 *   before the bundle/snapshot lands).
 */
export function usePrefField<T = unknown>(
  key: string,
  fallback?: T,
  options: UsePrefFieldOptions = {},
): PrefFieldBinding<T> {
  const { data } = useBackend<PreferencesMenuData>();
  const ledger = useDirtyLedger();

  const staged = ledger.peek(key) as T | undefined;
  const snapshot = data.prefs ? (data.prefs[key] as T | undefined) : undefined;
  const value = staged !== undefined ? staged : (snapshot ?? fallback);

  const setValue = useCallback(
    (next: T) => {
      ledger.stage(key, next as unknown, { autosave: options.autosave });
    },
    // ledger.stage is referentially stable across renders.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [key, options.autosave],
  );

  return { value, setValue };
}
