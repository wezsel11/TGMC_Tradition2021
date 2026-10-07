// Shows the key an action is bound to on its button, as modern TGMC (#11031).

/client
	///Cache of keybind signal -> the first key bound to it, see get_key_for_signal()
	var/list/key_by_keybind_signal

///Returns the first key bound to a keybind signal, or null
/client/proc/get_key_for_signal(signal)
	if(!signal || !prefs)
		return
	if(!key_by_keybind_signal)
		key_by_keybind_signal = list()
		for(var/key in prefs.key_bindings)
			for(var/kb_name in prefs.key_bindings[key])
				var/datum/keybinding/kb = GLOB.keybindings_by_name[kb_name]
				if(!kb?.keybind_signal || key_by_keybind_signal[kb.keybind_signal])
					continue
				key_by_keybind_signal[kb.keybind_signal] = key
	return key_by_keybind_signal[signal]

///Called when the keybinds of this client changed, so action buttons show the new keys
/client/proc/keybinds_changed()
	key_by_keybind_signal = null
	mob?.update_action_buttons()

///Returns the text shown on the action button for the key it is bound to, or null
/datum/action/proc/get_keybind_text()
	return

/datum/action/xeno_action/get_keybind_text()
	return owner?.client?.get_key_for_signal(keybind_signal)

///Updates the key shown on the action button
/datum/action/proc/update_button_keybind_text()
	var/key = get_keybind_text()
	button.maptext = key ? MAPTEXT(key) : null
	button.maptext_width = 32
	button.maptext_x = 2
	button.maptext_y = 2
