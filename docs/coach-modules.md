# Coach Module Specifications

## 1. Dashboard Module

### Features
- **Announcements Display**: Show latest academy announcements
- **Today's Sessions**: List of sessions scheduled for the current day
- **Quick Stats**: Overview metrics (total students, sessions this week, pending payments)

### Data Required
- Announcements from `/announcements`
- Sessions from `/sessions` filtered by today's date
- Stats aggregated from `/players`, `/sessions`, `/invoices`

---

## 2. Sessions Module

### Features
- **View All Sessions**: Calendar or list view of scheduled sessions
- **Filter by Type**: Private or group sessions
- **Session Details**: Date, time, court, rate, attending players

### Data Required
- Sessions from `/sessions` with coachId filter

---

## 3. Attendance Module

### Features
- **Mark Attendance**: Toggle present/absent for each player per session
- **Session Selection**: Choose which session to take attendance for
- **View History**: Past attendance records

### Data Required
- Sessions from `/sessions`
- Attendance records from `/attendance`

---

## 4. Coaching Program Module

### Features
- **Create Program**: Set title and goals (e.g., "improve footwork", "improve hitting")
- **Link Sessions**: Associate sessions with coaching programs
- **Track Progress**: Monitor player development across sessions

### Data Required
- Coaching programs from `/coaching_programs`
- Sessions from `/sessions`

---

## 5. Player Comments Module

### Features
- **Give Feedback**: Add comments for each player per session
- **Rating System**: Rate player performance (1-5 stars)
- **View History**: Past comments for each player

### Data Required
- Player comments from `/player_comments`
- Players from `/players`

---

## 6. Match Results Module

### Features
- **Record Results**: Enter wins/losses for match sessions
- **Track Partners**: Record who played with whom
- **Match History**: View past match results

### Data Required
- Matches from `/matches`
- Players from `/players`

---

## 7. Billing Module

### Features
- **View Earnings**: Total earnings, pending payouts
- **Bank Details**: Account name, account number, bank name
- **Payout Status**: Track pending/paid status

### Data Required
- Coach payouts from `/coach_payouts`
- Invoices from `/invoices`

---

## 8. Profile Module

### Features
- **Edit Profile**: Name, phone, email
- **Settings**: Notification preferences
- **Logout**: Sign out functionality

### Data Required
- User data from `/users/{userId}`
