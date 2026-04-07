import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum BadgeType {
  firstDeposit,
  generousHeart,
  youngInvestor,
  goalGetter,
  saver,
  streak,
}

class Badge extends Equatable {
  const Badge({
    required this.id,
    required this.type,
    required this.earnedAt,
    required this.seen,
  });

  final String id;
  final BadgeType type;
  final DateTime earnedAt;
  final bool seen;

  String get emoji {
    switch (type) {
      case BadgeType.firstDeposit:
        return '🌱';
      case BadgeType.generousHeart:
        return '💚';
      case BadgeType.youngInvestor:
        return '📈';
      case BadgeType.goalGetter:
        return '🎯';
      case BadgeType.saver:
        return '💰';
      case BadgeType.streak:
        return '🔥';
    }
  }

  String get displayName {
    switch (type) {
      case BadgeType.firstDeposit:
        return 'First Deposit';
      case BadgeType.generousHeart:
        return 'Generous Heart';
      case BadgeType.youngInvestor:
        return 'Young Investor';
      case BadgeType.goalGetter:
        return 'Goal Getter';
      case BadgeType.saver:
        return 'Saver';
      case BadgeType.streak:
        return 'Streak';
    }
  }

  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawEarned = data['earnedAt'];
    final earnedAt = rawEarned is Timestamp
        ? rawEarned.toDate()
        : DateTime.parse(rawEarned as String);

    return Badge(
      id: doc.id,
      type: BadgeType.values.byName(data['type'] as String),
      earnedAt: earnedAt,
      seen: data['seen'] as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'earnedAt': Timestamp.fromDate(earnedAt),
        'seen': seen,
      };

  Badge copyWith({
    String? id,
    BadgeType? type,
    DateTime? earnedAt,
    bool? seen,
  }) {
    return Badge(
      id: id ?? this.id,
      type: type ?? this.type,
      earnedAt: earnedAt ?? this.earnedAt,
      seen: seen ?? this.seen,
    );
  }

  @override
  List<Object?> get props => [id, type, earnedAt, seen];
}
