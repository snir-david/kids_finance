import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'badge_repository.dart';
import 'firebase_badge_repository.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return FirebaseBadgeRepository();
});
