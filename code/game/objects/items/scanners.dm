/*
CONTAINS:
T-RAY
DETECTIVE SCANNER
HEALTH ANALYZER
GAS ANALYZER
PLANT ANALYZER
MASS SPECTROMETER
REAGENT SCANNER
*/
/obj/item/t_scanner
	name = "\improper T-ray scanner"
	desc = "A terahertz-ray emitter and scanner used to detect underfloor objects such as cables and pipes."
	icon_state = "t-ray0"
	var/on = 0
	flags_atom = CONDUCT
	flags_equip_slot = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"


/obj/item/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = "t-ray[on]"

	if(on)
		START_PROCESSING(SSobj, src)


/obj/item/t_scanner/process()
	if(!on)
		STOP_PROCESSING(SSobj, src)
		return null

	for(var/turf/T in range(1, src.loc) )

		if(!T.intact_tile)
			continue

		for(var/obj/O in T.contents)

			if(O.level != 1)
				continue

			if(O.invisibility == INVISIBILITY_MAXIMUM)
				O.invisibility = 0
				O.alpha = 128
				spawn(10)
					if(O && !O.gc_destroyed)
						var/turf/U = O.loc
						if(U.intact_tile)
							O.invisibility = INVISIBILITY_MAXIMUM
							O.alpha = 255


/obj/item/healthanalyzer
	name = "\improper HF2 health analyzer"
	icon_state = "health"
	item_state = "analyzer"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject. The front panel is able to provide the basic readout of the subject's status."
	flags_atom = CONDUCT
	flags_equip_slot = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 5
	throw_range = 10
	var/mode = 1
	var/hud_mode = 1
	var/skill_threshold = SKILL_MEDICAL_PRACTICED
	///Results of the last scan, shown in the scanner window
	var/list/last_scan

/obj/item/healthanalyzer/attack(mob/living/carbon/M, mob/living/user) //Integrated analyzers don't need special training to be used quickly.
	if((user.getBrainLoss() >= 60) && prob(50))
		to_chat(user, "<span class='warning'>You try to analyze the floor's vitals!</span>")
		visible_message("<span class='warning'>[user] has analyzed the floor's vitals!</span>")
		user.show_message("<span class='notice'>Health Analyzer results for The floor:\n\t Overall Status: Healthy</span>", 1)
		user.show_message("<span class='notice'>\t Damage Specifics: [0]-[0]-[0]-[0]</span>", 1)
		user.show_message("<span class='notice'>Key: Suffocation/Toxin/Burns/Brute</span>", 1)
		user.show_message("<span class='notice'>Body Temperature: ???</span>", 1)
		return
	if(user.skills.getRating("medical") < skill_threshold)
		to_chat(user, "<span class='warning'>You start fumbling around with [src]...</span>")
		var/fduration = max(SKILL_TASK_AVERAGE - (1 SECONDS * user.skills.getRating("medical")), 0)
		if(!do_mob(user, M, fduration, BUSY_ICON_UNSKILLED))
			return
	if(isxeno(M))
		to_chat(user, "<span class='warning'>[src] can't make sense of this creature.</span>")
		return
	to_chat(user, "<span class='notice'>[user] has analyzed [M]'s vitals.")
	playsound(src.loc, 'sound/items/healthanalyzer.ogg', 50)

	// Doesn't work on non-humans and synthetics
	if(!iscarbon(M) || issynth(M))
		user.show_message("\n<span class='notice'> Health Analyzer results for ERROR:\n\t Overall Status: ERROR</span>")
		user.show_message("\tType: <span class='notice'>Oxygen</font>-<font color='green'>Toxin</font>-<font color='#FFA500'>Burns</font>-<font color='red'>Brute</span>", 1)
		user.show_message("\tDamage: <span class='notice'>?</font> - <font color='green'>?</font> - <font color='#FFA500'>?</font> - <font color='red'>?</span>")
		user.show_message("<span class='notice'> Body Temperature: [M.bodytemperature-T0C]&deg;C ([M.bodytemperature*1.8-459.67]&deg;F)</span>", 1)
		user.show_message("<span class='warning'> <b>Warning: Blood Level ERROR: --% --cl.<span class='notice'> Type: ERROR</span>")
		user.show_message("<span class='notice'> Subject's pulse: <font color='red'>-- bpm.</font></span>")
		return

	var/list/scan = analyze_vitals(M)
	if(hud_mode) //The results are shown in a TGUI window, as modern TGMC
		last_scan = scan
		ui_interact(user)
	else
		user.show_message(scan_to_text(scan), 1)

