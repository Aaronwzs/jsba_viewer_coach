# Push Notification Implementation — JSBA App

> **Native Android & iOS Push Notifications with In-App Notification Feed**

---

## Overview

This document describes the complete push notification implementation for the JSBA Badminton Academy app. It covers both **Google (Android FCM)** and **Apple (iOS APNs)** push notifications, plus an in-app notification feed that appears on the dashboard and a dedicated Notifications page.

### Architecture

```
Firestore Document Created/Updated
    ↓
Cloud Function (TypeScript) triggered
    ↓
├── Writes to /users/{userId}/notifications/{notifId}   ← In-app feed
└── Sends FCM push via admin.messaging().sendEachForMulticast()
        ↓
    Flutter App receives notification
        ├── Foreground → flutter_local_notifications shows system tray
        └── Background → FCM SDK shows system tray automatically
        ↓
    NotificationViewModel (Provider) listens to Firestore subcollection
        ├── Dashboard bell badge updates (unread count)
        ├── Dashboard "Recent Notifications" section (3 latest items)
        └── NotificationsPage shows full list with read/unread state
```

---

## Files Changed Summary

### Flutter App — New Files (3)

| # | File | Description |
|---|------|-------------|
| 1 | `lib/app/model/notification_item_model.dart` | Data model for in-app notification feed items |
| 2 | `lib/app/service/notification_service.dart` | FCM init, permissions, foreground/background handling, token management |
| 3 | `lib/app/viewmodel/notification_view_model.dart` | Real-time Firestore listener, unread count, markAsRead/markAllAsRead |

### Flutter App — Modified Files (8)

| # | File | Changes |
|---|------|---------|
| 4 | `lib/app/model/user_model.dart` | Added `deviceTokens` (List<String>) for FCM token storage |
| 5 | `lib/app/utils/starter_handler.dart` | Initializes NotificationService on startup via singleton |
| 6 | `lib/app/viewmodel/auth_view_model.dart` | Saves/removes FCM token on login/register/phone-OTP/logout |
| 7 | `lib/app/view/app.dart` | Added NotificationViewModel to MultiProvider |
| 8 | `lib/app/view/splash/splash_screen_page.dart` | Starts notification listener for the authenticated user |
| 9 | `lib/app/view/shared/notifications_page.dart` | Replaced placeholder with full notification list UI |
| 10 | `lib/app/view/parent/parent_dashboard_page.dart` | Badge on bell icon + "Recent Notifications" section |
| 11 | `lib/app/view/coach/coach_dashboard_page.dart` | Badge on bell icon + "Recent Notifications" section |

### Native Platform Configs — Modified Files (2)

| # | File | Changes |
|---|------|---------|
| 12 | `android/app/src/main/AndroidManifest.xml` | Added `POST_NOTIFICATIONS` permission + FCM channel metadata |
| 13 | `ios/Runner/Info.plist` | Added `UIBackgroundModes` with `fetch` and `remote-notification` |

### Cloud Functions — New Files (3)

| # | File | Description |
|---|------|-------------|
| 14 | `functions/package.json` | Node.js dependencies for Firebase Cloud Functions |
| 15 | `functions/tsconfig.json` | TypeScript compiler configuration |
| 16 | `functions/src/index.ts` | All 10 notification trigger functions (~580 lines) |

---

## Detailed File Changes

### 1. `lib/app/model/notification_item_model.dart` — NEW

```dart
class NotificationItemModel {
  final String id;
  final String type;       // 'announcement', 'invoice', 'receipt', 'availability', 
                           // 'session', 'training', 'attendance', 'feedback', 'payment_due'
  final String title;
  final String body;
  final String? referenceId;           // ID of the related Firestore document
  final String? referenceCollection;   // Collection name (for navigation)
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;    // Extra payload
}
```

Firestore path: `/users/{userId}/notifications/{notificationId}`

### 2. `lib/app/service/notification_service.dart` — NEW

Key methods:
- `initialize()` — Sets up FCM, local notifications, channel, and listeners
- `requestPermissions()` — Requests iOS/Android 13+ permission
- `getDeviceToken()` — Gets current FCM token
- `saveDeviceToken(userId)` — Adds token to Firestore user doc
- `removeDeviceToken(userId)` — Removes token from Firestore user doc
- `onNotificationTap` — Callback for navigation (set by UI layer)

