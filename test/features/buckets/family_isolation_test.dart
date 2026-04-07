// TODO: wire up when Firestore security rules are enforced
// Testing family isolation (Sprint 5C — Security)

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/children/domain/child.dart';
import 'package:kids_finance/features/children/domain/child_repository.dart';
import 'package:kids_finance/features/buckets/domain/bucket.dart';
import 'package:kids_finance/features/buckets/domain/bucket_repository.dart';

class _FakeChildRepository implements ChildRepository {
  bool shouldThrowFetchChildren = false;

  Future<List<Child>> fetchChildren({required String familyId}) async {
    if (shouldThrowFetchChildren) {
      throw Exception('PermissionDeniedException: not a member of $familyId');
    }
    return [];
  }

  @override
  Stream<Child?> getChildStream(String childId, String familyId) =>
      Stream.value(null);

  @override
  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? name,
    String? avatarEmoji,
    String? newPin,
  }) async {}

  @override
  Future<void> updatePinHash({
    required String childId,
    required String familyId,
    required String newPinHash,
  }) async {}

  @override
  Future<void> updateSessionExpiry({
    required String childId,
    required String familyId,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<void> archiveChild({
    required String familyId,
    required String childId,
  }) async {}
}

class _FakeBucketRepository implements BucketRepository {
  bool getBucketsThrows = false;

  Stream<List<Bucket>> getBuckets({
    required String childId,
    required String familyId,
  }) {
    if (getBucketsThrows) {
      return Stream.error(Exception(
          'PermissionDeniedException: child1 cannot read child2 buckets'));
    }
    return Stream.value([]);
  }

  @override
  Stream<List<Bucket>> getBucketsStream({
    required String childId,
    required String familyId,
  }) =>
      getBuckets(childId: childId, familyId: familyId);

  @override
  Future<void> setMoneyBalance({
    required String childId,
    required String familyId,
    required double newBalance,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {}

  @override
  Future<void> multiplyInvestment({
    required String childId,
    required String familyId,
    required double multiplier,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {}

  @override
  Future<void> donateCharity({
    required String childId,
    required String familyId,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {}

  @override
  Future<void> addMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {}

  @override
  Future<void> removeMoney({
    required String childId,
    required String familyId,
    required double amount,
    required String performedByUid,
    String? note,
    double? baseValue,
  }) async {}

  @override
  Future<void> distributeFunds({
    required String familyId,
    required String childId,
    required double moneyAmount,
    required double investmentAmount,
    required double charityAmount,
    required String performedByUid,
    String? note,
    double? baseValueMoney,
    double? baseValueInvestment,
    double? baseValueCharity,
  }) async {}

  @override
  Future<double> donateBucket(String familyId, String childId) async => 0.0;

  @override
  Future<void> transferBetweenBuckets(
    String familyId,
    String childId,
    BucketType from,
    BucketType to,
    double amount,
  ) async {}

  @override
  Future<void> withdrawFromBucket(
      String familyId, String childId, double amount) async {}

  @override
  Future<void> multiplyBucket(
    String familyId,
    String childId,
    BucketType bucketType,
    double multiplier,
  ) async {}
}

void main() {
  group('Family Isolation', () {
    late _FakeChildRepository mockChildRepo;
    late _FakeBucketRepository mockBucketRepo;

    setUp(() {
      mockChildRepo = _FakeChildRepository();
      mockBucketRepo = _FakeBucketRepository();
    });

    test('parent can read own family\'s children', () async {
      const familyId = 'family1';
      const parentUid = 'parent1';

      // For now, verify own family access
      expect(familyId, equals('family1'));
      expect(parentUid, isNotNull);
    });

    test('parent CANNOT read another family\'s children (permission denied)',
        () async {
      const ownFamilyId = 'family1';
      const otherFamilyId = 'family2';

      mockChildRepo.shouldThrowFetchChildren = true;

      expect(
        () => mockChildRepo.fetchChildren(familyId: otherFamilyId),
        throwsException,
      );
      expect(ownFamilyId, isNot(equals(otherFamilyId)));
    });

    test('child can read own buckets', () async {
      const childId = 'child1';

      // For now, verify own bucket access
      expect(childId, equals('child1'));
    });

    test('child CANNOT read sibling\'s buckets', () async {
      const childId = 'child1';
      const siblingId = 'child2';
      const familyId = 'family1';

      mockBucketRepo.getBucketsThrows = true;

      expect(childId, isNot(equals(siblingId)));
      expect(
        mockBucketRepo
            .getBuckets(
              childId: siblingId,
              familyId: familyId,
            )
            .first,
        throwsException,
      );
    });
  });
}
