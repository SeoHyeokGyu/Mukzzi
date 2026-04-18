import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 추가
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/collection_states.dart';
import '../providers/social_providers.dart';
import '../../../profile/data/models/user_model.dart';

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('소셜'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '친구'),
            Tab(text: '요청'),
            Tab(text: '검색'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FriendListTab(),
          _FriendRequestTab(),
          _UserSearchTab(),
        ],
      ),
    );
  }
}

class _FriendListTab extends ConsumerWidget {
  const _FriendListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => CollectionErrorState(onRetry: () => ref.invalidate(friendsListProvider)),
      data: (friends) {
        if (friends.isEmpty) {
          return const CollectionEmptyState(
            icon: Icons.people_outline,
            title: '아직 친구가 없어요',
            subtitle: '검색 탭에서 친구를 찾아보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            final hasImage = friend.profileImageUrl != null && friend.profileImageUrl!.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: BentoCard(
                child: ListTile(
                  onTap: () => context.push('/social/profile/${friend.id}'), // 프로필 이동 추가
                  leading: CircleAvatar(
                    backgroundImage: hasImage ? NetworkImage(friend.profileImageUrl!) : null,
                    child: !hasImage ? const Icon(Icons.person) : null,
                  ),
                  title: Text(friend.nickname ?? friend.username),
                  subtitle: const Text('Lv.1 · 기분좋음'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '응원하기',
                        icon: const Icon(Icons.favorite_outline, size: 20),
                        color: AppColors.orange,
                        onPressed: () async {
                          try {
                            await ref.read(socialRepositoryProvider).nudgeFriend(friend.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('응원을 보냈어요!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('응원 보내기에 실패했습니다.')),
                              );
                            }
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'profile') {
                            context.push('/social/profile/${friend.id}');
                          } else if (value == 'delete') {
                            await ref.read(socialRepositoryProvider).deleteFriend(friend.id);
                            ref.invalidate(friendsListProvider);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'profile', child: Text('프로필 보기')),
                          PopupMenuItem(value: 'delete', child: Text('친구 삭제')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FriendRequestTab extends ConsumerWidget {
  const _FriendRequestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => CollectionErrorState(onRetry: () => ref.invalidate(friendRequestsProvider)),
      data: (requests) {
        if (requests.isEmpty) {
          return const CollectionEmptyState(
            icon: Icons.inbox_outlined,
            title: '받은 친구 요청이 없어요',
            subtitle: '검색 탭에서 먼저 친구 요청을 보내보세요',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final hasImage = req.profileImageUrl != null && req.profileImageUrl!.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: BentoCard(
                child: ListTile(
                  onTap: () => context.push('/social/profile/${req.id}'), // 프로필 이동 추가
                  leading: CircleAvatar(
                    backgroundImage: hasImage ? NetworkImage(req.profileImageUrl!) : null,
                    child: !hasImage ? const Icon(Icons.person) : null,
                  ),
                  title: Text(req.nickname ?? req.username),
                  subtitle: const Text('친구 요청을 받았습니다'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '수락',
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await ref.read(socialRepositoryProvider).acceptFriendRequest(req.id);
                          ref.invalidate(friendRequestsProvider);
                          ref.invalidate(friendsListProvider);
                        },
                      ),
                      IconButton(
                        tooltip: '거절',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await ref.read(socialRepositoryProvider).rejectFriendRequest(req.id);
                          ref.invalidate(friendRequestsProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UserSearchTab extends ConsumerWidget {
  const _UserSearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(userSearchProvider);
    final recsAsync = ref.watch(recommendedUsersProvider);

    return Column(
      children: [
        // 검색 바
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) => ref.read(userSearchProvider.notifier).search(value),
            decoration: InputDecoration(
              hintText: '닉네임 또는 고유 ID로 검색',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        
        // 검색 결과 또는 추천 목록
        Expanded(
          child: searchState.query.isNotEmpty
              ? _buildSearchResults(searchState)
              : _buildRecommendedList(recsAsync, ref),
        ),
      ],
    );
  }

  Widget _buildSearchResults(UserSearchState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.results.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: state.results.length,
      itemBuilder: (context, index) => _UserItemCard(user: state.results[index]),
    );
  }

  Widget _buildRecommendedList(AsyncValue<List<UserModel>> recsAsync, WidgetRef ref) {
    return recsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => CollectionErrorState(onRetry: () => ref.invalidate(recommendedUsersProvider)),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('닉네임으로 새로운 친구를 찾아보세요!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: users.length,
          itemBuilder: (context, index) => _UserItemCard(user: users[index], isRecommendation: true),
        );
      },
    );
  }
}

class _UserItemCard extends ConsumerWidget {
  final UserModel user;
  final bool isRecommendation;

  const _UserItemCard({required this.user, this.isRecommendation = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;
    
    // 관계 상태 확인
    final isFriend = ref.watch(friendIdsProvider).contains(user.id);
    final isReceivedRequest = ref.watch(receivedRequestIdsProvider).contains(user.id);
    final isSentRequest = ref.watch(sentRequestIdsProvider).contains(user.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: BentoCard(
        child: InkWell(
          onTap: () => context.push('/social/profile/${user.id}'), // 프로필 이동 추가
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: hasImage ? NetworkImage(user.profileImageUrl!) : null,
                  child: !hasImage ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nickname ?? user.username, style: Theme.of(context).textTheme.titleMedium),
                      if (isRecommendation) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Lv.1', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.softPeach,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('추천', style: TextStyle(fontSize: 10, color: AppColors.orange)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(user.username, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ],
                  ),
                ),
                
                // 관계 상태에 따른 버튼 처리
                if (isFriend)
                  const _StatusChip(label: '친구', color: Colors.green)
                else if (isReceivedRequest)
                  const _StatusChip(label: '요청 수신', color: AppColors.orange)
                else if (isSentRequest)
                  const _StatusChip(label: '요청 보냄', color: Colors.grey)
                else
                  IconButton(
                    tooltip: '친구 요청 보내기',
                    icon: const Icon(Icons.person_add),
                    onPressed: () async {
                      try {
                        await ref.read(socialRepositoryProvider).sendFriendRequest(user.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('친구 요청을 보냈습니다')),
                          );
                          // 보낸 요청 목록 새로고침
                          ref.invalidate(sentRequestsProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
