import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Widget test for the proof-of-payment display tiles shared by
// invoice_details_page.dart and receipt_details_page.dart.
//
// The source pages use private methods (_buildReferenceProofs,
// _buildFileRefTile, _isImageUrl).  We re-declare the same contract here
// as a stand-alone widget so the visual behaviour can be tested without
// depending on the page-level wiring (Providers, router, Firestore, etc.).
//
// This test guards the public contract:
//   * image URLs are rendered as Image.network
//   * PDF URLs are rendered as a tappable file chip
//   * image loading errors fall back to the file chip
// ---------------------------------------------------------------------------

void main() {
  group('ProofDisplayWidget contract', () {
    testWidgets('image URL renders Image.network', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProofDisplayWidget(
            urls: ['https://ik.imagekit.io/example/session.jpg'],
          ),
        ),
      ));

      // The image network widget should be present.  We cannot assert it
      // loaded because the test has no real network, but the widget tree
      // should contain the Image widget.
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('image URL fallback shows file chip on load error',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProofDisplayWidget(
            urls: ['https://nonexistent.example.com/missing.jpg'],
          ),
        ),
      ));

      // After pumpAndSettle the Image.network will fire onError and the
      // fallback file chip should appear.  But since onError is async
      // and the test has no real network, we pump a frame to let the
      // error builder fire.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The fallback should be present — a GestureDetector wrapping the
      // file chip container.
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('PDF URL renders file chip (not Image)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProofDisplayWidget(
            urls: ['https://ik.imagekit.io/example/receipt.pdf'],
          ),
        ),
      ));

      // No Image widget should be present for PDFs.
      expect(find.byType(Image), findsNothing);

      // A tappable file chip should render instead.
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('multiple URLs render multiple tiles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProofDisplayWidget(
            urls: [
              'https://ik.imagekit.io/example/proof.jpg',
              'https://ik.imagekit.io/example/doc.pdf',
            ],
          ),
        ),
      ));

      // One image + one PDF chip = one Image + one GestureDetector.
      expect(find.byType(Image), findsOneWidget);
      // The image errorBuilder also returns a GestureDetector fallback, but
      // since the image URL is valid-format (not loaded), the errorBuilder
      // won't fire in a standard pump.  So we should see exactly 1
      // GestureDetector for the PDF chip.
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('empty URL list renders nothing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProofDisplayWidget(urls: const []),
        ),
      ));

      expect(find.byType(Image), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('file chip shows PDF icon and open-in-new icon',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProofDisplayWidget(
            urls: ['https://example.com/document.pdf'],
          ),
        ),
      ));

      // The chip should display the PDF icon (red) and open-in-new icon.
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });
  });
}

// ============================================================================
// Testable stand-in for the private _buildReferenceProofs + _buildFileRefTile
// from invoice_details_page.dart and receipt_details_page.dart.
// ============================================================================

/// Renders proof-of-payment references exactly as the real pages do:
///   - Image URLs → ClipRRect(Image.network(...)) with error fallback
///   - PDF URLs → clickable file chip
class ProofDisplayWidget extends StatelessWidget {
  final List<String> urls;

  const ProofDisplayWidget({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: urls.map((url) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: _isImageUrl(url)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFileRefTile(url);
                    },
                  ),
                )
              : _buildFileRefTile(url),
        );
      }).toList(),
    );
  }

  bool _isImageUrl(String url) {
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

  String _fileNameFromUrl(String url) {
    try {
      return url.split('/').last;
    } catch (_) {
      return url;
    }
  }

  Widget _buildFileRefTile(String url) {
    return GestureDetector(
      onTap: () {
        // In the real app this calls url_launcher.launchUrl.
        // The test only checks that the widget renders.
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
            const SizedBox(width: 6),
            Text(
              _fileNameFromUrl(url),
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade400),
          ],
        ),
      ),
    );
  }
}
