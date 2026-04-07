import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge_model.dart';
import '../repositories/badge_repository.dart';
import '../repositories/badge_repository_provider.dart';

class BadgeEvaluationService {
  BadgeEvaluationService(this._badgeRepo, this._firestore);

  final BadgeRepository _badgeRepo;
  final FirebaseFirestore _firestore;

  /// Call after any deposit (addMoney, setMoney, distributeFunds) completes.
  /// [myMoneyBalance] is the child's current Money bucket balance post-write.
  Future<void> evaluateAfterDeposit(
    String familyId,
    String childId,
    double myMoneyBalance,
  ) async {
    await _badgeRepo.awardBadge(familyId, childId, BadgeType.firstDeposit);
    if (myMoneyBalance >= 100) {
      await _badgeRepo.awardBadge(familyId, childId, BadgeType.saver);
    }
  }

  /// Call after a charity donation (donateCharity / donateBucket) completes.
  Future<void> evaluateAfterDonation(
    String familyId,
    String childId,
  ) async {
    await _badgeRepo.awardBadge(familyId, childId, BadgeType.generousHeart);
  }

  /// Call after an investment multiply completes.
  Future<void> evaluateAfterInvestmentMultiply(
    String familyId,
    String childId,
  ) async {
    await _badgeRepo.awardBadge(familyId, childId, BadgeType.youngInvestor);
  }

  /// Call after a savings goal is marked completed.
  Future<void> evaluateAfterGoalCompleted(
    String familyId,
    String childId,
  ) async {
    await _badgeRepo.awardBadge(familyId, childId, BadgeType.goalGetter);
  }

  /// Call after a deposit to check whether the child has deposited in each of
  /// the 4 most recent calendar weeks. Awards the streak badge if so.
  ///
  /// Queries the family-level transactions collection for money-adding
  /// transactions belonging to this child in the last 28 days, then checks
  /// whether at least one deposit exists in each of the 4 calendar weeks.
  Future<void> evaluateStreak(
    String familyId,
    String childId,
  ) async {
    final fourWeeksAgo = DateTime.now().subtract(const Duration(days: 28));

    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .where('childId', isEqualTo: childId)
        .where('type', whereIn: ['moneyAdded', 'distributed', 'moneySet'])
        .where('performedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fourWeeksAgo))
        .get();

    if (snapshot.docs.isEmpty) return;

    // Determine which ISO week numbers are covered.
    final coveredWeeks = <int>{};
    for (final doc in snapshot.docs) {
      final rawDate = doc.data()['performedAt'];
      if (rawDate == null) continue;
      final date = rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.parse(rawDate as String);
      coveredWeeks.add(_isoWeekNumber(date));
    }

    // We need the 4 most recent weeks (including current) to all be covered.
    final now = DateTime.now();
    final requiredWeeks = {
      _isoWeekNumber(now),
      _isoWeekNumber(now.subtract(const Duration(days: 7))),
      _isoWeekNumber(now.subtract(const Duration(days: 14))),
      _isoWeekNumber(now.subtract(const Duration(days: 21))),
    };

    if (requiredWeeks.every(coveredWeeks.contains)) {
      await _badgeRepo.awardBadge(familyId, childId, BadgeType.streak);
    }
  }

  /// Returns the ISO week number for a given [date].
  int _isoWeekNumber(DateTime date) {
    // ISO week: week containing the first Thursday of the year.
    final thursday =
        date.add(Duration(days: 4 - (date.weekday == 7 ? 0 : date.weekday)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    return 1 +
        (thursday.difference(firstDayOfYear).inDays +
                (firstDayOfYear.weekday - 1)) ~/
            7;
  }
}

final badgeEvaluationServiceProvider = Provider<BadgeEvaluationService>((ref) {
  final badgeRepo = ref.watch(badgeRepositoryProvider);
  return BadgeEvaluationService(badgeRepo, FirebaseFirestore.instance);
});
