import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goal_repository.dart';
import 'firebase_goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirebaseGoalRepository();
});