///Scans a patient, returns the results as a list for the scanner window or chat
/obj/item/healthanalyzer/proc/analyze_vitals(mob/living/carbon/M)
	var/list/scan = list()
	var/list/warnings = list()
	scan["patient"] = "[M]"

	// Calculate damage amounts
	var/oxy = M.getOxyLoss()
	if(HAS_TRAIT(M, TRAIT_FAKEDEATH))
		oxy = max(rand(1,40), M.getOxyLoss(), (300 - (M.getToxLoss() + M.getFireLoss() + M.getBruteLoss())))
		scan["dead"] = TRUE
	else
		scan["dead"] = M.stat > 1
	scan["health"] = M.health
	scan["damage"] = list(oxy, M.getToxLoss(), M.getFireLoss(), M.getBruteLoss())

	var/infection_present = 0
	var/unrevivable = 0
	var/overdosed = 0

	// Show specific limb damage
	var/list/limbs = null
	if(ishuman(M) && mode == 1)
		limbs = list()
		var/mob/living/carbon/human/H = M
		for(var/datum/limb/org in H.limbs)
			var/open_incision = (org.surgery_open_stage != 0)

			if(org.limb_status & LIMB_DESTROYED)
				limbs += list(list("name" = capitalize(org.display_name), "missing" = TRUE))
				continue

			var/show_limb = (org.burn_dam > 0 || org.brute_dam > 0 || (org.limb_status & (LIMB_BLEEDING | LIMB_NECROTIZED | LIMB_SPLINTED | LIMB_STABILIZED)) || open_incision)
			var/fracture = (org.limb_status & LIMB_BROKEN) && !(org.limb_status & LIMB_SPLINTED) && !(org.limb_status & LIMB_STABILIZED)
			if(fracture)
				show_limb = 1
			var/infection = org.has_infected_wound()
			if(infection)
				show_limb = 1
			if(org.limb_status & LIMB_NECROTIZED)
				infection_present = 10
			var/org_advice = ""
			switch(org.body_part)
				if(HEAD)
					fracture = FALSE
					if(org.brute_dam > 40 || M.getBrainLoss() >= 20)
						org_advice = "Possible Skull Fracture."
						show_limb = 1
				if(CHEST)
					fracture = FALSE
					if(org.brute_dam > 40 || M.getOxyLoss() > 50)
						org_advice = "Possible Chest Fracture."
						show_limb = 1
				if(GROIN)
					fracture = FALSE
					if(org.brute_dam > 40 || M.getToxLoss() > 50)
						org_advice = "Possible Groin Fracture."
						show_limb = 1
			if(!show_limb)
				continue
			limbs += list(list(
				"name" = "[capitalize(org.display_name)][org.limb_status & LIMB_ROBOT ? " (Cybernetic)" : ""]",
				"missing" = FALSE,
				"burn" = round(org.burn_dam),
				"brute" = round(org.brute_dam),
				"untreated_burn" = org.burn_dam > 0 && !org.is_salved(),
				"untreated_brute" = org.brute_dam >= 1 && (!(org.is_bandaged() || org.is_disinfected()) || open_incision),
				"fracture" = fracture,
				"infection" = infection,
				"bleeding" = !!(org.limb_status & LIMB_BLEEDING),
				"necrotizing" = !!(org.limb_status & LIMB_NECROTIZED),
				"incision" = open_incision,
				"advice" = org_advice,
				"splinted" = !!(org.limb_status & LIMB_SPLINTED),
				"stabilized" = !(org.limb_status & LIMB_SPLINTED) && (org.limb_status & LIMB_STABILIZED),
			))
	scan["limbs"] = limbs

	// Show red messages - broken bokes, infection, etc
	if (M.getCloneLoss())
		warnings += "Subject appears to have been imperfectly cloned."
	if (M.getBrainLoss() >= 100 || !M.has_brain())
		warnings += "Subject is brain dead."
	else if (M.getBrainLoss() >= 60)
		warnings += "Severe brain damage detected. Subject likely to have intellectual disabilities."
	else if (M.getBrainLoss() >= 10)
		warnings += "Significant brain damage detected. Subject may have had a concussion."

	if(M.has_brain() && M.stat != DEAD && ishuman(M))
		if(!M.key)
			warnings += "No soul detected." // they ghosted
		else if(!M.client)
			warnings += "SSD detected." // SSD

	var/internal_bleed_detected = FALSE
	var/fracture_detected = FALSE
	var/unknown_body = 0
	var/known_implants = list(/obj/item/implant/neurostim)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/core_fracture = FALSE
		for(var/X in H.limbs)
			var/datum/limb/e = X
			var/limb = e.display_name
			var/can_amputate = ""
			for(var/datum/wound/W in e.wounds)
				if(W.internal)
					internal_bleed_detected = TRUE
					break
			if(e.body_part != CHEST && e.body_part != GROIN && e.body_part != HEAD)
				can_amputate = "or amputation"
				if((e.limb_status & LIMB_BROKEN) && !(e.limb_status & LIMB_SPLINTED) && !(e.limb_status & LIMB_STABILIZED))
					fracture_detected = TRUE
					warnings += "Bone Fracture: Unsecured fracture in subject's [limb]. Splinting recommended."
			else
				if((e.limb_status & LIMB_BROKEN) && !(e.limb_status & LIMB_SPLINTED) && !(e.limb_status & LIMB_STABILIZED))
					fracture_detected = TRUE
					core_fracture = TRUE
			if(e.germ_level >= INFECTION_LEVEL_THREE)
				warnings += "Subject's [limb] is in the last stage of infection. < 30u of antibiotics [can_amputate] recommended."
				infection_present = 25
			if(e.germ_level >= INFECTION_LEVEL_ONE && e.germ_level < INFECTION_LEVEL_THREE)
				warnings += "Subject's [limb] has an infection. Antibiotics recommended."
				infection_present = 5
			if(e.has_infected_wound())
				warnings += "Infected wound detected in subject's [limb]. Disinfection recommended."
			if (e.implants.len)
				for(var/I in e.implants)
					if(!is_type_in_list(I,known_implants))
						unknown_body++
			if(e.hidden)
				unknown_body++
			if(e.body_part == CHEST) //embryo in chest?
				if(locate(/obj/item/alien_embryo) in H)
					unknown_body++

		if(unknown_body)
			if(unknown_body > 1)
				warnings += "Foreign objects detected in body. Advanced scanner required for location."
			else
				warnings += "Foreign object detected in body. Advanced scanner required for location."
		if(core_fracture)
			warnings += "Bone fractures detected. Advanced scanner required for location."
		if(internal_bleed_detected)
			warnings += "Internal bleeding detected. Advanced scanner required for location."
	scan["warnings"] = warnings

	var/reagents_in_body[0] // yes i know -spookydonut
	var/list/reagents = list()
	var/unknown = 0
	// Show helpful reagents
	if(M.reagents.total_volume > 0)
		for(var/A in M.reagents.reagent_list)
			var/datum/reagent/R = A
			reagents_in_body["[R.type]"] = R.volume
			if(R.scannable)
				reagents += list(list("name" = R.name, "amount" = round(R.volume, 0.01), "od" = R.overdosed))
				if(R.overdosed)
					overdosed++
			else
				unknown++
	scan["reagents"] = reagents
	scan["unknown_reagents"] = unknown

	// Show body temp
	scan["temperature"] = list(M.bodytemperature - T0C, M.bodytemperature * 1.8 - 459.67)
	scan["blood"] = null
	scan["pulse"] = null
	scan["advice"] = list()
	scan["contraindications"] = list()
	if(!ishuman(M))
		return scan

	var/mob/living/carbon/human/H = M
	// Show blood level
	var/blood_volume = BLOOD_VOLUME_NORMAL
	var/is_dead = FALSE
	if(!(H.species.species_flags & NO_BLOOD))
		blood_volume = round(H.blood_volume)
		var/blood_status = "normal"
		if(blood_volume <= 500 && blood_volume > 336)
			blood_status = "LOW"
		else if(blood_volume <= 336)
			blood_status = "CRITICAL"
		scan["blood"] = list("status" = blood_status, "percent" = blood_volume / 560 * 100, "volume" = blood_volume, "type" = H.blood_type)
	// Show pulse
	var/pulse = H.handle_pulse()
	scan["pulse"] = list("bpm" = H.get_pulse(GETPULSE_TOOL), "bad" = (pulse == PULSE_THREADY || pulse == PULSE_NONE))
	if(H.stat == DEAD)
		is_dead = TRUE
		//check to see if the target is revivable
		if(!H.is_revivable())
			unrevivable = TRUE
	if(unrevivable)
		return scan

	//Chems that conflict with others:
	var/synaptizine_amount = reagents_in_body[/datum/reagent/medicine/synaptizine]
	var/hyperzine_amount = reagents_in_body[/datum/reagent/medicine/hyperzine]
	var/paracetamol_amount = reagents_in_body[/datum/reagent/medicine/paracetamol]
	var/neurotoxin_amount = reagents_in_body[/datum/reagent/toxin/xeno_neurotoxin]
	var/growthtoxin_amount = reagents_in_body[/datum/reagent/toxin/xeno_growthtoxin]
	//Recurring chems:
	var/peridaxon = ""
	var/tricordrazine = ""
	//The actual medical advice summary:
	var/list/advice = list()
	//We start checks for ailments here:
	if(is_dead)
		var/death_message = ""
		//Check for whether there's an appropriate ghost
		if(H.client)
			//Calculate revival status/time left
			var/revive_timer = round((H.timeofdeath + H.revive_grace_time + CONFIG_GET(number/revive_grace_period) - world.time) * 0.1)
			if(revive_timer < 60) //Almost out of time; urgency required.
				death_message = "CRITICAL: Brain death imminent. Reduce total injury value to sub-200 and administer defibrillator to unarmoured chest immediately."
			else if(revive_timer < 120) //Running out of time; increase urgency of message.
				death_message = "URGENT: Brain death occurring soon. Reduce total injury value to sub-200 and administer defibrillator to unarmoured chest to revive."
			else //Freshly dead.
				death_message = "Brain death will occur if patient is left untreated. Reduce total injury value to sub-200 and administer defibrillator to unarmoured chest to revive."
		else //No soul? Change the death message.
			death_message = "No soul detected. Cannot revive."
		advice += list(list("title" = "Patient Dead", "text" = death_message))
	if(M.on_fire)
		advice += list(list("title" = "Patient Combusting", "text" = "Administer fire extinguisher, pat out or submerge patient in water, or employ other fire suppressant."))
	if(blood_volume <= 500 && !reagents_in_body[/datum/reagent/consumable/nutriment])
		var/iron = "."
		if(reagents_in_body[/datum/reagent/iron] < 5)
			iron = " or one dose of iron."
		advice += list(list("title" = "Low Blood", "text" = "Administer or recommend consumption of food[iron]"))
	if(overdosed && reagents_in_body[/datum/reagent/medicine/hypervene] < 3)
		advice += list(list("title" = "Overdose", "text" = "Administer one dose of hypervene or perform dialysis on patient via sleeper."))
	if(unknown_body)
		advice += list(list("title" = "Shrapnel/Embedded Object(s)", "text" = "Seek surgical remedy to remove embedded object(s)."))
	if(fracture_detected)
		advice += list(list("title" = "Unsecured Fracture", "text" = "Administer splints to specified areas."))
	if(internal_bleed_detected)
		var/internal_bleed_advice = "Administer one dose of quick-clot then seek surgical remedy."
		if(reagents_in_body[/datum/reagent/medicine/quickclot] > 4)
			internal_bleed_advice = "Quick-Clot has been administered to patient. Seek surgical remedy."
		advice += list(list("title" = "Internal Bleeding", "text" = internal_bleed_advice))
	if(H.getToxLoss() > 10)
		var/dylovene = ""
		var/dylo_recommend = ""
		if(reagents_in_body[/datum/reagent/medicine/dylovene] < 5)
			if(synaptizine_amount)
				dylo_recommend = "Addendum: Dylovene recommended, but conflicting synaptizine present."
			else
				dylovene = "dylovene"
		if(reagents_in_body[/datum/reagent/medicine/tricordrazine] < 5)
			tricordrazine = "tricordrazine"
		if(H.getToxLoss() > 50) //Serious toxin damage that is likely to threaten liver damage or be caused by it
			peridaxon = "Administer one dose of peridaxon and: "
			if(hyperzine_amount) //Need to make sure no conflicting chems are present; if so, warn the operator
				peridaxon = "Purge hyperzine in patient or wait for it to metabolize, then administer one dose of peridaxon and:"
			advice += list(list("title" = "Extreme Toxin Damage/Probable or Imminent Liver Damage", "text" = "[peridaxon] [dylovene] | [tricordrazine]. [dylo_recommend]"))
		else
			advice += list(list("title" = "Toxin Damage", "text" = "Administer one dose of: [tricordrazine] | [dylovene]."))
	if(((H.getOxyLoss() > 50 && blood_volume > 400) || H.getBrainLoss() >= 10) && reagents_in_body[/datum/reagent/medicine/peridaxon] < 5)
		peridaxon = "Administer one dose of peridaxon."
		if(hyperzine_amount) //Need to make sure no conflicting chems are present; if so, warn the operator
			peridaxon = "Purge hyperzine in patient or wait for it to metabolize, then administer one dose of peridaxon."
		advice += list(list("title" = "Brain Damage/Probable Organ Damage", "text" = peridaxon))
	if(infection_present && reagents_in_body[/datum/reagent/medicine/spaceacillin] < infection_present)
		advice += list(list("title" = "Infection", "text" = "Administer one dose of spaceacillin."))
	if(H.getOxyLoss() > 10)
		var/dexalin = ""
		var/dexplus = ""
		if(reagents_in_body[/datum/reagent/medicine/dexalin] < 5)
			dexalin = "dexalin"
		if(reagents_in_body[/datum/reagent/medicine/dexalinplus] < 1)
			dexplus = "dexalin plus"
		advice += list(list("title" = "Oxygen Deprivation", "text" = "Administer one dose of: [dexalin] | [dexplus]."))
	if(H.getFireLoss(1)  > 10)
		var/kelotane = ""
		var/dermaline = ""
		if(reagents_in_body[/datum/reagent/medicine/kelotane] < 5)
			kelotane = "kelotane"
		if(reagents_in_body[/datum/reagent/medicine/dermaline] < 1)
			dermaline = "dermaline"
		if(reagents_in_body[/datum/reagent/medicine/tricordrazine] < 5)
			tricordrazine = "tricordrazine"
		advice += list(list("title" = "Burn Damage", "text" = "Administer burn kit to affected areas and one dose of: [kelotane] | [dermaline] | [tricordrazine]."))
	if(H.getBruteLoss(1) > 10)
		var/bicaridine = ""
		if (reagents_in_body[/datum/reagent/medicine/bicaridine] < 5)
			bicaridine = "bicaridine"
		if(reagents_in_body[/datum/reagent/medicine/tricordrazine] < 5)
			tricordrazine = "tricordrazine"
		advice += list(list("title" = "Physical Trauma", "text" = "Administer trauma kit to affected areas and one dose of: [bicaridine] | [tricordrazine]."))
	if(H.health < 0 && reagents_in_body[/datum/reagent/medicine/inaprovaline] < 5)
		advice += list(list("title" = "Patient Critical", "text" = "Administer one dose of inaprovaline."))
	var/shock_number = H.traumatic_shock
	if(shock_number > 30)
		var/painlevel = "Significant"
		var/tramadol = ""
		var/oxycodone = ""
		var/oxy_recommend = "N/A"
		var/trama_recommend = "N/A"
		if (reagents_in_body[/datum/reagent/medicine/tramadol] < 3)
			if(paracetamol_amount)
				trama_recommend = "Tramadol recommended, but conflicting paracetamol present."
			else
				tramadol = "tramadol"
		if (reagents_in_body[/datum/reagent/medicine/oxycodone] < 3)
			oxycodone = "oxycodone"
		if(shock_number > 120)
			painlevel = "Extreme"
			if(oxycodone)
				oxy_recommend = "Oxycodone recommended."
		advice += list(list("title" = "[painlevel] Pain", "text" = "Administer one dose of: [tramadol] | [oxycodone]. Addendum: [oxy_recommend] | [trama_recommend]."))
	scan["advice"] = advice

	var/list/contraindications = list()
	if(synaptizine_amount)
		contraindications += list(list("title" = "Synaptizine Detected", "text" = "DO NOT administer dylovene until synaptizine is purged or metabolized."))
	if(paracetamol_amount)
		contraindications += list(list("title" = "Paracetamol Detected", "text" = "DO NOT administer tramadol until paracetamol is purged or metabolized."))
	if(neurotoxin_amount)
		contraindications += list(list("title" = "Xenomorph Neurotoxin Detected", "text" = "Administer hypervene to purge."))
	if(growthtoxin_amount)
		contraindications += list(list("title" = "Xenomorph Growth Toxin Detected", "text" = "Administer hypervene to purge."))
	scan["contraindications"] = contraindications
	return scan

