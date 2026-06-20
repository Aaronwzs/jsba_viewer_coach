import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceLineItem {
  final String id;
  final String title;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? attendanceId;
  final String? trainingId;
  final DateTime? date;
  final String? attendanceStatus;
  final List<String> packageIds;

  InvoiceLineItem({
    required this.id,
    required this.title,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.attendanceId,
    this.trainingId,
    this.date,
    this.attendanceStatus,
    this.packageIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'attendanceId': attendanceId,
    'trainingId': trainingId,
    'date': date != null ? Timestamp.fromDate(date!) : null,
    'attendanceStatus': attendanceStatus,
    'packageIds': packageIds,
  };

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    DateTime? date;
    final dateField = map['date'];
    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is DateTime) {
      date = dateField;
    }

    return InvoiceLineItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      attendanceId: map['attendanceId'] as String?,
      trainingId: map['trainingId'] as String?,
      date: date,
      attendanceStatus: map['attendanceStatus'] as String?,
      packageIds: List<String>.from(map['packageIds'] ?? []),
    );
  }
}

class AppliedPromotionInfo {
  final String promotionPackageId;
  final String promotionPackageName;
  final int sessionsCount;
  final double discountAmount;
  final int batchCount;

  AppliedPromotionInfo({
    required this.promotionPackageId,
    required this.promotionPackageName,
    required this.sessionsCount,
    required this.discountAmount,
    this.batchCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'promotionPackageId': promotionPackageId,
        'promotionPackageName': promotionPackageName,
        'sessionsCount': sessionsCount,
        'discountAmount': discountAmount,
        'batchCount': batchCount,
      };

  factory AppliedPromotionInfo.fromMap(Map<String, dynamic> map) {
    return AppliedPromotionInfo(
      promotionPackageId: map['promotionPackageId'] as String? ?? '',
      promotionPackageName: map['promotionPackageName'] as String? ?? '',
      sessionsCount: (map['sessionsCount'] as num?)?.toInt() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      batchCount: (map['batchCount'] as num?)?.toInt() ?? 1,
    );
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String playerId;
  final String playerName;
  final String playerPhone;
  final int billingYear;
  final int billingMonth;
  final String billingPeriodKey; // YYYY-MM
  final List<InvoiceLineItem> lineItems;
  final double subTotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String status; // draft, sent, paid, overdue, void
  final String? notes;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? paymentReference;
  final List<String> receiptUrls;
  final String? receiptId;
  final String currency;
  final Map<String, dynamic> customFields;
  // Billing recipient fields
  final String? billToName;
  final String? billToPhone;
  final String? billToEmail;
  final String? billToType; // 'player' or 'parent'
  final String?
  billingPlayerName; // Store the player's name separately for reference
  // Family invoice: list of all player IDs
  final List<String> playerIds;
  final List<AppliedPromotionInfo>? appliedPromotions;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.playerId,
    required this.playerName,
    required this.playerPhone,
    required this.billingYear,
    required this.billingMonth,
    required this.billingPeriodKey,
    required this.lineItems,
    required this.subTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    this.sentAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.receiptUrls = const [],
    this.receiptId,
    this.currency = 'RM',
    this.customFields = const {},
    this.billToName,
    this.billToPhone,
    this.billToEmail,
    this.billToType,
    this.billingPlayerName,
    this.playerIds = const [],
    this.appliedPromotions,
  });

  Map<String, dynamic> toJson() => {
    'invoiceNumber': invoiceNumber,
    'playerId': playerId,
    'playerName': playerName,
    'playerPhone': playerPhone,
    'billingYear': billingYear,
    'billingMonth': billingMonth,
    'billingPeriodKey': billingPeriodKey,
    'lineItems': lineItems.map((e) => e.toJson()).toList(),
    'subTotal': subTotal,
    'discountAmount': discountAmount,
    'taxAmount': taxAmount,
    'totalAmount': totalAmount,
    'status': status,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'paymentMethod': paymentMethod,
    'paymentReference': paymentReference,
    'receiptUrls': receiptUrls,
    'receiptId': receiptId,
    'currency': currency,
    'customFields': customFields,
    'billToName': billToName,
    'billToPhone': billToPhone,
    'billToEmail': billToEmail,
    'billToType': billToType,
    'billingPlayerName': billingPlayerName,
    'playerIds': playerIds,
    if (appliedPromotions != null)
      'appliedPromotions':
          appliedPromotions!.map((p) => p.toJson()).toList(),
  };

  factory InvoiceModel.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? createdAt;
    final createdAtField = map['createdAt'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    } else {
      createdAt = DateTime.now();
    }

    DateTime? sentAt;
    final sentAtField = map['sentAt'];
    if (sentAtField is Timestamp) {
      sentAt = sentAtField.toDate();
    } else if (sentAtField is DateTime) {
      sentAt = sentAtField;
    }

    DateTime? paidAt;
    final paidAtField = map['paidAt'];
    if (paidAtField is Timestamp) {
      paidAt = paidAtField.toDate();
    } else if (paidAtField is DateTime) {
      paidAt = paidAtField;
    }

    final items = (map['lineItems'] as List<dynamic>? ?? [])
        .map((e) => InvoiceLineItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final playerIdsList = (map['playerIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();

    final receiptUrlsList = (map['receiptUrls'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      playerPhone: map['playerPhone'] as String? ?? '',
      billingYear: (map['billingYear'] as num?)?.toInt() ?? 0,
      billingMonth: (map['billingMonth'] as num?)?.toInt() ?? 0,
      billingPeriodKey: map['billingPeriodKey'] as String? ?? '',
      lineItems: items,
      subTotal: (map['subTotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'draft',
      notes: map['notes'] as String?,
      createdAt: createdAt,
      sentAt: sentAt,
      paidAt: paidAt,
      paymentMethod: map['paymentMethod'] as String?,
      paymentReference: map['paymentReference'] as String?,
      receiptUrls: receiptUrlsList,
      receiptId: map['receiptId'] as String?,
      currency: map['currency'] as String? ?? 'RM',
      customFields: Map<String, dynamic>.from(
        map['customFields'] as Map? ?? {},
      ),
      billToName: map['billToName'] as String?,
      billToPhone: map['billToPhone'] as String?,
      billToEmail: map['billToEmail'] as String?,
      billToType: map['billToType'] as String?,
      billingPlayerName: map['billingPlayerName'] as String?,
      playerIds: playerIdsList,
      appliedPromotions: (map['appliedPromotions'] as List<dynamic>?)
          ?.map(
            (e) => AppliedPromotionInfo.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}
