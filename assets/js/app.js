// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import 'phoenix_html';
import {Socket} from 'phoenix';
import LiveSocket from 'phoenix_live_view';

// Resize viewport units based on innerHeight rather than max height of the browser
window.onresize = () => {
  let vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty('--vh', `${vh}px`);
};
window.onresize();

// Functions for inviting friends via sms
var isIosDevice = () => {
  var ua = navigator.userAgent.toLowerCase();
  return ua.indexOf('iphone') > -1 || ua.indexOf('ipad') > -1;
};

var smsLink = message => {
  var msg = encodeURIComponent(message),
    href;
  return isIosDevice ? 'sms:&body=' + msg : 'sms:?body=' + msg;
};

window.openSmsInvite = joinCode => {
  var message = `Come play Level 10 with me!\nhttps://level10.games/join/${joinCode}`;
  location.href = smsLink(message);
};

// Set up the LiveView
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