///Turns scan results into the chat message used when the scanner is not in hud mode
/obj/item/healthanalyzer/proc/scan_to_text(list/scan)
	var/list/damage = scan["damage"]
	var/list/damage_text = list()
	for(var/amount in damage)
		damage_text += amount > 50 ? "<b>[amount]</b>" : "[amount]"
	var/dat = "\nHealth Analyzer results for [scan["patient"]]:\n\tOverall Status: [scan["dead"] ? "<b>DEAD</b>" : "<b>[scan["health"]]% healthy</b>"]\n"
	dat += "\tType:    <span class='notice'>Oxygen</font>-<font color='green'>Toxin</font>-<font color='#FFA500'>Burns</font>-<font color='red'>Brute</span>\n"
	dat += "\tDamage: \t<span class='notice'>[damage_text[1]]</font> - <font color='green'>[damage_text[2]]</font> - <font color='#FFA500'>[damage_text[3]]</font> - <font color='red'>[damage_text[4]]</span>\n"
	dat += "\tUntreated: {B}=Burns,{T}=Trauma,{F}=Fracture,{I}=Infection\n"

	for(var/list/limb as anything in scan["limbs"])
		if(limb["missing"])
			dat += "\t\t [limb["name"]]: <span class='scannerb'>Missing!</span>\n"
			continue
		dat += "\t\t [limb["name"]]: \t "
		dat += limb["burn"] > 0 ? "<span class='scannerburnb'> [limb["burn"]]</span>" : "<span class='scannerburn'>0</span>"
		dat += "[limb["untreated_burn"] ? "{B}" : ""] - "
		dat += limb["brute"] > 0 ? "<span class='scannerb'> [limb["brute"]]</span>" : "<span class='scanner'>0</span>"
		dat += "[limb["untreated_brute"] ? "{T}" : ""] [limb["fracture"] ? "{F}" : ""][limb["infection"] ? "{I}" : ""]"
		dat += "[limb["bleeding"] ? "<span class='scannerb'>(Bleeding)</span>" : ""][limb["necrotizing"] ? "<span class='scannerb'>(Necrotizing)</span>" : ""]"
		dat += "[limb["incision"] ? " <span class='scanner'>Open surgical incision</span>" : ""][limb["advice"] ? " [limb["advice"]]" : ""]"
		if(limb["splinted"])
			dat += "(Splinted)"
		else if(limb["stabilized"])
			dat += "(Stabilized)"
		dat += "\n"

	for(var/warning in scan["warnings"])
		dat += "\t<span class='scanner'> *[warning]</span>\n"

	var/list/reagents = scan["reagents"]
	if(length(reagents))
		dat += "\n\tBeneficial reagents:\n"
		for(var/list/reagent as anything in reagents)
			dat += "\t\t [reagent["od"] ? "<span class='warning'><b>OD: </b></span> " : ""]<font color='#9773C4'><b>[reagent["amount"]]u [reagent["name"]]</b></font>\n"
	if(scan["unknown_reagents"])
		dat += "\t<span class='scanner'> Warning: Unknown substance[(scan["unknown_reagents"] > 1) ? "s" : ""] detected in subject's blood.</span>\n"

	dat += "\n\tBody Temperature: [scan["temperature"][1]]&deg;C ([scan["temperature"][2]]&deg;F)\n"
	var/list/blood = scan["blood"]
	if(blood)
		if(blood["status"] == "normal")
			dat += "\tBlood Level normal: [blood["percent"]]% [blood["volume"]]cl. Type: [blood["type"]]\n"
		else
			dat += "\t<span class='scanner'> <b>Warning: Blood Level [blood["status"]]: [blood["percent"]]% [blood["volume"]]cl.</span><font color='blue;'> Type: [blood["type"]]</font>\n"
	var/list/pulse = scan["pulse"]
	if(pulse)
		dat += "\tPulse: <font color='[pulse["bad"] ? "red" : ""]'>[pulse["bpm"]] bpm.</font>\n"

	var/list/advice = scan["advice"]
	if(length(advice))
		dat += "\t<span class='scanner'> <b>Medication Advice:</b></span>\n"
		for(var/list/entry as anything in advice)
			dat += "<span class='scanner'><b>[entry["title"]]:</b> [entry["text"]]</span>\n"
	var/list/contraindications = scan["contraindications"]
	if(length(contraindications))
		dat += "\t<span class='scanner'> <b>Contraindications:</b></span>\n"
		for(var/list/entry as anything in contraindications)
			dat += "<span class='scanner'><b>[entry["title"]]:</b> [entry["text"]]</span>\n"
	return dat

