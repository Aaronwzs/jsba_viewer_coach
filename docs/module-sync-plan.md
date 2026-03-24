# Module Sync Plan: JuniorShuttlers Admin ↔ JSBA (Parent & Coach)

## Overview

This document outlines the sync plan between JuniorShuttlers admin app and JSBA parent/coach app based on the actual Firestore data models implemented in JuniorShuttlers.

---

## Current Status

### Admin Side (JuniorShuttlers)

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

## JSBA App Implementation Plan

### 1. Sessions/Training Module

**DB Collection:** `training`

**DB Fields (ACTUAL):**
```dart
{
  className: string,
  playerIds: List<string>,
  date: timestamp,
  dayOfWeek: string,
  venue: string,
  startTime: string,
  endTime: string?,
  status: string,           // 'upcoming', 'completed', 'cancelled'
  classType: string,        // 'group', 'private', 'sparring', 'skill', 'physical'
  level: string,            // 'Beginner', 'Intermediate', 'Advanced'
  durationMinutes: int,
  price: double,
  maxPlayers: int?,
  coachId: string?
}
```

**For Parents:**
- View child's registered sessions
- Session details (time, venue, coach, classType)
- Register for available session slots
- View session history

**For Coaches:**
- View all assigned sessions
- Create/edit sessions
- View players in session

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Sessions List | /sessions | Partial |
| Session Details | /session-details/:id | Partial |
| Create Session | /create-session | Partial |

---

### 2. Attendance Module

**DB Collection:** `attendance`

**DB Fields (ACTUAL):**
```dart
{
  trainingId: string,
  playerId: string,
  attendanceStatus: string,  // 'present', 'absent', 'late', 'pending'
  amountCharge: double,
  reasonCharge: string,
  coachComments: string,
  createdAt: timestamp
}
```

**For Parents:**
- View child's attendance history per session
- View attendance status (present/absent/late)
- View coach comments

**For Coaches:**
- Mark attendance per session
- Add comments per player
- Set charge for absences

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Take Attendance | /attendance/:sessionId | ❌ Missing |
| Attendance History | /child-attendance/:playerId | ❌ Missing |

---

### 3. Billing Module (Invoices & Receipts)

**DB Collections:** `invoices`, `receipts`

**Invoice DB Fields (ACTUAL):**
```dart
{
  invoiceNumber: string,
  playerId: string,
  playerName: string,
  playerPhone: string,
  billingYear: int,
  billingMonth: int,
  billingPeriodKey: string,  // YYYY-MM
  lineItems: [
    {
      id: string,
      title: string,
      description: string?,
      quantity: int,
      unitPrice: double,
      totalPrice: double,
      attendanceId: string?,
      trainingId: string?,
      date: timestamp?,
      attendanceStatus: string?
    }
  ],
  subTotal: double,
  discountAmount: double,
  taxAmount: double,
  totalAmount: double,
  status: string,  // 'draft', 'sent', 'paid', 'overdue', 'void'
  notes: string?,
  createdAt: timestamp,
  sentAt: timestamp?,
  paidAt: timestamp?,
  paymentMethod: string?,
  paymentReference: string?,
  receiptId: string?,
  currency: string,
  billToName: string?,
  billToPhone: string?,
  billToEmail: string?,
  billToType: string?,
  playerIds: List<string>  // for family invoices
}
```

**Receipt DB Fields (ACTUAL):**
```dart
{
  receiptNumber: string,
  invoiceId: string,
  playerId: string,
  playerName: string?,
  amountPaid: double,
  paymentMethod: string,
  paymentReference: string?,
  issuedAt: timestamp,
  notes: string?,
  currency: string,
  billingPeriodKey: string,
  billToName: string?,
  billToPhone: string?,
  billToEmail: string?,
  billToType: string?,
  playerIds: List<string>
}
```

**For Parents:**
- View list of invoices
- View invoice details
- View payment status
- View receipts
- Download receipt PDF

**For Coaches:**
- View earnings summary (read-only)
- View payout history

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Invoice Details | /invoice-details/:id | Partial |
| Receipt Details | /receipt-details/:id | ❌ Missing |
| Payment History | /payment-history | ❌ Missing |

---

### 4. Player Comments/Feedback Module

**DB Collection:** `player_comments`

**DB Fields (ACTUAL):**
```dart
{
  playerId: string,
  coachId: string,
  coachName: string,
  category: string,  // 'progress', 'behavior', 'skill', 'general'
  comment: string,
  createdAt: timestamp
}
```

**Categories:**
- progress
- behavior
- skill
- general

**For Parents:**
- View coach comments for child
- Filter by category
- View chronological timeline

**For Coaches:**
- Add comments for players
- Categorize feedback
- View comment history

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Player Comments | /player-comments/:playerId | ❌ Missing |
| Add Comment | /add-comment | ❌ Missing |

---

### 5. Player Progress Module

**DB Collection:** `player_progress`

**DB Fields (ACTUAL):**
```dart
{
  playerId: string,
  playerName: string,
  skills: [
    {
      skillId: string,
      skillName: string,
      category: string,
      level: string,        // 'not_started', 'learning', 'practicing', 'proficient'
      coachNotes: string?,
      updatedAt: timestamp,
      updatedBy: string?
    }
  ],
  lastUpdated: timestamp,
  lastUpdatedBy: string?
}
```

