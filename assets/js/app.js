import 'phoenix_html';
import {Socket} from 'phoenix';
import {LiveSocket} from 'phoenix_live_view';
import Alpine from 'alpinejs';
import persist from '@alpinejs/persist';

Alpine.plugin(persist);
window.Alpine = Alpine;
Alpine.start();

const FLASH_TTL = 8000;
const Hooks = {};

Hooks.Flash = {
  mounted() {
    this.timer = setTimeout(() => this._hide(), FLASH_TTL);

    this.el.addEventListener('mouseover', () => {
      clearTimeout(this.timer);
      this.timer = setTimeout(() => this._hide(), FLASH_TTL);
    });
  },

  destroyed() {
    clearTimeout(this.timer);
  },

  _hide() {
    liveSocket.execJS(this.el, this.el.getAttribute('phx-click'));
  }
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

const liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken} // eslint-disable-line camelcase
});

liveSocket.connect();
