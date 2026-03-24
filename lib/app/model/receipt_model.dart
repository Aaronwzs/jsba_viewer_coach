import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptModel {
  final String id;
  final String receiptNumber;
  final String invoiceId;
  final String playerId;
  final String? playerName;
  final double amountPaid;
  final String paymentMethod;
  final String? paymentReference;
  final DateTime issuedAt;
  final String? notes;
  final String currency;
  final String billingPeriodKey;
  // Billing recipient fields
  final String? billToName;
  final String? billToPhone;
  final String? billToEmail;
  final String? billToType;
  final String? billingPlayerName;
  // Family invoice: list of all player IDs
  final List<String> playerIds;

  ReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.invoiceId,
    required this.playerId,
    this.playerName,
    required this.amountPaid,
    required this.paymentMethod,
    this.paymentReference,
    required this.issuedAt,
    this.notes,
    this.currency = 'RM',
    required this.billingPeriodKey,
    this.billToName,
    this.billToPhone,
    this.billToEmail,
    this.billToType,
    this.billingPlayerName,
    this.playerIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'receiptNumber': receiptNumber,
    'invoiceId': invoiceId,
    'playerId': playerId,
    'playerName': playerName,
    'amountPaid': amountPaid,
    'paymentMethod': paymentMethod,
    'paymentReference': paymentReference,
    'issuedAt': Timestamp.fromDate(issuedAt),
    'notes': notes,
    'currency': currency,
    'billingPeriodKey': billingPeriodKey,
    'billToName': billToName,
    'billToPhone': billToPhone,
    'billToEmail': billToEmail,
    'billToType': billToType,
    'billingPlayerName': billingPlayerName,
    'playerIds': playerIds,
  };

  factory ReceiptModel.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? issuedAt;
    final issuedAtField = map['issuedAt'];
    if (issuedAtField is Timestamp) {
      issuedAt = issuedAtField.toDate();
    } else if (issuedAtField is DateTime) {
      issuedAt = issuedAtField;
    } else {
      issuedAt = DateTime.now();
    }

    final playerIdsList = (map['playerIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    return ReceiptModel(
      id: id,
      receiptNumber: map['receiptNumber'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String?,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      paymentReference: map['paymentReference'] as String?,
      issuedAt: issuedAt,
      notes: map['notes'] as String?,
      currency: map['currency'] as String? ?? 'RM',
      billingPeriodKey: map['billingPeriodKey'] as String? ?? '',
      billToName: map['billToName'] as String?,
      billToPhone: map['billToPhone'] as String?,
      billToEmail: map['billToEmail'] as String?,
      billToType: map['billToType'] as String?,
      billingPlayerName: map['billingPlayerName'] as String?,
      playerIds: playerIdsList,
    );
  }
}
