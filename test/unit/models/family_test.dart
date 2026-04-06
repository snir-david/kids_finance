import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/family/domain/family.dart';

void main() {
  group('Family', () {
    late Family family;
    
    setUp(() {
      family = Family(
        id: 'fam1',
        name: 'The Smiths',
        parentIds: ['uid1'],
        childIds: ['child1'],
        createdAt: DateTime(2024, 1, 1),
      );
    });
    
    test('creates with required fields', () {
      expect(family.id, 'fam1');
      expect(family.name, 'The Smiths');
      expect(family.schemaVersion, '1.0.0'); // default
      expect(family.parentIds, ['uid1']);
      expect(family.childIds, ['child1']);
    });
    
    test('copyWith replaces fields', () {
      final updated = family.copyWith(name: 'The Joneses');
      expect(updated.name, 'The Joneses');
      expect(updated.id, family.id); // unchanged
      expect(updated.parentIds, family.parentIds); // unchanged
    });
    
    test('copyWith can update parentIds', () {
      final updated = family.copyWith(parentIds: ['uid1', 'uid2']);
      expect(updated.parentIds, ['uid1', 'uid2']);
      expect(updated.name, family.name); // unchanged
    });
    
    test('equality works', () {
      final same = Family(
        id: 'fam1',
        name: 'The Smiths',
        parentIds: ['uid1'],
        childIds: ['child1'],
        createdAt: DateTime(2024, 1, 1),
      );
      expect(family, equals(same));
    });
    
    test('inequality works with different id', () {
      final different = family.copyWith(id: 'fam2');
      expect(family, isNot(equals(different)));
    });
    
    test('props includes all fields', () {
      expect(family.props, [
        'fam1',
        'The Smiths',
        ['uid1'],
        ['child1'],
        DateTime(2024, 1, 1),
        '1.0.0',
      ]);
    });
  });
}
