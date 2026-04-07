import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/badge_repository_provider.dart';

/// StreamProvider for a child's badges, ordered by earnedAt desc.
/// Params: ({familyId, childId})
final badgesProvider = StreamProvider.family<List<Badge>,
    ({String familyId, String childId})>((ref, params) {
  final repository = ref.watch(badgeRepositoryProvider);
  return repository.watchBadges(params.familyId, params.childId);
});

/// Derived provider counting badges not yet seen by the child.
final unseenBadgeCountProvider = Provider.family<int,
    ({String familyId, String childId})>((ref, params) {
  final badges = ref.watch(badgesProvider(params));
  return badges.maybeWhen(
    data: (list) => list.where((b) => !b.seen).length,
    orElse: () => 0,
  );
});
