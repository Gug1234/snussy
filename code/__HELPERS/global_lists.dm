//////////////////////////
/////Initial Building/////
//////////////////////////

/proc/make_datum_references_lists()
	//Species
	if(!islist(GLOB.species_list))
		GLOB.species_list = list()
	for(var/species_path in subtypesof(/datum/species))
		var/datum/species/species = new species_path()
		if(!species?.name)
			qdel(species)
			continue
		GLOB.species_list[species.name] = species_path
	sortList(GLOB.species_list, GLOBAL_PROC_REF(cmp_typepaths_asc))

	//Surgery steps
	GLOB.surgery_steps = list()
	for(var/path in subtypesof(/datum/surgery_step))
		GLOB.surgery_steps[++GLOB.surgery_steps.len] = new path()
	sortList(GLOB.surgery_steps, GLOBAL_PROC_REF(cmp_typepaths_asc))

	//Surgeries
	GLOB.surgeries_list = list()
	for(var/path in subtypesof(/datum/surgery))
		GLOB.surgeries_list[++GLOB.surgeries_list.len] = new path()
	sortList(GLOB.surgeries_list, GLOBAL_PROC_REF(cmp_typepaths_asc))

	// Keybindings
	init_keybindings()

	GLOB.emote_list = init_emote_list()

	GLOB.crafting_recipes = init_subtypes(/datum/crafting_recipe, GLOB.crafting_recipes)

	GLOB.alch_grind_recipes = init_subtypes(/datum/alch_grind_recipe, GLOB.alch_grind_recipes)

	GLOB.artificer_recipes = init_subtypes(/datum/artificer_recipe, GLOB.artificer_recipes)

	GLOB.alch_cauldron_recipes = init_subtypes(/datum/alch_cauldron_recipe, GLOB.alch_cauldron_recipes)

	GLOB.stew_recipes = init_subtypes(/datum/stew_recipe, GLOB.stew_recipes)

	// Anvil recipes
	if(!islist(GLOB.anvil_recipes))
		GLOB.anvil_recipes = list()
	for(var/path in subtypesof(/datum/anvil_recipe))
		var/datum/anvil_recipe/recipe = new path()
		if(istype(recipe) && recipe.name && recipe.i_type)
			GLOB.anvil_recipes[++GLOB.anvil_recipes.len] = recipe
		else
			qdel(recipe)

	// Faiths
	if(!islist(GLOB.faithlist))
		GLOB.faithlist = list()
	if(!islist(GLOB.preference_faiths))
		GLOB.preference_faiths = list()
	for(var/path in subtypesof(/datum/faith))
		var/datum/faith/faith = new path()
		GLOB.faithlist[path] = faith
		if(faith.preference_accessible)
			GLOB.preference_faiths[path] = faith

	// Patron Gods
	if(!islist(GLOB.patronlist))
		GLOB.patronlist = list()
	if(!islist(GLOB.patrons_by_faith))
		GLOB.patrons_by_faith = list()
	if(!islist(GLOB.preference_patrons))
		GLOB.preference_patrons = list()
	for(var/path in subtypesof(/datum/patron))
		var/datum/patron/patron = new path()
		GLOB.patronlist[path] = patron
		LAZYINITLIST(GLOB.patrons_by_faith[patron.associated_faith])
		GLOB.patrons_by_faith[patron.associated_faith][path] = patron
		if(patron.preference_accessible)
			GLOB.preference_patrons[path] = patron

	// Ported from Lethalstone
	if(!islist(GLOB.statpacks))
		GLOB.statpacks = list()
	for (var/path in subtypesof(/datum/statpack))
		var/datum/statpack/statpack = new path()
		GLOB.statpacks[path] = statpack
	sortList(GLOB.statpacks, GLOBAL_PROC_REF(cmp_text_dsc))

	if(!islist(GLOB.virtues))
		GLOB.virtues = list()
	for (var/path in subtypesof(/datum/virtue))
		var/datum/virtue/virtue = new path()
		GLOB.virtues[path] = virtue

	// Loadout items
	if(!islist(GLOB.loadout_items))
		GLOB.loadout_items = list()
	for (var/path in subtypesof(/datum/loadout_item))
		var/datum/loadout_item/loadout_item = new path()
		GLOB.loadout_items[++GLOB.loadout_items.len] = loadout_item


	// Combat Music Overrides
	if(!islist(GLOB.cmode_tracks_by_type))
		GLOB.cmode_tracks_by_type = list()
	for (var/path in subtypesof(/datum/combat_music))
		var/datum/combat_music/combat_music = new path()
		GLOB.cmode_tracks_by_type[path] = combat_music

	for (var/path in GLOB.cmode_tracks_by_type)
		var/datum/combat_music/trackref = GLOB.cmode_tracks_by_type[path]
		cmode_track_to_namelist(trackref)

	// Inquisition Hermes list
	if(!islist(GLOB.inqsupplies))
		GLOB.inqsupplies = list()
	for (var/path in subtypesof(/datum/inqports))
		var/datum/inqports/inqports = new path()
		GLOB.inqsupplies[path] = inqports

	//druids menu
	if(!islist(GLOB.wildshapes))
		GLOB.wildshapes = list()
	for(var/mob/living/carbon/human/species/wildshape/shape as anything in subtypesof(/mob/living/carbon/human/species/wildshape))
		GLOB.wildshapes[shape.name] = shape

	// Vices 
	if(!islist(GLOB.charflaw_singletons))
		GLOB.charflaw_singletons = list()
	for (var/path in subtypesof(/datum/charflaw))
		var/datum/charflaw/charflaw = new path()
		GLOB.charflaw_singletons[path] = charflaw


//creates every subtype of prototype (excluding prototype) and adds it to list L.
//if no list/L is provided, one is created.
/proc/init_subtypes(prototype, list/L)
	if(!istype(L))
		L = list()
	for(var/path in subtypesof(prototype))
		L += new path()
	return L

//returns a list of paths to every subtype of prototype (excluding prototype)
//if no list/L is provided, one is created.
/proc/init_paths(prototype, list/L)
	if(!istype(L))
		L = list()
		for(var/path in subtypesof(prototype))
			L+= path
		return L
