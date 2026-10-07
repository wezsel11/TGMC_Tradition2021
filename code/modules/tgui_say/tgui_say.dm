/**
 * TGUI Say, as modern TGMC.
 * A small input window for say, radio, me, OOC and LOOC, replacing the BYOND input popups.
 * Can be turned off in the game preferences, which brings the popups back.
 */

/datum/asset/simple/tgui_say
	keep_local_name = TRUE
	assets = list(
		"tgui-say.bundle.js" = 'tgui/public/tgui-say.bundle.js',
		"tgui-say.bundle.css" = 'tgui/public/tgui-say.bundle.css',
	)

/client
	///The TGUI Say window of this client
	var/datum/tgui_say/tgui_say

/datum/tgui_say
	var/client/client
	var/datum/tgui_window/window

/datum/tgui_say/New(client/client)
	src.client = client
	window = new(client, "tgui_say_browser")
	window.subscribe(src, .proc/on_message)

/datum/tgui_say/Del()
	window.unsubscribe(src)
	return ..()

///Loads the window, it stays hidden until it is opened
/datum/tgui_say/proc/initialize()
	set waitfor = FALSE
	// Defer to after the client constructor, like the tgui panel
	sleep(1)
	window.initialize(inline_assets = list(
		get_asset_datum(/datum/asset/simple/tgui_common),
		get_asset_datum(/datum/asset/simple/tgui_say),
	))
	window.send_message("props", list("maxLength" = MAX_MESSAGE_LEN))

///Opens the window on a channel. Returns FALSE when TGUI Say can't be used, so the old input popup is used instead
/datum/tgui_say/proc/open(channel)
	if(!client?.prefs?.tgui_say || !window.is_ready())
		return FALSE
	if(channel == "Say" || channel == "Radio")
		client.mob?.add_typing_indicator()
	else if(channel == "Me")
		client.mob?.add_typing_indicator(TRUE)
	window.send_message("open", list("channel" = channel))
	return TRUE

/datum/tgui_say/proc/on_message(type, list/payload, list/href_list)
	switch(type)
		if("dismiss")
			client.mob?.remove_typing_indicator()
			return TRUE
		if("entry")
			client.mob?.remove_typing_indicator()
			if(islist(payload))
				handle_entry(payload["channel"], payload["entry"])
			return TRUE

///Sends the message to the verb of its channel
/datum/tgui_say/proc/handle_entry(channel, entry)
	if(!istext(entry) || !client?.mob)
		return
	entry = copytext_char(entry, 1, MAX_MESSAGE_LEN)
	if(!length(entry))
		return
	switch(channel)
		if("Say")
			client.mob.say_verb(entry)
		if("Radio")
			client.mob.say_verb(";[entry]")
		if("Me")
			client.mob.me_verb(entry)
		if("OOC")
			client.ooc(entry)
		if("LOOC")
			client.looc(entry)
