import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository_provider.dart';

/// StreamProvider for a child's active savings goals.
/// Params: ({familyId, childId})
final goalsProvider = StreamProvider.family<List<Goal>,
    ({String familyId, String childId})>((ref, params) {
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchGoals(params.familyId, params.childId);
});
