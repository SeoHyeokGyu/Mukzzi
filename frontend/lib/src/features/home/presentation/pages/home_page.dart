import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/shimmer_card.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: _isLoading ? _buildShimmer() : _buildContent(),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          const ShimmerCard(height: 220),
          const SizedBox(height: 16),
          const ShimmerCard(height: 220),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: ShimmerCard(height: 90)),
            SizedBox(width: 12),
            Expanded(child: ShimmerCard(height: 90)),
          ]),
          const SizedBox(height: 12),
          const ShimmerCard(height: 160),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: ShimmerCard(height: 100)),
            SizedBox(width: 12),
            Expanded(child: ShimmerCard(height: 100)),
          ]),
          const SizedBox(height: 24),
          const ShimmerListItem(),
          const SizedBox(height: 12),
          const ShimmerListItem(),
          const SizedBox(height: 12),
          const ShimmerListItem(),
        ],
      ),
    );
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
    return BentoCard(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('먹찌 (Coming Soon)', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CharacterStat(label: '레벨', value: '1'),
              _CharacterStat(label: '경험치', value: '0/100'),
              _CharacterStat(label: '상태', value: 'NORMAL'),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }

  Widget _buildMacroChartCard() {
    final remaining = _caloriesGoal - _caloriesConsumed;
    return BentoCard(
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
                _MacroRow(
                  label: '단백질',
                  consumed: _proteinConsumed,
                  goal: _proteinGoal,
                  unit: 'g',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 10),
                _MacroRow(
                  label: '탄수화물',
                  consumed: _carbsConsumed,
                  goal: _carbsGoal,
                  unit: 'g',
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 10),
                _MacroRow(
                  label: '지방',
                  consumed: _fatConsumed,
                  goal: _fatGoal,
                  unit: 'g',
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 80.ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }

  Widget _buildQuickStatsRow() {
    return Row(
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
    )
        .animate()
        .fadeIn(delay: 160.ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }

  Widget _buildWeeklyChartCard() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return BentoCard(
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
    )
        .animate()
        .fadeIn(delay: 240.ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: BentoCard(
              height: 100,
              gradient: AppColors.primaryGradient,
              padding: const EdgeInsets.all(12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text('메뉴 선택', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: BentoCard(
              height: 100,
              gradient: AppColors.primaryGradient,
              padding: const EdgeInsets.all(12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text('식사 기록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 320.ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }

  Widget _buildRecentMeals() {
    return Column(
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
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 300.ms)
        .slideY(begin: 0.08, end: 0, duration: 300.ms);
  }
}

class _CharacterStat extends StatelessWidget {
  final String label;
  final String value;

  const _CharacterStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
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
