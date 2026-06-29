import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/collection_states.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/core/widgets/profile_avatar.dart';
import '../providers/social_providers.dart';
import '../../data/models/social_models.dart';
import '../../data/models/feed_model.dart';
import '../../../meal_record/data/models/meal_model.dart';
import '../../../meal_record/presentation/widgets/menu_detail_sheet.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';

CharacterState _stateFromPenalty(String status) {
  switch (status.toUpperCase()) {
    case 'HUNGRY':  return CharacterState.hungry;
    case 'STARVED': return CharacterState.starving;
    default:        return CharacterState.normal;
  }
}

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

class _FeedCard extends StatefulWidget {
  final FeedPost post;
  final AppColorTokens tokens;

  const _FeedCard({required this.post, required this.tokens});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  bool _cheered = false;
  int _cheerCount = 0;

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
    final post = widget.post;
    final tokens = widget.tokens;

    return BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                profileImageUrl: post.user.profileImageUrl,
                nickname: post.user.nickname ?? post.user.username,
                radius: 20,
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
                      ],
                    ),
                    Text(_formatTime(post.meal.recordedAt), style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MealTypeBadge(
                type: MealTypeHelper.fromString(post.meal.mealType),
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: post.meal.menuId != null 
                    ? () => MenuDetailSheet.show(context, post.meal.menuId!)
                    : null,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: post.meal.menuName,
                          style: TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.bold,
                            color: tokens.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: tokens.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        TextSpan(
                          text: '을(를) 먹었어요!',
                          style: TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.w500,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (post.meal.review != null && post.meal.review!.isNotEmpty) ...[
            const SizedBox(height: 8),
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이미지를 불러올 수 없습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() {
              _cheered = !_cheered;
              _cheerCount += _cheered ? 1 : -1;
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _cheered ? Icons.favorite : Icons.favorite_border,
                  size: 14,
                  color: _cheered ? const Color(0xFFFF85A1) : tokens.textSub,
                ),
                const SizedBox(width: 4),
                Text(
                  _cheerCount > 0 ? '$_cheerCount' : '응원하기',
                  style: TextStyle(
                    fontSize: 12,
                    color: _cheered ? const Color(0xFFFF85A1) : tokens.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealTypeBadge extends StatelessWidget {
  final MealType type;
  final AppColorTokens tokens;

  const _MealTypeBadge({required this.type, required this.tokens});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case MealType.breakfast: color = Colors.orange; break;
      case MealType.lunch:     color = Colors.green; break;
      case MealType.dinner:    color = Colors.indigo; break;
      case MealType.snack:     color = Colors.purple; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 랭킹 탭
// ─────────────────────────────────────────

class _RankingTab extends ConsumerStatefulWidget {
  final AppColorTokens tokens;
  const _RankingTab({required this.tokens});

  @override
  ConsumerState<_RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends ConsumerState<_RankingTab> {
  bool _isFriendsComparisonMode = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final myUserId = ref.watch(userProvider).user?.id;

    return RefreshIndicator(
      onRefresh: () async {
        if (_isFriendsComparisonMode) {
          ref.invalidate(friendsComparisonProvider);
        } else {
          ref.invalidate(socialRankingProvider);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 상단 세그먼트 컨트롤
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isFriendsComparisonMode = false),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isFriendsComparisonMode ? tokens.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '전체 랭킹',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !_isFriendsComparisonMode ? Colors.white : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isFriendsComparisonMode = true),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isFriendsComparisonMode ? tokens.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '친구 비교',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isFriendsComparisonMode ? Colors.white : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 내용 렌더링
          if (!_isFriendsComparisonMode)
            _buildAllUsersRanking(tokens, myUserId)
          else
            _buildFriendsComparison(tokens, myUserId),
        ],
      ),
    );
  }

  Widget _buildAllUsersRanking(AppColorTokens tokens, String? myUserId) {
    final rankingAsync = ref.watch(socialRankingProvider);

    return rankingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => CollectionErrorState(onRetry: () => ref.invalidate(socialRankingProvider)),
      data: (ranking) {
        if (ranking.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('아직 랭킹 정보가 없습니다.')));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이번 주 랭킹 (경험치 기준)',
              style: TextStyle(fontSize: 13, color: tokens.textMuted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ranking.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final r = ranking[i];
                  final isMe = r.userId == myUserId;
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
                            gradient: tokens.cardHeroGrad,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: MukzziCharacter(
                              state: _stateFromPenalty(r.penaltyStatus),
                              size: 64,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                        ),
                        Text(
                          '${r.score.toInt()}일',
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
              '상위 10위 명단',
              style: TextStyle(fontSize: 13, color: tokens.textMuted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: ranking.indexed.map((entry) {
                  final (i, r) = entry;
                  final isMe = r.userId == myUserId;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? tokens.primaryBg : Colors.transparent,
                      border: i < ranking.length - 1
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
                            gradient: tokens.cardHeroGrad,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: MukzziCharacter(
                              state: _stateFromPenalty(r.penaltyStatus),
                              size: 64,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.nickname}${isMe ? ' (나)' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              Text('영양 달성 ${r.score.toInt()}일', style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                            ],
                          ),
                        ),
                        Text(
                          '${r.score.toInt()}일',
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
      },
    );
  }

  Widget _buildFriendsComparison(AppColorTokens tokens, String? myUserId) {
    final comparisonAsync = ref.watch(friendsComparisonProvider);
    final sortBy = ref.watch(friendsComparisonSortProvider);

    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => CollectionErrorState(onRetry: () => ref.invalidate(friendsComparisonProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('비교할 친구가 없습니다.')));
        }

        // 1. 정렬 수행
        final sortedList = [...list];
        switch (sortBy) {
          case FriendsSortType.totalExp:
            sortedList.sort((a, b) => b.totalExp.compareTo(a.totalExp));
            break;
          case FriendsSortType.streakDays:
            sortedList.sort((a, b) => b.streakDays.compareTo(a.streakDays));
            break;
          case FriendsSortType.badgeCount:
            sortedList.sort((a, b) => b.badgeCount.compareTo(a.badgeCount));
            break;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 정렬 필터 칩 목록
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('총 경험치순', FriendsSortType.totalExp, sortBy),
                  const SizedBox(width: 8),
                  _buildFilterChip('연속 스트릭순', FriendsSortType.streakDays, sortBy),
                  const SizedBox(width: 8),
                  _buildFilterChip('뱃지 개수순', FriendsSortType.badgeCount, sortBy),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '친구 지표 비교 보드',
              style: TextStyle(fontSize: 13, color: tokens.textMuted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: sortedList.indexed.map((entry) {
                  final (i, r) = entry;
                  final isMe = r.userId == myUserId;
                  final rank = i + 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? tokens.primaryBg : Colors.transparent,
                      border: isMe ? Border.all(color: tokens.primary, width: 1.5) : null,
                      borderRadius: isMe ? BorderRadius.circular(tokens.rCard) : null,
                    ),
                    margin: isMe ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2) : EdgeInsets.zero,
                    child: Row(
                      children: [
                        // 순위/메달 뱃지
                        SizedBox(
                          width: 32,
                          child: rank <= 3
                              ? Icon(
                                  Icons.emoji_events,
                                  color: rank == 1
                                      ? const Color(0xFFFFD700)
                                      : rank == 2
                                          ? const Color(0xFFC0C0C0)
                                          : const Color(0xFFCD7F32),
                                  size: 20,
                                )
                              : Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textMuted,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // 프로필 이미지 (여기서는 먹찌 캐릭터 기본 렌더링)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: tokens.cardHeroGrad,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: MukzziCharacter(
                              state: CharacterState.normal,
                              size: 64,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 닉네임 및 장착 칭호
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.nickname,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  if (isMe)
                                    Text(
                                      ' (나)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: tokens.primary,
                                      ),
                                    ),
                                ],
                              ),
                              if (r.equippedTitle != null && r.equippedTitle!.isNotEmpty)
                                Text(
                                  r.equippedTitle!,
                                  style: TextStyle(fontSize: 11, color: tokens.primary, fontWeight: FontWeight.w600),
                                ),
                              const SizedBox(height: 4),
                              // 세부 지표 정보 노출
                              Text(
                                'Lv.${r.level} (${r.exp} XP) · ${r.streakDays}일 연속 · 뱃지 ${r.badgeCount}개',
                                style: TextStyle(fontSize: 11, color: tokens.textMuted),
                              ),
                            ],
                          ),
                        ),
                        // 우측 메인 지표 밸류 강조
                        Text(
                          _getMainStatValue(r, sortBy),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.textSub,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, FriendsSortType type, FriendsSortType current) {
    final isSelected = type == current;
    final tokens = widget.tokens;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : tokens.textMuted)),
      onSelected: (_) => ref.read(friendsComparisonSortProvider.notifier).state = type,
      selectedColor: tokens.primary,
      backgroundColor: tokens.card,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    );
  }

  String _getMainStatValue(ComparisonModel model, FriendsSortType type) {
    switch (type) {
      case FriendsSortType.totalExp:
        return '${model.totalExp} XP';
      case FriendsSortType.streakDays:
        return '${model.streakDays}일';
      case FriendsSortType.badgeCount:
        return '${model.badgeCount}개';
    }
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: BentoCard(
                                child: ListTile(
                                  onTap: () => context.push('/social/profile/${friend.id}'),
                                  leading: ProfileAvatar(
                                    profileImageUrl: friend.profileImageUrl,
                                    nickname: friend.nickname ?? friend.username,
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
                                          } else if (value == 'profile') {
                                            context.push('/social/profile/${friend.id}');
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                              value: 'profile', child: Text('프로필 보기')),
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: BentoCard(
                child: ListTile(
                  onTap: () => context.push('/social/profile/${req.id}'),
                  leading: ProfileAvatar(
                    profileImageUrl: req.profileImageUrl,
                    nickname: req.nickname ?? req.username,
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
                          try {
                            await ref
                                .read(socialRepositoryProvider)
                                .acceptFriendRequest(req.id);
                            ref.invalidate(friendRequestsProvider);
                            ref.invalidate(friendsListProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('친구 요청을 수락했습니다')),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('요청 수락 실패')),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        tooltip: '거절',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          try {
                            await ref
                                .read(socialRepositoryProvider)
                                .rejectFriendRequest(req.id);
                            ref.invalidate(friendRequestsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('친구 요청을 거절했습니다')),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('요청 거절 실패')),
                              );
                            }
                          }
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
                ProfileAvatar(
                  profileImageUrl: user.profileImageUrl,
                  nickname: user.nickname ?? user.username,
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
