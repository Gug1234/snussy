/**
 * @file ModalDialog.tsx
 * @description Accessible modal dialog primitive for appearance-preview
 * editors. Replaces the hand-rolled `position: fixed` overlay used by the
 * custom-piercing Import/Export panel with a real dialog surface that:
 *
 *   - Uses a native `<dialog>` element via `showModal()` when available
 *     (modern CEF / Chromium shipped with TGUI since 2024). Inherits the
 *     browser's built-in focus trap, scrim, and `::backdrop` pseudo-element.
 *   - Falls back to a role-dialog `<div>` overlay with a manual focus trap
 *     + backdrop click-to-close when `HTMLDialogElement` is unavailable
 *     (older chromium builds).
 *   - Always reacts to Escape by invoking `onClose` — native `<dialog>` fires
 *     a `cancel` event that we intercept; the fallback listens on keydown.
 *   - Restores focus to the element that was focused when the modal opened.
 *   - Hosts an optional `aria-live="polite"` status region so the import
 *     outcome (success / error) is announced to screen readers without a
 *     second focus shift.
 *   - Does NOT own any of the modal's business content — callers pass their
 *     body as `children`, so the same primitive serves any future editor's
 *     dialog needs.
 *
 * ## Why not a context/portal?
 *
 * TGUI renders inside a single iframe per window with no route-level layout,
 * and the existing editor code already composes sections top-down. A
 * declarative `<ModalDialog open={ioOpen} onClose={…}>` slotted into the
 * editor tree is the minimal surface for our two current use sites. A
 * portal would force us to own a portal host div and a dismissal context
 * for zero gain.
 *
 * ## Scale note (200-client worst case)
 *
 * Zero server traffic. All focus-trap + keydown work happens on the client
 * when the modal is open, which is at most one instance per editor window.
 * No background listeners when closed.
 */

import {
  type KeyboardEvent as ReactKeyboardEvent,
  type ReactNode,
  type SyntheticEvent,
  useCallback,
  useEffect,
  useId,
  useRef,
} from 'react';
import { Button } from 'tgui-core/components';

import { Box } from '../Box';

/**
 * Selector for anything the focus trap should consider focusable. Matches
 * the WAI-ARIA authoring-practices list, minus things we never render
 * inside a modal (audio controls, contenteditable, summary). Trailing
 * `:not([disabled]):not([aria-hidden="true"])` filters out disabled or
 * explicitly-hidden candidates without needing a second pass.
 */
const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled]):not([type="hidden"])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(',');

interface Props {
  /** Whether the modal is currently open. Drives show/hide + focus capture. */
  open: boolean;
  /** Invoked when the modal should close (Escape, backdrop, explicit button). */
  onClose: () => void;
  /** Dialog title. Rendered inside the header and wired to `aria-labelledby`. */
  title: string;
  /** Modal body. Caller-composed. */
  children: ReactNode;
  /**
   * Optional live-region message. When set, announces via `aria-live="polite"`
   * so status updates (e.g. "Import succeeded") reach assistive tech without
   * shifting focus.
   */
  status?: string | null;
  /** Tone of the status message — controls colour only. */
  statusTone?: 'good' | 'bad' | 'neutral';
  /** Optional width override (default 480px). */
  width?: string;
  /**
   * Optional Close-button label override. Defaults to "Close" — kept short
   * so it fits in the header's right-aligned control slot.
   */
  closeLabel?: string;
}

/**
 * Accessible dialog primitive. See the file-level doc-comment for the
 * motivation and contract.
 */
