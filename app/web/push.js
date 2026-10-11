// Browser boundary only. Tokens and subscription keys are never persisted here.
(() => {
  'use strict';
  const appUrl = new URL('.', document.baseURI);
  const installed = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  const ios = () => /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  function reason() {
    if (!isSecureContext) return 'Notifications require HTTPS (localhost is allowed for development).';
    if (ios() && !installed()) return 'On iOS/iPadOS 16.4 or later, use Share → Add to Home Screen, then open the installed app to enable notifications.';
    if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) return 'Web Push is not supported by this browser. On iOS, use iOS 16.4 or later and the Home Screen app.';
    return '';
  }
  async function registration() {
    // Replace the legacy Flutter cache worker at this scope, rather than racing
    // two registrations. Our worker has no fetch handler and caches nothing.
    const reg = await navigator.serviceWorker.register(new URL('push-sw.js', appUrl).href, {scope: appUrl.pathname, updateViaCache: 'none'});
    if (!reg.active || !reg.active.scriptURL.endsWith('/push-sw.js')) {
      const worker = reg.installing || reg.waiting;
      if (worker) await new Promise((resolve, reject) => {
        const check = () => {
          if (worker.state === 'activated') resolve();
          else if (worker.state === 'redundant') reject(new Error('Notification worker failed to activate.'));
        };
        worker.addEventListener('statechange', check);
        check();
      });
    }
    return reg;
  }
  function keyBytes(value) {
    const padded = value.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - value.length % 4) % 4);
    return Uint8Array.from(atob(padded), c => c.charCodeAt(0));
  }
  window.ratatoskPush = {
    async status() {
      const unsupported = reason();
      if (unsupported) return JSON.stringify({supported: false, reason: unsupported, subscribed: false});
      const reg = await registration();
      return JSON.stringify({supported: true, permission: Notification.permission, subscribed: !!(await reg.pushManager.getSubscription())});
    },
    // Called directly from the explicit user button: request permission BEFORE
    // any asynchronous work so Safari retains the user activation.
    async enable(publicKey) {
      const unsupported = reason();
      if (unsupported) throw new Error(unsupported);
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') throw new Error('Notifications are blocked or were not allowed. Change notification permission in browser/system settings and try again.');
      const reg = await registration();
      let subscription = await reg.pushManager.getSubscription();
      const applicationServerKey = keyBytes(publicKey);
      if (subscription && subscription.options.applicationServerKey) {
        const current = new Uint8Array(subscription.options.applicationServerKey);
        if (current.length !== applicationServerKey.length || current.some((v, i) => v !== applicationServerKey[i])) {
          await subscription.unsubscribe();
          subscription = null;
        }
      }
      subscription ||= await reg.pushManager.subscribe({userVisibleOnly: true, applicationServerKey});
      return JSON.stringify(subscription.toJSON());
    },
    async subscription() {
      if (!('serviceWorker' in navigator)) return 'null';
      const reg = await navigator.serviceWorker.getRegistration(appUrl.href);
      const sub = reg && await reg.pushManager.getSubscription();
      return JSON.stringify(sub ? sub.toJSON() : null);
    },
    async unsubscribe() {
      if (!('serviceWorker' in navigator)) return;
      const reg = await navigator.serviceWorker.getRegistration(appUrl.href);
      const sub = reg && await reg.pushManager.getSubscription();
      if (sub && !(await sub.unsubscribe())) throw new Error('Could not disable browser notifications. Please try again.');
    }
  };
})();
