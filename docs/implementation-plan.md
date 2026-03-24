# JSBA App Implementation Plan - Feature by Feature

## Approach
Implement feature by feature, starting with Coach features, then Parent/Viewer features.

---

## Feature 1: Authentication & Role Management

### Tasks
- [ ] Update `user_model.dart` to support parent/coach roles
- [ ] Update `auth_service.dart` for role-based login
- [ ] Update `auth_view_model.dart` for role detection
- [ ] Enhance login landing page for role selection
- [ ] Configure routing based on role (coach vs parent)

### Files
- `lib/app/model/user_model.dart` - modify
- `lib/app/service/auth_service.dart` - modify
- `lib/app/viewmodel/auth_view_model.dart` - modify
- `lib/app/view/auth/login_landing_page.dart` - modify
- `lib/app/assets/router/app_router.dart` - modify

---

## Feature 2: Coach - Players Management

### Tasks
- [ ] Copy `player_model.dart` from JuniorShuttlers (sync fields)
- [ ] Update `player_service.dart` to fetch players by coach
- [ ] Create/get `coach_view_model.dart` players list
- [ ] Enhance `players_page.dart` for coach view
- [ ] Create `player_details_page.dart`

### Files
- `lib/app/model/player_model.dart` - sync
- `lib/app/service/player_service.dart` - modify
- `lib/app/view/coach/players_page.dart` - modify
- `lib/app/view/coach/player_details_page.dart` - exists, enhance

### Dependencies
- Requires: Feature 1 (Auth)

---

## Feature 3: Coach - Sessions/Training Management

### Tasks
- [ ] Copy/sync `training_model.dart` from JuniorShuttlers
- [ ] Update `training_service.dart` - fetch sessions by coach
- [ ] Create sessions list in `coach_view_model.dart`
- [ ] Enhance `sessions_page.dart`
- [ ] Enhance `create_session_page.dart`
- [ ] Create `session_details_page.dart`

### Files
- `lib/app/model/training_model.dart` - sync
- `lib/app/service/training_service.dart` - modify
- `lib/app/view/coach/sessions_page.dart` - modify
- `lib/app/view/coach/create_session_page.dart` - exists, enhance
- `lib/app/view/coach/session_details_page.dart` - exists, enhance

### Dependencies
- Requires: Feature 2 (Players)

---

## Feature 4: Coach - Attendance Management

### Tasks
- [ ] Create `attendance_model.dart` (copy from JuniorShuttlers)
- [ ] Create `attendance_service.dart`
- [ ] Create `attendance_view_model.dart`
- [ ] Create `take_attendance_page.dart`
- [ ] Link attendance to session in sessions page

### Files
- `lib/app/model/attendance_model.dart` - new
- `lib/app/service/attendance_service.dart` - new
- `lib/app/viewmodel/attendance_view_model.dart` - new
- `lib/app/view/coach/take_attendance_page.dart` - new

### Dependencies
- Requires: Feature 3 (Sessions)

---

## Feature 5: Coach - Player Comments/Feedback

### Tasks
- [ ] Create `player_comment_model.dart`
- [ ] Create `comment_service.dart`
- [ ] Create `comments_view_model.dart`
- [ ] Create `add_comment_page.dart`
- [ ] Create `player_comments_page.dart` (coach view)

### Files
- `lib/app/model/player_comment_model.dart` - new
- `lib/app/service/comment_service.dart` - new
- `lib/app/viewmodel/comments_view_model.dart` - new
- `lib/app/view/coach/add_comment_page.dart` - new
- `lib/app/view/coach/player_comments_page.dart` - new

### Dependencies
- Requires: Feature 2 (Players)

---

## Feature 6: Coach - Player Progress Tracking

### Tasks
- [ ] Create `player_progress_model.dart` (from JuniorShuttlers)
- [ ] Create `progress_service.dart`
- [ ] Create `progress_view_model.dart`
- [ ] Create `update_progress_page.dart`
- [ ] Create `player_progress_page.dart` (coach view)

### Files
- `lib/app/model/player_progress_model.dart` - new
- `lib/app/service/progress_service.dart` - new
- `lib/app/viewmodel/progress_view_model.dart` - new
- `lib/app/view/coach/update_progress_page.dart` - new
- `lib/app/view/coach/player_progress_page.dart` - new

### Dependencies
- Requires: Feature 2 (Players)

---

## Feature 7: Coach - Dashboard

### Tasks
- [ ] Enhance `coach_dashboard_page.dart`
- [ ] Show today's sessions
- [ ] Show total players count
- [ ] Show quick stats
- [ ] Add announcements section
- [ ] Add quick actions

