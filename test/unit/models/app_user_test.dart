import 'package:flutter_test/flutter_test.dart';
import 'package:kids_finance/features/auth/domain/app_user.dart';

void main() {
  group('AppUserRole', () {
    test('has exactly 3 values', () {
      expect(AppUserRole.values.length, 3);
    });
    
    test('contains parent, child, and unauthenticated', () {
      expect(AppUserRole.values, contains(AppUserRole.parent));
      expect(AppUserRole.values, contains(AppUserRole.child));
      expect(AppUserRole.values, contains(AppUserRole.unauthenticated));
    });
    
    test('toJson returns string name', () {
      expect(AppUserRole.parent.toJson(), 'parent');
      expect(AppUserRole.child.toJson(), 'child');
      expect(AppUserRole.unauthenticated.toJson(), 'unauthenticated');
    });
    
    test('fromJson parses correctly', () {
      expect(AppUserRole.fromJson('parent'), AppUserRole.parent);
      expect(AppUserRole.fromJson('child'), AppUserRole.child);
      expect(AppUserRole.fromJson('unauthenticated'), AppUserRole.unauthenticated);
    });
    
    test('fromJson returns unauthenticated for invalid value', () {
      expect(AppUserRole.fromJson('invalid'), AppUserRole.unauthenticated);
    });
  });
  
  group('AppUser', () {
    late AppUser parentUser;
    late AppUser childUser;
    late AppUser unauthenticatedUser;
    
    setUp(() {
      parentUser = AppUser(
        id: 'uid1',
        email: 'parent@example.com',
        role: AppUserRole.parent,
        familyId: 'fam1',
        childId: null,
      );
      
      childUser = AppUser(
        id: 'child1',
        email: 'child@example.com',
        role: AppUserRole.child,
        familyId: 'fam1',
        childId: 'child1',
      );
      
      unauthenticatedUser = AppUser(
        id: '',
        email: '',
        role: AppUserRole.unauthenticated,
        familyId: null,
        childId: null,
      );
    });
    
    test('parent user has correct role and familyId', () {
      expect(parentUser.role, AppUserRole.parent);
      expect(parentUser.familyId, 'fam1');
      expect(parentUser.childId, isNull);
    });
    
    test('child user has correct role and childId', () {
      expect(childUser.role, AppUserRole.child);
      expect(childUser.familyId, 'fam1');
      expect(childUser.childId, 'child1');
    });
    
    test('unauthenticated user has empty fields', () {
      expect(unauthenticatedUser.role, AppUserRole.unauthenticated);
      expect(unauthenticatedUser.familyId, isNull);
      expect(unauthenticatedUser.childId, isNull);
    });
    
    test('copyWith replaces fields', () {
      final updated = parentUser.copyWith(email: 'newemail@example.com');
      expect(updated.email, 'newemail@example.com');
      expect(updated.id, parentUser.id); // unchanged
    });
    
    test('copyWith can change role', () {
      final updated = parentUser.copyWith(role: AppUserRole.child);
      expect(updated.role, AppUserRole.child);
    });
    
    test('equality works', () {
      final same = AppUser(
        id: 'uid1',
        email: 'parent@example.com',
        role: AppUserRole.parent,
        familyId: 'fam1',
        childId: null,
      );
      expect(parentUser, equals(same));
    });
    
    test('inequality works with different role', () {
      final different = parentUser.copyWith(role: AppUserRole.child);
      expect(parentUser, isNot(equals(different)));
    });
    
    test('toJson includes all fields', () {
      final json = parentUser.toJson();
      expect(json['id'], 'uid1');
      expect(json['email'], 'parent@example.com');
      expect(json['role'], 'parent');
      expect(json['familyId'], 'fam1');
      expect(json['childId'], isNull);
    });
    
    test('fromJson creates AppUser correctly', () {
      final json = {
        'id': 'uid2',
        'email': 'test@example.com',
        'role': 'parent',
        'familyId': 'fam2',
        'childId': null,
      };
      final user = AppUser.fromJson(json);
      expect(user.id, 'uid2');
      expect(user.email, 'test@example.com');
      expect(user.role, AppUserRole.parent);
      expect(user.familyId, 'fam2');
    });
    
    test('props includes all fields', () {
      expect(parentUser.props, [
        'uid1',
        'parent@example.com',
        AppUserRole.parent,
        'fam1',
        null,
      ]);
    });
  });
}
