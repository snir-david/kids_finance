import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'multiply_rule_repository.dart';
import 'firebase_multiply_rule_repository.dart';

final multiplyRuleRepositoryProvider = Provider<MultiplyRuleRepository>((ref) {
  return FirebaseMultiplyRuleRepository();
});
