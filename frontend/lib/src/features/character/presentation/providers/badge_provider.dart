import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/repositories/badge_repository.dart';
import '../../domain/models/badge_model.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(ref.watch(apiClientProvider));
});

final badgeListProvider = FutureProvider<List<BadgeModel>>((ref) {
  return ref.watch(badgeRepositoryProvider).getBadges();
});
