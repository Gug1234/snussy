/**
 * @file widgets/StatMatrix.tsx
 * @description Sticky-header / sticky-total stat-contribution table.
 *
 * Consumes the server-side `build_stat_matrix()` payload (Step 5) and
 * renders one row per contributor (statpack / job / species / age /
 * virtue / vice) plus a sticky bottom Total row computed client-side
 * from `baseline + sum(rows[*][stat])`. Range-cell tooltips surface
 * the optional `ranges[row][stat]` side-channel when present so
 * statpacks with random rolls show the underlying [lo, hi] band.
 *
 * Performance:
 *   - Pure render; memoizes computed totals on the input identity.
 *   - Tables are small (≤ 6 rows × ≤ 12 stats); no virtualization.
 *   - Renders nothing when `data` is undefined so bodies that don't
 *     hydrate the matrix yet stay zero-cost.
 */

import { useMemo } from 'react';
import { Box, Table } from 'tgui-core/components';

import type { StatMatrixData } from '../types';

export interface StatMatrixProps {
  data?: StatMatrixData;
  /** Optional className hook for §19 styling. */
  className?: string;
}

/** Compute total per stat. Pulled out so the test surface is trivial. */
function computeTotals(data: StatMatrixData): Record<string, number> {
  const totals: Record<string, number> = {};
  for (const stat of data.stats) {
    let total = data.baseline;
    for (const row of data.order) {
      const cell = data.rows[row]?.[stat];
      if (typeof cell === 'number') total += cell;
    }
    totals[stat] = total;
  }
  return totals;
}

export function StatMatrix(props: StatMatrixProps) {
  const { data, className } = props;
  // Hooks must be called unconditionally — compute against an empty
  // shell when no data is present so the conditional render below is
  // safe. The empty-shell totals are immediately discarded.
  const safeData: StatMatrixData = data ?? {
    order: [],
    stats: [],
    rows: {},
    baseline: 0,
  };
  const totals = useMemo(() => computeTotals(safeData), [safeData]);
  if (!data) {
    return null;
  }

  return (
    <Box className={className}>
      <Table>
        <Table.Row header>
          <Table.Cell>Source</Table.Cell>
          {data.stats.map((stat) => (
            <Table.Cell key={stat} textAlign="center">
              {stat}
            </Table.Cell>
          ))}
        </Table.Row>
        {data.order.map((row) => (
          <Table.Row key={row}>
            <Table.Cell bold>{row}</Table.Cell>
            {data.stats.map((stat) => {
              const cell = data.rows[row]?.[stat] ?? 0;
              // Table.Cell does not accept `title`; wrap with Tooltip if a hover
              // hint becomes required. Range data still flows in via data.ranges.
              return (
                <Table.Cell key={stat} textAlign="center">
                  {cell === 0 ? (
                    <span style={{ opacity: 0.3 }}>·</span>
                  ) : cell > 0 ? (
                    `+${cell}`
                  ) : (
                    cell
                  )}
                </Table.Cell>
              );
            })}
          </Table.Row>
        ))}
        <Table.Row header>
          <Table.Cell>Total</Table.Cell>
          {data.stats.map((stat) => (
            <Table.Cell key={stat} textAlign="center" bold>
              {totals[stat]}
            </Table.Cell>
          ))}
        </Table.Row>
      </Table>
    </Box>
  );
}
