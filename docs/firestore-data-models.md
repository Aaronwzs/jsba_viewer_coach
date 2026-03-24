# Firestore Data Models (JuniorShuttlers + JSBA)

## Overview

This document contains the complete Firestore data models used in JuniorShuttlers admin app and JSBA parent/coach app. All models are synced between both applications.

---

## Users Collection

### `/users/{userId}`

| Field | Type | Description |
|-------|------|-------------|
| uid | string | User ID (Firebase Auth UID) |
| email | string | User email |
| name | string | Display name |
| phone | string? | Phone number |
| role | string | "Viewer", "Coach", "Admin", "SuperAdmin" |
| status | string | "active", "pending" |
| createdAt | timestamp | Account creation date |

### User Roles (Admin Side)

```dart
class UserRole {
  static const String viewer = 'Viewer';
  static const String coach = 'Coach';
  static const String admin = 'Admin';
  static const String superAdmin = 'SuperAdmin';
}
```

### User Status

```dart
class UserStatus {
  static const String active = 'active';
  static const String pending = 'pending';
}
```

---

## Players Collection

### `/players/{playerId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Player ID |
| name | string | Player full name |
| age | int | Player age |
| level | string | Skill level (Beginner, Intermediate, Advanced) |
| phone | string | Contact number |
| isActive | bool | Active status |
| createdAt | timestamp | Registration date |
| imageUrl | string? | Profile image URL |
| parentName | string? | Parent/guardian name |
| parentPhone | string? | Parent contact |
| parentEmail | string? | Parent email |
| parentId | string? | Link to parent user |
| coachId | string? | Assigned coach user ID |

---

## Training Sessions Collection

### `/training/{trainingId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Training ID |
| className | string | Class name |
| playerIds | array | List of enrolled player IDs |
| date | timestamp | Session date |
| dayOfWeek | string | Day (Monday, Tuesday, etc.) |
| venue | string | Court location |
| startTime | string | Start time (HH:mm) |
| endTime | string? | End time (HH:mm) |
| status | string | "upcoming", "completed", "cancelled" |
| classType | string | "group", "private", "sparring", "skill", "physical" |
| level | string | Skill level (Beginner, Intermediate, Advanced) |
| durationMinutes | int | Session duration |
| price | double | Session price |
| maxPlayers | int? | Maximum players allowed |
| coachId | string? | Assigned coach ID |

### Class Types

```dart
static const List<String> validClassTypes = [
  'group',    // Default 6 players max
  'private',  // 1 player
  'sparring', // 2 players
  'skill',    // 4 players max
  'physical', // 4 players max
];
```

### Venues

```dart
static const List<String> validVenues = [
  'Desa Petaling',
  'Midfields',
  'Sky Condo',
  'Yoke Nam',
];
```

---

## Attendance Collection

### `/attendance/{attendanceId}` (per player per session)

| Field | Type | Description |
|-------|------|-------------|
| id | string | Attendance ID |
| trainingId | string | Link to training session |
| playerId | string | Link to player |
| attendanceStatus | string | "present", "absent", "late", "pending" |
| amountCharge | double | Charge amount |
| reasonCharge | string | Reason for charge |
| coachComments | string | Coach feedback |
| createdAt | timestamp | Record creation time |

### Attendance Status

```dart
// 'present' - Player attended
// 'absent' - Player didn't attend
// 'late' - Player arrived late
// 'pending' - Not yet marked
```

---

## Announcements Collection

### `/announcements/{announcementId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Announcement ID |
| title | string | Announcement title |
| content | string | Announcement body |
| type | enum | "general", "event", "urgent", "update" |
| imageUrls | array | List of image URLs |
| createdAt | timestamp | Creation date |
| createdBy | string | Admin who created |
| createdByName | string? | Admin display name |
| viewerIds | array | Specific user IDs to notify |
| isPinned | bool | Pin to top |
| expiresAt | timestamp? | Expiration date |

### Announcement Types

```dart
enum AnnouncementType {
  general,  // General news
  event,    // Upcoming events
  urgent,   // Urgent notices
  update,    // App/system updates
}
```

---

## Invoices Collection

### `/invoices/{invoiceId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Invoice ID |
| invoiceNumber | string | Human-readable invoice number |
| playerId | string | Link to player |
| playerName | string | Player name |
| playerPhone | string | Contact number |
| billingYear | int | Year (e.g., 2024) |
| billingMonth | int | Month (1-12) |
| billingPeriodKey | string | YYYY-MM format |
| lineItems | array | List of InvoiceLineItem |
| subTotal | double | Subtotal before tax |
| discountAmount | double | Discount applied |
| taxAmount | double | Tax amount |
| totalAmount | double | Total to pay |
| status | string | "draft", "sent", "paid", "overdue", "void" |
| notes | string? | Additional notes |
| createdAt | timestamp | Creation date |
| sentAt | timestamp? | When sent to parent |
| paidAt | timestamp? | Payment date |
| paymentMethod | string? | How paid |
| paymentReference | string? | Payment reference |
| receiptId | string? | Link to receipt |
| currency | string | "RM" (default) |
| billToName | string? | Billing name |
| billToPhone | string? | Billing phone |
| billToEmail | string? | Billing email |
| billToType | string? | "player" or "parent" |
| playerIds | array | For family invoices |

### Invoice Line Item

```dart
class InvoiceLineItem {
  String id;
  String title;
  String? description;
  int quantity;
  double unitPrice;
  double totalPrice;
  String? attendanceId;
  String? trainingId;
  DateTime? date;
  String? attendanceStatus;  // present/absent for billing
}
```

### Invoice Status

```dart
// 'draft' - Not yet sent
// 'sent' - Sent to parent
// 'paid' - Payment received
// 'overdue' - Payment overdue
// 'void' - Cancelled
```

