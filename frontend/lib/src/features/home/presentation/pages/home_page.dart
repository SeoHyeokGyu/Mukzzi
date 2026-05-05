import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/core/widgets/shimmer_card.dart';
import 'package:mukzzi/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:mukzzi/src/features/notification/presentation/providers/notification_provider.dart';
import 'package:mukzzi/src/features/character/data/models/character_model.dart';
import 'package:mukzzi/src/features/character/presentation/providers/character_provider.dart';
import 'package:mukzzi/src/features/profile/presentation/providers/user_provider.dart';
import 'package:mukzzi/src/features/home/presentation/widgets/menu_decision_section.dart';
import 'package:mukzzi/src/features/quest/domain/entities/quest.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';


// Mock 데이터 - 추후 API로 교체
const double _caloriesConsumed = 1200;
const double _caloriesGoal = 2000;
const double _proteinConsumed = 45;
const double _proteinGoal = 60;
const double _carbsConsumed = 150;
const double _carbsGoal = 300;
const double _fatConsumed = 30;
const double _fatGoal = 60;
const int _mockStreakDays = 3;

const _mockMeals = [
  (emoji: '🍚', time: '오전 8:30', name: '아침밥', kcal: 350),
  (emoji: '🍜', time: '오후 12:00', name: '점심 국수', kcal: 520),
  (emoji: '🍎', time: '오후 3:00', name: '간식', kcal: 80),
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    ref.listen(notificationProvider, (previous, next) {
      if (previous == null || (previous.notifications.isEmpty && next.notifications.isNotEmpty)) {
        return;
      }
      if (next.notifications.length > previous.notifications.length) {
        final newNotification = next.notifications.first;
        final isRecent = DateTime.now().difference(newNotification.createdAt).inMinutes < 1;
        if (!newNotification.isRead && isRecent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(newNotification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(newNotification.content, style: const TextStyle(fontSize: 12)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '보기',
                onPressed: () => context.push('/notifications'),
              ),
            ),
          );
        }
      }
    });

    ref.listen(userProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading && next.user == null) {
        ref.read(authProvider.notifier).logout().then((_) {
          if (context.mounted) {
            context.go('/auth');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')),
            );
          }
        });
      }
    });

    final notificationState = ref.watch(notificationProvider);
    final userState = ref.watch(userProvider);
    final unreadCount = notificationState.unreadCount;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    final now = DateTime.now();
    final dateLabel = DateFormat('M월 d일 (E)', 'ko').format(now);
    final nickname = userState.user?.nickname ?? userState.user?.username ?? '먹찌';

    return GradientScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateLabel,
              style: TextStyle(fontSize: 11, color: tokens.textMuted),
            ),
            Text(
              '안녕하세요, $nickname',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: '알림',
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: userState.isLoading && userState.user == null
          ? _buildShimmer()
          : _buildContent(tokens),
    );
  }

  Widget _buildShimmer() {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          ShimmerCard(height: 320),
          SizedBox(height: 12),
          ShimmerCard(height: 56),
          SizedBox(height: 12),
          ShimmerCard(height: 130),
          SizedBox(height: 24),
          ShimmerListItem(),
          SizedBox(height: 12),
          ShimmerListItem(),
          SizedBox(height: 12),
          ShimmerListItem(),
        ],
      ),
    );
  }

  Widget _animated(Widget child, {Duration? delay, bool slideY = false}) {
    if (MediaQuery.of(context).disableAnimations) return child;
    var effect = child.animate().fadeIn(
      delay: delay ?? Duration.zero,
      duration: const Duration(milliseconds: 300),
    );
    return slideY
        ? effect.slideY(begin: 0.08, end: 0, duration: const Duration(milliseconds: 300))
        : effect;
  }

  Widget _buildContent(AppColorTokens tokens) {
    // 유저 데이터 없으면 재요청
    final userState = ref.watch(userProvider);
    if (userState.user == null && !userState.isLoading && userState.error == null) {
      Future.microtask(() => ref.read(userProvider.notifier).fetchMe());
    }

    final characterAsync = ref.watch(characterProvider);
    final dailyQuests = ref.watch(dailyQuestsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          characterAsync.when(
            data: (char) => _buildHeroCard(tokens, char),
            loading: () => const ShimmerCard(height: 320),
            error: (_, __) => _buildHeroCard(tokens, null),
          ),
          const SizedBox(height: 12),
          _buildStreakQuestRow(tokens, dailyQuests),
          const SizedBox(height: 12),
          _buildQuickCTAs(tokens),
          const SizedBox(height: 12),
          _buildNutritionCard(tokens),
          const SizedBox(height: 12),
          _animated(const MenuDecisionSection(), delay: 200.ms, slideY: true),
          const SizedBox(height: 24),
          _buildRecentMeals(tokens),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AppColorTokens tokens, CharacterModel? char) {
    final state = char?.state ?? CharacterState.normal;
    final level = char?.level ?? 1;
    final name = char?.name ?? '먹찌';
    final xp = char?.exp.toDouble() ?? 0;
    const xpGoal = 100.0;

    final card = BentoCard(
      showPaperTexture: true,
      borderRadius: BorderRadius.circular(tokens.rHero),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: state.indicatorColor.withValues(alpha: 0.18),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lv.$level',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.heroText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.indicatorColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(state.icon, size: 11, color: const Color(0xFF1A1A1A)),
                    const SizedBox(width: 3),
                    Text(
                      state.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MukzziCharacter(state: state, size: 160, level: level),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tokens.heroText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.message,
            style: TextStyle(fontSize: 12, color: tokens.heroTextSub),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '경험치',
                    style: TextStyle(fontSize: 11, color: tokens.heroTextSub),
                  ),
                  Text(
                    '${xp.toInt()} / ${xpGoal.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (xp / xpGoal).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.black.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return _animated(card, slideY: true);
  }

  Widget _buildStreakQuestRow(AppColorTokens tokens, List<Quest> quests) {
    final row = BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push('/home/quests'),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: tokens.primary, size: 18),
          const SizedBox(width: 4),
          Text(
            '연속 $_mockStreakDays일',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.primary),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 28, color: tokens.primaryBg),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                if (quests.isEmpty)
                  const Expanded(
                    child: Text(
                      '진행 중인 퀘스트가 없습니다.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  )
                else
                  for (int i = 0; i < quests.length && i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: quests[i].progress,
                              minHeight: 4,
                              backgroundColor: tokens.primaryBg,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                quests[i].isCompleted ? tokens.primary : tokens.primaryBg,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quests[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: quests[i].isCompleted ? tokens.textSub : tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
    return _animated(row, delay: 100.ms, slideY: true);
  }

  Widget _buildQuickCTAs(AppColorTokens tokens) {
    final row = Row(
      children: [
        Expanded(
          flex: 2,
          child: Semantics(
            label: '먹찌 밥 주기',
            button: true,
            child: BentoCard(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shadows: [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              onTap: () => context.go('/meal-record'),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '먹찌 밥 주기',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Semantics(
            label: '사진 촬영',
            button: true,
            child: BentoCard(
              borderRadius: BorderRadius.circular(tokens.rCard),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('준비 중입니다'))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: tokens.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '촬영',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    return _animated(row, delay: 80.ms, slideY: true);
  }

  Widget _buildNutritionCard(AppColorTokens tokens) {
    const remaining = _caloriesGoal - _caloriesConsumed;

    final card = BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 영양',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tokens.textPrimary),
              ),
              Text(
                '${_caloriesConsumed.toInt()} / ${_caloriesGoal.toInt()} kcal',
                style: TextStyle(fontSize: 11, color: tokens.textSub),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: _caloriesConsumed,
                        color: tokens.primary,
                        radius: 18,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: remaining,
                        color: tokens.primaryBg,
                        radius: 18,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_caloriesConsumed.toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tokens.primary,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(fontSize: 11, color: tokens.textMuted, height: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MacroBar(label: '탄수', consumed: _carbsConsumed, goal: _carbsGoal, color: AppColors.carbsColor, tokens: tokens),
          const SizedBox(height: 8),
          _MacroBar(label: '단백', consumed: _proteinConsumed, goal: _proteinGoal, color: AppColors.proteinColor, tokens: tokens),
          const SizedBox(height: 8),
          _MacroBar(label: '지방', consumed: _fatConsumed, goal: _fatGoal, color: AppColors.fatColor, tokens: tokens),
        ],
      ),
    );
    return _animated(card, delay: 160.ms, slideY: true);
  }

  Widget _buildRecentMeals(AppColorTokens tokens) {
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '오늘 먹은 것',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/meal-record'),
              child: Text(
                '전체 보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...(_mockMeals.indexed.map((entry) {
          final (i, meal) = entry;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BentoCard(
              borderRadius: BorderRadius.circular(tokens.rItem),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.listItemBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(meal.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tokens.textPrimary)),
                        Text(meal.time, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${meal.kcal}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' kcal',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 240 + i * 60)).fadeIn(duration: 250.ms),
          );
        })),
      ],
    );
    return _animated(col, delay: 240.ms);
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final Color color;
  final AppColorTokens tokens;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(label, style: TextStyle(fontSize: 11, color: tokens.textSub)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (consumed / goal).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: tokens.primaryBg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${consumed.toInt()}g',
          style: TextStyle(fontSize: 10, color: tokens.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
