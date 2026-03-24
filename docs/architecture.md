# Badminton Academy App Architecture

## Overview

A Flutter mobile application for managing a badminton academy with role-based access for coaches and parents. Built using the Solarvest reference architecture pattern. Based on the actual Firestore data models from JuniorShuttlers.

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| State Management | Provider |
| Navigation | Auto Route (declarative routing) |
| Backend | Firebase (Firestore, Auth, Cloud Functions, Cloud Messaging) |

## Architecture Pattern

**Single App with Role-Based Access**

- One Flutter app
- Login → Detect role → Route to Coach or Parent dashboard
- Shared UI components where possible
- Faster development, easier maintenance

---

## Module Breakdown

### Coach Modules

| Module | Features |
|--------|----------|
| Dashboard | Announcements, today's sessions, quick stats |
| Sessions | View all scheduled sessions (private/group/sparring/skill/physical) |
| Attendance | Mark players present/absent per session, add comments |
| Player Comments | Give individual feedback per player (progress/behavior/skill/general) |
| Player Progress | Track skill development, update levels |
| Court Bookings | View court signups, monitor usage |
| Billing | View earnings (invoices/receipts) |
| Profile | Edit profile, settings |

### Parent Modules

| Module | Features |
|--------|----------|
| Dashboard | Announcements, kids' upcoming sessions |
| My Kids | Add/manage children profiles |
| Sessions | View child's registered sessions |
| Attendance | View child's attendance history |
| Progress Reports | View coach comments, skill progress |
| Court Booking | Book court slots, register kids |
| Availability | Set child's available time slots |
| Invoices | View invoices, payment status |
| Receipts | View payment receipts |

### Shared Modules

| Module | Features |
|--------|----------|
| Announcements | Academy news/posts (general/event/urgent/update) |
| Authentication | Login, OTP verification, password reset |
| Notifications | Push notifications for bookings, invoices, etc. |

---

## Current Admin Implementation (JuniorShuttlers)

| Module | Status | DB Collection | Key Fields |
|--------|--------|---------------|------------|
| Players | ✅ Complete | players | id, name, age, level, parentId, coachId |
| Training | ✅ Complete | training | className, playerIds, date, venue, classType |
| Attendance | ✅ Complete | attendance | trainingId, playerId, attendanceStatus |
| Billing/Invoices | ✅ Complete | invoices | playerId, lineItems, status |
| Receipts | ✅ Complete | receipts | invoiceId, amountPaid, paymentMethod |
| Announcements | ✅ Complete | announcements | title, content, type, isPinned |
| Player Comments | ❓ TBD | player_comments | playerId, coachId, category, comment |
| Player Progress | ❓ TBD | player_progress | playerId, skills (with levels) |
| Kid Availability | ❓ TBD | kid_availability | playerId, weekId, availableDays |
| Court Signups | ❓ TBD | court_signups | venue, date, signUps, status |

---

## Data Structure (Firestore)

Based on actual JuniorShuttlers models:

### `/users/{userId}`
```
- uid: string (Firebase Auth UID)
- email: string
- name: string
- phone: string?
- role: "Viewer" | "Coach" | "Admin" | "SuperAdmin" | "Parent"
- status: "active" | "pending"
- createdAt: timestamp
```

### `/players/{playerId}`
```
- name: string
- age: int
- level: string (Beginner/Intermediate/Advanced)
- phone: string
- isActive: bool
- createdAt: timestamp
- imageUrl: string?
- parentName: string?
- parentPhone: string?
- parentEmail: string?
- parentId: string? (link to parent user)
- coachId: string? (link to coach user)
```

### `/training/{trainingId}`
```
- className: string
- playerIds: [playerId]
- date: timestamp
- dayOfWeek: string
- venue: string (Desa Petaling/Midfields/Sky Condo/Yoke Nam)
- startTime: string (HH:mm)
- endTime: string?
- status: "upcoming" | "completed" | "cancelled"
- classType: "group" | "private" | "sparring" | "skill" | "physical"
- level: string
- durationMinutes: int
- price: double
- maxPlayers: int?
- coachId: string?
```

### `/attendance/{attendanceId}`
```
- trainingId: string
- playerId: string
- attendanceStatus: "present" | "absent" | "late" | "pending"
- amountCharge: double
- reasonCharge: string
- coachComments: string
- createdAt: timestamp
```

