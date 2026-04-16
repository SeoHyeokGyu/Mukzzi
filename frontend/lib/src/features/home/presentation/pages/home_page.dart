import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../profile/presentation/providers/user_provider.dart';

// Mock 데이터 - 추후 API로 교체
const double _caloriesConsumed = 1200;
const double _caloriesGoal = 2000;
const double _proteinConsumed = 45;
const double _proteinGoal = 60;
const double _carbsConsumed = 150;
const double _carbsGoal = 300;
const double _fatConsumed = 30;
const double _fatGoal = 60;
const int _mealCount = 3;
const int _streakDays = 7;
final List<double> _weeklyCalories = [1800, 2200, 1600, 1900, 2100, 1750, 1200];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('먹찌'),
        actions: [
          IconButton(tooltip: '알림', icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(
            tooltip: '마이페이지',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/home/profile'),
          ),
        ],
      ),
      body: _isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildShimmer() {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          ShimmerCard(height: 220),
          SizedBox(height: 16),
          ShimmerCard(height: 220),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: ShimmerCard(height: 90)),
            SizedBox(width: 12),
            Expanded(child: ShimmerCard(height: 90)),
          ]),
          SizedBox(height: 12),
          ShimmerCard(height: 160),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: ShimmerCard(height: 100)),
            SizedBox(width: 12),
            Expanded(child: ShimmerCard(height: 100)),
          ]),
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

  // 시스템 모션 감소 설정 적용 헬퍼
  Widget _animated(Widget child, {Duration? delay, bool slideY = false}) {
    if (MediaQuery.of(context).disableAnimations) return child;
    var effect = child.animate().fadeIn(
      delay: delay ?? Duration.zero,
      duration: const Duration(milliseconds: 300),
    );
    return slideY ? effect.slideY(begin: 0.08, end: 0, duration: const Duration(milliseconds: 300)) : effect;
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCharacterCard(),
          const SizedBox(height: 16),
          _buildMacroChartCard(),
          const SizedBox(height: 12),
          _buildQuickStatsRow(),
          const SizedBox(height: 12),
          _buildWeeklyChartCard(),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentMeals(),
        ],
      ),
    );
  }

  Widget _buildCharacterCard() {
    final userState = ref.watch(userProvider);
    final nickname = userState.user?.nickname ?? userState.user?.username ?? '먹찌';
    
    const double xp = 0;
    const double xpGoal = 100;
    final card = BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.egg_outlined, size: 44, color: AppColors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nickname, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.softPeach,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('부화 단계', style: TextStyle(fontSize: 11, color: AppColors.orange)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Lv.1 · NORMAL', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EXP', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        Text(
                          '${xp.toInt()} / ${xpGoal.toInt()}',
                          style: const TextStyle(fontSize: 11, color: AppColors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (xp / xpGoal).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '식사를 기록하면 먹찌가 성장해요',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
    return _animated(card, slideY: true);
  }

  Widget _buildMacroChartCard() {
    const remaining = _caloriesGoal - _caloriesConsumed;
    final card = BentoCard(
      child: Row(
        children: [
          // 도넛 차트
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: _caloriesConsumed,
                        color: AppColors.orange,
                        radius: 22,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: remaining,
                        color: AppColors.divider,
                        radius: 22,
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
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      '/ ${_caloriesGoal.toInt()}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 영양소 수치
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '오늘의 영양',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                const _MacroRow(
                  label: '단백질',
                  consumed: _proteinConsumed,
                  goal: _proteinGoal,
                  unit: 'g',
                  color: AppColors.proteinColor,
                ),
                const SizedBox(height: 10),
                const _MacroRow(
                  label: '탄수화물',
                  consumed: _carbsConsumed,
                  goal: _carbsGoal,
                  unit: 'g',
                  color: AppColors.carbsColor,
                ),
                const SizedBox(height: 10),
                const _MacroRow(
                  label: '지방',
                  consumed: _fatConsumed,
                  goal: _fatGoal,
                  unit: 'g',
                  color: AppColors.fatColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return _animated(card, delay: 80.ms, slideY: true);
  }

  Widget _buildQuickStatsRow() {
    final row = Row(
      children: [
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘 식사', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_mealCount',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 4),
                      child: Text('끼', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('연속 기록', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$_streakDays',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.peach,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 4),
                      child: Text('일', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return _animated(row, delay: 160.ms, slideY: true);
  }

  Widget _buildWeeklyChartCard() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final card = BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번주 칼로리',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        return Text(
                          days[idx],
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                minY: 1000,
                maxY: 2800,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _weeklyCalories.length,
                      (i) => FlSpot(i.toDouble(), _weeklyCalories[i]),
                    ),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.orange,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: index == _weeklyCalories.length - 1 ? 5 : 3,
                        color: AppColors.orange,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orange.withValues(alpha: 0.2),
                          AppColors.orange.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // 목표 칼로리 기준선
                  LineChartBarData(
                    spots: List.generate(7, (i) => FlSpot(i.toDouble(), _caloriesGoal)),
                    isCurved: false,
                    color: AppColors.divider,
                    barWidth: 1,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return _animated(card, delay: 240.ms, slideY: true);
  }

  Widget _buildQuickActions() {
    final row = Row(
      children: [
        Expanded(
          child: Semantics(
            label: '메뉴 선택',
            button: true,
            child: GestureDetector(
              onTap: () => context.go('/meal-record'),
              child: const BentoCard(
                height: 100,
                gradient: AppColors.primaryGradient,
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.white, size: 30, semanticLabel: '메뉴'),
                    SizedBox(height: 8),
                    Text('메뉴 선택', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: '식사 기록 추가',
            button: true,
            child: GestureDetector(
              onTap: () => context.go('/meal-record'),
              child: const BentoCard(
                height: 100,
                gradient: AppColors.primaryGradient,
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 30, semanticLabel: '추가'),
                    SizedBox(height: 8),
                    Text('식사 기록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return _animated(row, delay: 320.ms, slideY: true);
  }

  Widget _buildRecentMeals() {
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 식사 기록',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.softPeach,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: AppColors.orange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('식사 ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const Text('오늘 12:30', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    '320kcal',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
    return _animated(col, delay: 400.ms, slideY: true);
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final String unit;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(
              '${consumed.toInt()}/${ goal.toInt()}$unit',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (consumed / goal).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
