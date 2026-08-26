// Intimate accessory variants split across focused feature files.
// Concrete piercings and insertables are included directly in roguetown.dme.

/obj/item/intimate_accessory/proc/apply_intimate_item_tint()
	if(intimate_metal_color)
		color = intimate_metal_color
	else
		color = initial(color)
