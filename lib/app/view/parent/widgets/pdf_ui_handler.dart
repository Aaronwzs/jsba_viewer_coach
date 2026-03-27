import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

typedef PdfBuilder = Future<Uint8List> Function();

class PdfUiHandler {
  final BuildContext context;
  final PdfBuilder pdfBuilder;
  final String documentNumber;
  final String documentType;

  PdfUiHandler({
    required this.context,
    required this.pdfBuilder,
    required this.documentNumber,
    required this.documentType,
  });

  List<Widget> buildAppBarActions() {
    return [
      IconButton(
        onPressed: _previewPdf,
        icon: const Icon(Icons.preview_rounded),
        color: Colors.black,
        tooltip: 'Preview PDF',
      ),
      IconButton(
        onPressed: _sharePdf,
        icon: const Icon(Icons.share),
        color: Colors.black,
        tooltip: 'Share PDF',
      ),
    ];
  }

  Future<void> _previewPdf() async {
    final bytes = await pdfBuilder();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(8),
        contentPadding: const EdgeInsets.all(8),
        content: SizedBox(
          width: double.maxFinite,
          height: 600,
          child: PdfPreview(
            build: (_) async => bytes,
            maxPageWidth: 700,
            canChangePageFormat: false,
            allowPrinting: false,
            allowSharing: false,
            useActions: false,
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf() async {
    try {
      final bytes = await pdfBuilder();
      if (!context.mounted) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$documentNumber.pdf');
      await file.writeAsBytes(bytes);
      if (!context.mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? Rect.zero
          : box.localToGlobal(Offset.zero) & box.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$documentType $documentNumber',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    }
  }
}
