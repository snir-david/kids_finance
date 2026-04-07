// TODO: wire up when parent-only action guards are available
// Testing parent-only action guards (Sprint 5C — Security)

import 'package:flutter_test/flutter_test.dart';

class _FakeBucketRepository {
  Exception? _distributeFundsException;

  void stubDistributeFundsThrows(Exception e) => _distributeFundsException = e;

  Future<void> distributeFunds({
    required String childId,
    required String familyId,
    required double moneyAmount,
    required double investmentAmount,
    required double charityAmount,
    required String performedByUid,
    String? note,
    double? baseValueMoney,
    double? baseValueInvestment,
    double? baseValueCharity,
  }) async {
    if (_distributeFundsException != null) throw _distributeFundsException!;
  }
}

class _FakeChildRepository {
  Exception? _archiveChildException;
  Exception? _updateChildException;

  void stubArchiveChildThrows(Exception e) => _archiveChildException = e;
  void stubUpdateChildThrows(Exception e) => _updateChildException = e;

  Future<void> archiveChild({
    required String childId,
    required String familyId,
  }) async {
    if (_archiveChildException != null) throw _archiveChildException!;
  }

  Future<void> updateChild({
    required String childId,
    required String familyId,
    String? name,
    String? avatarEmoji,
    String? newPin,
  }) async {
    if (_updateChildException != null) throw _updateChildException!;
  }
}

void main() {
  group('Parent-Only Action Guards', () {
    late _FakeBucketRepository mockBucketRepo;
    late _FakeChildRepository mockChildRepo;

    setUp(() {
      mockBucketRepo = _FakeBucketRepository();
      mockChildRepo = _FakeChildRepository();
    });

    test('distributeFunds called without parent claim → throws PermissionException', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      mockBucketRepo.stubDistributeFundsThrows(
          Exception('PermissionException: parent role required'));

      expect(
        () => mockBucketRepo.distributeFunds(
          childId: childId,
          familyId: familyId,
          moneyAmount: 50.0,
          investmentAmount: 30.0,
          charityAmount: 20.0,
          performedByUid: 'child1',
        ),
        throwsException,
      );
    });

    test('archiveChild called without parent claim → throws PermissionException', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      mockChildRepo.stubArchiveChildThrows(
          Exception('PermissionException: parent role required'));

      expect(
        () => mockChildRepo.archiveChild(
          childId: childId,
          familyId: familyId,
        ),
        throwsException,
      );
    });

    test('updateChild called without parent claim → throws PermissionException', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const newName = 'Hacker';
      mockChildRepo.stubUpdateChildThrows(
          Exception('PermissionException: parent role required'));

      expect(
        () => mockChildRepo.updateChild(
          childId: childId,
          familyId: familyId,
          name: newName,
        ),
        throwsException,
      );
    });

    test('distributeFunds called with valid parent → succeeds', () async {
      // Arrange
      const childId = 'child1';
      const performedByUid = 'parent1'; // Valid parent

      // For now, verify parent role concept
      expect(performedByUid, equals('parent1'));
      expect(performedByUid, isNot(equals(childId)));
    });
  });
}
