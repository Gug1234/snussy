/**
 * @file MiddleColumn.tsx
 * @description Body-renderer registry for the Elden-Ring shell (Step 7).
 *
 * Step 7 scope: empty registry. Category body modules (Steps 10-14)
 * import `registerPrefsBody` and register their `{categoryId, rowId,
 * label, component}` descriptors at module load time. The registry is
 * a module-level Map so registration is idempotent across HMR.
 *
 * The shell calls:
 *   - `getCategoryRows(categoryId)` to feed the LeftColumn row list.
 *   - `getBodyComponent(categoryId, rowId)` to render the active body.
 *
 * Performance rationale: the registry pattern keeps Step 7 free of
 * any dependency on category bodies, so the shell compiles standalone
 * before any body module lands. It also localises future body churn —
 * adding a row touches one body file and one DM setter, never this file.
 */

import type { PrefsCategoryId } from './constants';
import { PREFS_CATEGORY_ORDER } from './constants';
import type { PrefsRowDescriptor } from './types';

/**
 * Row descriptor with its body component. Body modules register one
 * of these per row at module load time.
 */
export interface PrefsBodyRegistration extends PrefsRowDescriptor {
  /** Owning category id. */
  category: PrefsCategoryId;
  /** React component rendered in the middle column when active. */
  component: React.ComponentType;
  /**
   * Optional visibility predicate. When present and returning false,
   * the row is hidden from LeftColumn for this client. Used to gate
   * opt-in rows (e.g. Gnoll, Familiar, Jelly) on the upstream pref
   * that enables them.
   */
  visible?: (data: any) => boolean;
}

/**
 * Module-level registry. Map<categoryId, Map<rowId, registration>> so
 * body lookup is O(1) by category+row and row enumeration per category
 * preserves insertion order.
 */
const registry: Map<
  PrefsCategoryId,
  Map<string, PrefsBodyRegistration>
> = new Map();

// Pre-seed empty maps for every known category so getCategoryRows can
// safely return an empty array for not-yet-implemented categories
// without a falsy check at every call site.
for (const cat of PREFS_CATEGORY_ORDER) {
  registry.set(cat, new Map());
}

/**
 * Register a body component for `category.row`. Called by category
 * body modules at module load time. Idempotent: re-registering the
 * same `(category, id)` overwrites the previous entry (HMR-safe).
 *
 * @param reg row+component descriptor.
 */
export function registerPrefsBody(reg: PrefsBodyRegistration): void {
  let bucket = registry.get(reg.category);
  if (!bucket) {
    bucket = new Map();
    registry.set(reg.category, bucket);
  }
  bucket.set(reg.id, reg);
}

/**
 * @returns ordered row descriptors for the category. If `data` is
 *   provided, registrations with a `visible(data) === false` predicate
 *   are filtered out. Empty array when the category has no registered
 *   bodies (Step 7 default state).
 */
export function getCategoryRows(
  category: PrefsCategoryId,
  data?: any,
): readonly PrefsRowDescriptor[] {
  const bucket = registry.get(category);
  if (!bucket) {
    return [];
  }
  const all = Array.from(bucket.values());
  if (!data) {
    return all;
  }
  return all.filter((r) => !r.visible || r.visible(data));
}

/**
 * @returns the React component for `category.row`, or null if no body
 *   is registered (the MiddleColumn renders an empty-state in that case).
 */
export function getBodyComponent(
  category: PrefsCategoryId,
  rowId: string | null,
): React.ComponentType | null {
  if (rowId === null) {
    return null;
  }
  const bucket = registry.get(category);
  if (!bucket) {
    return null;
  }
  const entry = bucket.get(rowId);
  return entry ? entry.component : null;
}

/**
 * Props for the MiddleColumn renderer.
 */
export interface MiddleColumnProps {
  /** Currently active category id. */
  activeCategory: PrefsCategoryId;
  /** Currently active row id (or null if none selected yet). */
  activeRow: string | null;
}

/**
 * Renders the body component for `(activeCategory, activeRow)`. Falls
 * back to a placeholder when nothing is selected or no body is
 * registered.
 */
export function MiddleColumn(props: MiddleColumnProps) {
  const Body = getBodyComponent(props.activeCategory, props.activeRow);
  if (!Body) {
    return (
      <div className="PrefsMenu__middleColumn PrefsMenu__middleColumn--empty">
        Select a row to begin editing.
      </div>
    );
  }
  return (
    <div className="PrefsMenu__middleColumn">
      <Body />
    </div>
  );
}
