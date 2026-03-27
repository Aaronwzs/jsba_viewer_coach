import 'package:cloud_firestore/cloud_firestore.dart';

class AcademySettingsModel {
  final String id;
  final List<String> venues;
  final int defaultMaxPlayersPerCourt;
  final String votingDeadlineTime;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? tngPhoneNumber;
  final DateTime lastUpdated;

  // Billing - Business Identity
  final String? billingName;
  final String? billingWebsite;
  final String? billingEmail;
  final String? billingPhone;
  final String? billingLogoUrl;

  // Billing - Social Media
  final Map<String, String> socialMedia;

  // Billing - Digital Wallet (enhanced)
  final String? duitNowId;
  final String? duitNowQrUrl;

  // Billing - Payment Terms
  final String? dueDateNote;

  static const String defaultVotingDeadline = '18:00';

  AcademySettingsModel({
    this.id = 'academy_settings',
    List<String>? venues,
    this.defaultMaxPlayersPerCourt = 6,
    this.votingDeadlineTime = defaultVotingDeadline,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankName,
    this.tngPhoneNumber,
    DateTime? lastUpdated,
    this.billingName,
    this.billingWebsite,
    this.billingEmail,
    this.billingPhone,
    this.billingLogoUrl,
    Map<String, String>? socialMedia,
    this.duitNowId,
    this.duitNowQrUrl,
    this.dueDateNote,
  }) : venues =
           venues ?? ['Desa Petaling', 'Midfields', 'Sky Condo', 'Yoke Nam'],
       socialMedia = socialMedia ?? const {},
       lastUpdated = lastUpdated ?? DateTime.now();

  String get paymentInstructions {
    final buffer = StringBuffer();

    if (bankName != null &&
        bankAccountName != null &&
        bankAccountNumber != null) {
      buffer.writeln('Bank Transfer:');
      buffer.writeln('Bank: $bankName');
      buffer.writeln('Account Name: $bankAccountName');
      buffer.writeln('Account Number: $bankAccountNumber');
    }

    if (tngPhoneNumber != null) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('TNG e-Wallet: $tngPhoneNumber');
    }

    return buffer.isEmpty ? 'Payment details not available' : buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'venues': venues,
    'defaultMaxPlayersPerCourt': defaultMaxPlayersPerCourt,
    'votingDeadlineTime': votingDeadlineTime,
    'bankAccountName': bankAccountName,
    'bankAccountNumber': bankAccountNumber,
    'bankName': bankName,
    'tngPhoneNumber': tngPhoneNumber,
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'billingName': billingName,
    'billingWebsite': billingWebsite,
    'billingEmail': billingEmail,
    'billingPhone': billingPhone,
    'billingLogoUrl': billingLogoUrl,
    'socialMedia': socialMedia,
    'duitNowId': duitNowId,
    'duitNowQrUrl': duitNowQrUrl,
    'dueDateNote': dueDateNote,
  };

  factory AcademySettingsModel.fromMap(Map<String, dynamic> map) {
    DateTime? updated;
    final updatedField = map['lastUpdated'];
    if (updatedField is Timestamp) {
      updated = updatedField.toDate();
    } else if (updatedField is DateTime) {
      updated = updatedField;
    }

    final venuesList = <String>[];
    final venuesField = map['venues'];
    if (venuesField is List) {
      for (final venue in venuesField) {
        if (venue is String) {
          venuesList.add(venue);
        }
      }
    }

    final socialRaw = map['socialMedia'];
    final socialMap = socialRaw is Map
        ? Map<String, String>.from(socialRaw)
        : <String, String>{};

    return AcademySettingsModel(
      venues: venuesList.isEmpty ? null : venuesList,
      defaultMaxPlayersPerCourt: map['defaultMaxPlayersPerCourt'] as int? ?? 6,
      votingDeadlineTime:
          map['votingDeadlineTime'] as String? ?? defaultVotingDeadline,
      bankAccountName: map['bankAccountName'] as String?,
      bankAccountNumber: map['bankAccountNumber'] as String?,
      bankName: map['bankName'] as String?,
      tngPhoneNumber: map['tngPhoneNumber'] as String?,
      lastUpdated: updated,
      billingName: map['billingName'] as String?,
      billingWebsite: map['billingWebsite'] as String?,
      billingEmail: map['billingEmail'] as String?,
      billingPhone: map['billingPhone'] as String?,
      billingLogoUrl: map['billingLogoUrl'] as String?,
      socialMedia: socialMap,
      duitNowId: map['duitNowId'] as String?,
      duitNowQrUrl: map['duitNowQrUrl'] as String?,
      dueDateNote: map['dueDateNote'] as String?,
    );
  }

  AcademySettingsModel copyWith({
    String? id,
    List<String>? venues,
    int? defaultMaxPlayersPerCourt,
    String? votingDeadlineTime,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankName,
    String? tngPhoneNumber,
    DateTime? lastUpdated,
    String? billingName,
    String? billingWebsite,
    String? billingEmail,
    String? billingPhone,
    String? billingLogoUrl,
    Map<String, String>? socialMedia,
    String? duitNowId,
    String? duitNowQrUrl,
    String? dueDateNote,
  }) {
    return AcademySettingsModel(
      id: id ?? this.id,
      venues: venues ?? this.venues,
      defaultMaxPlayersPerCourt:
          defaultMaxPlayersPerCourt ?? this.defaultMaxPlayersPerCourt,
      votingDeadlineTime: votingDeadlineTime ?? this.votingDeadlineTime,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      tngPhoneNumber: tngPhoneNumber ?? this.tngPhoneNumber,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      billingName: billingName ?? this.billingName,
      billingWebsite: billingWebsite ?? this.billingWebsite,
      billingEmail: billingEmail ?? this.billingEmail,
      billingPhone: billingPhone ?? this.billingPhone,
      billingLogoUrl: billingLogoUrl ?? this.billingLogoUrl,
      socialMedia: socialMedia ?? this.socialMedia,
      duitNowId: duitNowId ?? this.duitNowId,
      duitNowQrUrl: duitNowQrUrl ?? this.duitNowQrUrl,
      dueDateNote: dueDateNote ?? this.dueDateNote,
    );
  }

  factory AcademySettingsModel.defaults() {
    return AcademySettingsModel(
      venues: ['Desa Petaling', 'Midfields', 'Sky Condo', 'Yoke Nam'],
      defaultMaxPlayersPerCourt: 6,
      votingDeadlineTime: defaultVotingDeadline,
      billingName: 'Junior Shuttlers Academy',
      dueDateNote: 'Payment due within 7 days',
      socialMedia: const {},
    );
  }
}
