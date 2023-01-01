import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

// Resize viewport units based on innerHeight rather than max height of the browser
window.onresize = () => {
  let vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty("--vh", `${vh}px`);
};
window.onresize();

// Functions for inviting friends via sms
var isIosDevice = () => {
  var ua = navigator.userAgent.toLowerCase();
  return ua.indexOf("iphone") > -1 || ua.indexOf("ipad") > -1;
};

var smsLink = (message) => {
  var msg = encodeURIComponent(message);
  return isIosDevice ? "sms:&body=" + msg : "sms:?body=" + msg;
};

window.addEventListener('phx:update-theme-color', e =>
  document.querySelector('meta[name="theme-color"]').setAttribute('content', e.detail.color)
);

window.openSmsInvite = (joinCode) => {
  const { hostname, protocol } = window.location;
  var message = `Come play Level 10 with me!\n${protocol}//${hostname}/join/${joinCode}`;
  location.href = smsLink(message);
};

// Set up the LiveView
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};

Hooks.SelectOnMount = {
  mounted() {
    this.el.select();
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (!window.Alpine || from.nodeType !== 1) return;
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});
// liveSocket.enableDebug()
liveSocket.connect();
