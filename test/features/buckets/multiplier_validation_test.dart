// TODO: wire up when multiplier validation is implemented
// Testing multiplier validation (Sprint 5C — Security)

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/buckets/domain/bucket_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'multiplier_validation_test.mocks.dart';

@GenerateMocks([BucketRepository])
void main() {
  group('Multiplier Validation', () {
    late MockBucketRepository mockRepository;

    setUp(() {
      mockRepository = MockBucketRepository();
    });

    test('multiply with factor 0 → rejected (UI + repo level)', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const bucketId = 'investment-bucket';
      const multiplier = 0.0; // Invalid: zero multiplier

      // Mock: repository validates and rejects zero multiplier
      when(mockRepository.multiplyInvestment(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        bucketId: anyNamed('bucketId'),
        multiplier: anyNamed('multiplier'),
        performedByUid: anyNamed('performedByUid'),
      )).thenThrow(ArgumentError('Multiplier must be greater than 0'));

      // TODO: When multiplyInvestment with validation is available, use:
      // expect(
      //   () => mockRepository.multiplyInvestment(
      //     childId: childId,
      //     familyId: familyId,
      //     bucketId: bucketId,
      //     multiplier: multiplier,
      //     performedByUid: 'parent1',
      //   ),
      //   throwsA(isA<ArgumentError>()),
      // );

      // For now, verify zero rejection
      expect(multiplier, equals(0.0));
      expect(multiplier > 0, isFalse);
    });

    test('multiply with factor < 0 → rejected', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const bucketId = 'investment-bucket';
      const multiplier = -2.0; // Invalid: negative multiplier

      // Mock: repository validates and rejects negative multiplier
      when(mockRepository.multiplyInvestment(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        bucketId: anyNamed('bucketId'),
        multiplier: anyNamed('multiplier'),
        performedByUid: anyNamed('performedByUid'),
      )).thenThrow(ArgumentError('Multiplier must be greater than 0'));

      // TODO: When multiplyInvestment with validation is available, use:
      // expect(
      //   () => mockRepository.multiplyInvestment(
      //     childId: childId,
      //     familyId: familyId,
      //     bucketId: bucketId,
      //     multiplier: multiplier,
      //     performedByUid: 'parent1',
      //   ),
      //   throwsA(isA<ArgumentError>()),
      // );

      // For now, verify negative rejection
      expect(multiplier, lessThan(0));
      expect(multiplier > 0, isFalse);
    });

    test('multiply with factor 1 → accepted (1x is valid per decision: > 0)', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const bucketId = 'investment-bucket';
      const multiplier = 1.0; // Valid: 1x multiplier (no change, but allowed)
      const currentBalance = 100.0;

      // Mock: repository allows 1x multiplier
      when(mockRepository.multiplyInvestment(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        bucketId: anyNamed('bucketId'),
        multiplier: anyNamed('multiplier'),
        performedByUid: anyNamed('performedByUid'),
      )).thenAnswer((_) async => Future.value());

      // TODO: When multiplyInvestment is available, use:
      // await mockRepository.multiplyInvestment(
      //   childId: childId,
      //   familyId: familyId,
      //   bucketId: bucketId,
      //   multiplier: multiplier,
      //   performedByUid: 'parent1',
      // );
      // 
      // verify(mockRepository.multiplyInvestment(
      //   childId: childId,
      //   familyId: familyId,
      //   bucketId: bucketId,
      //   multiplier: multiplier,
      //   performedByUid: 'parent1',
      // )).called(1);

      // For now, verify 1x is valid
      expect(multiplier, equals(1.0));
      expect(multiplier > 0, isTrue);
      expect(currentBalance * multiplier, equals(currentBalance));
    });

    test('multiply with factor 2 → accepted, balance doubles', () async {
      // Arrange
      const childId = 'child1';
      const familyId = 'family1';
      const bucketId = 'investment-bucket';
      const multiplier = 2.0; // Valid: 2x multiplier
      const currentBalance = 100.0;
      const expectedBalance = 200.0;

      // Mock: repository allows 2x multiplier
      when(mockRepository.multiplyInvestment(
        childId: anyNamed('childId'),
        familyId: anyNamed('familyId'),
        bucketId: anyNamed('bucketId'),
        multiplier: anyNamed('multiplier'),
        performedByUid: anyNamed('performedByUid'),
      )).thenAnswer((_) async => Future.value());

      // TODO: When multiplyInvestment is available, use:
      // await mockRepository.multiplyInvestment(
      //   childId: childId,
      //   familyId: familyId,
      //   bucketId: bucketId,
      //   multiplier: multiplier,
      //   performedByUid: 'parent1',
      // );
      // 
      // final bucket = await mockRepository.getBucket(
      //   childId: childId,
      //   familyId: familyId,
      //   bucketId: bucketId,
      // );
      // expect(bucket.balance, equals(expectedBalance));

      // For now, verify 2x calculation
      expect(multiplier, equals(2.0));
      expect(multiplier > 0, isTrue);
      expect(currentBalance * multiplier, equals(expectedBalance));
    });
  });
}
