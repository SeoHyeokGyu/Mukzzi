import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/exceptions.dart';
import '../../../../core/providers/common_providers.dart';
import '../../data/datasources/quest_remote_data_source.dart';
import '../../data/repositories/quest_repository_impl.dart';
import '../../domain/entities/quest.dart';

final questRepositoryProvider = Provider<QuestRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return QuestRepositoryImpl(QuestRemoteDataSourceImpl(dio));
});

class QuestState {
  final List<Quest> quests;
  final bool isLoading;
  final String? error;

  QuestState({
    this.quests = const [],
    this.isLoading = false,
    this.error,
  });

  QuestState copyWith({
    List<Quest>? quests,
    bool? isLoading,
    String? error,
  }) {
    return QuestState(
      quests: quests ?? this.quests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class QuestNotifier extends StateNotifier<QuestState> {
  final QuestRepository _repository;

  QuestNotifier(this._repository) : super(QuestState());

  Future<void> fetchQuests({String? period}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quests = await _repository.getQuests(period: period);
      state = state.copyWith(quests: quests, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '퀘스트를 불러오는 데 실패했습니다.');
    }
  }

  Future<bool> claimReward(String userQuestId) async {
    try {
      await _repository.claimReward(userQuestId);
      // 성공 시 목록 갱신
      await fetchQuests();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final questProvider = StateNotifierProvider<QuestNotifier, QuestState>((ref) {
  final repository = ref.watch(questRepositoryProvider);
  return QuestNotifier(repository);
});

// 편의를 위한 필터링된 프로바이더들
final dailyQuestsProvider = Provider<List<Quest>>((ref) {
  final state = ref.watch(questProvider);
  return state.quests.where((q) => q.type == QuestType.daily).toList();
});

final weeklyQuestsProvider = Provider<List<Quest>>((ref) {
  final state = ref.watch(questProvider);
  return state.quests.where((q) => q.type == QuestType.weekly).toList();
});

final achievementQuestsProvider = Provider<List<Quest>>((ref) {
  final state = ref.watch(questProvider);
  return state.quests.where((q) => q.type == QuestType.achievement).toList();
});
