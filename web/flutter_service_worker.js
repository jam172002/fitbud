// Custom Flutter service worker that skips caching.
// This prevents the stale-cache blank-screen issue in Replit's dev environment.
// On install, skip waiting immediately so this worker activates right away.
self.addEventListener('install', function(event) {
  self.skipWaiting();
});

// On activate, delete ALL old caches and claim every open client immediately.
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(cacheNames.map(function(name) {
        return caches.delete(name);
      }));
    }).then(function() {
      return self.clients.claim();
    })
  );
});

// Pass every request straight through to the network — no caching at all.
self.addEventListener('fetch', function(event) {
  event.respondWith(fetch(event.request));
});