### Files
- `lib/app/view/coach/coach_dashboard_page.dart` - modify

### Dependencies
- Requires: Features 2, 3, 4 (Players, Sessions, Attendance)

---

## Feature 8: Coach - Billing/Earnings

### Tasks
- [ ] Copy/sync `invoice_model.dart`
- [ ] Copy `receipt_model.dart`
- [ ] Update `billing_service.dart`
- [ ] Create `coach_earnings_page.dart`
- [ ] Show earnings summary

### Files
- `lib/app/model/invoice_model.dart` - sync
- `lib/app/model/receipt_model.dart` - new
- `lib/app/service/billing_service.dart` - modify
- `lib/app/view/coach/coach_earnings_page.dart` - new

### Dependencies
- Requires: Features 1-7

---

## ================================

## Feature 9: Parent - My Kids Management

### Tasks
- [ ] Update `parent_view_model.dart` - fetch kids by parent
- [ ] Enhance `my_kids_page.dart`
- [ ] Enhance `add_child_page.dart`
- [ ] Enhance `child_details_page.dart`
- [ ] Create link to player via `parentId`

### Files
- `lib/app/view/parent/my_kids_page.dart` - modify
- `lib/app/view/parent/add_child_page.dart` - modify
- `lib/app/view/parent/child_details_page.dart` - modify
- `lib/app/viewmodel/parent_view_model.dart` - modify

### Dependencies
- Requires: Feature 1 (Auth)

---

## Feature 10: Parent - Sessions View

### Tasks
- [ ] Update `training_service.dart` - fetch by player
- [ ] Create `sessions_view_model.dart`
- [ ] Enhance `session_slots_page.dart` (view available)
- [ ] Create `register_session_page.dart`
- [ ] Show child's registered sessions

### Files
- `lib/app/service/training_service.dart` - modify
- `lib/app/viewmodel/sessions_view_model.dart` - new
- `lib/app/view/parent/session_slots_page.dart` - modify
- `lib/app/view/parent/register_session_page.dart` - new

### Dependencies
- Requires: Feature 9 (My Kids)

---

## Feature 11: Parent - Attendance View

### Tasks
- [ ] Update `attendance_service.dart` - fetch by player
- [ ] Create `child_attendance_page.dart`
- [ ] Show attendance history
- [ ] Show status (present/absent/late)

### Files
- `lib/app/service/attendance_service.dart` - modify
- `lib/app/view/parent/child_attendance_page.dart` - new

### Dependencies
- Requires: Feature 10 (Sessions)

---

## Feature 12: Parent - Billing/Invoices

### Tasks
- [ ] Update `billing_service.dart` - fetch by parent
- [ ] Create `invoices_view_model.dart`
- [ ] Enhance `parent_invoices_page.dart`
- [ ] Enhance `invoice_details_page.dart`
- [ ] Create `receipt_details_page.dart`
- [ ] Create `payment_history_page.dart`

### Files
- `lib/app/service/billing_service.dart` - modify
- `lib/app/viewmodel/invoices_view_model.dart` - new
- `lib/app/view/parent/parent_invoices_page.dart` - modify
- `lib/app/view/parent/invoice_details_page.dart` - modify
- `lib/app/view/parent/receipt_details_page.dart` - new
- `lib/app/view/parent/payment_history_page.dart` - new

### Dependencies
- Requires: Feature 9 (My Kids)

---

## Feature 13: Parent - Progress Reports View

### Tasks
- [ ] Update `progress_service.dart` - fetch by player
- [ ] Create `child_progress_page.dart`
- [ ] Show skill progress dashboard
- [ ] Show by category

### Files
- `lib/app/service/progress_service.dart` - modify
- `lib/app/view/parent/child_progress_page.dart` - new

### Dependencies
- Requires: Feature 9 (My Kids)

---

## Feature 14: Parent - Comments/Feedback View

### Tasks
- [ ] Update `comment_service.dart` - fetch by player
- [ ] Create `child_comments_page.dart`
- [ ] Show coach comments
- [ ] Filter by category

### Files
- `lib/app/service/comment_service.dart` - modify
- `lib/app/view/parent/child_comments_page.dart` - new

### Dependencies
- Requires: Feature 9 (My Kids)

---

## Feature 15: Parent - Court Booking

### Tasks
- [ ] Create `court_signup_model.dart`
- [ ] Create `court_service.dart`
- [ ] Create `court_booking_view_model.dart`
- [ ] Enhance `court_bookings_page.dart`
- [ ] Create `create_booking_page.dart`
- [ ] Create `booking_details_page.dart`

