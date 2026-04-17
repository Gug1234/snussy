/**
 * body_marking_entry.dm — per-entry schema helpers for body_markings.
 *
 * A body marking entry can be stored as either:
 *   - a flat hex string ("FFAACC") — legacy shape, still used by species
 *     randomizers and preset assembly procs.
 *   - an associative list with shape:
 *       list(
 *         "color"    = "FFAACC",
 *         "pixel_x"  = int in [BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX],
 *         "pixel_y"  = int in [BODY_MARKING_OFFSET_MIN, BODY_MARKING_OFFSET_MAX],
 *         "flip_x"   = TRUE/FALSE,
 *         "flip_y"   = TRUE/FALSE,
 *         "rotation" = 0|90|180|270,
 *         "scale"    = 1|2,
 *       )
 *
 * Always read the color via `body_marking_entry_color()` so callers don't
 * have to branch on shape.
 */

/// Returns a freshly-constructed default entry dict with the given color
/// (stored without the leading `#`, matching the existing convention).
/proc/body_marking_entry_defaults(color)
	return list(
		"color" = color,
		"pixel_x" = 0,
		"pixel_y" = 0,
		"flip_x" = FALSE,
		"flip_y" = FALSE,
		"rotation" = 0,
		"scale" = 1,
	)

/// Returns the color string for a marking entry regardless of shape.
/proc/body_marking_entry_color(entry)
	if(islist(entry))
		return entry["color"]
	return entry

/// Upgrades a legacy flat-hex entry to the dict shape. Entries already in
/// dict shape are returned unchanged.
/proc/body_marking_entry_upgrade(entry)
	if(islist(entry))
		return entry
	return body_marking_entry_defaults(entry)
