// Hive Status as a TGUI window, as modern TGMC. Shows the same information as the old Hive Status popup.

/proc/check_hive_status(mob/user)
	if(!SSticker)
		return

	var/datum/hive_status/hive
	if(isxeno(user))
		var/mob/living/carbon/xenomorph/xeno_user = user
		if(xeno_user.hive)
			hive = xeno_user.hive
	else
		hive = GLOB.hive_datums[XENO_HIVE_NORMAL]

	if(!hive)
		CRASH("couldnt find a hive in check_hive_status")

	if(!hive.status_ui)
		hive.status_ui = new(hive)
	hive.status_ui.ui_interact(user)


/datum/hive_status
	///The Hive Status window of this hive
	var/datum/hive_status_ui/status_ui

///Holds the Hive Status window of a hive
/datum/hive_status_ui
	var/datum/hive_status/hive

/datum/hive_status_ui/New(datum/hive_status/new_hive)
	. = ..()
	hive = new_hive

/datum/hive_status_ui/ui_state(mob/user)
	return GLOB.hive_ui_state

/datum/hive_status_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HiveStatus")
		ui.open()

/datum/hive_status_ui/ui_data(mob/user)
	. = list()
	.["hive_name"] = hive.name
	var/mob/living/carbon/xenomorph/xeno_user = user
	.["can_watch"] = isxenoqueen(user) && xeno_user.hive == hive

	var/list/tier_counts = list("[XENO_TIER_ONE]" = list(), "[XENO_TIER_TWO]" = list(), "[XENO_TIER_THREE]" = list())
	var/list/xeno_list = list()

	for(var/mob/living/carbon/xenomorph/X as anything in hive.xenos_by_typepath[/mob/living/carbon/xenomorph/queen])
		xeno_list += list(xeno_entry(X, FALSE))

	for(var/mob/living/carbon/xenomorph/X as anything in hive.xeno_leader_list)
		xeno_list += list(xeno_entry(X, TRUE))

	for(var/typepath in hive.xenos_by_typepath)
		var/mob/living/carbon/xenomorph/T = typepath
		var/datum/xeno_caste/XC = GLOB.xeno_caste_datums[typepath][XENO_UPGRADE_BASETYPE]
		if(XC.caste_flags & CASTE_HIDE_IN_STATUS)
			continue
		var/tier = initial(T.tier)
		if(tier == XENO_TIER_ZERO)
			continue
		if(tier_counts["[tier]"])
			tier_counts["[tier]"] += list(list("name" = "[initial(T.name)]s", "count" = length(hive.xenos_by_typepath[typepath])))
		for(var/mob/living/carbon/xenomorph/X as anything in hive.xenos_by_typepath[typepath])
			if(X.queen_chosen_lead)
				continue
			xeno_list += list(xeno_entry(X, FALSE))

	for(var/mob/living/carbon/xenomorph/X as anything in hive.xenos_by_typepath[/mob/living/carbon/xenomorph/larva])
		if(X.queen_chosen_lead)
			continue
		xeno_list += list(xeno_entry(X, FALSE))

	.["xenos"] = xeno_list
	.["total"] = hive.get_total_xeno_number()
	.["tiers"] = list(
		list("name" = "Tier 3", "count" = length(hive.xenos_by_tier[XENO_TIER_THREE]), "limit" = hive.tier3_xeno_limit, "castes" = tier_counts["[XENO_TIER_THREE]"]),
		list("name" = "Tier 2", "count" = length(hive.xenos_by_tier[XENO_TIER_TWO]), "limit" = hive.tier2_xeno_limit, "castes" = tier_counts["[XENO_TIER_TWO]"]),
		list("name" = "Tier 1", "count" = length(hive.xenos_by_tier[XENO_TIER_ONE]), "castes" = tier_counts["[XENO_TIER_ONE]"]),
	)
	.["larva"] = length(hive.xenos_by_typepath[/mob/living/carbon/xenomorph/larva])

	var/mob/living/carbon/xenomorph/queen/hive_queen = hive.living_xeno_queen
	.["queen"] = hive_queen ? "[hive_queen][hive_queen.client ? "" : " (SSD)"]" : "None"
	.["hivemind"] = length(hive.xenos_by_typepath[/mob/living/carbon/xenomorph/hivemind]) > 0

	.["burrowed"] = null
	if(hive.hivenumber == XENO_HIVE_NORMAL)
		var/datum/job/xeno_job = SSjob.GetJobType(/datum/job/xenomorph)
		.["burrowed"] = xeno_job.total_positions - xeno_job.current_positions

	var/list/silos = list()
	for(var/obj/structure/resin/silo/resin_silo as anything in GLOB.xeno_resin_silos)
		if(resin_silo.associated_hive != hive)
			continue
		silos += list(list(
			"name" = resin_silo.name,
			"health" = resin_silo.obj_integrity,
			"max_health" = resin_silo.max_integrity,
			"location" = AREACOORD_NO_Z(resin_silo),
		))
	.["silos"] = silos

///Data of one xeno for the Hive Status window
/datum/hive_status_ui/proc/xeno_entry(mob/living/carbon/xenomorph/X, leader)
	return list(
		"ref" = REF(X),
		"name" = X.name,
		"leader" = leader,
		"ssd" = !X.client,
		"health" = X.health,
		"max_health" = X.maxHealth,
		"location" = AREACOORD_NO_Z(X),
	)

/datum/hive_status_ui/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("watch")
			var/mob/living/carbon/xenomorph/queen/Q = usr
			if(!istype(Q) || Q.hive != hive || !Q.check_state())
				return
			var/mob/living/carbon/xenomorph/X = locate(params["xeno"]) in hive.get_watchable_xenos()
			if(!X)
				return
			SEND_SIGNAL(Q, COMSIG_XENOMORPH_WATCHXENO, X)
			return TRUE
