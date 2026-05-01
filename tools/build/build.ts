#!/usr/bin/env node
/**
 * Build script for /tg/station 13 codebase.
 *
 * This script uses Juke Build, read the docs here:
 * https://github.com/stylemistake/juke-build
 */

import Bun from "bun";
import fs from "node:fs";
import Juke from "./juke/index.js";
import { buildAppearancePreviews } from "./appearance_preview/build";
import { materializeAppearancePreviews } from "./appearance_preview/materialize";
import type { BuildResult } from "./appearance_preview/types";
import { bun, bun_tgfont } from "./lib/bun";
import { DreamDaemon, DreamMaker, NamedVersionFile } from "./lib/byond";
import { downloadFile } from "./lib/download";
import { formatDeps } from "./lib/helpers";
import { prependDefines } from "./lib/tgs";

export const TGS_MODE = process.env.CBT_BUILD_MODE === "TGS";

export const DME_NAME = "roguetown";
const DYNAMIC_RSC_NAME = `${DME_NAME}.dyn.rsc`;

Juke.chdir("../..", import.meta.url);

function removeDynamicRsc(): void {
  try {
    fs.rmSync(DYNAMIC_RSC_NAME, { force: true });
  } catch {
    // Best-effort cleanup. A locked dynamic RSC means a DreamDaemon process is
    // still using the build output and should be handled by the caller.
  }
}

const dependencies: Record<string, any> = await Bun.file("dependencies.sh")
  .text()
  .then(formatDeps)
  .catch((err: unknown) => {
    Juke.logger.error(
      "Failed to read dependencies.sh, please ensure it exists and is formatted correctly.",
    );
    Juke.logger.error(err);
    throw new Juke.ExitCode(1);
  });

export const DefineParameter = new Juke.Parameter({
  type: "string[]",
  alias: "D",
});

export const PortParameter = new Juke.Parameter({
  type: "string",
  alias: "p",
});

export const DmVersionParameter = new Juke.Parameter({
  type: "string",
});

export const CiParameter = new Juke.Parameter({ type: "boolean" });

export const ForceRecutParameter = new Juke.Parameter({
  type: "boolean",
  name: "force-recut",
});

export const WarningParameter = new Juke.Parameter({
  type: "string[]",
  alias: "W",
});

export const NoWarningParameter = new Juke.Parameter({
  type: "string[]",
  alias: "I",
});

export const DmMapsIncludeTarget = new Juke.Target({
  executes: async () => {
    const folders = [
      ...Juke.glob("_maps/map_files/**/*.dmm"),
      ...Juke.glob("_maps/map_files/templates/**/*.dmm"),
    ];
    const content =
      folders
        .map((file) => file.replace("_maps/", ""))
        .map((file) => `#include "${file}"`)
        .join("\n") + "\n";
    fs.writeFileSync("_maps/templates.dm", content);
  },
});

export const DmTarget = new Juke.Target({
  parameters: [
    DefineParameter,
    DmVersionParameter,
    WarningParameter,
    NoWarningParameter,
  ],
  dependsOn: ({ get }) => [
    get(DefineParameter).includes("ALL_TEMPLATES") && DmMapsIncludeTarget,
  ],
  inputs: [
    "_maps/**",
    "code/**",
    "html/**",
    "icons/**",
    "interface/**",
    "sound/**",
    "tgui/public/tgui.html",
    "modular/**",
    "modular_azurepeak/**",
    "modular_hearthstone/**",
    `${DME_NAME}.dme`,
    NamedVersionFile,
  ],
  outputs: ({ get }) => {
    if (get(DmVersionParameter)) {
      return []; // Always rebuild when dm version is provided
    }
    return [`${DME_NAME}.dmb`, `${DME_NAME}.rsc`];
  },
  executes: async ({ get }) => {
    removeDynamicRsc();
    await DreamMaker(`${DME_NAME}.dme`, {
      defines: ["CBT", ...get(DefineParameter)],
      warningsAsErrors: get(WarningParameter).includes("error"),
      ignoreWarningCodes: get(NoWarningParameter),
      namedDmVersion: get(DmVersionParameter),
    });
  },
});

