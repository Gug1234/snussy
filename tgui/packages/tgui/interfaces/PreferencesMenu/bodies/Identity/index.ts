/**
 * @file bodies/Identity/index.ts
 * @description Side-effect barrel for Identity body modules.
 *
 * Importing this file from the shell triggers `registerPrefsBody()`
 * for every Identity row. Order here drives the LeftColumn row-list
 * order because the registry preserves insertion order.
 */

import './Name';
import './Pronouns';
import './Voice';
import './Origin';
import './Family';
import './Faith';
import './Descriptors';
import './Flavor';
import './Images';
import './Song';
import './Misc';
import './Gnoll';
import './Familiar';
import './Jelly';
