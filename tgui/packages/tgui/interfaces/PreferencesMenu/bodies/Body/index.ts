/**
 * @file bodies/Body/index.ts
 * @description Side-effect barrel for Body body modules.
 *
 * Importing this file from the shell triggers `registerPrefsBody()`
 * for every Body row. Insertion order here drives the LeftColumn row
 * order because the registry preserves it.
 */

import './Race';
import './BodyType';
import './Coloration';
import './Hair';
import './Head';
import './Extremities';
import './Genitals';
import './Markings';
import './Taur';
import './CustomizerCatalog';
