importScripts("./scram/scramjet.all.js");

const { ScramjetServiceWorker } = $scramjetLoadWorker();
const scramjet = new ScramjetServiceWorker();

async function handleRequest(event) {
	// If Scramjet's stored data is broken, never take the whole site down:
	// fall back to a normal network request so the page can still load and repair itself.
	try {
		await scramjet.loadConfig();
	} catch (e) {
		console.error("Scramjet config failed, falling back to network:", e);
		return fetch(event.request);
	}
	try {
		if (scramjet.route(event)) {
			return await scramjet.fetch(event);
		}
	} catch (e) {
		console.error("Scramjet fetch failed:", e);
		return new Response("Proxy error: " + e, { status: 502 });
	}
	return fetch(event.request);
}

self.addEventListener("fetch", (event) => {
	event.respondWith(handleRequest(event));
});

