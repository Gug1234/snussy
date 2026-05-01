/**
 * tools/build/appearance_preview/adapters/index.ts
 *
 * Public barrel for the adapter subsystem. Importing this module:
 *   - Re-exports the contract + registry surface.
 *   - In Step 3, will additionally side-effect-import every concrete adapter
 *     module so the registry is populated by the time `loadAdapters` runs.
 *
 * Step 2 scope: re-exports only. No concrete adapters exist yet.
 */

export type {
  Adapter,
  AdapterDiscovery,
  DiscoveredState,
  PreviewMetadata,
} from "./contract";

export {
  type AdapterConfig,
  getRegisteredAdapters,
  loadAdapters,
  readAdapterConfig,
  registerAdapter,
  validateDiscovery,
} from "./registry";

// Side-effect imports: each concrete adapter calls `registerAdapter` at
// module top-level, so importing this barrel populates the registry with
// every shipped family. Order does not matter for registration but we keep
// it alphabetical for readability.
import "./custom_piercings";
import "./intimate_piercing_items";
import "./taur_offsets";