Event listeners:
- `FirebaseMessaging.onMessage` — Foreground messages → local notification
- `FirebaseMessaging.onMessageOpenedApp` — Background notification tap → navigation
- `getInitialMessage()` — Cold start notification → navigation

### 3. `lib/app/viewmodel/notification_view_model.dart` — NEW

Key state:
- `notifications` — Full list sorted by `createdAt` desc
- `recentNotifications` — Top 3 unread (or recent) for dashboard
- `unreadCount` — For badge
- `isLoading` — Loading state

Key methods:
- `startListening(userId)` — Subscribes to `/users/{userId}/notifications` via `snapshots()`
- `stopListening()` — Cancels subscription
- `markAsRead(notificationId)` — Updates Firestore + optimistic local update
- `markAllAsRead()` — Batch updates all unread to read
- Static helpers: `getNotificationIcon(type)`, `getNotificationTypeLabel(type)`

### 4. `lib/app/model/user_model.dart` — MODIFIED

Added field:
```dart
final List<String> deviceTokens;  // List of FCM registration tokens
```

Updated:
- `fromMap()` — Reads `deviceTokens` array from Firestore
- `toMap()` — Includes `deviceTokens` if non-empty
- `copyWith()` — Accepts optional `deviceTokens`

### 5. `lib/app/utils/starter_handler.dart` — MODIFIED

Added `NotificationService` singleton:
```dart
NotificationService get notificationService { ... }
```

Initialized in `initApiServices()`:
```dart
Future<void> initApiServices() async {
  _ensureNotificationService();
  await _notificationService!.initialize();
}
```

### 6. `lib/app/viewmodel/auth_view_model.dart` — MODIFIED

Token saved on login/register/phone-OTP:
```dart
await notificationService.saveDeviceToken(credential.user!.uid);
```

Token removed on logout:
```dart
if (_currentUser != null) {
  await notificationService.removeDeviceToken(_currentUser!.uid);
}
```

### 7. `lib/app/view/app.dart` — MODIFIED

Added to MultiProvider:
```dart
ChangeNotifierProvider(create: (_) => NotificationViewModel()),
```

### 8. `lib/app/view/splash/splash_screen_page.dart` — MODIFIED

After successful auth check:
```dart
context.read<NotificationViewModel>().startListening(user!.uid);
```

### 9. `lib/app/view/shared/notifications_page.dart` — MODIFIED

Features:
- Full notification list with real-time updates via `Consumer<NotificationViewModel>`
- Each card shows: type icon, type label badge, title, body (2 lines truncated), timestamp, unread dot
- Color-coded backgrounds by type (orange=announcement, green=invoice, red=payment_due, etc.)
- "Mark all read" button in AppBar when unread exist
- Tap to navigate: announcement → `/announcement-details/:id`, invoice → `/invoice-details/:id`, training → `/class-detail/:id`, etc.
- Empty state when no notifications

### 10. `lib/app/view/parent/parent_dashboard_page.dart` — MODIFIED

**Welcome card**: Bell icon wrapped in `Badge` widget showing `unreadCount`:
```dart
Badge(
  isLabelVisible: notifVM.unreadCount > 0,
  label: Text('${notifVM.unreadCount}'),
  child: IconButton(onPressed: () => context.router.pushPath('/notifications')),
)
```

**New section**: "Recent Notifications" between welcome card and "About Academy" — shows 3 latest unread/recent items with tap-to-mark-read and navigate.

### 11. `lib/app/view/coach/coach_dashboard_page.dart` — MODIFIED

Same changes as parent dashboard: badge on bell + recent notifications section.

### 12. `android/app/src/main/AndroidManifest.xml` — MODIFIED

