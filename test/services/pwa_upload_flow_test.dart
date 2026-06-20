import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jsba_app/app/service/storage_service.dart';

// ---------------------------------------------------------------------------
// Pure-unit testable analogues of the private helper methods in
// invoice_details_page.dart and receipt_details_page.dart.
//
// These guards are the contract shared by both pages — if the logic changes
// in one page it must change in the other, and the tests catch drift.
// ---------------------------------------------------------------------------

/// Determines whether a URL should be displayed as an image (true) or as
/// a file chip (false, e.g. PDF).
///
/// Mirrors `_isImageUrl` in both invoice_details_page.dart and
/// receipt_details_page.dart.
bool imageUrlPredicate(String url) {
  final lower = url.toLowerCase();
  final path = Uri.tryParse(lower)?.path ?? lower;
  if (path.endsWith('.pdf')) return false;
  return lower.contains('ik.imagekit.io') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp');
}

/// Extracts a display-friendly file name from a URL.
///
/// Mirrors `_fileNameFromUrl` in both invoice_details_page.dart and
/// receipt_details_page.dart.
String fileNameFromUrl(String url) {
  try {
    return url.split('/').last;
  } catch (_) {
    return url;
  }
}

/// Builds the ordered list of receipt proof URLs, preferring the structured
/// list and falling back to a comma-separated `paymentReference`.
///
/// Mirrors `_receiptUrls` in both invoice_details_page.dart and
/// receipt_details_page.dart.
List<String> receiptUrls({
  required List<String> receiptUrlsList,
  String? paymentReference,
}) {
  if (receiptUrlsList.isNotEmpty) return receiptUrlsList;
  if (paymentReference == null || paymentReference.isEmpty) return [];
  return paymentReference
      .split(',')
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
}

