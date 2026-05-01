/**
 * Admin verb for triggering the pref_catalog plan dump during development.
 * Writes data/pref_catalog/plan.json so the result can be inspected and
 * iterated on without needing the full materialize pipeline (Phase 2).
 *
 * Removed once Phase 2 lands a proper build-time entry point.
 */

/client/proc/dump_pref_catalog_plan()
	set name = "Dump Pref Catalog Plan"
	set category = "Debug"
	set desc = "Phase 1 dev tool: enumerate wildkin/moth/construct customizer accessories and write data/pref_catalog/plan.json."

	if(!check_rights(R_DEBUG))
		return

	var/output_path = "data/pref_catalog/plan.json"
	var/list/species_targets = pref_catalog_default_species_targets()
	var/start_ms = world.time
	var/ok = pref_catalog_emit_plan(output_path, species_targets)
	var/elapsed = world.time - start_ms

	if(ok)
		to_chat(usr, span_notice("pref_catalog: wrote plan to [output_path] in [elapsed]ds. Inspect with a JSON viewer."))
	else
		to_chat(usr, span_warning("pref_catalog: plan emission FAILED. See runtime / stack traces."))

	log_admin("[key_name(usr)] dumped pref_catalog plan ([species_targets.len] species) -> [output_path] (ok=[ok], [elapsed]ds).")

/**
 * Phase 2 dev verb: run the full enumerate -> iconforge bake cycle in one
 * shot. Writes plan.json, then sheets/<name>.png + manifest.json under the
 * same data/pref_catalog/ output dir. Use after content changes to refresh
 * the baked spritesheets without restarting dreamdaemon.
 */
/client/proc/materialize_pref_catalog()
	set name = "Materialize Pref Catalog"
	set category = "Debug"
	set desc = "Phase 2 dev tool: enumerate the catalog plan and bake every sheet via iconforge into data/pref_catalog/."

	if(!check_rights(R_DEBUG))
		return

	var/output_dir = "data/pref_catalog/"
	var/plan_path = "[output_dir]plan.json"
	var/list/species_targets = pref_catalog_default_species_targets()

	to_chat(usr, span_notice("pref_catalog: enumerating plan ([species_targets.len] species)..."))
	var/start_ms = world.time
	if(!pref_catalog_emit_plan(plan_path, species_targets))
		to_chat(usr, span_warning("pref_catalog: plan emission FAILED. See runtime / stack traces."))
		return
	to_chat(usr, span_notice("pref_catalog: plan written to [plan_path] in [world.time - start_ms]ds. Baking sheets..."))

	var/bake_start_ms = world.time
	var/ok = pref_catalog_materialize_run(plan_path, output_dir)
	var/bake_elapsed = world.time - bake_start_ms
	var/total_elapsed = world.time - start_ms

	if(ok)
		to_chat(usr, span_notice("pref_catalog: bake OK ([bake_elapsed]ds, total [total_elapsed]ds). See [output_dir]manifest.json + sheets under [output_dir]sheets/."))
	else
		to_chat(usr, span_warning("pref_catalog: bake FAILED after [bake_elapsed]ds. See [output_dir]materialize_status.json for the failure stage."))

	log_admin("[key_name(usr)] ran materialize_pref_catalog ([species_targets.len] species, ok=[ok], total [total_elapsed]ds).")
