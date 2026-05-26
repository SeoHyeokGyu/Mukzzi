import "package:showcaseview/showcaseview.dart";
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/constants/app_constants.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/mukzzi_character.dart';
import 'package:mukzzi/src/core/widgets/shimmer_card.dart';
import 'package:mukzzi/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';
import 'package:mukzzi/src/features/notification/presentation/providers/notification_provider.dart';
import 'package:mukzzi/src/features/character/data/models/character_model.dart';
import 'package:mukzzi/src/features/character/presentation/providers/character_provider.dart';
import 'package:mukzzi/src/features/profile/presentation/providers/user_provider.dart';
import 'package:mukzzi/src/features/home/presentation/widgets/menu_decision_section.dart';
import 'package:mukzzi/src/features/home/data/models/nutrition_model.dart';
import 'package:mukzzi/src/features/home/presentation/providers/nutrition_provider.dart';
import 'package:mukzzi/src/features/meal_record/data/models/meal_model.dart';
import 'package:mukzzi/src/features/meal_record/presentation/providers/meal_provider.dart';
import 'package:mukzzi/src/features/quest/domain/entities/quest.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey _feedMukzziKey = GlobalKey();
  bool _tutorialStarted = false;

  @override
  void initState() {
    super.initState();
    // 퀘스트 데이터 로드
    Future.microtask(() => ref.read(questProvider.notifier).fetchQuests());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkTutorial(List<Quest> quests) {
    if (_tutorialStarted) return;

    // 튜토리얼 퀘스트가 진행 중인지 확인
    final hasTutorialQuest = quests.any(
      (q) => q.code == 'TUTORIAL_FIRST_MEAL' && q.status == QuestStatus.progress,
    );

    if (hasTutorialQuest) {
      _tutorialStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowcaseView.get().startShowCase([_feedMukzziKey]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    ref.listen(notificationProvider, (previous, next) {
      if (previous == null || (previous.notifications.isEmpty && next.notifications.isNotEmpty)) {
        return;
      }
      if (next.notifications.length > previous.notifications.length) {
        final newNotification = next.notifications.first;
        final isRecent = DateTime.now().difference(newNotification.createdAt).inMinutes < 1;
        if (!newNotification.isRead && isRecent) {
          final isQuest = newNotification.type == NotificationType.questCompleted;
          final isBadge = newNotification.type == NotificationType.badgeAcquired;
          final isSpecial = isQuest || isBadge;
          
          if (!context.mounted) return;
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: isSpecial ? AppColors.primaryGradient : null,
                      color: isSpecial ? null : tokens.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSpecial ? [
                        BoxShadow(
                          color: tokens.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                    child: Icon(
                      isQuest ? Icons.emoji_events_rounded : (isBadge ? Icons.verified_rounded : Icons.notifications_rounded),
                      color: isSpecial ? Colors.white : tokens.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          newNotification.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: tokens.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          newNotification.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textSub,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: tokens.card,
              behavior: SnackBarBehavior.floating,
              elevation: 8,
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.rItem + 4),
                side: BorderSide(
                  color: isSpecial ? tokens.primary.withValues(alpha: 0.4) : tokens.textMuted.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              duration: const Duration(seconds: 5),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              action: SnackBarAction(
                label: isSpecial ? '이동' : '확인',
                textColor: tokens.primary,
                onPressed: () {
                  // 알림을 즉시 닫아 Navigator와의 키 충돌 방지
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  // 다음 프레임에서 안전하게 페이지 이동
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context.go(newNotification.navigationPath);
                    }
                  });
                },
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

    ref.listen(questProvider, (previous, next) {
      if (!next.isLoading && next.quests.isNotEmpty) {
        _checkTutorial(next.quests);
      }
    });

    final notificationState = ref.watch(notificationProvider);
    final userState = ref.watch(userProvider);
    final unreadCount = notificationState.unreadCount;

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
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final weeklyNutritionAsync = ref.watch(weeklyNutritionProvider);
    final mealsAsync = ref.watch(todayMealsProvider);

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
          _buildStreakQuestRow(tokens, dailyQuests, characterAsync.asData?.value.streakDays ?? 0),
          const SizedBox(height: 12),
          _buildQuickCTAs(tokens),
          const SizedBox(height: 12),
          nutritionAsync.when(
            data: (nutrition) => _buildNutritionCard(tokens, nutrition),
            loading: () => const ShimmerCard(height: 280),
            error: (_, __) => _buildNutritionCard(tokens, null),
          ),
          const SizedBox(height: 12),
          weeklyNutritionAsync.when(
            data: (weekly) => _buildWeeklyTrendChart(tokens, weekly),
            loading: () => const ShimmerCard(height: 200),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          _animated(const MenuDecisionSection(), delay: 200.ms, slideY: true),
          const SizedBox(height: 24),
          mealsAsync.when(
            data: (meals) => _buildRecentMeals(tokens, meals),
            loading: () => const ShimmerCard(height: 100),
            error: (_, __) => _buildRecentMeals(tokens, []),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendChart(AppColorTokens tokens, List<WeeklyNutritionItemModel> weekly) {
    if (weekly.isEmpty) return const SizedBox.shrink();

    final chart = BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주간 영양 트렌드',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: tokens.textPrimary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= weekly.length) return const SizedBox.shrink();
                        final date = DateTime.parse(weekly[index].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E', 'ko').format(date),
                            style: TextStyle(fontSize: 10, color: tokens.textMuted),
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weekly.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.calories);
                    }).toList(),
                    isCurved: true,
                    color: tokens.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: tokens.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return _animated(chart, delay: 180.ms, slideY: true);
  }

  Widget _buildHeroCard(AppColorTokens tokens, CharacterModel? char) {
    final state = char?.state ?? CharacterState.normal;
    final name = char?.name ?? '먹찌';

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
          MukzziCharacter(
            state: state,
            size: 160,
            showAccessory: char?.equippedAccessory != null,
            equippedAccessory: char?.equippedAccessory?.assetUrl,
            growthStage: char != null ? char.growthStage : 'baby',
          ),
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
        ],
      ),
    );
    return _animated(card, slideY: true);
  }

  Widget _buildStreakQuestRow(AppColorTokens tokens, List<Quest> quests, int streakDays) {
    final row = BentoCard(
      borderRadius: BorderRadius.circular(tokens.rCard),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push('/home/quests'),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: tokens.primary, size: 18),
          const SizedBox(width: 4),
          Text(
            '연속 $streakDays일',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.primary),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 28, color: tokens.primaryBg),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                if (quests.isEmpty)
                  Expanded(
                    child: Text(
                      '오늘의 목표를 확인하고 먹찌를 키워봐요! ➔',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
          child: Showcase(
            key: _feedMukzziKey,
            title: '첫 식사 기록',
            description: '먹찌가 배고파요! 첫 식사를 기록하고 성장을 시작하세요.',
            targetPadding: const EdgeInsets.all(8),
            tooltipBackgroundColor: tokens.primary,
            textColor: Colors.white,
            disableDefaultTargetGestures: true,
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
                onTap: () {
                  if (_tutorialStarted) {
                    ShowcaseView.get().dismiss();
                  }
                  context.go('/meal-record');
                },
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

  Widget _buildNutritionCard(AppColorTokens tokens, DailyNutritionModel? nutrition) {
    final consumed = nutrition?.totalCalories ?? 0;
    final goal = nutrition?.nutritionGoal?.calorieGoal ?? AppConstants.defaultDailyCalorieGoal;
    final remaining = (goal - consumed).clamp(0.0, goal);

    return BentoCard(
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
                '${consumed.toInt()} / ${goal.toInt()} kcal',
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
                        value: consumed,
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
                      '${consumed.toInt()}',
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
          _MacroBar(
            label: '탄수',
            consumed: nutrition?.totalCarbs ?? 0,
            goal: nutrition?.nutritionGoal?.carbGoal ?? 300,
            color: AppColors.carbsColor,
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _MacroBar(
            label: '단백',
            consumed: nutrition?.totalProtein ?? 0,
            goal: nutrition?.nutritionGoal?.proteinGoal ?? 60,
            color: AppColors.proteinColor,
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _MacroBar(
            label: '지방',
            consumed: nutrition?.totalFat ?? 0,
            goal: nutrition?.nutritionGoal?.fatGoal ?? 60,
            color: AppColors.fatColor,
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeals(AppColorTokens tokens, List<MealRecord> meals) {
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
        if (meals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                '아직 오늘 기록한 식사가 없어요.',
                style: TextStyle(fontSize: 13, color: tokens.textMuted),
              ),
            ),
          )
        else
          ...(meals.indexed.map((entry) {
            final (i, meal) = entry;
            final mealType = MealTypeHelper.fromString(meal.mealType);
            final timeStr = DateFormat('a h:mm', 'ko').format(meal.recordedAt);

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
                        child: Icon(mealType.icon, color: tokens.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meal.menuName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14, color: tokens.textPrimary)),
                          Text(timeStr, style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${meal.calories?.toInt() ?? 0}',
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
