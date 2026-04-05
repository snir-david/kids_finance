/// Domain model for a child's financial bucket (Money, Investment, or Charity).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum BucketType {
  money,
  investment,
  charity;

  String toJson() => name;

  static BucketType fromJson(String value) {
    return BucketType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => BucketType.money,
    );
  }
}

class Bucket extends Equatable {
  const Bucket({
    required this.id,
    required this.childId,
    required this.familyId,
    required this.type,
    required this.balance,
    required this.lastUpdatedAt,
  });

  final String id;
  final String childId;
  final String familyId;
  final BucketType type;
  final double balance;
  final DateTime lastUpdatedAt;

  Bucket copyWith({
    String? id,
    String? childId,
    String? familyId,
    BucketType? type,
    double? balance,
    DateTime? lastUpdatedAt,
  }) {
    return Bucket(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      familyId: familyId ?? this.familyId,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory Bucket.fromJson(Map<String, dynamic> json) => Bucket(
        id: json['id'] as String,
        childId: json['childId'] as String,
        familyId: json['familyId'] as String,
        type: BucketType.fromJson(json['type'] as String),
        balance: (json['balance'] as num).toDouble(),
        lastUpdatedAt: (json['lastUpdatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'familyId': familyId,
        'type': type.toJson(),
        'balance': balance,
        'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      };

  @override
  List<Object?> get props => [
        id,
        childId,
        familyId,
        type,
        balance,
        lastUpdatedAt,
      ];
}
