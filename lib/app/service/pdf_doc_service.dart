import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:jsba_app/app/model/invoice_model.dart';
import 'package:jsba_app/app/model/invoice_profile_model.dart';
import 'package:jsba_app/app/model/receipt_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static final PdfColor primaryColor = PdfColor.fromHex('#2E7D32');
  static final PdfColor accentColor = PdfColor.fromHex('#F57C00');
  static final PdfColor darkGray = PdfColor.fromHex('#212121');
  static final PdfColor mediumGray = PdfColor.fromHex('#757575');
  static final PdfColor lightGray = PdfColor.fromHex('#F5F5F5');
  static final PdfColor borderColor = PdfColor.fromHex('#E0E0E0');

  Future<pw.ThemeData> _buildTheme() async {
    final emojiFont = await PdfGoogleFonts.notoEmojiRegular();
    return pw.ThemeData.withFont(fontFallback: [emojiFont]);
  }

  Future<pw.TextStyle> _emojiStyle({
    double fontSize = 16,
    PdfColor? color,
  }) async {
    final emojiFont = await PdfGoogleFonts.notoEmojiRegular();
    return pw.TextStyle(font: emojiFont, fontSize: fontSize, color: color);
  }

  Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required InvoiceProfile profile,
    Uint8List? logoBytes,
    Uint8List? duitNowQrBytes,
  }) async {
    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final currency = invoice.currency;
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final duitNowQr = duitNowQrBytes != null
        ? pw.MemoryImage(duitNowQrBytes)
        : null;

    pdf.addPage(
      _buildInvoicePage(
        invoice: invoice,
        profile: profile,
        logo: logo,
        duitNowQr: duitNowQr,
        currency: currency,
      ),
    );

    final bytes = await pdf.save();
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List> generateReceiptPdf({
    required ReceiptModel receipt,
    required InvoiceProfile profile,
    Uint8List? logoBytes,
    Uint8List? duitNowQrBytes,
  }) async {
    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final currency = receipt.currency;
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final duitNowQr = duitNowQrBytes != null
        ? pw.MemoryImage(duitNowQrBytes)
        : null;

    pdf.addPage(
      await _buildReceiptPage(
        receipt: receipt,
        profile: profile,
        logo: logo,
        duitNowQr: duitNowQr,
        currency: currency,
      ),
    );

    final bytes = await pdf.save();
    return Uint8List.fromList(bytes);
  }

  // ============================================================================
  // INVOICE PAGE
  // ============================================================================
  pw.Page _buildInvoicePage({
    required InvoiceModel invoice,
    required InvoiceProfile profile,
    required pw.ImageProvider? logo,
    required pw.ImageProvider? duitNowQr,
    required String currency,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        _buildHeader(
          profile: profile,
          logo: logo,
          documentType: 'INVOICE',
          documentNumber: invoice.invoiceNumber,
          color: primaryColor,
        ),
        pw.SizedBox(height: 32),

        // Bill To & Invoice Details
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildInfoBox(
                title: 'BILL TO',
                children: [
                  pw.Text(
                    _getBillingDisplayName(invoice),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: darkGray,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.billToPhone ?? invoice.playerPhone,
                    style: pw.TextStyle(fontSize: 10, color: mediumGray),
                  ),
                  if (invoice.billToEmail != null &&
                      invoice.billToEmail!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      invoice.billToEmail!,
                      style: pw.TextStyle(fontSize: 10, color: mediumGray),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildInfoBox(
                title: 'DETAILS',
                children: [
                  _buildKeyValue(
                    'Period',
                    _formatPeriod(invoice.billingYear, invoice.billingMonth),
                  ),
                  pw.SizedBox(height: 4),
                  _buildKeyValue(
                    'Status',
                    invoice.status.toUpperCase(),
                    valueColor: invoice.status == 'paid'
                        ? primaryColor
                        : PdfColor.fromHex('#F59E0B'),
                  ),
                  if (profile.dueDateNote.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _buildKeyValue('Due', profile.dueDateNote),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 24),

        // Line Items
        _buildLineItemsTable(invoice.lineItems, currency),
        pw.SizedBox(height: 24),

        // Totals
        _buildTotalsBox(
          subTotal: invoice.subTotal,
          discount: invoice.discountAmount,
          tax: invoice.taxAmount,
          total: invoice.totalAmount,
          currency: currency,
        ),
        pw.SizedBox(height: 24),

        // Payment Info
        _buildPaymentInfo(profile, duitNowQr),
      ],
    );
  }

  // ============================================================================
  // RECEIPT PAGE
  // ============================================================================
  Future<pw.Page> _buildReceiptPage({
    required ReceiptModel receipt,
    required InvoiceProfile profile,
    required pw.ImageProvider? logo,
    required pw.ImageProvider? duitNowQr,
    required String currency,
  }) async {
    final methodLabel = _getMethodLabel(receipt.paymentMethod);
    final checkmarkStyle = await _emojiStyle(fontSize: 28, color: primaryColor);

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        _buildHeader(
          profile: profile,
          logo: logo,
          documentType: 'RECEIPT',
          documentNumber: receipt.receiptNumber,
          color: accentColor,
        ),
        pw.SizedBox(height: 32),

        // Amount Received Banner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [accentColor, PdfColor.fromHex('#C62828')],
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'AMOUNT RECEIVED',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                '$currency ${receipt.amountPaid.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // Receipt Details
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildInfoBox(
                title: 'RECEIVED FROM',
                children: [
                  pw.Text(
                    _getReceiptDisplayName(receipt),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: darkGray,
                    ),
                  ),
                  if (receipt.billToPhone != null &&
                      receipt.billToPhone!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      receipt.billToPhone!,
                      style: pw.TextStyle(fontSize: 10, color: mediumGray),
                    ),
                  ],
                  if (receipt.billToEmail != null &&
                      receipt.billToEmail!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      receipt.billToEmail!,
                      style: pw.TextStyle(fontSize: 10, color: mediumGray),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildInfoBox(
                title: 'PAYMENT',
                children: [
                  _buildKeyValue(
                    'Date',
                    DateFormat('MMM dd, yyyy').format(receipt.issuedAt),
                  ),
                  pw.SizedBox(height: 4),
                  _buildKeyValue('Method', methodLabel),
                  if (receipt.paymentReference != null &&
                      receipt.paymentReference!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    _buildKeyValue('Ref', receipt.paymentReference!),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 32),

        // Thank You
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: borderColor),
          ),
          child: pw.Column(
            children: [
              pw.Text('✔', style: checkmarkStyle),
              pw.SizedBox(height: 8),
              pw.Text(
                'Thank you for your payment!',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: darkGray,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'We appreciate your business.',
                style: pw.TextStyle(fontSize: 10, color: mediumGray),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Footer
        pw.Center(
          child: pw.Text(
            'Generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: mediumGray),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // SHARED COMPONENTS
  // ============================================================================

  pw.Widget _buildHeader({
    required InvoiceProfile profile,
    required pw.ImageProvider? logo,
    required String documentType,
    required String documentNumber,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            pw.Container(
              width: 48,
              height: 48,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 16),
          ],

          // Academy Info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  profile.name.isNotEmpty
                      ? profile.name
                      : 'JSBA Badminton Academy',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: darkGray,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildContactList(profile),
              ],
            ),
          ),

          // Document Badge
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Text(
                  documentType,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                documentNumber,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: darkGray,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style: pw.TextStyle(fontSize: 9, color: mediumGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoBox({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: mediumGray,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildLineItemsTable(List<InvoiceLineItem> items, String currency) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: darkGray,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 2, child: _buildTableHeader('DATE')),
                pw.Expanded(flex: 5, child: _buildTableHeader('ITEM')),
                pw.Expanded(
                  flex: 2,
                  child: _buildTableHeader('QTY', align: pw.TextAlign.center),
                ),
                pw.Expanded(
                  flex: 2,
                  child: _buildTableHeader('PRICE', align: pw.TextAlign.right),
                ),
                pw.Expanded(
                  flex: 2,
                  child: _buildTableHeader('TOTAL', align: pw.TextAlign.right),
                ),
              ],
            ),
          ),

          // Rows
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;

            return pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: index.isEven ? PdfColors.white : lightGray,
                border: pw.Border(
                  bottom: isLast
                      ? pw.BorderSide.none
                      : pw.BorderSide(color: borderColor, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.date != null
                          ? DateFormat('MMM dd').format(item.date!)
                          : '-',
                      style: pw.TextStyle(fontSize: 9, color: darkGray),
                    ),
                  ),
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      item.title.length > 28
                          ? '${item.title.substring(0, 25)}...'
                          : item.title,
                      style: pw.TextStyle(fontSize: 9, color: darkGray),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.quantity.toString(),
                      style: pw.TextStyle(fontSize: 9, color: darkGray),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '$currency ${item.unitPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 9, color: mediumGray),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '$currency ${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text, {pw.TextAlign? align}) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        letterSpacing: 0.8,
      ),
      textAlign: align,
    );
  }

  pw.Widget _buildTotalsBox({
    required double subTotal,
    required double discount,
    required double tax,
    required double total,
    required String currency,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 260,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: lightGray,
            border: pw.Border.all(color: borderColor),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildTotalLine('Subtotal', subTotal, currency),
              if (discount > 0) ...[
                pw.SizedBox(height: 6),
                _buildTotalLine(
                  'Discount',
                  discount,
                  currency,
                  isNegative: true,
                ),
              ],
              if (tax > 0) ...[
                pw.SizedBox(height: 6),
                _buildTotalLine('Tax', tax, currency),
              ],
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: borderColor, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      '$currency ${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalLine(
    String label,
    double amount,
    String currency, {
    bool isNegative = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: mediumGray)),
        pw.Text(
          '${isNegative && amount > 0 ? '-' : ''}$currency ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: darkGray,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildKeyValue(String key, String value, {PdfColor? valueColor}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(key, style: pw.TextStyle(fontSize: 10, color: mediumGray)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? darkGray,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildContactList(InvoiceProfile profile) {
    final contactItems = <String>[];

    if (profile.email.isNotEmpty) contactItems.add(profile.email);
    if (profile.phone.isNotEmpty) contactItems.add(profile.phone);
    if (profile.website.isNotEmpty) contactItems.add(profile.website);

    final platformOrder = [
      'instagram',
      'facebook',
      'whatsapp',
      'tiktok',
      'twitter',
    ];
    final social =
        profile.socialMedia.entries
            .where((e) => e.value.trim().isNotEmpty)
            .toList()
          ..sort(
            (a, b) => platformOrder
                .indexOf(a.key)
                .compareTo(platformOrder.indexOf(b.key)),
          );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...contactItems.take(3).map((item) {
          final display = item.length > 35
              ? '${item.substring(0, 32)}...'
              : item;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              display,
              style: pw.TextStyle(fontSize: 9, color: mediumGray),
            ),
          );
        }),
        if (social.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          ...social.map((entry) {
            final icon = _getSocialIcon(entry.key);
            final platform = _getSocialAbbr(entry.key);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('$icon ', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    '$platform: ',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: mediumGray,
                    ),
                  ),
                  pw.Text(
                    entry.value,
                    style: pw.TextStyle(fontSize: 9, color: mediumGray),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  pw.Widget _buildPaymentInfo(
    InvoiceProfile profile,
    pw.ImageProvider? duitNowQr,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightGray,
        border: pw.Border.all(color: borderColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYMENT INFORMATION',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: darkGray,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (profile.bankAccount != null) ...[
                      pw.Text(
                        'Bank Transfer',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _buildPaymentLine('Bank', profile.bankAccount!.name),
                      _buildPaymentLine('Account', profile.bankAccount!.number),
                      _buildPaymentLine(
                        'Name',
                        profile.bankAccount!.holderName,
                      ),
                      pw.SizedBox(height: 12),
                    ],
                    if (profile.digitalWallet != null) ...[
                      pw.Text(
                        'Digital Wallets',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      if (profile.digitalWallet!.duitNowId.isNotEmpty)
                        _buildPaymentLine(
                          'DuitNow',
                          profile.digitalWallet!.duitNowId,
                        ),
                      if (profile.digitalWallet!.tngNumber.isNotEmpty)
                        _buildPaymentLine(
                          'TNG',
                          profile.digitalWallet!.tngNumber,
                        ),
                    ],
                  ],
                ),
              ),
              if (duitNowQr != null)
                pw.Container(
                  width: 90,
                  height: 90,
                  margin: const pw.EdgeInsets.only(left: 16),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: borderColor),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Image(duitNowQr, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Scan to Pay',
                        style: pw.TextStyle(fontSize: 7, color: mediumGray),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 9, color: mediumGray),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.length > 30 ? '${value.substring(0, 27)}...' : value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSocialAbbr(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'whatsapp':
        return 'WhatsApp';
      case 'tiktok':
        return 'TikTok';
      case 'twitter':
        return 'Twitter/X';
      default:
        return platform;
    }
  }

  String _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return '📷';
      case 'facebook':
        return '👍';
      case 'whatsapp':
        return '💬';
      case 'tiktok':
        return '🎵';
      case 'twitter':
        return '🐦';
      default:
        return '';
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _getBillingDisplayName(InvoiceModel invoice) {
    if (invoice.billToName != null && invoice.billToName!.isNotEmpty) {
      return invoice.billToName!;
    }
    return invoice.playerName;
  }

  String _getReceiptDisplayName(ReceiptModel receipt) {
    if (receipt.billToName != null && receipt.billToName!.isNotEmpty) {
      return receipt.billToName!;
    }
    return receipt.playerName ?? 'Unknown';
  }

  String _formatPeriod(int year, int month) {
    return DateFormat('MMMM yyyy').format(DateTime(year, month));
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Bank Transfer';
      case 'tng':
        return 'Touch n Go';
      case 'card':
        return 'Card';
      default:
        return method.toUpperCase();
    }
  }
}