/obj/item/healthanalyzer/ui_state(mob/user)
	return GLOB.always_state

/obj/item/healthanalyzer/ui_interact(mob/user, datum/tgui/ui)
	if(!last_scan)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HealthAnalyzer")
		ui.open()

/obj/item/healthanalyzer/ui_data(mob/user)
	return last_scan

/obj/item/healthanalyzer/verb/toggle_mode()
	set name = "Switch Verbosity"
	set category = "Object"
	mode = !mode
	switch (mode)
		if(1)
			to_chat(usr, "The scanner now shows specific limb damage.")
		if(0)
			to_chat(usr, "The scanner no longer shows limb damage.")

/obj/item/healthanalyzer/verb/toggle_hud_mode()
	set name = "Switch Hud"
	set category = "Object"
	hud_mode = !hud_mode
	switch (hud_mode)
		if(1)
			to_chat(usr, "The scanner now shows results on the hud.")
		if(0)
			to_chat(usr, "The scanner no longer shows results on the hud.")

/obj/item/healthanalyzer/integrated
	name = "\improper HF2 integrated health analyzer"
	desc = "A body scanner able to distinguish vital signs of the subject. This model has been integrated into another object, and is simpler to use."
	skill_threshold = SKILL_MEDICAL_UNTRAINED

