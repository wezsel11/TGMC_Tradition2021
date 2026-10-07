/**
 * tgui state: xeno_state
 *
 * Checks that the user is a xeno, ezpz.
 **/

GLOBAL_DATUM_INIT(xeno_state, /datum/ui_state/xeno_state, new)

/datum/ui_state/xeno_state/can_use_topic(src_object, mob/user)
	if(!isxeno(user))
		return UI_CLOSE
	if(user.stat == DEAD)
		return UI_DISABLED
	if(user.stat == UNCONSCIOUS || user.incapacitated())
		return UI_UPDATE
	return UI_INTERACTIVE

/**
 * tgui state: hive_ui_state
 *
 * The Hive Status window, as modern TGMC. Xenos and ghosts can view it, admins too
 * for the admin Hive Status verb. Marines respawning should not be able to see it anymore.
 **/

GLOBAL_DATUM_INIT(hive_ui_state, /datum/ui_state/hive_ui_state, new)

/datum/ui_state/hive_ui_state/can_use_topic(src_object, mob/user)
	if(isxeno(user) || isobserver(user) || check_rights_for(user.client, R_ADMIN))
		return UI_INTERACTIVE
	return UI_CLOSE
