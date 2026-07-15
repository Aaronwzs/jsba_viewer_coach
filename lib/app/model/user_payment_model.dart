import 'package:cloud_firestore/cloud_firestore.dart';

/// A single discount line applied to a user payment (e.g. a promotion).
class DiscountItem {
  final String configType; // 'group' | 'private' | promotion id
  final String? promotionName;
  final double amount;

  const DiscountItem({
    required this.configType,
    this.promotionName,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'configType': configType,
        'promotionName': promotionName,
        'amount': amount,
      };

  factory DiscountItem.fromMap(Map<String, dynamic> map) {
    return DiscountItem(
      configType: map['configType'] as String? ?? '',
      promotionName: map['promotionName'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserPaymentModel {
  final String id;
  final String playerId;
  final String playerName;
  final String parentId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus; // 'pending' | 'approved' | 'rejected'
  final String? uploadProof;
  final String? notes;
  final String? invoiceId;
  final String? invoiceNumber;
  final List<String> attendanceIds;
  final String referenceType; // 'invoice' | 'attendance'
  final String billingPeriodKey;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final List<String> playerIds;
  final bool isInvoice; // true once an invoice has been generated for this payment
  final double subtotal; // sum of all training session prices before discounts
  final List<DiscountItem> discounts;
  final double totalAmt; // subtotal - sum(discounts); falls back to [amount]

  UserPaymentModel({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.parentId,
    required this.amount,
    this.currency = 'RM',
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.uploadProof,
    this.notes,
    this.invoiceId,
    this.invoiceNumber,
    this.attendanceIds = const [],
    this.referenceType = 'invoice',
    required this.billingPeriodKey,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.playerIds = const [],
    this.isInvoice = false,
    this.subtotal = 0,
    this.discounts = const [],
    this.totalAmt = 0,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'playerName': playerName,
        'parentId': parentId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'uploadProof': uploadProof,
        'notes': notes,
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
        'attendanceIds': attendanceIds,
        'referenceType': referenceType,
        'billingPeriodKey': billingPeriodKey,
        'createdAt': Timestamp.fromDate(createdAt),
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
        'approvedBy': approvedBy,
        'playerIds': playerIds,
        'isInvoice': isInvoice,
        'subtotal': subtotal,
        'discounts': discounts.map((d) => d.toJson()).toList(),
        'totalAmt': totalAmt,
      };

  factory UserPaymentModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime createdAt;
    final createdAtField = map['createdAt'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    } else {
      createdAt = DateTime.now();
    }

    DateTime? approvedAt;
    final approvedAtField = map['approvedAt'];
    if (approvedAtField is Timestamp) {
      approvedAt = approvedAtField.toDate();
    } else if (approvedAtField is DateTime) {
      approvedAt = approvedAtField;
    }

    final uploadProof = map['uploadProof'] as String?;

    final attendanceIdsList = (map['attendanceIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final playerIdsList = (map['playerIds'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final discountsList = (map['discounts'] as List<dynamic>? ?? [])
        .map((e) => DiscountItem.fromMap(e as Map<String, dynamic>))
        .toList();

    // Older documents stored only a flat [amount]. Treat that as the total
    // when the new breakdown fields are absent.
    final parsedTotal =
        (map['totalAmt'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0;
    final parsedSubtotal =
        (map['subtotal'] as num?)?.toDouble() ?? parsedTotal;

    return UserPaymentModel(
      id: id,
      playerId: map['playerId'] as String? ?? '',
      playerName: map['playerName'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'RM',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      uploadProof: uploadProof,
      notes: map['notes'] as String?,
      invoiceId: map['invoiceId'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      attendanceIds: attendanceIdsList,
      referenceType: map['referenceType'] as String? ?? 'invoice',
      // Accept either `billingPeriodKey` or `periodKey` so records created by
      // different writers/stores still filter correctly by period.
      billingPeriodKey: (map['billingPeriodKey'] as String?) ??
          (map['periodKey'] as String?) ??
          '',
      createdAt: createdAt,
      approvedAt: approvedAt,
      approvedBy: map['approvedBy'] as String?,
      playerIds: playerIdsList,
      isInvoice: map['isInvoice'] as bool? ?? false,
      subtotal: parsedSubtotal,
      discounts: discountsList,
      totalAmt: parsedTotal,
    );
  }

  UserPaymentModel copyWith({
    String? paymentStatus,
    String? uploadProof,
    DateTime? approvedAt,
    String? approvedBy,
    String? notes,
    bool? isInvoice,
    double? subtotal,
    List<DiscountItem>? discounts,
    double? totalAmt,
  }) {
    return UserPaymentModel(
      id: id,
      playerId: playerId,
      playerName: playerName,
      parentId: parentId,
      amount: amount,
      currency: currency,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      uploadProof: uploadProof ?? this.uploadProof,
      notes: notes ?? this.notes,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      attendanceIds: attendanceIds,
      referenceType: referenceType,
      billingPeriodKey: billingPeriodKey,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      playerIds: playerIds,
      isInvoice: isInvoice ?? this.isInvoice,
      subtotal: subtotal ?? this.subtotal,
      discounts: discounts ?? this.discounts,
      totalAmt: totalAmt ?? this.totalAmt,
    );
  }
}
