/* eslint-disable no-undef */
/**
 * FCM service worker for JSBA PWA.
 *
 * Runs in its own context, separate from the main page (which uses the
 * modular Firebase JS SDK loaded by `firebase_core_web`). The compat SDK
 * is the only option for FCM inside a service worker — the modular SDK
 * does not support the service-worker environment.
 *
 * Responsibilities:
 *  1. Receive background push messages from FCM and display them as
 *     native browser/system notifications.
 *  2. Open the app and focus the existing tab (if any) when the user
 *     clicks a notification.
 *
 * Required companion wiring:
 *  - `web/manifest.json` includes `gcm_sender_id` (handled separately).
 *  - `web/index.html` registers this file in a separate inline <script>
 *    (the registration cannot live inside `flutter_bootstrap.js` — see
 *    flutterfire/firebase_messaging#17837).
 *  - Flutter side calls `FirebaseMessaging.getToken(vapidKey: ...)` with
 *    the public VAPID key from `env/{environment}-env.json`.
 *
 * NOTE: Replace the placeholder `apiKey` and `appId` below with the web
 * values from Firebase Console (or run `flutterfire configure --platforms=web`
 * to generate them and copy into this file).
 */

/* eslint-env serviceworker */
/* global self, importScripts, firebase, clients */

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'REPLACE_WITH_WEB_API_KEY',
  authDomain: 'juniorshuttlers.firebaseapp.com',
  projectId: 'juniorshuttlers',
  storageBucket: 'juniorshuttlers.firebasestorage.app',
  messagingSenderId: '713373958841',
  appId: 'REPLACE_WITH_WEB_APP_ID',
});

const messaging = firebase.messaging();

// Show a system notification for messages received while the app is
// in the background or closed. The Dart-side `NotificationService`
// handles foreground messages via `onMessage`.
messaging.onBackgroundMessage((payload) => {
  // eslint-disable-next-line no-console
  console.log('[firebase-messaging-sw.js] Background message', payload);
  const title = (payload.notification && payload.notification.title) || 'Notification';
  const options = {
    body: (payload.notification && payload.notification.body) || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  return self.registration.showNotification(title, options);
});

// Map a notification data payload to a deep-link path inside the app.
// Mirrors the routing table in `lib/app/view/app.dart#_wireNotificationTap`.
// Keep in sync when adding new `referenceCollection` values.
function buildNotificationPath(data) {
  if (!data) return '/';
  const refCollection = data.referenceCollection;
  const refId = data.referenceId;
  if (!refCollection) return '/';
  switch (refCollection) {
    case 'announcements':
      return refId ? `/announcement-details/${refId}` : '/';
    case 'invoices':
      return refId ? `/invoice-details/${refId}` : '/';
    case 'receipts':
      return refId ? `/receipt-details/${refId}` : '/';
    case 'training':
      return refId ? `/class-detail/${refId}` : '/';
    case 'court_signups':
      return refId ? `/open-court-detail/${refId}` : '/';
    case 'kid_availability':
      return refId ? `/open-court-detail/${refId}` : '/';
    case 'feedbacks':
      return '/feedback-report';
    default:
      return '/';
  }
}

// Focus the existing tab if the app is already open, otherwise open a
// new tab. The target URL is derived from the notification's
// `referenceCollection` + `referenceId` (see `buildNotificationPath`).
// The Dart-side `NotificationService` also marks the notification as read
// when the page receives the click via `onNotificationTap`.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = buildNotificationPath(event.notification.data);
  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client && 'url' in client && client.url.startsWith(self.location.origin)) {
            client.navigate(targetUrl);
            return client.focus();
          }
        }
        if (self.clients.openWindow) {
          return self.clients.openWindow(targetUrl);
        }
        return null;
      }),
  );
});
