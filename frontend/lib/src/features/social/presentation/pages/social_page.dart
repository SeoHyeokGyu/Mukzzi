import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/collection_states.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import '../providers/social_providers.dart';
import '../../data/models/feed_model.dart';
import '../../../profile/data/models/user_model.dart';

CharacterState _stateFromString(String s) {
  switch (s) {
    case '행복':   return CharacterState.happy;
    case '배고픔': return CharacterState.hungry;
    case '굶주림': return CharacterState.starving;
    case '기력저하': return CharacterState.weak;
    default:       return CharacterState.normal;
  }
}

// TODO: (cjkang) 랭킹 데이터를 API로 교체
typedef _RankEntry = ({String name, int rank, int level, String state, bool isMe});

const List<_RankEntry> _mockRanking = [
  (name: '지원', rank: 1, level: 12, state: '행복',    isMe: false),
  (name: '현수', rank: 2, level: 9,  state: '평온',    isMe: false),
  (name: '민재', rank: 3, level: 7,  state: '배고픔',  isMe: true),
  (name: '서연', rank: 4, level: 6,  state: '평온',    isMe: false),
  (name: '도윤', rank: 5, level: 4,  state: '기력저하', isMe: false),
];

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('소셜'),
        actions: [
          IconButton(
            tooltip: '친구 관리',
            icon: const Icon(Icons.people_outline, size: 22),
            onPressed: () => context.push('/social/friends'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '피드'),
            Tab(text: '랭킹'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedTab(tokens: tokens),
          _RankingTab(tokens: tokens),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 피드 탭
// ─────────────────────────────────────────

class _FeedTab extends ConsumerWidget {
  final AppColorTokens tokens;
  const _FeedTab({required this.tokens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(socialFeedProvider);

    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feedState.posts.isEmpty) {
      return CollectionEmptyState(
        icon: Icons.newspaper_outlined,
        title: '아직 소식이 없어요',
        subtitle: '친구를 추가하면 친구들의 식사 소식을 볼 수 있어요',
        actionLabel: '친구 찾기',
        onAction: () => context.push('/social/friends'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(socialFeedProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            ref.read(socialFeedProvider.notifier).fetchNextPage();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: feedState.posts.length + (feedState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == feedState.posts.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final post = feedState.posts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: _FeedCard(post: post, tokens: tokens),
            );
          },
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedPost post;
  final AppColorTokens tokens;

  const _FeedCard({required this.post, required this.tokens});

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M월 d일').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = post.user.profileImageUrl != null && post.user.profileImageUrl!.isNotEmpty;
    
    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                  image: hasImage 
                    ? DecorationImage(
                        image: NetworkImage(post.user.profileImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: !hasImage 
                  ? Center(
                      child: Text(
                        (post.user.nickname ?? post.user.username)[0],
                        style: TextStyle(fontWeight: FontWeight.w700, color: tokens.primary, fontSize: 16),
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.user.nickname ?? post.user.username,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· Lv.1', 
                          style: TextStyle(fontSize: 11, color: tokens.textMuted),
                        ),
                      ],
                    ),
                    Text(_formatTime(post.meal.recordedAt), style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${post.meal.mealType}으로 ${post.meal.menuName}을(를) 먹었어요!',
            style: TextStyle(fontSize: 14, color: tokens.textPrimary),
          ),
          if (post.meal.review != null && post.meal.review!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.meal.review!,
              style: TextStyle(fontSize: 13, color: tokens.textSub),
            ),
          ],
          if (post.meal.imageUrl != null && post.meal.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.meal.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star_outline, size: 14, color: tokens.textSub),
              const SizedBox(width: 4),
              Text('응원하기', style: TextStyle(fontSize: 12, color: tokens.textSub)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 랭킹 탭
// ─────────────────────────────────────────

class _RankingTab extends StatelessWidget {
  final AppColorTokens tokens;
  const _RankingTab({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '이번 주 랭킹',
          style: TextStyle(fontSize: 13, color: tokens.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _mockRanking.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final r = _mockRanking[i];
              final isMe = r.isMe;
              return Container(
                width: 96,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe ? tokens.primaryBg : tokens.card,
                  borderRadius: BorderRadius.circular(tokens.rCard),
                  border: isMe ? Border.all(color: tokens.primary, width: 1) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${r.rank}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: r.rank <= 3 ? tokens.primary : tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF5E6D3),
                            Color(0xFFE8C89A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: MukzziCharacter(
                          state: _stateFromString(r.state),
                          size: 48,
                          level: r.level,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                    ),
                    Text(
                      'Lv.${r.level}',
                      style: TextStyle(fontSize: 10, color: tokens.textMuted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '전체 순위',
          style: TextStyle(fontSize: 13, color: tokens.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        BentoCard(
          borderRadius: BorderRadius.circular(tokens.rCard),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: _mockRanking.indexed.map((entry) {
              final (i, r) = entry;
              final isMe = r.isMe;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? tokens.primaryBg : Colors.transparent,
                  border: i < _mockRanking.length - 1
                      ? Border(bottom: BorderSide(color: tokens.primary.withValues(alpha: 0.08)))
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${r.rank}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: r.rank <= 3 ? tokens.primary : tokens.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5E6D3), Color(0xFFE8C89A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: MukzziCharacter(
                          state: _stateFromString(r.state),
                          size: 34,
                          level: r.level,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.name}${isMe ? ' (나)' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                              color: tokens.textPrimary,
                            ),
                          ),
                          Text(r.state, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                        ],
                      ),
                    ),
                    Text(
                      'Lv.${r.level}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textSub),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// 친구 관리 전용 페이지 (기존 로직 이동)
// ─────────────────────────────────────────

class FriendManagePage extends ConsumerStatefulWidget {
  const FriendManagePage({super.key});

  @override
  ConsumerState<FriendManagePage> createState() => _FriendManagePageState();
}

class _FriendManagePageState extends ConsumerState<FriendManagePage>
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
        title: const Text('친구 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '친구'),
            Tab(text: '요청'),
            Tab(text: '둘러보기'),
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

class _FriendListTab extends ConsumerStatefulWidget {
  const _FriendListTab();

  @override
  ConsumerState<_FriendListTab> createState() => _FriendListTabState();
}

class _FriendListTabState extends ConsumerState<_FriendListTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final friendsAsync = ref.watch(friendsListProvider);

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => CollectionErrorState(onRetry: () => ref.invalidate(friendsListProvider)),
      data: (friends) {
        final filtered = friends.where((f) {
          final q = _searchQuery.toLowerCase();
          return (f.nickname ?? '').toLowerCase().contains(q) ||
              f.username.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            if (friends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: '내 친구 검색',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: tokens.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: friends.isEmpty
                  ? const CollectionEmptyState(
                      icon: Icons.people_outline,
                      title: '아직 친구가 없어요',
                      subtitle: '검색 탭에서 친구를 찾아보세요',
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('검색 결과가 없습니다.',
                                style: TextStyle(color: tokens.textMuted)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final friend = filtered[index];
                            final hasImage = friend.profileImageUrl != null &&
                                friend.profileImageUrl!.isNotEmpty;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: BentoCard(
                                child: ListTile(
                                  onTap: () => context.push('/social/profile/${friend.id}'),
                                  leading: CircleAvatar(
                                    backgroundImage: hasImage
                                        ? NetworkImage(friend.profileImageUrl!)
                                        : null,
                                    child: !hasImage ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(friend.nickname ?? friend.username),
                                  subtitle: Text(friend.equippedTitle ?? '칭호 없음'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: '응원하기',
                                        icon: Icon(Icons.favorite_outline,
                                            size: 20, color: tokens.primary),
                                        onPressed: () async {
                                          try {
                                            await ref
                                                .read(socialRepositoryProvider)
                                                .nudgeFriend(friend.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('응원을 보냈어요!')),
                                              );
                                            }
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('응원 보내기 실패')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'delete') {
                                            await ref
                                                .read(socialRepositoryProvider)
                                                .deleteFriend(friend.id);
                                            ref.invalidate(friendsListProvider);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                              value: 'delete', child: Text('친구 삭제')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
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
      error: (err, _) =>
          CollectionErrorState(onRetry: () => ref.invalidate(friendRequestsProvider)),
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
            final hasImage =
                req.profileImageUrl != null && req.profileImageUrl!.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: BentoCard(
                child: ListTile(
                  onTap: () => context.push('/social/profile/${req.id}'),
                  leading: CircleAvatar(
                    backgroundImage:
                        hasImage ? NetworkImage(req.profileImageUrl!) : null,
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
                          await ref
                              .read(socialRepositoryProvider)
                              .acceptFriendRequest(req.id);
                          ref.invalidate(friendRequestsProvider);
                          ref.invalidate(friendsListProvider);
                        },
                      ),
                      IconButton(
                        tooltip: '거절',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await ref
                              .read(socialRepositoryProvider)
                              .rejectFriendRequest(req.id);
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final searchState = ref.watch(userSearchProvider);
    final recsAsync = ref.watch(recommendedUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) => ref.read(userSearchProvider.notifier).search(value),
            decoration: InputDecoration(
              hintText: '닉네임 또는 고유 ID로 검색',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: tokens.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
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
      error: (err, _) =>
          CollectionErrorState(onRetry: () => ref.invalidate(recommendedUsersProvider)),
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('닉네임으로 새로운 친구를 찾아보세요!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: users.length,
          itemBuilder: (context, index) =>
              _UserItemCard(user: users[index], isRecommendation: true),
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final hasImage = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;
    final isFriend = ref.watch(friendIdsProvider).contains(user.id);
    final isReceivedRequest = ref.watch(receivedRequestIdsProvider).contains(user.id);
    final isSentRequest = ref.watch(sentRequestIdsProvider).contains(user.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: BentoCard(
        child: InkWell(
          onTap: () => context.push('/social/profile/${user.id}'),
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
                      Text(user.nickname ?? user.username,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (isRecommendation) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Lv.1',
                                style: TextStyle(fontSize: 12, color: tokens.textSub)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: tokens.primaryBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('추천',
                                  style: TextStyle(
                                      fontSize: 10, color: tokens.primary)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(user.username,
                            style: TextStyle(fontSize: 12, color: tokens.textMuted)),
                      ],
                    ],
                  ),
                ),
                if (isFriend)
                  const _StatusChip(label: '친구', color: Colors.green)
                else if (isReceivedRequest)
                  _StatusChip(label: '요청 수신', color: tokens.primary)
                else if (isSentRequest)
                  const _StatusChip(label: '요청 보냄', color: Colors.grey)
                else
                  IconButton(
                    tooltip: '친구 요청 보내기',
                    icon: const Icon(Icons.person_add),
                    onPressed: () async {
                      try {
                        await ref
                            .read(socialRepositoryProvider)
                            .sendFriendRequest(user.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('친구 요청을 보냈습니다')),
                          );
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
