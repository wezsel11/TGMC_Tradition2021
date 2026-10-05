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
    // Center the window on the game window
    Byond.winget('mainwindow', ['pos', 'size']).then(props => {
      const [x, y] = String(props.pos).split(',').map(Number);
      const [width, height] = String(props.size).split('x').map(Number);
      const posX = Math.round(x + width / 2 - 130);
      const posY = Math.round(y + height * 0.6);
      Byond.winset(WINDOW_ID, {
        'pos': `${posX},${posY}`,
        'is-visible': true,
      });
      Byond.winset('tgui_say_browser', { 'focus': true });
      setTimeout(() => this.input.current?.focus(), 10);
    });
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
      <div className={`window ${channelClass}${lightMode ? ' lightMode' : ''}`}>
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
