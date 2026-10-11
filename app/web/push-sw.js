'use strict';
// Intentionally no fetch handler, CacheStorage, API requests or payload parsing.
// Even a malformed/hostile payload must not expose sender, message or chat data.
self.addEventListener('install', event => event.waitUntil(self.skipWaiting()));
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('push', event => {
  event.waitUntil(self.registration.showNotification('New message', {
    icon: new URL('icons/Icon-192.png', self.registration.scope).href,
    badge: new URL('icons/Icon-192.png', self.registration.scope).href,
    tag: 'ratatosk-new-message'
  }));
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  const appUrl = new URL(self.registration.scope);
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    const existing = windows.find(client => {
      const url = new URL(client.url);
      return url.origin === appUrl.origin && url.pathname.startsWith(appUrl.pathname);
    });
    if (existing) {
      await existing.focus();
      await existing.navigate(appUrl.href);
    } else {
      await self.clients.openWindow(appUrl.href);
    }
  })());
});