/obj/item/analyzer
	desc = "A hand-held environmental scanner which reports current gas levels."
	name = "analyzer"
	icon_state = "atmos"
	item_state = "analyzer"
	w_class = WEIGHT_CLASS_SMALL
	flags_atom = CONDUCT
	flags_equip_slot = ITEM_SLOT_BELT
	throwforce = 5
	throw_speed = 4
	throw_range = 20


/obj/item/analyzer/attack_self(mob/user as mob)
	..()
	var/turf/T = get_turf(user)
	if(!T)
		return

	playsound(src, 'sound/effects/pop.ogg', 100)
	var/area/user_area = T.loc
	var/datum/weather/ongoing_weather = null

	if(!user_area.outside)
		to_chat(user, "<span class='warning'>[src]'s barometer function won't work indoors!</span>")
		return

	for(var/V in SSweather.processing)
		var/datum/weather/W = V
		if(W.barometer_predictable && (T.z in W.impacted_z_levels) && W.area_type == user_area.type && !(W.stage == END_STAGE))
			ongoing_weather = W
			break

	if(ongoing_weather)
		if((ongoing_weather.stage == MAIN_STAGE) || (ongoing_weather.stage == WIND_DOWN_STAGE))
			to_chat(user, "<span class='warning'>[src]'s barometer function can't trace anything while the storm is [ongoing_weather.stage == MAIN_STAGE ? "already here!" : "winding down."]</span>")
			return

		to_chat(user, "<span class='notice'>The next [ongoing_weather] will hit in [(ongoing_weather.next_hit_time - world.time)/10] Seconds.</span>")
		if(ongoing_weather.aesthetic)
			to_chat(user, "<span class='warning'>[src]'s barometer function says that the next storm will breeze on by.</span>")
	else
		var/next_hit = SSweather.next_hit_by_zlevel["[T.z]"]
		var/fixed = next_hit ? timeleft(next_hit) : -1
		if(fixed < 0)
			to_chat(user, "<span class='warning'>[src]'s barometer function was unable to trace any weather patterns.</span>")
		else
			to_chat(user, "<span class='warning'>[src]'s barometer function says a storm will land in approximately [fixed/10] Seconds].</span>")

