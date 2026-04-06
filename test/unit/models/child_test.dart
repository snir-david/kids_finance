import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/children/domain/child.dart';

void main() {
  group('Child', () {
    late Child child;
    
    setUp(() {
      child = Child(
        id: 'child1',
        familyId: 'fam1',
        displayName: 'Alice',
        avatarEmoji: '🦄',
        pinHash: 'hashed_pin_123',
        sessionExpiresAt: DateTime(2024, 2, 1),
        createdAt: DateTime(2024, 1, 1),
      );
    });
    
    test('creates with required fields', () {
      expect(child.id, 'child1');
      expect(child.familyId, 'fam1');
      expect(child.displayName, 'Alice');
      expect(child.avatarEmoji, '🦄');
      expect(child.pinHash, 'hashed_pin_123');
    });
    
    test('sessionExpiresAt can be null', () {
      final childWithoutSession = Child(
        id: 'child2',
        familyId: 'fam1',
        displayName: 'Bob',
        avatarEmoji: '🚀',
        pinHash: 'hash',
        sessionExpiresAt: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(childWithoutSession.sessionExpiresAt, isNull);
    });
    
    test('copyWith replaces fields', () {
      final updated = child.copyWith(displayName: 'Alicia');
      expect(updated.displayName, 'Alicia');
      expect(updated.id, child.id); // unchanged
      expect(updated.familyId, child.familyId); // unchanged
    });
    
    test('copyWith can update sessionExpiresAt', () {
      final newExpiry = DateTime(2024, 3, 1);
      final updated = child.copyWith(sessionExpiresAt: newExpiry);
      expect(updated.sessionExpiresAt, newExpiry);
    });
    
    test('equality works', () {
      final same = Child(
        id: 'child1',
        familyId: 'fam1',
        displayName: 'Alice',
        avatarEmoji: '🦄',
        pinHash: 'hashed_pin_123',
        sessionExpiresAt: DateTime(2024, 2, 1),
        createdAt: DateTime(2024, 1, 1),
      );
      expect(child, equals(same));
    });
    
    test('inequality works with different displayName', () {
      final different = child.copyWith(displayName: 'Bob');
      expect(child, isNot(equals(different)));
    });
    
    test('props includes all fields including nullable sessionExpiresAt', () {
      expect(child.props, [
        'child1',
        'fam1',
        'Alice',
        '🦄',
        'hashed_pin_123',
        DateTime(2024, 2, 1),
        DateTime(2024, 1, 1),
      ]);
    });
  });
}
