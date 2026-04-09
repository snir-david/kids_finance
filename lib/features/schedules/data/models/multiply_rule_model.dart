import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'schedule_model.dart';

export 'schedule_model.dart' show ScheduleFrequency;

class MultiplyRule extends Equatable {
  const MultiplyRule({
    required this.id,
    required this.childId,
    required this.familyId,
    required this.multiplierPercent,
    required this.frequency,
    required this.isActive,
    required this.nextRunAt,
    required this.createdAt,
  });

  final String id;
  final String childId;
  final String familyId;

  /// Growth rate per period, e.g. 5.0 = +5 %.
  final double multiplierPercent;

  final ScheduleFrequency frequency;
  final bool isActive;
  final DateTime nextRunAt;
  final DateTime createdAt;

  bool get isOverdue => isActive && nextRunAt.isBefore(DateTime.now());

  /// Actual multiplier to apply (1.05 for 5 %).
  double get factor => 1.0 + multiplierPercent / 100.0;

  factory MultiplyRule.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MultiplyRule(
      id: doc.id,
      childId: d['childId'] as String,
      familyId: d['familyId'] as String,
      multiplierPercent: (d['multiplierPercent'] as num).toDouble(),
      frequency: ScheduleFrequency.fromJson(d['frequency'] as String),
      isActive: d['isActive'] as bool? ?? true,
      nextRunAt: (d['nextRunAt'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'familyId': familyId,
        'multiplierPercent': multiplierPercent,
        'frequency': frequency.toJson(),
        'isActive': isActive,
        'nextRunAt': Timestamp.fromDate(nextRunAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// First nextRunAt from today for the given frequency.
  static DateTime computeFirstRunAt(ScheduleFrequency frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case ScheduleFrequency.weekly:
        return now.add(const Duration(days: 7));
      case ScheduleFrequency.biweekly:
        return now.add(const Duration(days: 14));
      case ScheduleFrequency.monthly:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }

  DateTime advanceNextRunAt() {
    switch (frequency) {
      case ScheduleFrequency.weekly:
        return nextRunAt.add(const Duration(days: 7));
      case ScheduleFrequency.biweekly:
        return nextRunAt.add(const Duration(days: 14));
      case ScheduleFrequency.monthly:
        return DateTime(nextRunAt.year, nextRunAt.month + 1, nextRunAt.day);
    }
  }

  MultiplyRule copyWith({bool? isActive}) => MultiplyRule(
        id: id,
        childId: childId,
        familyId: familyId,
        multiplierPercent: multiplierPercent,
        frequency: frequency,
        isActive: isActive ?? this.isActive,
        nextRunAt: nextRunAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, childId, familyId, multiplierPercent, frequency, isActive, nextRunAt, createdAt];
}
