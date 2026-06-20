# PWA Upload & Proof Display — Cross-Platform Test Checklist

Test every row below on **all three** platform contexts:

| Platform | Context |
|----------|---------|
| ☐ | **iOS Safari → PWA** (Add to Home Screen) |
| ☐ | **Android Chrome → PWA** (Install / Add to Home Screen) |
| ☐ | **Desktop Browser** (Chrome / Edge / Safari) |

Use the app as a **parent** who has at least one invoice in "sent" (pending) state.

---

## 1. Profile Image Upload (Settings Page)

| # | Check | iOS PWA | Android PWA | Desktop Web |
|---|-------|---------|-------------|-------------|
| 1.1 | Tap avatar → bottom sheet appears with Gallery + Camera options | ☐ | ☐ | ☐ |
| 1.2 | "Choose from Gallery" opens the photo picker | ☐ | ☐ | ☐ |
| 1.3 | "Take a Photo" opens the camera (skip on desktop) | ☐ | ☐ | N/A |
| 1.4 | After selecting a photo, the crop UI appears | ☐ | ☐ | ☐ |
| 1.5 | After cropping, the new image is shown as a preview | ☐ | ☐ | ☐ |
| 1.6 | Tap "Save" → image uploads to ImageKit → success snackbar | ☐ | ☐ | ☐ |
| 1.7 | After save, re-open settings → old image replaced with new one | ☐ | ☐ | ☐ |
| 1.8 | One-image limit enforced: try to pick a second image while one is pending | ☐ | ☐ | ☐ |
| 1.9 | **Error handling:** turn off network → try to upload → error shown, data NOT saved | ☐ | ☐ | ☐ |

---

## 2. Invoice Payment — Image Upload

| # | Check | iOS PWA | Android PWA | Desktop Web |
|---|-------|---------|-------------|-------------|
| 2.1 | Open a "sent" invoice → "Pay Now" button visible | ☐ | ☐ | ☐ |
| 2.2 | Tap "Pay Now" → dialog appears with payment method + proof section | ☐ | ☐ | ☐ |
| 2.3 | Tap "Add Receipt File" → bottom sheet with "Add Image" option | ☐ | ☐ | ☐ |
| 2.4 | Tap "Add Image" → file picker opens with image filter | ☐ | ☐ | ☐ |
| 2.5 | Select a JPG/PNG → thumbnail preview appears in dialog | ☐ | ☐ | ☐ |
| 2.6 | Upload completes → green checkmark shows "Uploaded" | ☐ | ☐ | ☐ |
| 2.7 | "Submit Payment" button becomes enabled | ☐ | ☐ | ☐ |
| 2.8 | One-image limit enforced: "Add Image" is disabled after first upload | ☐ | ☐ | ☐ |
| 2.9 | Remove uploaded image with ✕ button → "Add Image" re-enabled | ☐ | ☐ | ☐ |

---

## 3. Invoice Payment — PDF Upload

| # | Check | iOS PWA | Android PWA | Desktop Web |
|---|-------|---------|-------------|-------------|
| 3.1 | Open invoice → tap "Pay Now" | ☐ | ☐ | ☐ |
| 3.2 | Tap "Add Receipt File" → bottom sheet shows "Add PDF" option | ☐ | ☐ | ☐ |
| 3.3 | Tap "Add PDF" → file picker opens with PDF filter | ☐ | ☐ | ☐ |
| 3.4 | Select a PDF → PDF icon preview appears in dialog | ☐ | ☐ | ☐ |
| 3.5 | Upload completes → green checkmark shows "Uploaded" | ☐ | ☐ | ☐ |
| 3.6 | Submit payment → success snackbar | ☐ | ☐ | ☐ |

---

## 4. Invoice — Viewing Proof After Submission

| # | Check | iOS PWA | Android PWA | Desktop Web |
|---|-------|---------|-------------|-------------|
| 4.1 | Invoice with image proof → "Awaiting Approval" section shows image thumbnail | ☐ | ☐ | ☐ |
| 4.2 | Invoice with PDF proof → "Awaiting Approval" section shows PDF chip | ☐ | ☐ | ☐ |
| 4.3 | Tap PDF chip → PDF opens in external viewer/browser | ☐ | ☐ | ☐ |
| 4.4 | Image thumbnail: verify it loads from ImageKit (not broken) | ☐ | ☐ | ☐ |
| 4.5 | PDF chip shows: PDF icon (red) + filename + open-in-new icon | ☐ | ☐ | ☐ |

---

## 5. Receipt — Viewing Proof After Approval

| # | Check | iOS PWA | Android PWA | Desktop Web |
|---|-------|---------|-------------|-------------|
| 5.1 | Open a paid invoice → "Payment Confirmed" section with receipt info | ☐ | ☐ | ☐ |
| 5.2 | If proof was an image → Image.network renders the thumbnail | ☐ | ☐ | ☐ |
| 5.3 | If proof was a PDF → PDF chip renders correctly | ☐ | ☐ | ☐ |
| 5.4 | Tap PDF chip → opens in external viewer/browser | ☐ | ☐ | ☐ |
| 5.5 | Open Receipt from invoice list → "Reference Proof" section shows same proof | ☐ | ☐ | ☐ |

---

## 6. PWA-Specific Behaviours

| # | Check | iOS PWA | Android PWA | Desktop Web |
|---|-------|---------|-------------|-------------|
| 6.1 | Install prompt appears on first visit (desktop and Android) | ☐ | ☐ | ☐ |
| 6.2 | App launches in standalone mode (no browser chrome) | ☐ | ☐ | N/A |
| 6.3 | **Offline:** Upload fails gracefully with error message (not a crash) | ☐ | ☐ | ☐ |
| 6.4 | **Slow network:** Upload shows spinner / "Uploading..." indicator | ☐ | ☐ | ☐ |
| 6.5 | Camera permission dialog appears on iOS (first camera use) | ☐ | N/A | N/A |
| 6.6 | Photo Library permission dialog appears on iOS (first gallery use) | ☐ | N/A | N/A |
| 6.7 | Service worker registered (check DevTools → Application → Service Workers) | ☐ | ☐ | N/A |

---

## Known Success Criteria

| Metric | Target |
|--------|--------|
| Image upload (JPG/PNG) to ImageKit | ≤ 5s on 4G |
| Image thumbnail load in UI | ≤ 3s on 4G |
| PDF chip tap → external viewer | ≤ 1s |
| Cropped profile image upload | ≤ 5s on 4G |
| No crashes on permission denial | Always |

---

## Automated Test Coverage Summary

| Test File | Tests | What It Covers |
|-----------|-------|----------------|
| `test/service/storage_service_test.dart` | 8 | Upload success, auth, error handling, missing key |
| `test/services/pwa_upload_flow_test.dart` | 21 | `_isImageUrl`, `_fileNameFromUrl`, `_receiptUrls`, `isImageFile`, StorageService Uint8List contract |
| `test/widgets/proof_display_widget_test.dart` | 6 | Image vs PDF rendering, empty list, error fallback, icon assertions |
| **Total** | **35** | |

> Run all automated tests: `flutter test`

---

*Last updated: 2026-06-20*
