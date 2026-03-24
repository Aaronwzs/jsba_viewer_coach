# Services Layer Specification

## Overview

The services layer handles all communication between the Flutter app and Firebase. Each service is responsible for a specific domain of functionality.

---

## AuthService

### Responsibilities
- User authentication (email/password)
- OTP verification
- Password reset
- Session management
- Role detection

### Key Methods

```dart
class AuthService {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String email, String password, String role);
  Future<void> signOut();
  Future<String?> getCurrentUserId();
  Future<String?> getUserRole(String userId);
  Future<void> resetPassword(String email);
}
```

---

## DatabaseService

### Responsibilities
- Generic Firestore operations
- Collection access
- Document CRUD operations
- Real-time listeners

### Key Methods

```dart
class DatabaseService {
  Future<DocumentSnapshot> getDocument(String collection, String docId);
  Future<List<DocumentSnapshot>> getCollection(String collection);
  Future<void> setDocument(String collection, String docId, Map data);
  Future<void> updateDocument(String collection, String docId, Map data);
  Future<void> deleteDocument(String collection, String docId);
  Stream<QuerySnapshot> listenToCollection(String collection);
}
```

---

## PlayerService

### Responsibilities
- Player profile management
- Parent-children relationships
- Coach-player assignments

### Key Methods

```dart
class PlayerService {
  Future<void> createPlayer(Player player);
  Future<void> updatePlayer(String playerId, Map data);
  Future<Player?> getPlayer(String playerId);
  Future<List<Player>> getPlayersByParent(String parentId);
  Future<List<Player>> getPlayersByCoach(String coachId);
  Future<void> assignCoach(String playerId, String coachId);
}
```

---

## TrainingService

### Responsibilities
- Session management
- Coaching programs
- Court bookings

### Key Methods

```dart
class TrainingService {
  Future<void> createSession(Session session);
  Future<void> updateSession(String sessionId, Map data);
  Future<List<Session>> getSessionsByCoach(String coachId);
  Future<List<Session>> getSessionsByPlayer(String playerId);
  Future<void> registerPlayer(String sessionId, String playerId);
  
  Future<void> createProgram(CoachingProgram program);
  Future<List<CoachingProgram>> getProgramsByCoach(String coachId);
  
  Future<void> createBooking(CourtBooking booking);
  Future<List<CourtBooking>> getOpenBookings();
  Future<void> registerPlayerToBooking(String bookingId, String playerId);
}
```

---

## AttendanceService

### Responsibilities
- Session attendance tracking
- Present/absent marking

### Key Methods

```dart
class AttendanceService {
  Future<void> markAttendance(String sessionId, String playerId, String status);
  Future<List<AttendanceRecord>> getAttendanceBySession(String sessionId);
  Future<List<AttendanceRecord>> getAttendanceByPlayer(String playerId);
}
```

---

## BillingService

### Responsibilities
- Invoice generation
- Payment tracking
- Coach payouts

### Key Methods

```dart
class BillingService {
  Future<void> createInvoice(Invoice invoice);
  Future<List<Invoice>> getInvoicesByParent(String parentId);
  Future<void> markInvoicePaid(String invoiceId);
  
  Future<void> createPayout(CoachPayout payout);
  Future<List<CoachPayout>> getPayoutsByCoach(String coachId);
  Future<void> updatePayoutStatus(String payoutId, String status);
}
```
