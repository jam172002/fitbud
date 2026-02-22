// Custom Flutter service worker — development mode.
// Goal: zero caching. Every request goes straight to the network so that
// hot-restarts always serve fresh JS files and never show a blank screen.

self.addEventListener('install', function (event) {
  // Activate this worker immediately without waiting for old one to finish.
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  // Delete all old caches and take control of all open pages immediately.
  event.waitUntil(
    caches.keys()
      .then(function (names) {
        return Promise.all(names.map(function (n) { return caches.delete(n); }));
      })
      .then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (event) {
  // Pass every request to the network with cache: 'reload' so the browser's
  // own HTTP cache is also bypassed — prevents stale .dart.js files after
  // a hot-restart that changed file hashes.
  event.respondWith(
    fetch(event.request, { cache: 'reload' }).catch(function () {
      // If the network is unreachable, fall back to a regular fetch
      // (which may hit browser cache) rather than showing an error.
      return fetch(event.request);
    })
  );
});
