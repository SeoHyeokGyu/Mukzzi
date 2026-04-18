import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/features/profile/data/models/user_model.dart';
import '../providers/social_providers.dart';

class OtherProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const OtherProfilePage({super.key, required this.userId});

  @override
  ConsumerState<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends ConsumerState<OtherProfilePage> {
  late Future<UserModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ref.read(socialRepositoryProvider).getOtherProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GradientScaffold(
            appBar: null,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return GradientScaffold(
            appBar: AppBar(title: const Text('프로필')),
            body: const Center(child: Text('사용자 정보를 불러올 수 없습니다.')),
          );
        }

        final user = snapshot.data!;
        final hasImage = user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;
        
        // 관계 상태 확인
        final isFriend = ref.watch(friendIdsProvider).contains(user.id);
        final isReceived = ref.watch(receivedRequestIdsProvider).contains(user.id);
        final isSent = ref.watch(sentRequestIdsProvider).contains(user.id);

        return GradientScaffold(
          appBar: AppBar(title: Text(user.nickname ?? '프로필')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 상단 프로필 영역
                BentoCard(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: hasImage ? NetworkImage(user.profileImageUrl!) : null,
                        child: !hasImage ? const Icon(Icons.person, size: 50) : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.nickname ?? user.username,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (isFriend) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                '친구',
                                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      
                      // 액션 버튼
                      _buildActionButtons(isFriend, isSent, isReceived, user.id),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 먹찌 정보 (예시 데이터)
                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('먹찌 상태', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: '진화', value: '부화 단계'),
                          _StatItem(label: '레벨', value: 'Lv.1'),
                          _StatItem(label: '기분', value: '좋음'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 방명록 섹션 (추후 고도화 가능)
                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('방명록', style: Theme.of(context).textTheme.titleMedium),
                          TextButton(onPressed: () {}, child: const Text('전체보기')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('아직 작성된 방명록이 없습니다.', style: TextStyle(color: AppColors.textTertiary)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isFriend, bool isSent, bool isReceived, String userId) {
    if (isFriend) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                 try {
                    await ref.read(socialRepositoryProvider).nudgeFriend(userId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('응원을 보냈어요!')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 오늘 응원을 보냈습니다.')));
                    }
                  }
              },
              icon: const Icon(Icons.favorite, size: 18),
              label: const Text('응원하기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {}, // 방명록 작성 다이얼로그 연동 가능
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('방명록'),
            ),
          ),
        ],
      );
    }

    if (isSent) {
      return const SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: null,
          child: Text('친구 요청 보냄'),
        ),
      );
    }

    if (isReceived) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () async {
                await ref.read(socialRepositoryProvider).acceptFriendRequest(userId);
                ref.invalidate(friendRequestsProvider);
                ref.invalidate(friendsListProvider);
                setState(() {});
              },
              child: const Text('수락하기'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          try {
            await ref.read(socialRepositoryProvider).sendFriendRequest(userId);
            ref.invalidate(sentRequestsProvider);
            setState(() {});
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈습니다.')));
            }
          } catch (e) {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('친구 신청하기'),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