---

## Receipts Collection

### `/receipts/{receiptId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Receipt ID |
| receiptNumber | string | Human-readable receipt number |
| invoiceId | string | Link to invoice |
| playerId | string | Link to player |
| playerName | string? | Player name |
| amountPaid | double | Amount paid |
| paymentMethod | string | Payment method |
| paymentReference | string? | Reference number |
| issuedAt | timestamp | Issue date |
| notes | string? | Additional notes |
| currency | string | "RM" (default) |
| billingPeriodKey | string | YYYY-MM format |
| billToName | string? | Billing name |
| billToPhone | string? | Billing phone |
| billToEmail | string? | Billing email |
| billToType | string? | "player" or "parent" |
| playerIds | array | For family invoices |

---

## Player Comments Collection

### `/player_comments/{commentId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Comment ID |
| playerId | string | Link to player |
| coachId | string | Coach who made comment |
| coachName | string | Coach display name |
| category | string | "progress", "behavior", "skill", "general" |
| comment | string | Comment text |
| createdAt | timestamp | Creation date |

### Comment Categories

```dart
class PlayerCommentModel {
  static const String categoryProgress = 'progress';
  static const String categoryBehavior = 'behavior';
  static const String categorySkill = 'skill';
  static const String categoryGeneral = 'general';
}
```

---

## Player Progress Collection

### `/player_progress/{progressId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Progress ID |
| playerId | string | Link to player |
| playerName | string | Player name |
| skills | array | List of SkillProgress |
| lastUpdated | timestamp | Last update time |
| lastUpdatedBy | string? | Coach who updated |

### Skill Progress

```dart
class SkillProgress {
  String skillId;
  String skillName;
  String category;
  String level;           // 'not_started', 'learning', 'practicing', 'proficient'
  String? coachNotes;
  DateTime updatedAt;
  String? updatedBy;
}
```

### Skill Categories

```dart
static const Map<String, List<String>> defaultSkillCategories = {
  'Grip Techniques': ['Forehand Grip', 'Backhand Grip', 'Switching Grip'],
  'Footwork': ['Ready Position', 'Footwork Basics', 'Movement Patterns', 'Recovery'],
  'Serving': ['Short Serve', 'Long Serve', 'Flick Serve', 'Drive Serve'],
  'Smashing': ['Basic Smash', 'Jump Smash', 'Smash Timing', 'Placement'],
  'Net Play': ['Net Lift', 'Net Drop', 'Net Shot', 'Interception'],
  'Defense': ['Block', 'Drive Defense', 'Lift', 'Retrieve'],
  'Match Play': ['Singles Strategy', 'Doubles Positioning', 'Communication'],
  'Physical Fitness': ['Cardio', 'Strength', 'Flexibility', 'Endurance'],
};
```

### Skill Levels

```dart
static const String levelNotStarted = 'not_started';
static const String levelLearning = 'learning';
static const String levelPracticing = 'practicing';
static const String levelProficient = 'proficient';
```

---

## Court Signups Collection

### `/court_signups/{signupId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Signup ID |
| courtVoteId | string? | Link to court vote |
| venue | string | Court location |
| date | timestamp | Session date |
| startTime | string | Start time (HH:mm) |
| endTime | string | End time (HH:mm) |
| maxPlayers | int | Maximum players |
| signUps | array | List of CourtSignUpEntry |
| status | string | "open", "full", "cancelled" |
| createdAt | timestamp | Creation date |

### Court Signup Entry

```dart
class CourtSignUpEntry {
  String id;
  String parentId;
  String parentName;
  String playerName;
  int slots;
  DateTime signedUpAt;
}
```

### Court Signup Status

```dart
static const String statusOpen = 'open';
static const String statusFull = 'full';
static const String statusCancelled = 'cancelled';
```

---

## Kid Availability Collection

### `/kid_availability/{availabilityId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Availability ID |
| parentId | string | Parent user ID |
| playerId | string | Player ID |
| playerName | string | Player name |
| weekId | string | Week identifier (YYYY-WW) |
| availableDays | array | List of DayAvailability |
| preferredVenue | string? | Preferred court |
| submittedAt | timestamp | Submission date |

### Day Availability

```dart
class DayAvailability {
  String dayOfWeek;        // Monday, Tuesday, etc.
  List<TimeSlot> timeSlots;
}

class TimeSlot {
  String startTime;
  String endTime;
}
```

### Days of Week

```dart
static const List<String> daysOfWeek = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
```

---

## Academy Settings Collection

### `/academy_settings/{settingsId}`

| Field | Type | Description |
|-------|------|-------------|
| id | string | Settings ID |
| academyName | string | Academy name |
| venues | array | List of venue names |
| classTypes | array | Allowed class types |
| defaultRates | map | Default pricing |
| notificationSettings | map | Push notification config |

---

## Collection Index

| Collection | Purpose | Admin R/W | Parent R | Coach R/W |
|------------|---------|-----------|----------|-----------|
| users | User accounts | ✅ | Read | Read |
| players | Player profiles | ✅ | Read (own) | Read/Write |
| training | Sessions | ✅ | Read (registered) | Read/Write |
| attendance | Attendance | ✅ | Read (own) | Read/Write |
| announcements | News | ✅ | Read | Read |
| invoices | Billing | ✅ | Read (own) | Read |
| receipts | Payments | ✅ | Read (own) | Read |
| player_comments | Feedback | ✅ | Read (own) | Read/Write |
| player_progress | Progress | ✅ | Read (own) | Read/Write |
| court_signups | Bookings | ✅ | Read/Write | Read |
| kid_availability | Availability | ✅ | Read/Write | Read |
| academy_settings | Config | ✅ | Read | Read |
