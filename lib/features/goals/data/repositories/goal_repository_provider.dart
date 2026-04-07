import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goal_repository.dart';
import 'firebase_goal_repository.dart';
import '../../../badges/data/services/badge_evaluation_service.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirebaseGoalRepository(
    badgeService: ref.watch(badgeEvaluationServiceProvider),
  );
});
