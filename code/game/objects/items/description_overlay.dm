// Short descriptions shown on the icon of an item, as modern TGMC (#10664).
// Only shown while the item is held or stored, never on the floor.

/obj/item
	///Short description shown on the icon while held or stored, eg. "Bi" on a bicaridine pill bottle
	var/description_overlay
	///The overlay currently showing the description
	var/mutable_appearance/description_overlay_appearance

/obj/item/Initialize()
	. = ..()
	if(description_overlay)
		update_description_overlay()

/obj/item/Moved(atom/oldloc, direction, Forced = FALSE)
	. = ..()
	if(description_overlay && isturf(loc) != isturf(oldloc))
		update_description_overlay()

///Shows or hides the short description overlay, depending on where the item is
/obj/item/proc/update_description_overlay()
	if(description_overlay_appearance)
		cut_overlay(description_overlay_appearance)
		description_overlay_appearance = null
	if(!description_overlay || isturf(loc))
		return
	description_overlay_appearance = mutable_appearance()
	description_overlay_appearance.pixel_w = 16
	description_overlay_appearance.maptext_width = 16
	description_overlay_appearance.maptext = MAPTEXT(description_overlay)
	add_overlay(description_overlay_appearance)
