import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/shimmer_card.dart';
import 'package:mukzzi/src/features/quest/presentation/providers/quest_provider.dart';
import 'package:mukzzi/src/features/quest/presentation/widgets/quest_item.dart';
import '../../../profile/presentation/providers/user_provider.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
      ),
      body: questState.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerListItem(),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _QuestList(questsProvider: dailyQuestsProvider),
                _QuestList(questsProvider: weeklyQuestsProvider),
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('진행 중인 퀘스트가 없습니다.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final user = ref.read(userProvider).user;
                if (user != null) {
                  // 일일 퀘스트 수동 할당 요청 (백엔드 로직 활용)
                  // 실제로는 별도 API가 필요할 수 있으나, 여기서는 UI 피드백만 제공하거나 
                  // 새로고침을 유도할 수 있음. 
                  // 현재 설계 상 새벽 5시 할당이 원칙이므로, 새로고침 시도를 권장.
                  await ref.read(questProvider.notifier).fetchQuests();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('퀘스트 불러오기'),
            ),
          ],
        ),
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