export const DmTestTarget = new Juke.Target({
  parameters: [
    DefineParameter,
    DmVersionParameter,
    WarningParameter,
    NoWarningParameter,
  ],
  dependsOn: ({ get }) => [
    get(DefineParameter).includes("ALL_MAPS") && DmMapsIncludeTarget,
  ],
  executes: async ({ get }) => {
    fs.copyFileSync(`${DME_NAME}.dme`, `${DME_NAME}.test.dme`);
    await DreamMaker(`${DME_NAME}.test.dme`, {
      defines: ["CBT", "CIBUILDING", ...get(DefineParameter)],
      warningsAsErrors: get(WarningParameter).includes("error"),
      ignoreWarningCodes: get(NoWarningParameter),
      namedDmVersion: get(DmVersionParameter),
    });
    Juke.rm("data/logs/ci", { recursive: true });
    const options = {
      dmbFile: `${DME_NAME}.test.dmb`,
      namedDmVersion: get(DmVersionParameter),
    };
    await DreamDaemon(
      options,
      "-close",
      "-trusted",
      "-verbose",
      "-params",
      "log-directory=ci",
    );
    Juke.rm("*.test.*");
    try {
      const cleanRun = fs.readFileSync("data/logs/ci/clean_run.lk", "utf-8");
      console.log(cleanRun);
    } catch (err) {
      Juke.logger.error("Test run was not clean, exiting");
      throw new Juke.ExitCode(1);
    }
  },
});

export const BunTarget = new Juke.Target({
  parameters: [CiParameter],
  inputs: ["tgui/**/package.json"],
  executes: () => {
    return bun("install", "--frozen-lockfile", "--ignore-scripts");
  },
});

export const TgFontTarget = new Juke.Target({
  dependsOn: [BunTarget],
  inputs: [
    "tgui/packages/tgfont/**/*.+(js|mjs|svg)",
    "tgui/packages/tgfont/package.json",
  ],
  outputs: [
    "tgui/packages/tgfont/dist/tgfont.css",
    "tgui/packages/tgfont/dist/tgfont.woff2",
  ],
  executes: async () => {
    await bun_tgfont("tgfont:build");
    fs.mkdirSync("tgui/packages/tgfont/static", { recursive: true });
    fs.copyFileSync(
      "tgui/packages/tgfont/dist/tgfont.css",
      "tgui/packages/tgfont/static/tgfont.css",
    );
    fs.copyFileSync(
      "tgui/packages/tgfont/dist/tgfont.woff2",
      "tgui/packages/tgfont/static/tgfont.woff2",
    );
  },
});

export const TguiTarget = new Juke.Target({
  dependsOn: [BunTarget],
  inputs: [
    "tgui/rspack.config.mjs",
    "tgui/**/package.json",
    "tgui/packages/**/*.+(js|cjs|ts|tsx|jsx|scss)",
  ],
  outputs: [
    "tgui/public/tgui.bundle.css",
    "tgui/public/tgui.bundle.js",
    "tgui/public/tgui-panel.bundle.css",
    "tgui/public/tgui-panel.bundle.js",
    "tgui/public/tgui-say.bundle.css",
    "tgui/public/tgui-say.bundle.js",
  ],
  executes: () => bun("tgui:build"),
});

export const TguiEslintTarget = new Juke.Target({
	parameters: [CiParameter],
	dependsOn: [BunTarget],
	executes: ({ get }) => bun("tgui:lint", !get(CiParameter) && "--fix"),
});

export const AppearancePreviewAssetsTarget = new Juke.Target({
	inputs: [
		"modular*/code/datums/appearance_preview/**/*.dm",
		"modular*/code/datums/custom_piercings/sticker_registry.dm",
		"modular*/code/modules/mob/dead/**/body_markings/**/*.dm",
		"modular*/code/modules/mob/dead/new_player/sprite_accessory/**/*.dm",
		"modular*/code/modules/mob/living/carbon/human/species_types/**/*.dm",
		"modular*/code/modules/surgery/bodyparts/taur.dm",
		"code/modules/mob/dead/new_player/body_markings/**/*.dm",
		"code/modules/mob/dead/new_player/sprite_accessory/**/*.dm",
		"code/modules/mob/living/carbon/human/species_types/**/*.dm",
		"code/modules/surgery/bodyparts/taur.dm",
		"modular/icons/obj/lewd/intimate_overlays.dmi",
		"modular/icons/obj/lewd/intimate_stickers.dmi",
		"tools/build/appearance_preview/**/*.ts",
		"tools/build/appearance_preview/config/adapters.json",
		"tools/build/build.ts",
	],
	outputs: [
		"tgui/public/appearance_preview/manifest.json",
		"tgui/public/appearance_preview/iconforge_plan.json",
	],
	executes: async () => {
		// Step 6: Invoke the RustG/iconforge-backed orchestrator in-process.
		// No subprocess hop; `buildAppearancePreviews` never throws and always
		// returns a `BuildResult`, so we translate failure -> Juke.ExitCode.
		const result = await buildAppearancePreviews({
			adapterConfig: "tools/build/appearance_preview/config/adapters.json",
			publicRoot: "tgui/public/appearance_preview",
			cacheDir: "tmp/appearance_preview_cache",
			silent: true,
		});
		logAppearancePreviewSummary(result);
		if (result.status !== "ok") {
			if (result.error) {
				Juke.logger.error(`Appearance preview build failed: ${result.error}`);
			}
			throw new Juke.ExitCode(1);
		}
	},
});

