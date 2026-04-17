// Extreme Offset Vetting — Phase 2 thresholds.
// Policy spec: modular/code/datums/EXTREME_OFFSET_POLICY.md
// Helpers: modular/code/datums/extreme_offset_policy.dm
//
// Rotation (90/180/270) and flip_x/flip_y are deliberately NOT flagged
// (shape-preserving at tile scale — legitimate for taur/marking/piercing
// creativity). Only pixel offset + scale contribute to flag bits.

// --- Per-entry pixel thresholds (absolute value on each axis) ---
#define EXTREME_OFFSET_SOFT_PX 8
#define EXTREME_OFFSET_HARD_PX 16
/// Phase 7 hard clamp — save rejected beyond this. Phase 2 only defines it.
#define EXTREME_OFFSET_CLAMP_PX 24

// --- Diagonal pixel threshold (hard flag only) ---
/// Squared form so we avoid sqrt at runtime. sqrt(px*px + py*py) > 20.
#define EXTREME_OFFSET_HARD_DIAG_SQ (20 * 20)

// --- Per-entry scale thresholds ---
#define EXTREME_OFFSET_SOFT_SCALE 1.5
#define EXTREME_OFFSET_HARD_SCALE 2.0
/// Phase 7 hard clamp — save rejected beyond this. Phase 2 only defines it.
#define EXTREME_OFFSET_CLAMP_SCALE 2.5

// --- Aggregate mob-level budget ---
/// Default budget for sum(|px| + |py|) across visible (whole-entry-enabled)
/// entries. Runtime-tunable via GLOB.extreme_aggregate_budget.
#define EXTREME_OFFSET_DEFAULT_AGGREGATE_BUDGET 120

// --- Flag bitfield returned by compute_entry_extreme_flags() ---
#define EXTREME_FLAG_NONE 0
#define EXTREME_FLAG_SOFT_PX (1<<0)
#define EXTREME_FLAG_SOFT_SCALE (1<<1)
#define EXTREME_FLAG_HARD_PX (1<<2)
#define EXTREME_FLAG_HARD_DIAG (1<<3)
#define EXTREME_FLAG_HARD_SCALE (1<<4)

#define EXTREME_FLAG_SOFT_MASK (EXTREME_FLAG_SOFT_PX | EXTREME_FLAG_SOFT_SCALE)
#define EXTREME_FLAG_HARD_MASK (EXTREME_FLAG_HARD_PX | EXTREME_FLAG_HARD_DIAG | EXTREME_FLAG_HARD_SCALE)
