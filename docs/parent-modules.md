# Parent Module Specifications

## 1. Dashboard Module

### Features
- **Announcements Display**: Show latest academy announcements
- **Kids' Sessions**: Upcoming sessions for all registered children

### Data Required
- Announcements from `/announcements`
- Sessions from `/sessions` filtered by player's sessions

---

## 2. My Kids Module

### Features
- **Add Child**: Create child profile with name, age, skill level
- **Manage Children**: Edit/delete child profiles
- **View Details**: See assigned coach, skill level

### Data Required
- Players from `/players` with parentId filter

---

## 3. Progress Reports Module

### Features
- **View Reports**: See coach comments for each child
- **Rating Display**: View performance ratings
- **Historical Progress**: Track improvement over time

### Data Required
- Player comments from `/player_comments`
- Players from `/players`

---

## 4. Court Booking Module

### Features
- **Volunteer to Book**: First parent to volunteer books the court
- **View Bookings**: See all available court bookings
- **Manage Booking**: Cancel or modify booking (if organizer)

### Data Required
- Court bookings from `/court_bookings`

---

## 5. Session Slots Module

### Features
- **View Open Slots**: See available session slots
- **Register Child**: Sign up child for available sessions
- **View Registered**: See all registered sessions

### Data Required
- Sessions from `/sessions` with status filter
- Court bookings from `/court_bookings`

---

## 6. Invoices Module

### Features
- **View Invoices**: List of all invoices (session/monthly)
- **Invoice Details**: Itemized breakdown
- **Payment Status**: Pending/paid status
- **Receipts**: Download payment receipts

### Data Required
- Invoices from `/invoices` with parentId filter

---

## 7. Profile Module

### Features
- **Edit Profile**: Name, phone, email
- **Settings**: Notification preferences
- **Logout**: Sign out functionality

### Data Required
- User data from `/users/{userId}`
