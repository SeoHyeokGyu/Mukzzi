import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/repositories/reward_repository.dart';
import '../../domain/models/reward_model.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository(ref.watch(apiClientProvider));
});

final rewardListProvider = FutureProvider<List<RewardModel>>((ref) {
  return ref.watch(rewardRepositoryProvider).getRewards();
});