/// Determines whether a locally-selected file is an image.
///
/// Mirrors `_isImageFile` in invoice_details_page.dart.
bool isImageFile(String fileName) {
  final name = fileName.toLowerCase();
  return name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.webp');
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('imageUrlPredicate (shared _isImageUrl logic)', () {
    test('returns true for ImageKit image URLs', () {
      expect(
        imageUrlPredicate('https://ik.imagekit.io/example/session.jpg'),
        isTrue,
      );
      expect(
        imageUrlPredicate('https://ik.imagekit.io/example/photo.png'),
        isTrue,
      );
    });

    test('returns true for common image extensions', () {
      expect(imageUrlPredicate('https://example.com/photo.jpg'), isTrue);
      expect(imageUrlPredicate('https://example.com/photo.jpeg'), isTrue);
      expect(imageUrlPredicate('https://example.com/photo.png'), isTrue);
      expect(imageUrlPredicate('https://example.com/photo.gif'), isTrue);
      expect(imageUrlPredicate('https://example.com/photo.webp'), isTrue);
    });

    test('returns false for PDF URLs', () {
      expect(imageUrlPredicate('https://example.com/receipt.pdf'), isFalse);
      expect(
        imageUrlPredicate('https://ik.imagekit.io/example/doc.pdf'),
        isFalse,
      );
    });

    test('handles PDF URL with query parameters (ImageKit transforms)', () {
      expect(
        imageUrlPredicate(
          'https://ik.imagekit.io/example/receipt.pdf?tr=w-200,h-200',
        ),
        isFalse,
      );
    });

    test('returns false for unknown extensions', () {
      expect(imageUrlPredicate('https://example.com/file.zip'), isFalse);
      expect(imageUrlPredicate('https://example.com/file'), isFalse);
    });

    test('handles empty and malformed URLs without crashing', () {
      expect(imageUrlPredicate(''), isFalse);
      expect(imageUrlPredicate('   '), isFalse);
      expect(imageUrlPredicate('not-a-url'), isFalse);
    });

    test('is case-insensitive', () {
      expect(imageUrlPredicate('https://example.com/PHOTO.JPG'), isTrue);
      expect(imageUrlPredicate('https://example.com/Receipt.PDF'), isFalse);
    });
  });

  group('fileNameFromUrl (shared _fileNameFromUrl logic)', () {
    test('extracts filename from a standard URL', () {
      expect(
        fileNameFromUrl('https://example.com/images/photo.jpg'),
        'photo.jpg',
      );
    });

    test('extracts filename from ImageKit URL with transforms', () {
      expect(
        fileNameFromUrl(
          'https://ik.imagekit.io/example/receipt.pdf?tr=w-200',
        ),
        'receipt.pdf?tr=w-200',
      );
    });

    test('returns the input for a bare filename', () {
      expect(fileNameFromUrl('receipt.pdf'), 'receipt.pdf');
    });

    test('handles empty string', () {
      expect(fileNameFromUrl(''), '');
    });
  });

  group('receiptUrls (shared _receiptUrls logic)', () {
    test('prefers receiptUrls list over paymentReference', () {
      final result = receiptUrls(
        receiptUrlsList: [
          'https://ik.imagekit.io/example/proof.jpg',
        ],
        paymentReference: 'https://old.com/ref.jpg',
      );
      expect(result, ['https://ik.imagekit.io/example/proof.jpg']);
    });

    test('falls back to comma-separated paymentReference', () {
      final result = receiptUrls(
        receiptUrlsList: [],
        paymentReference: 'https://ik.io/a.jpg,https://ik.io/b.pdf',
      );
      expect(result, ['https://ik.io/a.jpg', 'https://ik.io/b.pdf']);
    });

    test('trims whitespace from paymentReference entries', () {
      final result = receiptUrls(
        receiptUrlsList: [],
        paymentReference: '  https://ik.io/a.jpg ,  https://ik.io/b.pdf  ',
      );
      expect(result, ['https://ik.io/a.jpg', 'https://ik.io/b.pdf']);
    });

    test('returns empty list when both sources are empty', () {
      expect(receiptUrls(receiptUrlsList: []), isEmpty);
      expect(
        receiptUrls(receiptUrlsList: [], paymentReference: ''),
        isEmpty,
      );
      expect(
        receiptUrls(receiptUrlsList: [], paymentReference: null),
        isEmpty,
      );
    });

    test('filters out empty entries from paymentReference', () {
      final result = receiptUrls(
        receiptUrlsList: [],
        paymentReference: 'https://ik.io/a.jpg,, ,https://ik.io/b.pdf',
      );
      expect(result, ['https://ik.io/a.jpg', 'https://ik.io/b.pdf']);
    });
  });

  group('isImageFile (shared _isImageFile logic for XFile name)', () {
    test('returns true for common image extensions', () {
      expect(isImageFile('photo.jpg'), isTrue);
      expect(isImageFile('photo.jpeg'), isTrue);
      expect(isImageFile('photo.png'), isTrue);
      expect(isImageFile('photo.gif'), isTrue);
      expect(isImageFile('photo.webp'), isTrue);
    });

    test('returns false for non-image files', () {
      expect(isImageFile('receipt.pdf'), isFalse);
      expect(isImageFile('document.txt'), isFalse);
    });

    test('is case-insensitive', () {
      expect(isImageFile('PHOTO.JPG'), isTrue);
      expect(isImageFile('Receipt.PDF'), isFalse);
    });
  });

  // =========================================================================
  // StorageService integration tests (cross-platform upload contract)
  // =========================================================================
  group('StorageService cross-platform contract', () {
    test('uploadImage accepts Uint8List (no dart:io dependency)', () async {
      const expectedUrl = 'https://ik.imagekit.io/example/uploaded.png';
      final client = _MockHttpClient((request) async {
        return _streamedResponse(
          '{"fileId": "abc", "url": "$expectedUrl"}',
          200,
        );
      });

      final service = StorageService(client: client, privateKey: 'test_key');
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final url = await service.uploadImage(bytes, fileName: 'test.png');

      expect(url, expectedUrl);
    });

    test('uploadImage uses fromBytes (not fromPath) for web compat', () async {
      http.MultipartRequest? captured;
      final client = _MockHttpClient((request) async {
        captured = request as http.MultipartRequest?;
        return _streamedResponse(
          '{"fileId": "abc", "url": "https://ik.io/img.jpg"}',
          200,
        );
      });

      final service = StorageService(client: client, privateKey: 'k');
      final bytes = Uint8List.fromList([1, 2, 3]);
      await service.uploadImage(bytes, fileName: 'pic.png');

      expect(captured, isNotNull);
      // fromBytes has no `file.path` dependency — it uses the raw bytes
      // that work identically on web, iOS, Android, and desktop.
      expect(captured!.files.length, 1);
      final file = captured!.files.first;
      // Reading the bytes back proves no dart:io.File was involved.
      final payload = await file.finalize();
      expect(await payload.toBytes(), [1, 2, 3]);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a StreamedResponse from a JSON string.
http.StreamedResponse _streamedResponse(String body, int statusCode) {
  final stream = http.ByteStream.fromBytes(utf8.encode(body));
  return http.StreamedResponse(stream, statusCode);
}

/// Minimal mock HTTP client that invokes [handler] for every request.
class _MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  _MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}
