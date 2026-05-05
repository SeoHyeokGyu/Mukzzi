import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';
import 'package:mukzzi/src/features/quest/presentation/widgets/quest_item.dart';

class QuestListPage extends ConsumerStatefulWidget {
  const QuestListPage({super.key});

  @override
  ConsumerState<QuestListPage> createState() => _QuestListPageState();
}

class _QuestListPageState extends ConsumerState<QuestListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(questProvider.notifier).fetchQuests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final questState = ref.watch(questProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          '퀘스트',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: tokens.primary,
          labelColor: tokens.primary,
          unselectedLabelColor: tokens.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '일일'),
            Tab(text: '주간'),
            Tab(text: '업적'),
          ],
        ),
      ),
      body: questState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _QuestList(questsProvider: dailyQuestsProvider),
                _QuestList(questsProvider: weeklyQuestsProvider),
                _QuestList(questsProvider: achievementQuestsProvider),
              ],
            ),
    );
  }
}

class _QuestList extends ConsumerWidget {
  final ProviderListenable<List<dynamic>> questsProvider;

  const _QuestList({required this.questsProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider);

    if (quests.isEmpty) {
      return const Center(
        child: Text('진행 중인 퀘스트가 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return QuestItem(quest: quests[index] as dynamic);
      },
    );
  }
}
