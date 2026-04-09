import '../models/schedule_model.dart';

abstract class ScheduleRepository {
  Stream<List<Schedule>> watchSchedules(String familyId, String childId);

  Future<void> addSchedule({
    required String familyId,
    required String childId,
    required double amount,
    required ScheduleFrequency frequency,
    required int dayOfWeek,
  });

  Future<void> toggleSchedule(
      String familyId, String scheduleId, bool isActive);

  Future<void> deleteSchedule(String familyId, String scheduleId);

  /// Client-side allowance distribution — no Cloud Function needed.
  Future<int> processOverdueAllowances(String familyId);
}
