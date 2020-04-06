import css from '../css/app.css';
import 'phoenix_html';

import {Socket} from 'phoenix';
import LiveSocket from 'phoenix_live_view';

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

let Hooks = {};

Hooks.NameInput = {
  mounted() {
    this.el.focus();
  },
};

let liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken},
});
liveSocket.connect();
