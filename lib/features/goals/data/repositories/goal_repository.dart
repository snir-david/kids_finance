import '../models/goal_model.dart';

abstract class GoalRepository {
  Stream<List<Goal>> watchGoals(String familyId, String childId);

  Future<void> createGoal(
    String familyId,
    String childId,
    String name,
    double targetAmount,
  );

  Future<void> deleteGoal(String familyId, String childId, String goalId);

  Future<void> markCompleted(String familyId, String childId, String goalId);
}
