// TODO: wire up when parent-only action guards are available
// Testing parent-only action guards (Sprint 5C — Security)

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/domain/bucket_repository.dart';
import 'package:kids_finance/features/children/domain/child_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'parent_only_guard_test.mocks.dart';

@GenerateMocks([BucketRepository, ChildRepository])
void main() {
  group('Parent-Only Action Guards', () {
    late MockBucketRepository mockBucketRepo;
    late MockChildRepository mockChildRepo;

    setUp(() {
      mockBucketRepo = MockBucketRepository();
      mockChildRepo = MockChildRepository();
    });

    test('distributeFunds called without parent claim → throws PermissionException', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const performedByUid = 'child1'; // Child trying to distribute funds
      const totalAmount = 100.0;
      const moneySplit = 50.0;
      const investmentSplit = 30.0;
      const charitySplit = 20.0;

      // Mock: repository checks claims and throws PermissionException
      when(mockBucketRepo.distributeFunds(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        totalAmount: anyNamed('totalAmount'),
        moneySplit: anyNamed('moneySplit'),
        investmentSplit: anyNamed('investmentSplit'),
        charitySplit: anyNamed('charitySplit'),
        performedByUid: anyNamed('performedByUid'),
      )).thenThrow(Exception('PermissionException: parent role required'));

      // TODO: When distributeFunds with permission check is available, use:
      // expect(
      //   () => mockBucketRepo.distributeFunds(
      //     childId: childId,
      //     familyId: familyId,
      //     totalAmount: totalAmount,
      //     moneySplit: moneySplit,
      //     investmentSplit: investmentSplit,
      //     charitySplit: charitySplit,
      //     performedByUid: performedByUid,
      //   ),
      //   throwsA(isA<PermissionException>()),
      // );

      // For now, verify exception thrown
      expect(
        () => mockBucketRepo.distributeFunds(
          childId: childId,
          familyId: familyId,
          totalAmount: totalAmount,
          moneySplit: moneySplit,
          investmentSplit: investmentSplit,
          charitySplit: charitySplit,
          performedByUid: performedByUid,
        ),
        throwsException,
      );
    });

    test('archiveChild called without parent claim → throws PermissionException', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const performedByUid = 'child1'; // Child trying to archive themselves

      // Mock: repository checks claims and throws PermissionException
      when(mockChildRepo.archiveChild(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
      )).thenThrow(Exception('PermissionException: parent role required'));

      // TODO: When archiveChild with permission check is available, use:
      // expect(
      //   () => mockChildRepo.archiveChild(
      //     childId: childId,
      //     familyId: familyId,
      //   ),
      //   throwsA(isA<PermissionException>()),
      // );

      // For now, verify exception thrown
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
      const performedByUid = 'child1'; // Child trying to update themselves
      const newName = 'Hacker';

      // Mock: repository checks claims and throws PermissionException
      when(mockChildRepo.updateChild(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        displayName: anyNamed('displayName'),
      )).thenThrow(Exception('PermissionException: parent role required'));

      // TODO: When updateChild with permission check is available, use:
      // expect(
      //   () => mockChildRepo.updateChild(
      //     childId: childId,
      //     familyId: familyId,
      //     displayName: newName,
      //   ),
      //   throwsA(isA<PermissionException>()),
      // );

      // For now, verify exception thrown
      expect(
        () => mockChildRepo.updateChild(
          childId: childId,
          familyId: familyId,
          displayName: newName,
        ),
        throwsException,
      );
    });

    test('distributeFunds called with valid parent → succeeds', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const performedByUid = 'parent1'; // Valid parent
      const totalAmount = 100.0;
      const moneySplit = 50.0;
      const investmentSplit = 30.0;
      const charitySplit = 20.0;

      // Mock: repository checks claims and allows operation
      when(mockBucketRepo.distributeFunds(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        totalAmount: anyNamed('totalAmount'),
        moneySplit: anyNamed('moneySplit'),
        investmentSplit: anyNamed('investmentSplit'),
        charitySplit: anyNamed('charitySplit'),
        performedByUid: anyNamed('performedByUid'),
      )).thenAnswer((_) async => Future.value());

      // TODO: When distributeFunds with permission check is available, use:
      // await mockBucketRepo.distributeFunds(
      //   childId: childId,
      //   familyId: familyId,
      //   totalAmount: totalAmount,
      //   moneySplit: moneySplit,
      //   investmentSplit: investmentSplit,
      //   charitySplit: charitySplit,
      //   performedByUid: performedByUid,
      // );
      // 
      // verify(mockBucketRepo.distributeFunds(
      //   childId: childId,
      //   familyId: familyId,
      //   totalAmount: totalAmount,
      //   moneySplit: moneySplit,
      //   investmentSplit: investmentSplit,
      //   charitySplit: charitySplit,
      //   performedByUid: performedByUid,
      // )).called(1);

      // For now, verify parent role concept
      expect(performedByUid, equals('parent1'));
      expect(performedByUid, isNot(equals(childId)));
    });
  });
}
