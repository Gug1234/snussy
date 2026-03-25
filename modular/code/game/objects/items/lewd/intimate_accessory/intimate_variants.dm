// Intimate accessory variants split across focused feature files.

/obj/item/intimate_accessory/proc/apply_intimate_item_tint()
	if(intimate_metal_color)
		color = intimate_metal_color
	else
		color = initial(color)

#include "intimate_piercings.dm"
#include "intimate_insertables.dm"
#include "intimate_jelly.dm"
