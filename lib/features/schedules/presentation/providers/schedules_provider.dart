import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/schedule_model.dart';
import '../../data/repositories/schedule_repository_provider.dart';

/// Watches all schedules for a specific child.
/// Params: ({familyId, childId})
final schedulesProvider = StreamProvider.family<List<Schedule>,
    ({String familyId, String childId})>((ref, params) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return repository.watchSchedules(params.familyId, params.childId);
});
