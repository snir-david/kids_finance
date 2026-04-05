/// Domain model for financial transactions within a bucket.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../buckets/domain/bucket.dart';

enum TransactionType {
  moneySet,
  investmentMultiplied,
  charityDonated,
  moneyAdded,
  moneyRemoved;

  String toJson() => name;

  static TransactionType fromJson(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TransactionType.moneyAdded,
    );
  }
}

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.bucketType,
    required this.type,
    required this.amount,
    this.multiplier,
    required this.previousBalance,
    required this.newBalance,
    this.note,
    required this.performedByUid,
    required this.performedAt,
  });

  final String id;
  final String familyId;
  final String childId;
  final BucketType bucketType;
  final TransactionType type;
  final double amount;
  final double? multiplier;
  final double previousBalance;
  final double newBalance;
  final String? note;
  final String performedByUid;
  final DateTime performedAt;

  Transaction copyWith({
    String? id,
    String? familyId,
    String? childId,
    BucketType? bucketType,
    TransactionType? type,
    double? amount,
    double? multiplier,
    double? previousBalance,
    double? newBalance,
    String? note,
    String? performedByUid,
    DateTime? performedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
      bucketType: bucketType ?? this.bucketType,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      multiplier: multiplier ?? this.multiplier,
      previousBalance: previousBalance ?? this.previousBalance,
      newBalance: newBalance ?? this.newBalance,
      note: note ?? this.note,
      performedByUid: performedByUid ?? this.performedByUid,
      performedAt: performedAt ?? this.performedAt,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        familyId: json['familyId'] as String,
        childId: json['childId'] as String,
        bucketType: BucketType.fromJson(json['bucketType'] as String),
        type: TransactionType.fromJson(json['type'] as String),
        amount: (json['amount'] as num).toDouble(),
        multiplier: json['multiplier'] != null
            ? (json['multiplier'] as num).toDouble()
            : null,
        previousBalance: (json['previousBalance'] as num).toDouble(),
        newBalance: (json['newBalance'] as num).toDouble(),
        note: json['note'] as String?,
        performedByUid: json['performedByUid'] as String,
        performedAt: (json['performedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'familyId': familyId,
        'childId': childId,
        'bucketType': bucketType.toJson(),
        'type': type.toJson(),
        'amount': amount,
        'multiplier': multiplier,
        'previousBalance': previousBalance,
        'newBalance': newBalance,
        'note': note,
        'performedByUid': performedByUid,
        'performedAt': Timestamp.fromDate(performedAt),
      };

  @override
  List<Object?> get props => [
        id,
        familyId,
        childId,
        bucketType,
        type,
        amount,
        multiplier,
        previousBalance,
        newBalance,
        note,
        performedByUid,
        performedAt,
      ];
}