**Skill Categories:**
- Grip Techniques (Forehand Grip, Backhand Grip, Switching Grip)
- Footwork (Ready Position, Footwork Basics, Movement Patterns, Recovery)
- Serving (Short Serve, Long Serve, Flick Serve, Drive Serve)
- Smashing (Basic Smash, Jump Smash, Smash Timing, Placement)
- Net Play (Net Lift, Net Drop, Net Shot, Interception)
- Defense (Block, Drive Defense, Lift, Retrieve)
- Match Play (Singles Strategy, Doubles Positioning, Communication)
- Physical Fitness (Cardio, Strength, Flexibility, Endurance)

**For Parents:**
- View skill progress dashboard
- View progress by category
- Track improvement over time

**For Coaches:**
- Update skill levels
- Add coach notes
- Track player development

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Progress Dashboard | /progress/:playerId | ❌ Missing |
| Update Progress | /update-progress | ❌ Missing |

---

### 6. Court Booking/Voting Module

**DB Collection:** `court_signups`

**DB Fields (ACTUAL):**
```dart
{
  courtVoteId: string?,
  venue: string,
  date: timestamp,
  startTime: string,
  endTime: string,
  maxPlayers: int,
  signUps: [
    {
      id: string,
      parentId: string,
      parentName: string,
      playerName: string,
      slots: int,
      signedUpAt: timestamp
    }
  ],
  status: string,  // 'open', 'full', 'cancelled'
  createdAt: timestamp
}
```

**For Parents:**
- View available court slots
- Sign up for court time
- Cancel registration
- View who's signed up

**For Coaches:**
- View all bookings
- Monitor court usage

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Court Bookings | /court-bookings | Partial |
| Create Booking | /create-booking | Partial |
| Booking Details | /booking-details/:id | ❌ Missing |

---

### 7. Kid Availability Module

**DB Collection:** `kid_availability`

**DB Fields (ACTUAL):**
```dart
{
  parentId: string,
  playerId: string,
  playerName: string,
  weekId: string,  // YYYY-WW (e.g., '2024-01')
  availableDays: [
    {
      dayOfWeek: string,  // Monday, Tuesday, etc.
      timeSlots: [
        { startTime: string, endTime: string }
      ]
    }
  ],
  preferredVenue: string?,
  submittedAt: timestamp
}
```

**For Parents:**
- Set child's weekly availability
- Select preferred venue
- Update for specific weeks

**For Coaches:**
- View all kids' availability
- Plan sessions accordingly

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Set Availability | /set-availability | ❌ Missing |
| View Availability | /availability/:playerId | ❌ Missing |

---

### 8. Announcements Module

**DB Collection:** `announcements`

**DB Fields (ACTUAL):**
```dart
{
  title: string,
  content: string,
  type: string,  // 'general', 'event', 'urgent', 'update'
  imageUrls: List<string>,
  createdAt: timestamp,
  createdBy: string,
  createdByName: string?,
  viewerIds: List<string>,
  isPinned: bool,
  expiresAt: timestamp?
}
```

**For Parents:**
- View announcements
- Filter by type
- View pinned announcements

**For Coaches:**
- Same as parents (read-only)

**Required Pages:**
| Page | Route | Status |
|------|-------|--------|
| Announcements List | /announcements | Partial |
| Announcement Details | /announcement-details/:id | Partial |

---

## Implementation Priority

| Priority | Module | DB Collection | Effort |
|----------|--------|---------------|--------|
| 1 | Sessions View | training | Medium |
| 2 | Attendance | attendance | Medium |
| 3 | Invoices/Receipts | invoices, receipts | Medium |
| 4 | Player Comments | player_comments | Low |
| 5 | Player Progress | player_progress | Medium |
| 6 | Court Bookings | court_signups | Medium |
| 7 | Kid Availability | kid_availability | Low |
| 8 | Announcements | announcements | Low |

---

## Data Sync Checklist

### From Admin → JSBA App

- [x] Players data (`players` collection)
- [x] Training sessions (`training` collection)
- [x] Attendance records (`attendance` collection)
- [x] Invoices (`invoices` collection)
- [x] Receipts (`receipts` collection)
- [x] Announcements (`announcements` collection)
- [x] Player comments (`player_comments` collection)
- [x] Player progress (`player_progress` collection)
- [x] Court signups (`court_signups` collection)
- [x] Kid availability (`kid_availability` collection)

### JSBA App Access Control

| Collection | Parent Access | Coach Access |
|------------|--------------|--------------|
| users | Read profile | Read profile |
| players | Read own kids | Read assigned |
| training | Read registered | Read/Write assigned |
| attendance | Read own | Read/Write |
| invoices | Read own | Read |
| receipts | Read own | Read |
| player_comments | Read own | Read/Write |
| player_progress | Read own | Read/Write |
| court_signups | Read/Write own | Read |
| kid_availability | Read/Write own | Read |

---

## Next Steps

1. **Copy models** from JuniorShuttlers to JSBA app (`lib/app/model/`)
2. **Add services** for each collection (`lib/app/service/`)
3. **Create ViewModels** for each module (`lib/app/viewmodel/`)
4. **Implement UI pages** based on priority
5. **Test data sync** between admin and client apps