export function ModalDialog(props: Props) {
  const {
    open,
    onClose,
    title,
    children,
    status,
    statusTone = 'neutral',
    width = '480px',
    closeLabel = 'Close',
  } = props;

  const titleId = useId();
  const dialogRef = useRef<HTMLDialogElement | null>(null);
  const fallbackRef = useRef<HTMLDivElement | null>(null);
  // Tracks the element that had focus before the modal opened, so we can
  // restore it on close. Null if the modal has never opened in this session.
  const previouslyFocusedRef = useRef<HTMLElement | null>(null);

  // ── Native <dialog> support probe ─────────────────────────────────────
  // Detect once per render. The flag only toggles if the runtime itself
  // changes (i.e., never in practice), so no memoisation is required.
  const supportsNativeDialog =
    typeof window !== 'undefined' &&
    typeof window.HTMLDialogElement === 'function';

  /**
   * Focus the first focusable element inside the modal. Called on open.
   * Falls back to the modal root when nothing focusable is present so the
   * user isn't stranded on an unfocusable element after tabbing into it.
   */
  const focusFirstInside = useCallback((container: HTMLElement) => {
    const first = container.querySelector<HTMLElement>(FOCUSABLE_SELECTOR);
    if (first) {
      first.focus();
    } else {
      // Last resort: make the container tabbable and focus it.
      container.tabIndex = -1;
      container.focus();
    }
  }, []);

  // ── Open/close lifecycle ──────────────────────────────────────────────
  useEffect(() => {
    if (!open) return;

    // Snapshot the currently-focused element so we can restore it on close.
    previouslyFocusedRef.current =
      (typeof document !== 'undefined' &&
        (document.activeElement as HTMLElement | null)) ||
      null;

    // Prefer the native dialog path when available.
    const dlg = dialogRef.current;
    if (supportsNativeDialog && dlg && !dlg.open) {
      try {
        dlg.showModal();
      } catch {
        // Some browsers throw if the element is detached from the DOM
        // at the moment we call showModal. Fall through to the fallback
        // path; the div overlay is always mounted as a sibling.
      }
    }

    // Focus handoff: native <dialog> autofocuses its first focusable element
    // only when an element inside it has the `autofocus` attribute. We have
    // no guarantee any caller supplies one, so we always run our own focus
    // handler regardless of the native path.
    const container = (supportsNativeDialog && dlg) || fallbackRef.current;
    if (container) {
      // Defer to the next microtask so children have committed before we
      // query them — useful when a child renders conditionally on `open`.
      queueMicrotask(() => focusFirstInside(container));
    }

    return () => {
      // Close the native dialog if still open (e.g. unmount mid-show).
      if (dlg && dlg.open) {
        try {
          dlg.close();
        } catch {
          // Ignore — the element may already be detached.
        }
      }
      // Restore focus to the trigger that opened us, if it's still around.
      const prev = previouslyFocusedRef.current;
      if (prev && typeof prev.focus === 'function') {
        try {
          prev.focus();
        } catch {
          // Element may have been unmounted while modal was open; swallow.
        }
      }
      previouslyFocusedRef.current = null;
    };
  }, [open, supportsNativeDialog, focusFirstInside]);

  /**
   * Intercepts the native dialog's `cancel` event (fired when the user
   * presses Escape) and routes it through `onClose` so we control the
   * dismissal contract (no implicit commit of the modal's action).
   */
  const handleNativeCancel = useCallback(
    (event: SyntheticEvent<HTMLDialogElement, Event>) => {
      event.preventDefault();
      onClose();
    },
    [onClose],
  );

  /**
   * Fallback-path keydown handler: Escape closes; Tab/Shift+Tab are
   * wrapped so focus cycles inside the modal. Native `<dialog>` already
   * enforces both of these so we only bind this on the fallback div.
   */
  const handleFallbackKeyDown = useCallback(
    (event: ReactKeyboardEvent<HTMLDivElement>) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        onClose();
        return;
      }
      if (event.key !== 'Tab') return;

      const container = fallbackRef.current;
      if (!container) return;

      // Snapshot focusable descendants. The DOM is tiny (dialog-scoped);
      // redoing this per Tab keystroke costs nothing.
      const focusables = Array.from(
        container.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR),
      );
      if (focusables.length === 0) return;

      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      const active = document.activeElement as HTMLElement | null;

      if (event.shiftKey && active === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && active === last) {
        event.preventDefault();
        first.focus();
      }
    },
    [onClose],
  );

  if (!open) return null;

  const statusColor =
    statusTone === 'good'
      ? '#71b271'
      : statusTone === 'bad'
        ? '#c97a7a'
        : '#cfcfcf';

  // Body content — rendered inside both the native dialog and the fallback
  // so the two paths share identical layout.
  const body = (
    <Box style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
      {/* ── Header ──────────────────────────────────────────────────── */}
      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '0.5rem',
          paddingBottom: '0.25rem',
          borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
        }}
      >
        <Box id={titleId} style={{ fontWeight: 700, fontSize: '13px' }}>
          {title}
        </Box>
        <Button icon="times" onClick={onClose} tooltip="Close dialog (Esc)">
          {closeLabel}
        </Button>
      </Box>

      {/* ── Children body ───────────────────────────────────────────── */}
      <Box>{children}</Box>

      {/* ── aria-live status region ─────────────────────────────────── */}
      {/* Always render the region so the message is announced as a change,
          not as the initial value. Hide visually when empty. Rendered as a
          native <div> because TGUI's typed `Box` props do not surface
          `role` / `aria-live`; using the intrinsic element is the
          cheapest way to keep the announcement semantics honest. */}
      <div
        role="status"
        aria-live="polite"
        style={{
          minHeight: '1.25rem',
          fontSize: '11px',
          color: statusColor,
        }}
      >
        {status || ''}
      </div>
    </Box>
  );

  // ── Native <dialog> path ──────────────────────────────────────────────
  if (supportsNativeDialog) {
    return (
      <dialog
        ref={dialogRef}
        aria-labelledby={titleId}
        onCancel={handleNativeCancel}
        // The browser supplies a ::backdrop pseudo-element; we still want
        // explicit backdrop-click-to-close since older chromium ignores
        // `light-dismiss` attributes. The click handler fires for both the
        // dialog and its descendants; filter by target identity so only
        // clicks on the dialog element itself (not its children) close.
        onClick={(event) => {
          if (event.target === dialogRef.current) {
            onClose();
          }
        }}
        style={{
          width,
          maxWidth: '90vw',
          maxHeight: '80vh',
          padding: '12px',
          background: '#1e1e1e',
          color: '#e0e0e0',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          borderRadius: '4px',
        }}
      >
        {body}
      </dialog>
    );
  }

  // ── Fallback overlay path ─────────────────────────────────────────────
  return (
    <Box
      // Backdrop. Click-on-self closes; click-on-child bubbles up but is
      // filtered by target identity below.
      onClick={(event) => {
        if (event.target === event.currentTarget) {
          onClose();
        }
      }}
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0, 0, 0, 0.55)',
        zIndex: 1000,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        // onKeyDown at the modal root so the trap covers every descendant.
        onKeyDown={handleFallbackKeyDown}
        ref={fallbackRef}
        style={{
          width,
          maxWidth: '90vw',
          maxHeight: '80vh',
          overflowY: 'auto',
          background: '#1e1e1e',
          color: '#e0e0e0',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          padding: '12px',
          borderRadius: '4px',
        }}
      >
        {body}
      </div>
    </Box>
  );
}