/obj/item/mass_spectrometer
	desc = "A hand-held mass spectrometer which identifies trace chemicals in a blood sample."
	name = "mass-spectrometer"
	icon_state = "spectrometer"
	item_state = "analyzer"
	w_class = WEIGHT_CLASS_SMALL
	flags_atom = CONDUCT
	flags_equip_slot = ITEM_SLOT_BELT
	throwforce = 5
	throw_speed = 4
	throw_range = 20

	var/details = 0
	var/recent_fail = 0

/obj/item/mass_spectrometer/Initialize(mapload)
	. = ..()
	create_reagents(5, OPENCONTAINER)

/obj/item/mass_spectrometer/on_reagent_change()
	if(reagents.total_volume)
		icon_state = initial(icon_state) + "_s"
	else
		icon_state = initial(icon_state)

/obj/item/mass_spectrometer/attack_self(mob/user as mob)
	if (user.stat)
		return
	if (crit_fail)
		to_chat(user, "<span class='warning'>This device has critically failed and is no longer functional!</span>")
		return
	if(reagents.total_volume)
		var/list/blood_traces = list()
		for(var/datum/reagent/R in reagents.reagent_list)
			if(R.type != /datum/reagent/blood)
				reagents.clear_reagents()
				to_chat(user, "<span class='warning'>The sample was contaminated! Please insert another sample</span>")
				return
			else
				blood_traces = params2list(R.data["trace_chem"])
				break
		var/dat = "Trace Chemicals Found: "
		for(var/R in blood_traces)
			if(prob(reliability))
				if(details)
					dat += "[R] ([blood_traces[R]] units) "
				else
					dat += "[R] "
				recent_fail = 0
			else
				if(recent_fail)
					crit_fail = 1
					reagents.clear_reagents()
					return
				else
					recent_fail = 1
		to_chat(user, "[dat]")
		reagents.clear_reagents()
	return


