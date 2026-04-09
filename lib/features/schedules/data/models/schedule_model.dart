import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ScheduleFrequency {
  weekly,
  biweekly,
  monthly;

  String toJson() => name;

  static ScheduleFrequency fromJson(String v) => ScheduleFrequency.values
      .firstWhere((e) => e.name == v, orElse: () => ScheduleFrequency.weekly);
}

class Schedule extends Equatable {
  const Schedule({
    required this.id,
    required this.childId,
    required this.familyId,
    required this.amount,
    required this.frequency,
    required this.dayOfWeek,
    required this.isActive,
    required this.nextRunAt,
    required this.createdAt,
  });

  final String id;
  final String childId;
  final String familyId;
  final double amount;

  /// Frequency of the allowance distribution.
  final ScheduleFrequency frequency;

  /// For weekly/biweekly: ISO weekday 1=Mon...7=Sun.
  /// For monthly: day of month 1-28.
  final int dayOfWeek;

  final bool isActive;
  final DateTime nextRunAt;
  final DateTime createdAt;

  bool get isOverdue => isActive && nextRunAt.isBefore(DateTime.now());

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      childId: data['childId'] as String,
      familyId: data['familyId'] as String,
      amount: (data['amount'] as num).toDouble(),
      frequency: ScheduleFrequency.fromJson(data['frequency'] as String),
      dayOfWeek: data['dayOfWeek'] as int,
      isActive: data['isActive'] as bool? ?? true,
      nextRunAt: (data['nextRunAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'familyId': familyId,
        'amount': amount,
        'frequency': frequency.toJson(),
        'dayOfWeek': dayOfWeek,
        'isActive': isActive,
        'nextRunAt': Timestamp.fromDate(nextRunAt),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// First nextRunAt from today for a given frequency + day.
  static DateTime computeNextRunAt(ScheduleFrequency frequency, int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (frequency) {
      case ScheduleFrequency.weekly:
        int d = (day - today.weekday) % 7;
        if (d == 0) d = 7;
        return today.add(Duration(days: d));
      case ScheduleFrequency.biweekly:
        int d = (day - today.weekday) % 7;
        if (d == 0) d = 14;
        return today.add(Duration(days: d));
      case ScheduleFrequency.monthly:
        final clampedDay = day.clamp(1, 28);
        if (today.day < clampedDay) {
          return DateTime(today.year, today.month, clampedDay);
        }
        final next = DateTime(today.year, today.month + 1, 1);
        return DateTime(next.year, next.month, clampedDay);
    }
  }

  Schedule copyWith({bool? isActive}) => Schedule(
        id: id,
        childId: childId,
        familyId: familyId,
        amount: amount,
        frequency: frequency,
        dayOfWeek: dayOfWeek,
        isActive: isActive ?? this.isActive,
        nextRunAt: nextRunAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [
        id, childId, familyId, amount, frequency,
        dayOfWeek, isActive, nextRunAt, createdAt,
      ];
}
