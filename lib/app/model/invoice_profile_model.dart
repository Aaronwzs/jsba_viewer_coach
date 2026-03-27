import 'dart:convert';
import 'dart:typed_data';
import 'package:jsba_app/app/model/academy_settings_model.dart';

class InvoiceProfile {
  final String name;
  final String website;
  final String email;
  final String phone;
  final String dueDateNote;

  // Structured social media (backward compatible)
  final Map<String, String> socialMedia; // platform -> handle/url

  // Structured payment methods (backward compatible)
  final BankAccount? bankAccount;
  final DigitalWallet? digitalWallet;

  const InvoiceProfile({
    required this.name,
    required this.website,
    required this.email,
    required this.phone,
    required this.dueDateNote,
    required this.socialMedia,
    this.bankAccount,
    this.digitalWallet,
  });

  // Backward compatibility constructor
  factory InvoiceProfile.fromLegacy({
    String name = 'JSBA Badminton Academy',
    String website = '',
    String email = '',
    String social = '', // Legacy single field
    String phone = '',
    String bankName = '',
    String bankAccountNumber = '',
    String bankAccountName = '',
    String duitNow = '',
    String tngNumber = '',
    String dueDateNote = '',
    Uint8List? duitNowQrBytes,
  }) {
    final socialMap = social.isNotEmpty
        ? {'custom': social}
        : <String, String>{};

    return InvoiceProfile(
      name: name,
      website: website,
      email: email,
      phone: phone,
      dueDateNote: dueDateNote,
      socialMedia: socialMap,
      bankAccount:
          bankName.isNotEmpty ||
              bankAccountNumber.isNotEmpty ||
              bankAccountName.isNotEmpty
          ? BankAccount(
              name: bankName,
              number: bankAccountNumber,
              holderName: bankAccountName,
            )
          : null,
      digitalWallet:
          duitNow.isNotEmpty || tngNumber.isNotEmpty || duitNowQrBytes != null
          ? DigitalWallet(
              duitNowId: duitNow,
              tngNumber: tngNumber,
              qrBytes: duitNowQrBytes,
            )
          : null,
    );
  }

  factory InvoiceProfile.empty() => const InvoiceProfile(
    name: 'JSBA Badminton Academy',
    website: '',
    email: '',
    phone: '',
    dueDateNote: 'Payment due within 7 days',
    socialMedia: {},
  );

  factory InvoiceProfile.fromAcademySettings(AcademySettingsModel settings) {
    return InvoiceProfile(
      name: settings.billingName ?? 'JSBA Badminton Academy',
      website: settings.billingWebsite ?? '',
      email: settings.billingEmail ?? '',
      phone: settings.billingPhone ?? '',
      dueDateNote: settings.dueDateNote ?? 'Payment due within 7 days',
      socialMedia: settings.socialMedia,
      bankAccount:
          (settings.bankName?.isNotEmpty == true ||
              settings.bankAccountNumber?.isNotEmpty == true ||
              settings.bankAccountName?.isNotEmpty == true)
          ? BankAccount(
              name: settings.bankName ?? '',
              number: settings.bankAccountNumber ?? '',
              holderName: settings.bankAccountName ?? '',
            )
          : null,
      digitalWallet:
          (settings.duitNowId?.isNotEmpty == true ||
              settings.tngPhoneNumber?.isNotEmpty == true)
          ? DigitalWallet(
              duitNowId: settings.duitNowId ?? '',
              tngNumber: settings.tngPhoneNumber ?? '',
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'website': website,
    'email': email,
    'phone': phone,
    'dueDateNote': dueDateNote,
    'socialMedia': socialMedia,
    'bankAccount': bankAccount?.toJson(),
    'digitalWallet': digitalWallet?.toJson(),
  };

  factory InvoiceProfile.fromJson(Map<String, dynamic> json) {
    final socialRaw = json['socialMedia'];
    final socialMap = socialRaw is Map
        ? Map<String, String>.from(socialRaw)
        : (json['social'] != null
              ? {'custom': json['social'] as String}
              : <String, String>{});

    return InvoiceProfile(
      name: json['name'] as String? ?? 'JSBA Badminton Academy',
      website: json['website'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dueDateNote:
          json['dueDateNote'] as String? ?? 'Payment due within 7 days',
      socialMedia: socialMap,
      bankAccount: json['bankAccount'] != null
          ? BankAccount.fromJson(json['bankAccount'] as Map<String, dynamic>)
          : null,
      digitalWallet: json['digitalWallet'] != null
          ? DigitalWallet.fromJson(
              json['digitalWallet'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class BankAccount {
  final String name;
  final String number;
  final String holderName;

  const BankAccount({
    required this.name,
    required this.number,
    required this.holderName,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'number': number,
    'holderName': holderName,
  };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    name: json['name'] as String? ?? '',
    number: json['number'] as String? ?? '',
    holderName: json['holderName'] as String? ?? '',
  );
}

class DigitalWallet {
  final String duitNowId;
  final String tngNumber;
  final Uint8List? qrBytes;

  const DigitalWallet({
    required this.duitNowId,
    required this.tngNumber,
    this.qrBytes,
  });

  Map<String, dynamic> toJson() => {
    'duitNowId': duitNowId,
    'tngNumber': tngNumber,
    'qrBase64': qrBytes != null ? base64Encode(qrBytes!) : null,
  };

  factory DigitalWallet.fromJson(Map<String, dynamic> json) {
    final qrBase64 = json['qrBase64'] as String?;
    return DigitalWallet(
      duitNowId: json['duitNowId'] as String? ?? '',
      tngNumber: json['tngNumber'] as String? ?? '',
      qrBytes: qrBase64 != null ? base64Decode(qrBase64) : null,
    );
  }
}