### Files
- `lib/app/model/court_signup_model.dart` - new
- `lib/app/service/court_service.dart` - new
- `lib/app/viewmodel/court_booking_view_model.dart` - new
- `lib/app/view/parent/court_bookings_page.dart` - modify
- `lib/app/view/parent/create_booking_page.dart` - modify
- `lib/app/view/parent/booking_details_page.dart` - new

### Dependencies
- Requires: Feature 9 (My Kids)

---

## Feature 16: Parent - Availability Setting

### Tasks
- [ ] Create `kid_availability_model.dart`
- [ ] Create `availability_service.dart`
- [ ] Create `availability_view_model.dart`
- [ ] Create `set_availability_page.dart`

### Files
- `lib/app/model/kid_availability_model.dart` - new
- `lib/app/service/availability_service.dart` - new
- `lib/app/viewmodel/availability_view_model.dart` - new
- `lib/app/view/parent/set_availability_page.dart` - new

### Dependencies
- Requires: Feature 9 (My Kids)

---

## Feature 17: Parent - Dashboard

### Tasks
- [ ] Enhance `parent_dashboard_page.dart`
- [ ] Show welcome + kids
- [ ] Show upcoming sessions
- [ ] Show quick actions
- [ ] Show announcements

### Files
- `lib/app/view/parent/parent_dashboard_page.dart` - modify

### Dependencies
- Requires: Features 9-16

---

## ================================

## Feature 18: Shared - Announcements

### Tasks
- [ ] Create `announcement_model.dart`
- [ ] Create `announcement_service.dart`
- [ ] Create `announcement_view_model.dart`
- [ ] Enhance `announcements_page.dart`
- [ ] Enhance `announcement_details_page.dart`

### Files
- `lib/app/model/announcement_model.dart` - new
- `lib/app/service/announcement_service.dart` - new
- `lib/app/viewmodel/announcement_view_model.dart` - new
- `lib/app/view/shared/announcements_page.dart` - modify
- `lib/app/view/shared/announcement_details_page.dart` - modify

### Dependencies
- Requires: Feature 1 (Auth)

---

## Feature 19: Shared - Profile Management

### Tasks
- [ ] Enhance `profile_page.dart`
- [ ] Enhance `edit_profile_page.dart`
- [ ] Create `change_password_page.dart`
- [ ] Add settings/notifications

### Files
- `lib/app/view/shared/profile_page.dart` - modify
- `lib/app/view/shared/edit_profile_page.dart` - modify
- `lib/app/view/shared/change_password_page.dart` - exists, enhance

### Dependencies
- Requires: Feature 1 (Auth)

---

## ================================

## Implementation Order Summary

### COACH FEATURES (Start Here)
1. Authentication & Role → Feature 1
2. Players → Feature 2
3. Sessions → Feature 3
4. Attendance → Feature 4
5. Comments → Feature 5
6. Progress → Feature 6
7. Dashboard → Feature 7
8. Billing → Feature 8

### PARENT FEATURES (After Coach)
9. My Kids → Feature 9
10. Sessions View → Feature 10
11. Attendance View → Feature 11
12. Billing → Feature 12
13. Progress View → Feature 13
14. Comments View → Feature 14
15. Court Booking → Feature 15
16. Availability → Feature 16
17. Dashboard → Feature 17

### SHARED FEATURES (Anytime)
18. Announcements → Feature 18
19. Profile → Feature 19

---

## Quick Reference: Files to Create

### New Models (11 files)
```
lib/app/model/
├── user_model.dart (modify)
├── attendance_model.dart (new)
├── receipt_model.dart (new)
├── announcement_model.dart (new)
├── player_comment_model.dart (new)
├── player_progress_model.dart (new)
├── court_signup_model.dart (new)
└── kid_availability_model.dart (new)
```

### New Services (6 files)
```
lib/app/service/
├── announcement_service.dart (new)
├── comment_service.dart (new)
├── progress_service.dart (new)
├── court_service.dart (new)
└── availability_service.dart (new)
```

### New ViewModels (9 files)
```
lib/app/viewmodel/
├── sessions_view_model.dart (new)
├── attendance_view_model.dart (new)
├── invoices_view_model.dart (new)
├── announcement_view_model.dart (new)
├── comments_view_model.dart (new)
├── progress_view_model.dart (new)
├── court_booking_view_model.dart (new)
└── availability_view_model.dart (new)
```

### New UI Pages (~20 files)
```
Coach: take_attendance, add_comment, update_progress, coach_earnings
Parent: child_attendance, receipt_details, child_progress, 
         child_comments, set_availability, booking_details,
         register_session, payment_history
Shared: (enhancements to existing)
```