```xml
<!-- Android 13+ notification permission -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- FCM default channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

### 13. `ios/Runner/Info.plist` — MODIFIED

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

> **Note**: iOS also requires the **Push Notifications** capability to be enabled in Xcode (under `Runner` → `Signing & Capabilities` → `+ Capability` → `Push Notifications`).

---

## Cloud Functions — `functions/src/index.ts`

### Helper Functions

| Function | Purpose |
|----------|---------|
| `getParentIdsForPlayers(playerIds)` | Queries `players` collection by document ID, extracts `parentId` |
| `getUserIdsByRole(role)` | Gets all user IDs with a specific role |
| `sendNotificationToUserIds(userIds, notification, bodyOverride?)` | Writes Firestore notification doc + sends FCM push, auto-cleans invalid tokens |
| `formatDate(date)` | Formats Timestamp/Date to short date string |
| `formatTime(time)` | Converts "09:00" → "9:00 AM" |

### All 10 Notification Triggers

#### 1. `onAnnouncementCreated`

| Property | Value |
|----------|-------|
| Event | `announcements/{announcementId}` `.onCreate` |
| Targets | Specific `viewerIds`, role-matched users, or all Viewers + Coaches |
| Type | `announcement` |

#### 2. `onInvoiceCreated`

| Property | Value |
|----------|-------|
| Event | `invoices/{invoiceId}` `.onCreate` |
| Targets | Parent(s) of the player(s) |
| Type | `invoice` |

#### 3. `onInvoiceUpdated`

| Property | Value |
|----------|-------|
| Event | `invoices/{invoiceId}` `.onUpdate` (status change) |
| Targets | Parent(s) of the player(s) |
| Type | `invoice` |
| Statuses | `paid` → "Payment Approved", `sent` → "Invoice Sent", `overdue` → "Payment Overdue" |

#### 4. `onReceiptCreated`

| Property | Value |
|----------|-------|
| Event | `receipts/{receiptId}` `.onCreate` |
| Targets | Parent(s) of the player(s) |
| Type | `receipt` |

#### 5. `onAvailabilityCreated`

| Property | Value |
|----------|-------|
| Event | `kid_availability/{availabilityId}` `.onCreate` |
| Targets | All Coaches, Admins, SuperAdmins |
| Type | `availability` |

#### 6. `onCourtSignupCreated`

| Property | Value |
|----------|-------|
| Event | `court_signups/{signupId}` `.onCreate` |
| Targets | All Viewers (parents) |
| Type | `session` |

#### 7. `onTrainingUpdated`

| Property | Value |
|----------|-------|
| Event | `training/{trainingId}` `.onUpdate` (time/venue/status change) |
| Targets | Parents of enrolled players |
| Type | `training` |
| Special | Cancellation → "Training Cancelled" notification |

#### 8. `onFeedbackRequested`

| Property | Value |
|----------|-------|
| Event | `feedbacks/{feedbackId}` `.onCreate` (type='request') |
| Targets | Parent of the player |
| Type | `feedback` |

#### 9. `dailyAttendanceReminder`

| Property | Value |
|----------|-------|
| Schedule | `0 20 * * *` (8:00 PM daily, Asia/Kuala_Lumpur) |
| Action | Queries `training` for next day's upcoming sessions |
| Targets | Parents of enrolled players |
| Type | `attendance` |

#### 10. `weeklyPaymentReminder`

| Property | Value |
|----------|-------|
| Schedule | `0 10 * * MON` (10:00 AM Monday, Asia/Kuala_Lumpur) |
| Action | Queries `invoices` where status='sent' and due within 7 days |
| Targets | Parents of the player(s) |
| Type | `payment_due` |

### Automated Token Cleanup

When FCM returns `registration-token-not-registered` or `invalid-registration-token`, the function automatically removes those tokens from all affected user documents to keep storage clean.

---

## Data Flow Diagram

```
┌─────────────────┐      ┌──────────────────────┐      ┌─────────────────┐
│  Admin Action    │      │  Cloud Function       │      │  Flutter App     │
│  (creates doc)   │ ───→ │  (Firestore trigger)  │ ───→ │  (User receives) │
└─────────────────┘      └──────────────────────┘      └─────────────────┘
                                  │                              │
                                  ▼                              ▼
                          ┌───────────────┐             ┌───────────────┐
                          │ Firestore      │             │ FCM Push      │
                          │ /users/{uid}/  │             │ (system tray) │
                          │ notifications/ │             └───────────────┘
                          └───────────────┘
                                  │
                                  ▼
                          ┌───────────────┐
                          │ Notification   │
                          │ ViewModel      │
                          │ (snapshots())  │
                          └───────────────┘
                                  │
                  ┌───────────────┼───────────────┐
                  ▼               ▼               ▼
          ┌────────────┐  ┌────────────┐  ┌────────────┐
          │ Dashboard  │  │ Dashboard  │  │ Notifi-    │
          │ Bell Badge │  │ Recent     │  │ cations    │
          │ (unread #) │  │ Notifs (3) │  │ Page (all) │
          └────────────┘  └────────────┘  └────────────┘
```

---

## Cost Estimate

All services on **Firebase Blaze plan (pay-as-you-go)**, but usage stays within free tier:

| Service | Free Tier | Expected Monthly Usage |
|---------|-----------|----------------------|
| **Cloud Functions** | 2,000,000 invocations | ~500–2,000 |
| **Cloud Functions Compute** | 400,000 GB-seconds | ~3,000 seconds |
| **FCM** | Unlimited | Unlimited |
| **Firestore Reads** (notifications subcollection) | 50,000/day | ~500/day |
| **Cloud Scheduler** (2 scheduled jobs) | 3 jobs free | 2 jobs |

**Total estimated cost: $0/month**

---

## Deployment Instructions

### 1. Deploy Cloud Functions

```bash
# Ensure you're logged in to Firebase
firebase login

# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:onAnnouncementCreated,functions:onInvoiceCreated
```

### 2. iOS APNs Setup

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Runner` target → `Signing & Capabilities`
3. Click `+ Capability` → add **Push Notifications**
4. Click `+ Capability` → add **Background Modes** → check **Remote notifications**
5. Go to [Firebase Console](https://console.firebase.google.com) → Project → Cloud Messaging → iOS app
6. Upload your APNs authentication key (`.p8` file from Apple Developer)
   - Or use APNs certificate if preferred

### 3. Add `dueDate` to Invoices

The `weeklyPaymentReminder` function checks for a `dueDate` field on invoice documents. If your existing invoices don't have this field, add it to the `InvoiceModel`:

```dart
// In lib/app/model/invoice_model.dart
final DateTime? dueDate;
```

Then run a one-time script or add it to the admin flow when creating invoices.

### 4. Build & Run

```bash
# Android (physical device or emulator)
flutter run --flavor production

# iOS (physical device only — simulator doesn't support push)
flutter run --flavor production
```

---

## Testing Notifications

### Test via Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click **Send test message**
3. Enter a device token (logged via `getDeviceToken()`)
4. Compose a notification with `type`, `referenceId`, `referenceCollection` in data payload
5. Send

### Test via cURL

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "🧾 Test Invoice",
        "body": "Invoice INV-001 for RM150.00 is ready."
      },
      "data": {
        "type": "invoice",
        "referenceId": "test-invoice-id",
        "referenceCollection": "invoices"
      }
    }
  }'
