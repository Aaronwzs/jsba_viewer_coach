# Feedback & Bug Report Feature Design

## Overview
Add a Feedback and Bug Report feature accessible from the FAQ page, allowing users to submit feedback or report bugs directly from the app.

## Location
- FAQ page at the bottom
- Banner/button: "Saw a bug? or want to leave a feedback about the app? Check it out here."

## Firestore Collection

### Collection Name
`feedback`

### Document Structure

```dart
{
  type: 'bug' | 'feedback',
  category: 'general' | 'suggestion' | 'complaint' | 'praise', // for feedback only
  title: String,
  description: String,
  stepsToReproduce: String, // bug only
  expectedBehavior: String, // bug only
  actualBehavior: String, // bug only
  screenshotUrl: String?, // bug only
  userId: String,
  deviceInfo: {
    model: String,
    osVersion: String,
    appVersion: String,
  },
  createdAt: Timestamp,
  status: 'pending' | 'reviewed' | 'resolved'
}
```

## Bug Report Fields
- Title (short description) - required
- Steps to reproduce - required
- Expected behavior - required
- Actual behavior - required
- Screenshot attachment - optional
- Auto-included: User ID, Device info (model, OS, app version)

## Feedback Fields
- Category: General, Suggestion, Complaint, Praise - required
- Title - required
- Description/Message - required
- Auto-included: User ID, Device info

## UI Flow
1. User taps banner on FAQ page
2. Modal/bottom sheet shows two options: "Report a Bug" or "Send Feedback"
3. User selects one → form appears
4. Submit → saves to Firestore → shows success message

## Implementation Components
1. Update FAQ page with banner at bottom
2. Create FeedbackReportPage with modal selection
3. Create BugReportForm widget
4. Create FeedbackForm widget
5. Add Firestore service for submitting feedback
6. Add device info helper utility
