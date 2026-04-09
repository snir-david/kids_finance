import '../models/multiply_rule_model.dart';

abstract class MultiplyRuleRepository {
  Stream<List<MultiplyRule>> watchRules(String familyId, String childId);
  Future<void> addRule({
    required String familyId,
    required String childId,
    required double multiplierPercent,
    required ScheduleFrequency frequency,
  });
  Future<void> toggleRule(String familyId, String ruleId, bool isActive);
  Future<void> deleteRule(String familyId, String ruleId);

  /// Applies all overdue multiply rules for the family. Returns count processed.
  Future<int> processOverdueRules(String familyId);
}
