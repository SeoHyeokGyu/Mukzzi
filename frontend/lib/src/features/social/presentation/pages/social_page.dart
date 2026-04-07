import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/bento_card.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
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
            Tab(text: '추천'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _FriendListTab(),
          const _FriendRequestTab(),
          const _RecommendedUsersTab(),
        ],
      ),
    );
  }
}

class _FriendListTab extends StatelessWidget {
  const _FriendListTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: BentoCard(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text('친구 ${index + 1}'),
              subtitle: const Row(
                children: [
                  Text('🌟 Lv.1'),
                  SizedBox(width: 12),
                  Text('😊 기분좋음'),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    child: Text('프로필 보기'),
                  ),
                  PopupMenuItem(
                    child: Text('응원하기'),
                  ),
                  PopupMenuItem(
                    child: Text('친구 삭제'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FriendRequestTab extends StatefulWidget {
  const _FriendRequestTab();

  @override
  State<_FriendRequestTab> createState() => _FriendRequestTabState();
}

class _FriendRequestTabState extends State<_FriendRequestTab> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: BentoCard(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('R${index + 1}'),
              ),
              title: Text('요청자 ${index + 1}'),
              subtitle: const Text('친구 요청을 받았습니다'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('친구 요청을 수락했습니다')),
                      );
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('친구 요청을 거절했습니다')),
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecommendedUsersTab extends StatelessWidget {
  const _RecommendedUsersTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: BentoCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '추천 사용자 ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('🌟 Lv.1'),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.softPeach,
                                        const Color(0xFF2A1C10),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '비슷한 식습관',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('친구 요청을 보냈습니다')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '먹부림 도감: 주요 메뉴는 김치찌개, 스파게티, 계란말이',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
