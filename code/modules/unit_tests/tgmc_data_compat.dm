///Checks that this codebase reads and writes a TGMC community's database the way modern TGMC does
/datum/unit_test/tgmc_data_compat/Run()
	// Admin permission bits as modern TGMC stores them in admin_ranks
	if(R_RUNTIME != 16384 || R_LOG != 32768 || R_POLLS != 65536)
		Fail("RUNTIME/LOG/POLLS bits are [R_RUNTIME]/[R_LOG]/[R_POLLS], TGMC uses 16384/32768/65536")
	if(R_EVERYTHING != 16777215)
		Fail("R_EVERYTHING is [R_EVERYTHING], TGMC stores EVERYTHING as 16777215")

	// Rank keywords from TGMC's admin_ranks.txt
	var/datum/admin_rank/rank = new("tgmc_data_compat test rank")
	rank.process_keyword("ADMIN RUNTIME LOG POLLS", 1)
	if(rank.rights != (R_ADMIN|R_RUNTIME|R_LOG|R_POLLS))
		Fail("rank keywords gave rights [rank.rights], expected [R_ADMIN|R_RUNTIME|R_LOG|R_POLLS]")
	var/text = rights2text(rank.rights, " ")
	for(var/keyword in list("+ADMIN", "+RUNTIME", "+LOG", "+POLLS"))
		if(!findtext(text, keyword))
			Fail("rights2text([rank.rights]) is '[text]', missing [keyword]")
	var/datum/admin_rank/everything = new("tgmc_data_compat everything rank", 16777215)
	if(everything.rights != R_EVERYTHING)
		Fail("a TGMC EVERYTHING rank (16777215) does not equal R_EVERYTHING")

	// Job titles in bans and playtime
	if(job_title_to_db(MEDICAL_OFFICER) != "Medical Doctor" || job_title_from_db("Medical Doctor") != MEDICAL_OFFICER)
		Fail("Medical Officer is not stored as TGMC's Medical Doctor")
	if(job_title_to_db(SQUAD_MARINE) != SQUAD_MARINE || job_title_from_db(SQUAD_MARINE) != SQUAD_MARINE)
		Fail("job titles without a TGMC name changed in the database")

	// Hive Status closes for anyone who isn't a xeno, a ghost or an admin
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	if(GLOB.hive_ui_state.can_use_topic(null, human) != UI_CLOSE)
		Fail("a human can keep the Hive Status window open")
