// Compatibility layer for the stat panel.
// The stat panel is written against the modern tgui Byond API
// (Byond.windowId, Byond.sendMessage, Byond.subscribeTo), which the
// tgui.html of this codebase does not have yet. This adds just those.
(function () {
	var listeners = [];

	Byond.windowId = window.__windowId__;

	Byond.sendMessage = function (type, payload) {
		var message = typeof type === 'string'
			? { type: type, payload: payload }
			: type;
		if (message.payload !== null && message.payload !== undefined) {
			message.payload = JSON.stringify(message.payload);
		}
		message.tgui = 1;
		message.window_id = Byond.windowId;
		Byond.topic(message);
	};

	Byond.subscribeTo = function (type, listener) {
		listeners.push(function (_type, payload) {
			if (_type === type) {
				listener(payload);
			}
		});
	};

	var dispatch = function (rawMessage) {
		var message = Byond.parseJson(rawMessage);
		for (var i = 0; i < listeners.length; i++) {
			listeners[i](message.type, message.payload);
		}
	};

	// Take over message delivery, and replay anything that arrived early
	// once the stat panel has registered its listeners.
	window.update = dispatch;
	setTimeout(function () {
		var queue = window.__updateQueue__ || [];
		window.__updateQueue__ = [];
		for (var i = 0; i < queue.length; i++) {
			dispatch(queue[i]);
		}
	}, 0);
})();
