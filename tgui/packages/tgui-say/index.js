/**
 * TGUI Say, as modern TGMC.
 * A small input window for say, radio, me, OOC and LOOC that replaces the
 * BYOND input popups.
 */

import './styles/main.scss';

import { Component, createRef, render } from 'inferno';
import { sendMessage } from 'tgui/backend';

const CHANNELS = ['Say', 'Radio', 'Me', 'OOC', 'LOOC'];
const MAX_HISTORY = 5;
const WINDOW_ID = 'tgui_say';

const isValidChannel = channel => CHANNELS.indexOf(channel) !== -1;

// winget gives positions and sizes as {x, y} objects, or as "1,2" / "1x2" text
const parseVector = value => {
  if (value && typeof value === 'object') {
    return [Number(value.x), Number(value.y)];
  }
  return String(value).split(/[,x]/).map(Number);
};

const POSITION_KEY = 'tgui-say-position';

const loadPosition = () => {
  try {
    const pos = JSON.parse(window.localStorage.getItem(POSITION_KEY));
    if (pos && pos.length === 2 && !isNaN(pos[0] + pos[1])) {
      return pos;
    }
  }
  catch (err) {}
  return null;
};

const savePosition = pos => {
  try {
    window.localStorage.setItem(POSITION_KEY, JSON.stringify(pos));
  }
  catch (err) {}
};

class TguiSay extends Component {
  constructor() {
    super();
    this.input = createRef();
    this.history = [];
    this.historyIndex = -1;
    this.state = {
      channel: 'Say',
      value: '',
      maxLength: 1024,
      lightMode: false,
    };
  }

  componentDidMount() {
    window.update = msg => this.onMessage(Byond.parseJson(msg));
    while (window.__updateQueue__.length > 0) {
      this.onMessage(Byond.parseJson(window.__updateQueue__.shift()));
    }
  }

  onMessage(message) {
    const { type, payload = {} } = message;
    if (type === 'props') {
      this.setState({
        maxLength: payload.maxLength || 1024,
        lightMode: !!payload.lightMode,
      });
    }
    if (type === 'open') {
      this.open(payload.channel);
    }
  }

  open(channel) {
    this.historyIndex = -1;
    this.setState({
      channel: isValidChannel(channel) ? channel : 'Say',
      value: '',
    });
    const show = pos => {
      const props = { 'is-visible': true };
      if (pos) {
        this.pos = pos;
        props.pos = `${pos[0]},${pos[1]}`;
      }
      Byond.winset(WINDOW_ID, props);
      Byond.winset('tgui_say_browser', { 'focus': true });
      setTimeout(() => this.input.current?.focus(), 10);
    };
    // Reopen where the player dragged it to
    const saved = loadPosition();
    if (saved) {
      show(saved);
      return;
    }
    // Otherwise center it near the bottom of the map
    Promise.all([
      Byond.winget('mainwindow', ['pos', 'size', 'is-maximized']),
      Byond.winget('mapwindow.map', 'size'),
    ]).then(([main, mapSize]) => {
      const ratio = window.devicePixelRatio || 1;
      let [x, y] = parseVector(main.pos);
      let [width, height] = parseVector(main.size);
      // The pos of a maximized window is where it goes when restored
      if (main['is-maximized'] === true || main['is-maximized'] === 'true') {
        x = 0;
        y = 0;
        width = window.screen.availWidth * ratio;
        height = window.screen.availHeight * ratio;
      }
      const [mapWidth, mapHeight] = parseVector(mapSize);
      if (mapWidth > 0 && mapHeight > 0) {
        width = Math.min(width, mapWidth);
        height = Math.min(height, mapHeight);
      }
      if (isNaN(x + y + width + height)) {
        show();
        return;
      }
      show([
        Math.round(x + width / 2 - 130 * ratio),
        Math.round(y + height * 0.85),
      ]);
    }, () => show());
  }

  // Dragging the window by its edge
  onMouseDown(event) {
    const tag = event.target.tagName;
    if (event.button !== 0 || tag === 'INPUT' || tag === 'BUTTON' || !this.pos) {
      return;
    }
    event.preventDefault();
    const ratio = window.devicePixelRatio || 1;
    const startX = event.screenX;
    const startY = event.screenY;
    const [posX, posY] = this.pos;
    const onMove = e => {
      const pos = [
        Math.round(posX + (e.screenX - startX) * ratio),
        Math.round(posY + (e.screenY - startY) * ratio),
      ];
      this.pos = pos;
      Byond.winset(WINDOW_ID, { pos: `${pos[0]},${pos[1]}` });
    };
    const onUp = () => {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
      savePosition(this.pos);
      this.input.current?.focus();
    };
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  }

  close() {
    Byond.winset(WINDOW_ID, { 'is-visible': false });
    Byond.winset('mapwindow.map', { 'focus': true });
    this.setState({ value: '' });
  }

  dismiss() {
    sendMessage({ type: 'dismiss' });
    this.close();
  }

  submit() {
    const { channel, value } = this.state;
    const entry = value.trim();
    if (entry.length) {
      this.history = [entry, ...this.history.filter(old => old !== entry)]
        .slice(0, MAX_HISTORY);
      sendMessage({
        type: 'entry',
        payload: { channel, entry },
      });
    }
    else {
      sendMessage({ type: 'dismiss' });
    }
    this.close();
  }

  cycleChannel(direction) {
    const index = CHANNELS.indexOf(this.state.channel);
    const next = (index + direction + CHANNELS.length) % CHANNELS.length;
    this.setState({ channel: CHANNELS[next] });
  }

  browseHistory(direction) {
    if (!this.history.length) {
      return;
    }
    const index = Math.min(Math.max(this.historyIndex + direction, -1),
      this.history.length - 1);
    this.historyIndex = index;
    this.setState({ value: index === -1 ? '' : this.history[index] });
  }

  onKeyDown(event) {
    switch (event.keyCode) {
      case 13: // Enter
        event.preventDefault();
        this.submit();
        break;
      case 27: // Escape
        event.preventDefault();
        this.dismiss();
        break;
      case 9: // Tab
        event.preventDefault();
        this.cycleChannel(event.shiftKey ? -1 : 1);
        break;
      case 38: // Up
        event.preventDefault();
        this.browseHistory(1);
        break;
      case 40: // Down
        event.preventDefault();
        this.browseHistory(-1);
        break;
    }
  }

  render() {
    const { channel, value, maxLength, lightMode } = this.state;
    const channelClass = `channel-${channel.toLowerCase()}`;
    return (
      <div
        className={`window ${channelClass}${lightMode ? ' lightMode' : ''}`}
        onMouseDown={e => this.onMouseDown(e)}>
        <button
          className="button"
          type="button"
          title="Tab to change the channel"
          onClick={() => this.cycleChannel(1)}>
          {channel}
        </button>
        <input
          ref={this.input}
          className="textarea"
          maxLength={maxLength}
          value={value}
          spellcheck={false}
          onInput={e => this.setState({ value: e.target.value })}
          onKeyDown={e => this.onKeyDown(e)} />
      </div>
    );
  }
}

const setupApp = () => {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupApp);
    return;
  }
  const root = document.getElementById('react-root');
  render(<TguiSay />, root);
};

setupApp();