/**
 * Remediation Step 6: headless materialize stage.
 *
 * Consumes `iconforge_plan.json` from the already-published appearance
 * preview bundle and spawns `dreamdaemon` against a pre-built
 * `roguetown.dmb` so RustG iconforge emits the sheet PNGs at build time
 * rather than at world boot. The DM-side entry point lives in
 * `code/controllers/subsystem/appearance_preview_materialize.dm`.
 *
 * Dependencies:
 *   - `AppearancePreviewAssetsTarget` (plan + manifest must be published).
 *   - `DmTarget` (the DMB the subprocess loads).
 *
 * Inputs/outputs are declared so Juke short-circuits the stage when the
 * bundle + DMB are unchanged; the sheet PNG paths are derived from the
 * plan by the DM-side proc at runtime and are covered transitively by the
 * `manifest.json` + `iconforge_plan.json` input declaration.
 *
 * On failure, the stage throws `Juke.ExitCode(1)`; the previous live bundle
 * (PNGs, manifest, plan) is unaffected because materialize writes PNGs in
 * place — a failure leaves the bundle exactly as the assets target left it,
 * which means the boot-time fallback flag can still recover a usable server.
 */
export const AppearancePreviewMaterializeTarget = new Juke.Target({
	dependsOn: [AppearancePreviewAssetsTarget, DmTarget],
	inputs: [
		`${DME_NAME}.dmb`,
		"tgui/public/appearance_preview/manifest.json",
		"tgui/public/appearance_preview/iconforge_plan.json",
	],
	outputs: [
		"tgui/public/appearance_preview/materialize_status.json",
	],
	executes: async () => {
		const result = await materializeAppearancePreviews({
			dmbPath: `${DME_NAME}.dmb`,
			planDir: "tgui/public/appearance_preview",
			outputDir: "tgui/public/appearance_preview",
		});
		if (!result.ok) {
			Juke.logger.error(
				`Appearance preview materialize failed at stage '${result.stage}': ${result.error}`,
			);
			if (result.diagnosticLog) {
				Juke.logger.error(result.diagnosticLog);
			}
			throw new Juke.ExitCode(1);
		}
		Juke.logger.info(
			`Appearance preview materialized ${result.sheetCount} sheet(s) in ${result.elapsedMs}ms`,
		);
	},
});

export const TguiPrettierTarget = new Juke.Target({
  dependsOn: [BunTarget],
  executes: () => bun("tgui:prettier"),
});

export const TguiSonarTarget = new Juke.Target({
  dependsOn: [BunTarget],
  executes: () => bun("tgui:sonar"),
});

export const TguiTscTarget = new Juke.Target({
  dependsOn: [BunTarget],
  executes: () => bun("tgui:tsc"),
});

export const TguiLintTarget = new Juke.Target({
	dependsOn: [BunTarget, TguiPrettierTarget, TguiEslintTarget, TguiTscTarget],
});

type AppearancePreviewStageName = "scan" | "hash" | "pack" | "publish";

const APPEARANCE_PREVIEW_STAGE_ORDER: AppearancePreviewStageName[] = [
  "scan",
  "hash",
  "pack",
  "publish",
];

function formatSeconds(seconds: number): string {
  return `${seconds.toFixed(3)}s`;
}

