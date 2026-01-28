import 'dart:convert';

class PaymentMethodsResponse {
  final String status;
  final String message;
  final List<CreditCardModel> creditCards;
  final List<BankAccountModel> bankAccounts;

  const PaymentMethodsResponse({
    required this.status,
    required this.message,
    required this.creditCards,
    required this.bankAccounts,
  });

  PaymentMethodsResponse copyWith({
    String? status,
    String? message,
    List<CreditCardModel>? creditCards,
    List<BankAccountModel>? bankAccounts,
  }) {
    return PaymentMethodsResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      creditCards: creditCards ?? this.creditCards,
      bankAccounts: bankAccounts ?? this.bankAccounts,
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "creditCards": creditCards.map((e) => e.toJson()).toList(),
        "bankAccounts": bankAccounts.map((e) => e.toJson()).toList(),
      };

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) {
    final ccRaw = json["creditCards"];
    final bankRaw = json["bankAccounts"];

    final ccList = (ccRaw is List) ? ccRaw.map((e) => CreditCardModel.fromJson(Map<String, dynamic>.from(e))).toList() : <CreditCardModel>[];

    final bankList = (bankRaw is List) ? bankRaw.map((e) => BankAccountModel.fromJson(Map<String, dynamic>.from(e))).toList() : <BankAccountModel>[];

    return PaymentMethodsResponse(
      status: (json["status"] ?? "").toString(),
      message: (json["message"] ?? "").toString(),
      creditCards: ccList,
      bankAccounts: bankList,
    );
  }

  // For local storage or API caching
  String encode() => jsonEncode(toJson());

  static PaymentMethodsResponse decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return PaymentMethodsResponse.fromJson(map);
      return const PaymentMethodsResponse(
        status: "",
        message: "",
        creditCards: [],
        bankAccounts: [],
      );
    } catch (_) {
      return const PaymentMethodsResponse(
        status: "",
        message: "",
        creditCards: [],
        bankAccounts: [],
      );
    }
  }
}

class BankAccountModel {
  final String id;
  final String? bankName;
  final String? nickName;
  final String? accountType; // Chequing / Savings
  final double? balance;
  final bool isDefault;
  final int createdAtMs;

  const BankAccountModel({
    required this.id,
    this.bankName,
    this.nickName,
    this.accountType,
    this.balance,
    this.isDefault = false,
    required this.createdAtMs,
  });

  BankAccountModel copyWith({
    String? id,
    String? bankName,
    String? nickName,
    String? accountType,
    double? balance,
    bool? isDefault,
    int? createdAtMs,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      nickName: nickName ?? this.nickName,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      isDefault: isDefault ?? this.isDefault,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "bankName": bankName,
        "nickName": nickName,
        "accountType": accountType,
        "balance": balance,
        "isDefault": isDefault,
        "createdAtMs": createdAtMs,
      };

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      final s = (v ?? "").toString().toLowerCase().trim();
      return s == "true" || s == "1" || s == "yes";
    }

