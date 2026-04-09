import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/multiply_rule_model.dart';
import '../../data/repositories/multiply_rule_repository_provider.dart';

final multiplyRulesProvider = StreamProvider.family<
    List<MultiplyRule>,
    ({String familyId, String childId})>((ref, params) {
  return ref.watch(multiplyRuleRepositoryProvider).watchRules(
        params.familyId,
        params.childId,
      );
});
