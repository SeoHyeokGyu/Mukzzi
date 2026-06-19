import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import 'package:mukzzi/src/core/widgets/profile_avatar.dart';
import 'package:mukzzi/src/features/profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/user_provider.dart';
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
        final isFriend = ref.watch(friendIdsProvider).contains(user.id);
        final isReceived = ref.watch(receivedRequestIdsProvider).contains(user.id);
        final isSent = ref.watch(sentRequestIdsProvider).contains(user.id);

        return GradientScaffold(
          appBar: AppBar(title: Text(user.nickname ?? '프로필')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                BentoCard(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        profileImageUrl: user.profileImageUrl,
                        radius: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.nickname ?? user.username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (user.equippedTitle != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            user.equippedTitle!,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                      if (isFriend) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                          ),
                          child: const Text('친구', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text('@${user.username}', style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      _buildActionButtons(isFriend, isSent, isReceived, user.id, user),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('먹찌 상태', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Row(
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
                _GuestbookSection(userId: widget.userId, nickname: user.nickname ?? user.username),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isFriend, bool isSent, bool isReceived, String userId, UserModel user) {
    if (isFriend) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/social/profile/$userId/room?nickname=${user.nickname ?? user.username}'),
              icon: const Icon(Icons.door_front_door_outlined, size: 18),
              label: const Text('캐릭터 방문'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _showWriteGuestbookDialog(context, ref, userId),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('방명록'),
            ),
          ),
        ],
      );
    }

    if (isSent) {
      return const SizedBox(width: double.infinity, child: FilledButton(onPressed: null, child: Text('친구 요청 보냄')));
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
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈습니다.')));
          } catch (e) {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('친구 신청하기'),
      ),
    );
  }

  void _showWriteGuestbookDialog(BuildContext context, WidgetRef ref, String targetUserId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('방명록 작성'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 100,
          decoration: const InputDecoration(hintText: '따뜻한 한마디를 남겨주세요.', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(socialRepositoryProvider).writeGuestbook(targetUserId, content, false);
                ref.invalidate(guestbookProvider(targetUserId));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('방명록이 등록되었습니다.')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록에 실패했습니다.')));
              }
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }
}

class _GuestbookSection extends ConsumerWidget {
  final String userId;
  final String nickname;

  const _GuestbookSection({required this.userId, required this.nickname});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final guestbooksAsync = ref.watch(guestbookProvider(userId));
    final myId = ref.watch(userProvider).user?.id;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('방명록', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => context.push('/social/profile/$userId/guestbook?nickname=$nickname'),
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          guestbooksAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('오류가 발생했습니다.', style: TextStyle(color: tokens.textMuted))),
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('아직 작성된 방명록이 없습니다.', style: TextStyle(color: AppColors.textTertiary))));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length > 3 ? 3 : entries.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: tokens.primary.withValues(alpha: 0.1)),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isMyPost = entry.writerId == myId;
                  final isProfileOwner = userId == myId;
                  final canDelete = isMyPost || isProfileOwner;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(entry.writer?.nickname ?? '익명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Text(_formatDate(entry.createdAt), style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                            const Spacer(),
                            if (canDelete)
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.withValues(alpha: 0.6)),
                                onPressed: () => _confirmDelete(context, ref, entry.id),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(entry.content, style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${date.month}월 ${date.day}일';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String guestbookId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('방명록 삭제'),
        content: const Text('이 방명록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(socialRepositoryProvider).deleteGuestbook(userId, guestbookId);
                ref.invalidate(guestbookProvider(userId));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
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