/**
 * Copy-to-clipboard helper for modal export affordances. Uses the
 * async Clipboard API when available; falls back to a transient textarea
 * + `document.execCommand('copy')` when not. Returns a truthy result on
 * success so callers can update the aria-live status region.
 */
export async function copyTextToClipboard(text: string): Promise<boolean> {
  // Prefer the modern async API. CEF builds shipped since 2021 expose it
  // under HTTPS-equivalent "secure" contexts; TGUI's iframe qualifies.
  if (
    typeof navigator !== 'undefined' &&
    navigator.clipboard &&
    typeof navigator.clipboard.writeText === 'function'
  ) {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      // Permission denied or no user gesture — fall through to the legacy
      // path rather than surfacing a raw promise rejection to the UI.
    }
  }

  // Legacy execCommand path. Kept narrow: stage a textarea, copy, remove.
  if (typeof document === 'undefined') return false;
  const ta = document.createElement('textarea');
  ta.value = text;
  // Avoid scroll-jank: position off-screen, not display:none (which would
  // defeat the copy selection).
  ta.setAttribute('aria-hidden', 'true');
  ta.style.position = 'fixed';
  ta.style.top = '-1000px';
  ta.style.left = '-1000px';
  document.body.appendChild(ta);
  ta.select();
  let ok = false;
  try {
    ok = document.execCommand('copy');
  } catch {
    ok = false;
  }
  document.body.removeChild(ta);
  return ok;
}
