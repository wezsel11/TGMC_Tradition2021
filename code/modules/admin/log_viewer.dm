/datum/admins
	///The log viewer window of this admin
	var/datum/log_viewer/log_viewer

/datum/admins/proc/open_log_viewer()
	set category = "Admin"
	set name = "Log Viewer"
	set desc = "Search the logs of the current round."

	if(!check_rights(R_ASAY))
		return

	var/datum/admins/holder = usr.client.holder
	if(!holder.log_viewer)
		holder.log_viewer = new
	holder.log_viewer.ui_interact(usr)


///Shows the recent log entries of the round, with filters on category and text
/datum/log_viewer
	///Categories that are hidden
	var/list/hidden_categories = list()
	///Text the entries have to contain
	var/search = ""
	///Most entries shown at once
	var/max_shown = 500

/datum/log_viewer/ui_state(mob/user)
	return GLOB.admin_state

/datum/log_viewer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LogViewer")
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/log_viewer/ui_data(mob/user)
	. = list()
	var/list/categories = list()
	for(var/category in GLOB.log_categories)
		categories += list(list("name" = category, "shown" = !hidden_categories[category]))
	.["categories"] = categories
	.["search"] = search
	.["total"] = length(GLOB.log_entries)

	var/list/entries = list()
	var/list/log_entries = GLOB.log_entries
	for(var/i in length(log_entries) to 1 step -1)
		var/list/entry = log_entries[i]
		if(hidden_categories[entry[2]])
			continue
		if(search && !findtext(entry[3], search))
			continue
		entries += list(entry)
		if(length(entries) >= max_shown)
			break
	.["entries"] = entries
	.["max_shown"] = max_shown

/datum/log_viewer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!check_rights(R_ASAY))
		return

	switch(action)
		if("refresh")
			return TRUE
		if("toggle_category")
			var/category = params["category"]
			if(!GLOB.log_categories[category])
				return
			if(hidden_categories[category])
				hidden_categories -= category
			else
				hidden_categories[category] = TRUE
			return TRUE
		if("show_all")
			hidden_categories.Cut()
			return TRUE
		if("hide_all")
			for(var/category in GLOB.log_categories)
				hidden_categories[category] = TRUE
			return TRUE
		if("search")
			search = copytext_char(trim("[params["search"]]"), 1, 100)
			return TRUE
