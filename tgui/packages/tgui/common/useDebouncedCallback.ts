/**
 * Shared TGUI hook for delaying high-frequency backend actions.
 *
 * Editors use this when a control such as NumberInput can emit many updates
 * during one drag gesture. The hook keeps the latest callback reference,
 * schedules only the last argument set, and flushes any pending call during
 * unmount so tab or category switches do not lose the final edit.
 */

import { useCallback, useEffect, useRef } from 'react';

type AnyCallback = (...args: any[]) => void;

/**
 * Returns a stable debounced callback.
 *
 * @param callback Function to call after the quiet period.
 * @param delay Delay in milliseconds after the last invocation.
 * @returns A callback with the same argument shape as `callback`.
 */
export function useDebouncedCallback<T extends AnyCallback>(
  callback: T,
  delay: number,
): T {
  const callbackRef = useRef(callback);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const argsRef = useRef<Parameters<T> | null>(null);

  useEffect(() => {
    callbackRef.current = callback;
  }, [callback]);

  useEffect(() => {
    return () => {
      if (timeoutRef.current !== null) {
        clearTimeout(timeoutRef.current);
        timeoutRef.current = null;
      }
      if (argsRef.current !== null) {
        callbackRef.current(...argsRef.current);
        argsRef.current = null;
      }
    };
  }, []);

  return useCallback(
    ((...args: Parameters<T>) => {
      argsRef.current = args;
      if (timeoutRef.current !== null) {
        clearTimeout(timeoutRef.current);
      }
      timeoutRef.current = setTimeout(() => {
        timeoutRef.current = null;
        if (argsRef.current !== null) {
          callbackRef.current(...argsRef.current);
          argsRef.current = null;
        }
      }, delay);
    }) as T,
    [delay],
  );
}
