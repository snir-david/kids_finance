/// Domain model for a child user in a family.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Child extends Equatable {
  const Child({
    required this.id,
    required this.familyId,
    required this.displayName,
    required this.avatarEmoji,
    this.pinHash = '',
    this.sessionExpiresAt,
    required this.createdAt,
    this.archived = false,
  });

  final String id;
  final String familyId;
  final String displayName;
  final String avatarEmoji;
  final String pinHash;
  final DateTime? sessionExpiresAt;
  final DateTime createdAt;
  final bool archived;

  Child copyWith({
    String? id,
    String? familyId,
    String? displayName,
    String? avatarEmoji,
    String? pinHash,
    DateTime? sessionExpiresAt,
    DateTime? createdAt,
    bool? archived,
  }) {
    return Child(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      pinHash: pinHash ?? this.pinHash,
      sessionExpiresAt: sessionExpiresAt ?? this.sessionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
    );
  }

  factory Child.fromJson(Map<String, dynamic> json) {
    final rawSessionExpiry = json['sessionExpiresAt'];
    final sessionExpiresAt = rawSessionExpiry == null
        ? null
        : rawSessionExpiry is Timestamp
            ? rawSessionExpiry.toDate()
            : DateTime.parse(rawSessionExpiry as String);
    final rawCreatedAt = json['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.parse(rawCreatedAt as String);
    return Child(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      displayName: json['displayName'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      pinHash: json['pinHash'] as String? ?? '',
      sessionExpiresAt: sessionExpiresAt,
      createdAt: createdAt,
      archived: json['archived'] as bool? ?? false,
    );
  }

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
        'archived': archived,
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
        archived,
      ];
}