function logAppearancePreviewSummary(result: BuildResult): void {
  const { metrics } = result;
  Juke.logger.info("Appearance preview build metrics:");
  Juke.logger.info(`  status: ${result.status}`);
  Juke.logger.info(`  backend: ${result.backend} (manifest v${result.manifestVersion})`);
  Juke.logger.info(`  total: ${formatSeconds(metrics.totalSeconds)}`);
  for (const stageName of APPEARANCE_PREVIEW_STAGE_ORDER) {
    Juke.logger.info(
      `  ${stageName}: ${formatSeconds(metrics.stageSeconds[stageName] ?? 0)}`,
    );
  }
  Juke.logger.info(`  cache hits: ${metrics.cacheHits}`);
  Juke.logger.info(`  cache misses: ${metrics.cacheMisses}`);
  Juke.logger.info(
    `  cache hit rate: ${(metrics.cacheHitRate * 100).toFixed(1)}%`,
  );
  Juke.logger.info(`  sheets: ${metrics.sheetCount}`);
  Juke.logger.info(`  states: ${metrics.stateCount}`);
  if (result.manifestPath) {
    Juke.logger.info(`  manifest: ${result.manifestPath}`);
  }
}

export const TguiTestTarget = new Juke.Target({
  parameters: [CiParameter],
  dependsOn: [BunTarget],
  executes: () => bun("tgui:test"),
});

export const TguiDevTarget = new Juke.Target({
  dependsOn: [BunTarget],
  executes: ({ args }) => bun("tgui:dev", ...args),
});

export const TguiAnalyzeTarget = new Juke.Target({
  dependsOn: [BunTarget],
  executes: () => bun("tgui:analyze"),
});

export const TguiBenchTarget = new Juke.Target({
  dependsOn: [BunTarget],
  executes: () => bun("tgui:bench"),
});

export const TestTarget = new Juke.Target({
  dependsOn: [DmTestTarget, TguiTestTarget],
});

export const LintTarget = new Juke.Target({
  dependsOn: [TguiLintTarget],
});

export const BuildTarget = new Juke.Target({
  dependsOn: [AppearancePreviewAssetsTarget, AppearancePreviewMaterializeTarget, TguiTarget, DmTarget],
});

export const ServerTarget = new Juke.Target({
  parameters: [DmVersionParameter, PortParameter],
  dependsOn: [BuildTarget],
  executes: async ({ get }) => {
    const port = get(PortParameter) || "1337";
    const options = {
      dmbFile: `${DME_NAME}.dmb`,
      namedDmVersion: get(DmVersionParameter),
    };
    removeDynamicRsc();
    await DreamDaemon(options, port, "-trusted");
  },
});

export const AllTarget = new Juke.Target({
  dependsOn: [TestTarget, LintTarget, BuildTarget],
});

export const TguiCleanTarget = new Juke.Target({
  executes: async () => {
    Juke.rm("tgui/public/appearance_preview", { recursive: true });
    Juke.rm("tgui/public/.tmp", { recursive: true });
    Juke.rm("tgui/public/*.map");
    Juke.rm("tgui/public/*.{chunk,bundle,hot-update}.*");
    Juke.rm("tgui/packages/tgfont/dist", { recursive: true });
    Juke.rm("tgui/node_modules", { recursive: true });
  },
});

export const CleanTarget = new Juke.Target({
  dependsOn: [TguiCleanTarget],
  executes: async () => {
    Juke.rm("*.{dmb,rsc}");
    Juke.rm("_maps/templates.dm");
  },
});

/**
 * Removes more junk at the expense of much slower initial builds.
 */
export const CleanAllTarget = new Juke.Target({
  dependsOn: [CleanTarget],
  executes: async () => {
    Juke.logger.info("Cleaning up data/logs");
    Juke.rm("data/logs", { recursive: true });
  },
});

export const TgsTarget = new Juke.Target({
  dependsOn: [TguiTarget],
  executes: async () => {
    Juke.logger.info("Prepending TGS define");
    prependDefines("TGS");
  },
});

Juke.setup({ file: import.meta.url }).then((code) => {
  // We're using the currently available quirk in Juke Build, which
  // prevents it from exiting on Windows, to wait on errors.
  if (code !== 0 && process.argv.includes("--wait-on-error")) {
    Juke.logger.error("Please inspect the error and close the window.");
    return;
  }

  if (TGS_MODE) {
    // workaround for ESBuild process lingering
    // Once https://github.com/privatenumber/esbuild-loader/pull/354 is merged and updated to, this can be removed
    setTimeout(() => process.exit(code), 10000);
  } else {
    process.exit(code);
  }
});

export default TGS_MODE ? TgsTarget : BuildTarget;
