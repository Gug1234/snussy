/**
 * @file LeftColumn.tsx
 * @description Category dropdown + sub-row list of the Elden-Ring shell
 * (Step 7).
 *
 * Step 7 scope:
 *   - Renders a Dropdown over PREFS_CATEGORY_ORDER + an empty row list.
 *   - Category bodies (and therefore concrete row schemas) land in
 *     Steps 10-14; each body module appends its rows by registering
 *     itself in the MiddleColumn body registry.
 *   - This file deliberately does NOT consume the row schema directly
 *     — it asks the parent for a `rows` array and a click callback so
 *     route state stays owned by `index.tsx`.
 *
 * Performance: the row list is virtualised only if it ever exceeds ~40
 * rows (currently no category does). Plain map() is fine for Step 7.
 */

import { Box, Dropdown, Section, Stack } from 'tgui-core/components';

import {
  PREFS_CATEGORY_LABELS,
  PREFS_CATEGORY_ORDER,
  type PrefsCategoryId,
} from './constants';
import type { PrefsRowDescriptor } from './types';

/**
 * Props for the LeftColumn route panel.
 */
export interface LeftColumnProps {
  /** Currently active category id (controlled). */
  activeCategory: PrefsCategoryId;
  /** Currently active row id within the active category (controlled). */
  activeRow: string | null;
  /**
   * Row descriptors for the active category. Empty in Step 7; populated
   * by the body registry in Steps 10-14.
   */
  rows: readonly PrefsRowDescriptor[];
  /** Fired when the user picks a different category. */
  onCategoryChange: (next: PrefsCategoryId) => void;
  /** Fired when the user clicks a row. */
  onRowClick: (rowId: string) => void;
}

/**
 * LeftColumn — category picker + per-category row list.
 */
export function LeftColumn(props: LeftColumnProps) {
  const { activeCategory, activeRow, rows, onCategoryChange, onRowClick } =
    props;

  const dropdownOptions = PREFS_CATEGORY_ORDER.map((id) => ({
    value: id,
    displayText: PREFS_CATEGORY_LABELS[id],
  }));

  return (
    <Section className="PrefsMenu__leftColumn" fill>
      <Stack vertical fill>
        <Stack.Item>
          <Dropdown
            options={dropdownOptions}
            selected={activeCategory}
            onSelected={(value) => onCategoryChange(value as PrefsCategoryId)}
            width="100%"
          />
        </Stack.Item>
        <Stack.Item grow style={{ overflowY: 'auto' }}>
          {rows.length === 0 ? (
            // Empty-state copy: helps reviewers identify which category
            // bodies are still pending implementation.
            <Box mt={2} color="label" italic>
              No rows registered for{' '}
              <b>{PREFS_CATEGORY_LABELS[activeCategory]}</b> yet.
            </Box>
          ) : (
            rows.map((row) => (
              <Box
                key={row.id}
                className={
                  'PrefsMenu__row' +
                  (row.id === activeRow ? ' PrefsMenu__row--active' : '')
                }
                p={1}
                onClick={() => onRowClick(row.id)}
              >
                {row.label}
              </Box>
            ))
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
}
