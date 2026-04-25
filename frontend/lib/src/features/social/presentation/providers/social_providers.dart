import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/providers/common_providers.dart';
import '../../../profile/data/models/user_model.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(apiClientProvider));
});

// 친구 목록
final friendsListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(socialRepositoryProvider).getFriends();
});

final friendIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final friends = ref.watch(friendsListProvider).value ?? [];
  return friends.map((u) => u.id).toSet();
});

// 받은 친구 요청 목록
final friendRequestsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(socialRepositoryProvider).getPendingRequests();
});

final receivedRequestIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final requests = ref.watch(friendRequestsProvider).value ?? [];
  return requests.map((u) => u.id).toSet();
});

// 보낸 친구 요청 목록
final sentRequestsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.watch(socialRepositoryProvider).getSentRequests();
});

final sentRequestIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final requests = ref.watch(sentRequestsProvider).value ?? [];
  return requests.map((u) => u.id).toSet();
});

// 추천 사용자 목록
final recommendedUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/users/recommendations');
  final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
  return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
});

// 방명록 목록 (단순 조회용 - 프로필 요약 등)
final guestbookProvider = FutureProvider.autoDispose.family<List<GuestbookModel>, String>((ref, userId) async {
  return ref.watch(socialRepositoryProvider).getGuestbooks(userId, limit: 5);
});

// 방명록 페이징 상태 클래스
class GuestbookPageState {
  final List<GuestbookModel> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;

  GuestbookPageState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  GuestbookPageState copyWith({
    List<GuestbookModel>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
  }) {
    return GuestbookPageState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// 방명록 페이징 Notifier
class GuestbookPagingNotifier extends StateNotifier<GuestbookPageState> {
  final SocialRepository _repository;
  final String _userId;
  static const int _limit = 20;

  GuestbookPagingNotifier(this._repository, this._userId) : super(GuestbookPageState()) {
    fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newItems = await _repository.getGuestbooks(_userId, page: state.currentPage, limit: _limit);
      
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length == _limit,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = GuestbookPageState();
    await fetchNextPage();
  }
  
  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }
}

final guestbookPagingProvider = StateNotifierProvider.autoDispose.family<GuestbookPagingNotifier, GuestbookPageState, String>((ref, userId) {
  return GuestbookPagingNotifier(ref.watch(socialRepositoryProvider), userId);
});

// 사용자 검색 상태 클래스
class UserSearchState {
  final List<UserModel> results;
  final bool isLoading;
  final String query;

  UserSearchState({this.results = const [], this.isLoading = false, this.query = ''});

  UserSearchState copyWith({List<UserModel>? results, bool? isLoading, String? query}) {
    return UserSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
  }
}

// 사용자 검색 Notifier
class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final SocialRepository _repository;
  Timer? _debounce;

  UserSearchNotifier(this._repository) : super(UserSearchState());

  void search(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      state = UserSearchState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _repository.searchUsers(query);
        state = state.copyWith(results: results, isLoading: false);
      } catch (e) {
        if (mounted) {
          state = state.copyWith(isLoading: false, results: []);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final userSearchProvider = StateNotifierProvider.autoDispose<UserSearchNotifier, UserSearchState>((ref) {
  return UserSearchNotifier(ref.watch(socialRepositoryProvider));
});