/obj/item/mass_spectrometer/adv
	name = "advanced mass-spectrometer"
	icon_state = "adv_spectrometer"
	details = 1


/obj/item/reagent_scanner
	name = "reagent scanner"
	desc = "A hand-held reagent scanner which identifies chemical agents."
	icon_state = "spectrometer"
	item_state = "analyzer"
	w_class = WEIGHT_CLASS_SMALL
	flags_atom = CONDUCT
	flags_equip_slot = ITEM_SLOT_BELT
	throwforce = 5
	throw_speed = 4
	throw_range = 20

	var/details = 0
	var/recent_fail = 0

/obj/item/reagent_scanner/afterattack(obj/O, mob/user as mob, proximity)
	if(!proximity)
		return
	if (user.stat)
		return
	if(!istype(O))
		return
	if (crit_fail)
		to_chat(user, "<span class='warning'>This device has critically failed and is no longer functional!</span>")
		return

	if(!isnull(O.reagents))
		var/dat = ""
		if(O.reagents.reagent_list.len > 0)
			var/one_percent = O.reagents.total_volume / 100
			for (var/datum/reagent/R in O.reagents.reagent_list)
				if(prob(reliability))
					dat += "\n \t <span class='notice'> [R][details ? ": [R.volume / one_percent]%" : ""]</span>"
					recent_fail = 0
				else if(recent_fail)
					crit_fail = 1
					dat = null
					break
				else
					recent_fail = 1
		if(dat)
			to_chat(user, "<span class='notice'>Chemicals found: [dat]</span>")
		else
			to_chat(user, "<span class='notice'>No active chemical agents found in [O].</span>")
	else
		to_chat(user, "<span class='notice'>No significant chemical agents found in [O].</span>")

	return

/obj/item/reagent_scanner/adv
	name = "advanced reagent scanner"
	icon_state = "adv_spectrometer"
	details = 1
