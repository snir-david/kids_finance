/// Domain model for a parent user in a family.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ParentUser extends Equatable {
  const ParentUser({
    required this.uid,
    required this.displayName,
    required this.familyId,
    required this.isOwner,
    required this.createdAt,
  });

  final String uid;
  final String displayName;
  final String familyId;
  final bool isOwner;
  final DateTime createdAt;

  ParentUser copyWith({
    String? uid,
    String? displayName,
    String? familyId,
    bool? isOwner,
    DateTime? createdAt,
  }) {
    return ParentUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      familyId: familyId ?? this.familyId,
      isOwner: isOwner ?? this.isOwner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ParentUser.fromJson(Map<String, dynamic> json) => ParentUser(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        familyId: json['familyId'] as String,
        isOwner: json['isOwner'] as bool,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'familyId': familyId,
        'isOwner': isOwner,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  List<Object?> get props => [uid, displayName, familyId, isOwner, createdAt];
}
