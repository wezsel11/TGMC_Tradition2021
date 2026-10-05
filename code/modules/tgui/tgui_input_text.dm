/**
 * Creates a TGUI window with a text input and returns the user's response, as modern TGMC.
 *
 * Behaves like `input() as text|null` (or `as message|null` when multiline): the text is returned
 * as typed, and null is returned when the user cancels or closes the window.
 * Falls back to the BYOND input box when the user disabled TGUI input boxes in their preferences.
 * Arguments:
 * * user - The user to show the input box to.
 * * message - The content of the input box, shown in the body of the TGUI window.
 * * title - The title of the input box, shown on the top of the TGUI window.
 * * default - The default (or current) value, shown as a placeholder.
 * * max_length - Specifies a max length for input. 0 is no limit.
 * * multiline - Bool that determines if the input box is much larger. Good for large messages, laws, etc.
 * * timeout - The timeout of the textbox, after which the modal will close and qdel itself. Set to zero for no timeout.
 */
/proc/tgui_input_text(mob/user, message = "", title = "Text Input", default, max_length = 0, multiline = FALSE, timeout = 0)
	if(!user)
		user = usr
	if(!istype(user))
		if(istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			return
	if(!user.client?.prefs?.tgui_input)
		if(multiline)
			return input(user, message, title, default) as message|null
		return input(user, message, title, default) as text|null
	var/datum/tgui_input_text/text_input = new(user, message, title, default, max_length, multiline, timeout)
	text_input.ui_interact(user)
	text_input.wait()
	if(text_input)
		. = text_input.entry
		qdel(text_input)

/**
 * Creates a TGUI window with a number input and returns the user's response, as modern TGMC.
 *
 * Behaves like `input() as num|null`: null is returned when the user cancels or closes the window.
 * Falls back to the BYOND input box when the user disabled TGUI input boxes in their preferences.
 * Arguments:
 * * user - The user to show the number input to.
 * * message - The content of the number input, shown in the body of the TGUI window.
 * * title - The title of the number input modal, shown on the top of the TGUI window.
 * * default - The default (or current) value, shown as a placeholder.
 * * max_value - Specifies a maximum value. Null for no maximum.
 * * min_value - Specifies a minimum value. Null for no minimum.
 * * timeout - The timeout of the number input, after which the modal will close and qdel itself. Set to zero for no timeout.
 */
/proc/tgui_input_number(mob/user, message = "", title = "Number Input", default, max_value, min_value, timeout = 0)
	if(!user)
		user = usr
	if(!istype(user))
		if(istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			return
	if(!user.client?.prefs?.tgui_input)
		return input(user, message, title, default) as num|null
	var/datum/tgui_input_text/number/number_input = new(user, message, title, default, max_value, min_value, timeout)
	number_input.ui_interact(user)
	number_input.wait()
	if(number_input)
		. = number_input.entry
		qdel(number_input)

/**
 * # tgui_input_text
 *
 * Datum used for instantiating and using a TGUI-controlled text input that prompts the user with
 * a message and has an input for text entry.
 */
/datum/tgui_input_text
	/// The title of the TGUI window
	var/title
	/// The textual body of the TGUI window
	var/message
	/// The default (or current) value, shown as a default.
	var/default
	/// The entry that the user has returned, null if no response has been made
	var/entry
	/// The maximum length for text entry
	var/max_length
	/// Multiline input for larger input boxes.
	var/multiline
	/// The time at which the text input was created, for displaying timeout progress.
	var/start_time
	/// The lifespan of the text input, after which the window will close and delete itself.
	var/timeout
	/// Boolean field describing if the text input was closed by the user.
	var/closed

/datum/tgui_input_text/New(mob/user, message, title, default, max_length, multiline, timeout)
	src.title = title
	src.message = message
	src.default = default
	src.max_length = max_length
	src.multiline = multiline
	if(timeout)
		src.timeout = timeout
		start_time = world.time
		QDEL_IN(src, timeout)

/datum/tgui_input_text/Destroy(force, ...)
	SStgui.close_uis(src)
	return ..()

/**
 * Waits for a user's response to the text input's prompt before returning. Returns early if
 * the window was closed by the user.
 */
/datum/tgui_input_text/proc/wait()
	while(!entry && !closed && !QDELETED(src))
		stoplag(1)

/datum/tgui_input_text/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TextInputModal")
		ui.open()

/datum/tgui_input_text/ui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/tgui_input_text/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_input_text/ui_static_data(mob/user)
	. = list(
		"max_length" = max_length,
		"message" = message,
		"multiline" = multiline,
		"placeholder" = default,
		"title" = title,
	)

/datum/tgui_input_text/ui_data(mob/user)
	. = list()
	if(timeout)
		.["timeout"] = clamp((timeout - (world.time - start_time) - 1 SECONDS) / (timeout - 1 SECONDS), 0, 1)

/datum/tgui_input_text/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("submit")
			var/text = params["entry"]
			if(!istext(text))
				return
			if(max_length && length(text) > max_length)
				text = copytext(text, 1, max_length + 1)
			entry = text
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE
		if("cancel")
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE

/**
 * # tgui_input_text/number
 *
 * The number variant of the text input.
 */
/datum/tgui_input_text/number
	/// The maximum value, null for no maximum
	var/max_value
	/// The minimum value, null for no minimum
	var/min_value

/datum/tgui_input_text/number/New(mob/user, message, title, default, max_value, min_value, timeout)
	..(user, message, title, default, 0, FALSE, timeout)
	src.max_value = max_value
	src.min_value = min_value

/datum/tgui_input_text/number/wait()
	while(isnull(entry) && !closed && !QDELETED(src))
		stoplag(1)

/datum/tgui_input_text/number/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NumberInputModal")
		ui.open()

/datum/tgui_input_text/number/ui_static_data(mob/user)
	. = list(
		"max_value" = max_value,
		"message" = message,
		"min_value" = min_value,
		"placeholder" = default,
		"title" = title,
	)

/datum/tgui_input_text/number/ui_act(action, list/params)
	if(action != "submit")
		return ..()
	if(closed)
		return
	var/number = text2num("[params["entry"]]")
	if(!isnum(number))
		return
	if(!isnull(max_value))
		number = min(number, max_value)
	if(!isnull(min_value))
		number = max(number, min_value)
	entry = number
	closed = TRUE
	SStgui.close_uis(src)
	return TRUE