    return BankAccountModel(
      id: (json["id"] ?? "").toString(),
      bankName: json["bankName"]?.toString(),
      nickName: json["nickName"]?.toString(),
      accountType: json["accountType"]?.toString(),
      balance: _toDouble(json["balance"]),
      isDefault: _toBool(json["isDefault"]),
      createdAtMs: (json["createdAtMs"] is int) ? json["createdAtMs"] as int : int.tryParse((json["createdAtMs"] ?? 0).toString()) ?? 0,
    );
  }

  // Helpers for local storage
  static String encodeList(List<BankAccountModel> list) => jsonEncode(list.map((e) => e.toJson()).toList());

  static List<BankAccountModel> decodeList(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data.map((e) => BankAccountModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

class CreditCardModel {
  final String id;
  final String? cardNumber; // store masked/last4 in real app
  final DateTime? expiryDate; // expiry date (store as DateTime)
  final String? cardHolderName;
  final String? cvvCode; // don't store in production
  final String? bankName;
  final String? cardType;
  final double? creditLimit;
  final double? creditLimitUsed;
  final bool isDefault;
  final int createdAtMs;

  // ✅ billing fields
  final DateTime? statementDate; // last statement/bill generated date
  final DateTime? paymentDueDate; // last statement/bill generated date
  final int billingCycleDays; // e.g., 30
  final int dueDaysAfterStatement; // e.g., 21

  const CreditCardModel({
    required this.id,
    this.cardNumber,
    this.expiryDate,
    this.cardHolderName,
    this.cvvCode,
    this.bankName,
    this.creditLimit,
    this.cardType,
    this.creditLimitUsed,
    this.isDefault = false,
    required this.createdAtMs,

    // ✅ new (null-safe)
    this.statementDate,
    this.paymentDueDate,
    this.billingCycleDays = 30,
    this.dueDaysAfterStatement = 21,
  });

  CreditCardModel copyWith({
    String? id,
    String? cardNumber,
    DateTime? expiryDate,
    String? cardHolderName,
    String? cardType,
    String? cvvCode,
    String? bankName,
    double? creditLimit,
    double? creditLimitUsed,
    bool? isDefault,
    int? createdAtMs,
    DateTime? statementDate,
    DateTime? paymentDueDate,
    int? billingCycleDays,
    int? dueDaysAfterStatement,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardType: cardType ?? this.cardType,
      cvvCode: cvvCode ?? this.cvvCode,
      bankName: bankName ?? this.bankName,
      creditLimit: creditLimit ?? this.creditLimit,
      creditLimitUsed: creditLimitUsed ?? this.creditLimitUsed,
      isDefault: isDefault ?? this.isDefault,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      statementDate: statementDate ?? statementDate,
      paymentDueDate: paymentDueDate ?? paymentDueDate,
      billingCycleDays: billingCycleDays ?? this.billingCycleDays,
      dueDaysAfterStatement: dueDaysAfterStatement ?? this.dueDaysAfterStatement,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "cardNumber": cardNumber,
        "expiryDateMs": expiryDate?.millisecondsSinceEpoch,
        "cardHolderName": cardHolderName,
        "cardType": cardType,
        "cvvCode": cvvCode,
        "bankName": bankName,
        "creditLimit": creditLimit,
        "creditLimitUsed": creditLimitUsed,
        "isDefault": isDefault,
        "createdAtMs": createdAtMs,

        // ✅ new
        "statementDate": statementDate?.millisecondsSinceEpoch,
        "paymentDueDate": paymentDueDate?.millisecondsSinceEpoch,
        "billingCycleDays": billingCycleDays,
        "dueDaysAfterStatement": dueDaysAfterStatement,
      };

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    bool _toBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      final s = v.toString().toLowerCase().trim();
      if (s == "true" || s == "1" || s == "yes") return true;
      if (s == "false" || s == "0" || s == "no") return false;
      return fallback;
    }

    DateTime? _toDate(dynamic ms) {
      final v = _toInt(ms);
      if (v == null || v <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(v);
    }

    return CreditCardModel(
      id: (json["id"] ?? "").toString(),
      cardNumber: json["cardNumber"]?.toString(),
      expiryDate: _toDate(json["expiryDateMs"] ?? json["expiryDate"]),
      cardHolderName: json["cardHolderName"]?.toString(),
      cvvCode: json["cvvCode"]?.toString(),
      bankName: json["bankName"]?.toString(),
      cardType: json["cardType"]?.toString(),
      creditLimit: _toDouble(json["creditLimit"]),
      creditLimitUsed: _toDouble(json["creditLimitUsed"]),
      isDefault: _toBool(json["isDefault"]),
      createdAtMs: _toInt(json["createdAtMs"]) ?? 0,

      // ✅ new
      statementDate: _toDate(json["statementDate"]),
      paymentDueDate: _toDate(json["paymentDueDate"]),
      billingCycleDays: _toInt(json["billingCycleDays"]) ?? 30,
      dueDaysAfterStatement: _toInt(json["dueDaysAfterStatement"]) ?? 21,
    );
  }

  // Helpers for local storage
  static String encodeList(List<CreditCardModel> list) => jsonEncode(list.map((e) => e.toJson()).toList());

  static List<CreditCardModel> decodeList(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is List) {
        return data.map((e) => CreditCardModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
