// Intimate accessory variants split across focused feature files.
// Note: intimate_piercings.dm and intimate_insertables.dm are included
// directly in roguetown.dme before this file; only intimate_jelly.dm
// is included here to avoid duplicate_include diagnostics.

/obj/item/intimate_accessory/proc/apply_intimate_item_tint()
	if(intimate_metal_color)
		color = intimate_metal_color
	else
		color = initial(color)

// intimate_jelly.dm is included via roguetown.dme — do not duplicate here.
