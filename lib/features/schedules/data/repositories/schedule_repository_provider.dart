import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'schedule_repository.dart';
import 'firebase_schedule_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return FirebaseScheduleRepository();
});
