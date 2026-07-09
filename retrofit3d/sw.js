/* Retrofit Factory 3D — service worker.
   The game is a single self-contained HTML file + a few PWA assets, so the whole
   app precaches on install and runs fully offline. Strategy: network-first (so a
   new deploy is picked up when online) with a cache fallback (so it works with no
   connection). Bump CACHE on each release to evict the old shell. */
const CACHE = 'rf3d-v2';
const SHELL = [
  'retrofit-factory-3d.html',
  'manifest.webmanifest',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/icon-512-maskable.png'
];

self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).catch(() => {}));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  e.respondWith(
    fetch(req)
      .then((res) => {
        // stash a fresh copy for offline; ignore opaque/cross-origin failures
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(req).then((r) => r || caches.match('retrofit-factory-3d.html')))
  );
});