```

### Test via Firestore Write

In Firestore console, manually create a document in any watched collection (e.g., `announcements`). The Cloud Function triggers automatically within seconds.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No notification on Android 13+ | Missing `POST_NOTIFICATIONS` permission | Runtime permission handled by `NotificationService.requestPermissions()` |
| No notification on iOS foreground | Missing `flutter_local_notifications` handling | Handled in `_handleForegroundMessage()` |
| iOS not receiving any push | APNs key not uploaded to Firebase Console | Upload `.p8` key in Firebase Console → Cloud Messaging |
| Android not receiving any push | Missing google-services.json | Already configured in your project |
| Dashboard badge not updating | NotificationViewModel not listening | Check `startListening(userId)` called after login |
| Cloud Function error | Missing Firestore index | Check Firebase Console → Firestore → Indexes |
| Invalid token errors | Token refreshed but old token still stored | Auto-cleaned by `sendNotificationToUserIds()` |

---

## Key Design Decisions

1. **Dual channel** — Every notification writes to both Firestore subcollection (for in-app feed) and FCM push (for system tray). This ensures history persistence even if push fails.

2. **Firestore subcollection pattern** — `/users/{userId}/notifications/{notificationId}` means each user reads only their own data. Security rules are simple: `allow read, write: if request.auth.uid == userId`.

3. **Singleton NotificationService** — Since FCM must be initialized once, `starter_handler.dart` provides a singleton accessor used by the AuthViewModel and any other service.

4. **Provider for state management** — The `NotificationViewModel` uses `ChangeNotifier` + `Provider` consistent with the rest of the app's architecture.

5. **Scheduled functions over onWrite** — Reminders (attendance, payment) use scheduled Cloud Functions rather than `onWrite` triggers to avoid redundant notifications on every document update.