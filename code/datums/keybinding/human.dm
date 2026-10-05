/datum/keybinding/human
	category = CATEGORY_HUMAN
	weight = WEIGHT_MOB


/datum/keybinding/human/quick_equip
	hotkey_keys = list("E")
	name = "quick_equip"
	full_name = "Quick equip"
	description = ""
	keybind_signal = COMSIG_KB_QUICKEQUIP

/datum/keybinding/human/quick_equip_alt
	hotkey_keys = list("ShiftE")
	name = "quick_equip_alt"
	full_name = "Quick equip alternate"
	description = "Quick equip using your alternate preferred slot"
	keybind_signal = COMSIG_KB_QUICKEQUIPALT

/datum/keybinding/human/toggle_suit_light
	name = "toggle_suit_light"
	full_name = "Toggle suit light"
	description = "Toggles your suit light on or off"
	keybind_signal = COMSIG_KB_SUITLIGHT


/datum/keybinding/human/holster
	hotkey_keys = list("H")
	name = "holster"
	full_name = "Holster"
	description = ""
	keybind_signal = COMSIG_KB_HOLSTER


/datum/keybinding/human/unique_action
	hotkey_keys = list("Space")
	name = "unique_action"
	full_name = "Perform unique action"
	description = ""
	keybind_signal = COMSIG_KB_UNIQUEACTION

/datum/keybinding/human/rail_attachment
	hotkey_keys = list("F")
	name = "rail_attachment"
	full_name = "Activate Rail attachment"
	description = ""
	keybind_signal = COMSIG_KB_RAILATTACHMENT

/datum/keybinding/human/interact_other_hand
	name = "interact_other_hand"
	full_name = "Interact with other hand"
	description = "Use the item in your active hand on the item in your other hand, or pick it up with an empty hand"
	keybind_signal = COMSIG_KB_HUMAN_INTERACT_OTHER_HAND

/datum/keybinding/human/interact_other_hand/down(client/user)
	. = ..()
	if(.)
		return
	if(!ishuman(user.mob))
		return
	var/mob/living/carbon/human/human_user = user.mob
	human_user.interact_other_hand()
	return TRUE

/datum/keybinding/human/toggle_auto_eject
	name = "toggle_auto_eject"
	full_name = "Toggle automatic magazine ejection"
	description = "Toggles the automatic unloading of the gun's magazine upon depletion"
	keybind_signal = COMSIG_KB_AUTOEJECT

/datum/keybinding/human/toggle_auto_eject/down(client/user)
	. = ..()
	if(.)
		return
	var/obj/item/weapon/gun/gun = get_active_firearm(user.mob)
	gun?.do_toggle_auto_eject(user.mob)
	return TRUE
