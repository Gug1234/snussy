/**
 * useDebouncedCallback — trailing-edge debounce hook.
 *
 * Returns a stable-behaving wrapper around `fn` that coalesces rapid calls
 * into a single invocation, fired `delay` ms after the last call.
 *
 * The wrapper always invokes the latest `fn` (captured via a ref), so stale
 * closures are avoided. On unmount, any pending call is flushed synchronously
 * with the most recent arguments so trailing edits are not lost when the
 * component disappears (e.g. category/phase switch, window close).
 */

import { useEffect, useRef } from 'react';

// eslint-disable-next-line
type AnyFn = (...args: any[]) => void;

export function useDebouncedCallback<T extends AnyFn>(fn: T, delay: number): T {
  const fnRef = useRef<T>(fn);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingArgsRef = useRef<Parameters<T> | null>(null);

  // Always call latest fn.
  fnRef.current = fn;

  useEffect(() => {
    return () => {
      if (timerRef.current !== null) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
        const pending = pendingArgsRef.current;
        pendingArgsRef.current = null;
        if (pending) {
          fnRef.current(...pending);
        }
      }
    };
  }, []);

  const debounced = ((...args: Parameters<T>) => {
    pendingArgsRef.current = args;
    if (timerRef.current !== null) {
      clearTimeout(timerRef.current);
    }
    timerRef.current = setTimeout(() => {
      timerRef.current = null;
      const pending = pendingArgsRef.current;
      pendingArgsRef.current = null;
      if (pending) {
        fnRef.current(...pending);
      }
    }, delay);
  }) as T;

  return debounced;
}
