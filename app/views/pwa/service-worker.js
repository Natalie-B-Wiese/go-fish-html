// https://blog.codeminer42.com/everything-you-need-to-ace-pwas/

const OFFLINE_ROUTE='/offline'

const CACHE_VERSION='v5';
const OFFLINE_CACHE_NAME='offline'+CACHE_VERSION;

const CACHE_NAME = 'main'+CACHE_VERSION;

self.addEventListener("install", (event) => {   
  event.waitUntil(
    caches.open(OFFLINE_CACHE_NAME)
      .then((cache) => cache.addAll([
        OFFLINE_ROUTE,
        "/assets/core/theme/student4-theme-core-9a6d929a.css"
      ]))
      .then(() => self.skipWaiting())
  );
});

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await caches.match(request);

  if (cachedResponse) {
    return cachedResponse;
  }

  // Next try to get the resource from the network
  try {
    const responseFromNetwork = await fetch(request.clone());

    cache.put(request, responseFromNetwork.clone());

    return responseFromNetwork;
  } catch (error) {
    return new Response('Network error happened', {
      status: 408,
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

self.addEventListener("fetch", (event) => {
  //event.respondWith(cacheFirst(event.request))
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Network request succeeded: the user is online
        return response;
      })
      .catch((error) => {
        // Network request failed: the user is offline or the server is down
        console.log("Fetch failed; returning offline cache fallback instead.", error);
        
        // Fallback to offline cache asset
        return caches.open(OFFLINE_CACHE_NAME)
          .then(cache => cache.match(OFFLINE_ROUTE));
      })
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((key) => !key.endsWith(CACHE_VERSION)).map((key) => caches.delete(key))
        )
      )
      .then(() => self.clients.claim())
  )
})