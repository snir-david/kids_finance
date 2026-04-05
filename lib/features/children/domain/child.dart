/// Domain model for a child user in a family.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Child extends Equatable {
  const Child({
    required this.id,
    required this.familyId,
    required this.displayName,
    required this.avatarEmoji,
    required this.pinHash,
    this.sessionExpiresAt,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String displayName;
  final String avatarEmoji;
  final String pinHash;
  final DateTime? sessionExpiresAt;
  final DateTime createdAt;

  Child copyWith({
    String? id,
    String? familyId,
    String? displayName,
    String? avatarEmoji,
    String? pinHash,
    DateTime? sessionExpiresAt,
    DateTime? createdAt,
  }) {
    return Child(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      pinHash: pinHash ?? this.pinHash,
      sessionExpiresAt: sessionExpiresAt ?? this.sessionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        familyId: json['familyId'] as String,
        displayName: json['displayName'] as String,
        avatarEmoji: json['avatarEmoji'] as String,
        pinHash: json['pinHash'] as String,
        sessionExpiresAt: json['sessionExpiresAt'] != null
            ? (json['sessionExpiresAt'] as Timestamp).toDate()
            : null,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'familyId': familyId,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'pinHash': pinHash,
        'sessionExpiresAt': sessionExpiresAt != null
            ? Timestamp.fromDate(sessionExpiresAt!)
            : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [
        id,
        familyId,
        displayName,
        avatarEmoji,
        pinHash,
        sessionExpiresAt,
        createdAt,
      ];
}
