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

Hooks.ManualSlotDragSelector = {
  mounted() {
    this.dragging = false;
    this.startIndex = null;
    this.endIndex = null;
    this.selectEvent = this.el.dataset.selectEvent || 'manual_drag_select';

    this.onMouseDown = event => {
      if (event.button !== 0) return;
      const index = this._slotIndexFromEvent(event);
      if (index === null) return;
      event.preventDefault();

      this.dragging = true;
      this.startIndex = index;
      this.endIndex = index;
      this._renderPreview();
    };

    this.onMouseOver = event => {
      if (!this.dragging) return;
      const index = this._slotIndexFromEvent(event);
      if (index === null) return;

      this.endIndex = index;
      this._renderPreview();
    };

    this.onWindowMouseUp = () => {
      if (!this.dragging) return;
      this.dragging = false;

      if (this.startIndex === null || this.endIndex === null) {
        this._clearPreview();
        return;
      }

      const start = Math.min(this.startIndex, this.endIndex);
      const end = Math.max(this.startIndex, this.endIndex) + 1;

      this.pushEvent(this.selectEvent, {
        start_index: String(start), // eslint-disable-line camelcase
        end_index: String(end) // eslint-disable-line camelcase
      });

      this.startIndex = null;
      this.endIndex = null;
      this._clearPreview();
    };

    this.el.addEventListener('mousedown', this.onMouseDown);
    this.el.addEventListener('mouseover', this.onMouseOver);
    window.addEventListener('mouseup', this.onWindowMouseUp);
  },

  updated() {
    this.dragging = false;
    this.startIndex = null;
    this.endIndex = null;
    this._clearPreview();
  },

  destroyed() {
    this.el.removeEventListener('mousedown', this.onMouseDown);
    this.el.removeEventListener('mouseover', this.onMouseOver);
    window.removeEventListener('mouseup', this.onWindowMouseUp);
    this._clearPreview();
  },

  _slotIndexFromEvent(event) {
    const target = event.target.closest('[data-slot-index]');
    if (!target) return null;
    const rawValue = target.dataset.slotIndex;
    const parsed = Number.parseInt(rawValue, 10);
    return Number.isNaN(parsed) ? null : parsed;
  },

  _clearPreview() {
    this.el
      .querySelectorAll('[data-slot-index].manual-drag-preview')
      .forEach(node => node.classList.remove('manual-drag-preview'));
  },

  _renderPreview() {
    this._clearPreview();
    if (this.startIndex === null || this.endIndex === null) return;

    const start = Math.min(this.startIndex, this.endIndex);
    const end = Math.max(this.startIndex, this.endIndex);

    this.el.querySelectorAll('[data-slot-index]').forEach(node => {
      const parsed = Number.parseInt(node.dataset.slotIndex, 10);
      if (!Number.isNaN(parsed) && parsed >= start && parsed <= end) {
        node.classList.add('manual-drag-preview');
      }
    });
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