### `/announcements/{announcementId}`
```
- title: string
- content: string
- type: "general" | "event" | "urgent" | "update"
- imageUrls: [string]
- createdAt: timestamp
- createdBy: string
- createdByName: string?
- viewerIds: [string]
- isPinned: bool
- expiresAt: timestamp?
```

### `/invoices/{invoiceId}`
```
- invoiceNumber: string
- playerId: string
- playerName: string
- playerPhone: string
- billingYear: int
- billingMonth: int
- billingPeriodKey: string (YYYY-MM)
- lineItems: [
    {
      id, title, description?, quantity, unitPrice, totalPrice,
      attendanceId?, trainingId?, date?, attendanceStatus?
    }
  ]
- subTotal: double
- discountAmount: double
- taxAmount: double
- totalAmount: double
- status: "draft" | "sent" | "paid" | "overdue" | "void"
- notes: string?
- createdAt: timestamp
- sentAt: timestamp?
- paidAt: timestamp?
- paymentMethod: string?
- paymentReference: string?
- receiptId: string?
- billToName: string?
- billToPhone: string?
- billToEmail: string?
- billToType: string? ("player" | "parent")
- playerIds: [string] (for family invoices)
```

### `/receipts/{receiptId}`
```
- receiptNumber: string
- invoiceId: string
- playerId: string
- playerName: string?
- amountPaid: double
- paymentMethod: string
- paymentReference: string?
- issuedAt: timestamp
- notes: string?
- currency: string (RM)
- billingPeriodKey: string
- billToName: string?
- billToPhone: string?
- billToEmail: string?
- playerIds: [string]
```

### `/player_comments/{commentId}`
```
- playerId: string
- coachId: string
- coachName: string
- category: "progress" | "behavior" | "skill" | "general"
- comment: string
- createdAt: timestamp
```

### `/player_progress/{progressId}`
```
- playerId: string
- playerName: string
- skills: [
    {
      skillId, skillName, category,
      level: "not_started" | "learning" | "practicing" | "proficient",
      coachNotes?, updatedAt, updatedBy?
    }
  ]
- lastUpdated: timestamp
- lastUpdatedBy: string?
```

### `/court_signups/{signupId}`
```
- courtVoteId: string?
- venue: string
- date: timestamp
- startTime: string
- endTime: string
- maxPlayers: int
- signUps: [
    { id, parentId, parentName, playerName, slots, signedUpAt }
  ]
- status: "open" | "full" | "cancelled"
- createdAt: timestamp
```

### `/kid_availability/{availabilityId}`
```
- parentId: string
- playerId: string
- playerName: string
- weekId: string (YYYY-WW)
- availableDays: [
    {
      dayOfWeek: string,
      timeSlots: [{ startTime, endTime }]
    }
  ]
- preferredVenue: string?
- submittedAt: timestamp
```

---

## Implementation Approach

### Single App with Role-Based Access

One Flutter app with:
- Login screen → Role detection → Route to appropriate dashboard
- Shared UI components for common features
- Provider for state management across the app
- Auto Route for declarative navigation

### Project Structure

```
lib/
├── app/
│   ├── assets/
│   │   ├── constants/
│   │   ├── router/
│   │   └── theme/
│   ├── model/           # Data models (copy from JuniorShuttlers)
│   ├── service/         # Firestore services
│   ├── repository/       # Data transformation
│   ├── providers/       # Provider setup
│   ├── utils/
│   ├── view/
│   │   ├── auth/        # Login, OTP
│   │   ├── coach/       # Coach modules
│   │   ├── parent/      # Parent modules
│   │   ├── dashboard/  # Root navigation
│   │   └── shared/     # Announcements, profile
│   ├── viewmodel/       # State management
│   └── widgets/        # Reusable widgets
├── firebase_options.dart
└── main.dart
```

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  auto_route: ^9.0.0
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_messaging: ^15.0.0
  cloud_functions: ^5.0.0
  intl: ^0.19.0
```

---

## Navigation Flow

```
Splash Screen
    ↓
Authentication (Login/OTP)
    ↓
Role Detection
    ↓
┌──────────────┴──────────────┐
↓                             ↓
Coach Dashboard          Parent Dashboard
    ↓                             ↓
Sessions, Attendance,     My Kids, Sessions,
Player Comments,         Attendance, Invoices,
Progress, Billing        Court Booking,
                          Availability
```
