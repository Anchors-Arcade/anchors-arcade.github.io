// Settings for your hosted copy
const WISP_URL = "wss://anura.pro/wisp/";

// Ping the wisp host as soon as the page opens, so it is (mostly)
// awake by the time you press Enter. Harmless if it is already running.
try {
	fetch(WISP_URL.replace("wss://", "https://").replace(/\/wisp\/?$/, "/"), {
		mode: "no-cors",
	}).catch(() => {});
} catch (e) {}

// The site that should load automatically through the proxy.
const SITE_URL = "https://anchors-arcade.github.io/VX/index.html";
