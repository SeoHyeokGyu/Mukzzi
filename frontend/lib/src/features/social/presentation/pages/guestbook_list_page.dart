import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mukzzi/src/core/theme/app_theme.dart';
import 'package:mukzzi/src/core/widgets/gradient_scaffold.dart';
import 'package:mukzzi/src/core/widgets/bento_card.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../providers/social_providers.dart';

class GuestbookListPage extends ConsumerStatefulWidget {
  final String userId;
  final String nickname;

  const GuestbookListPage({super.key, required this.userId, required this.nickname});

  @override
  ConsumerState<GuestbookListPage> createState() => _GuestbookListPageState();
}

class _GuestbookListPageState extends ConsumerState<GuestbookListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(guestbookPagingProvider(widget.userId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final pagingState = ref.watch(guestbookPagingProvider(widget.userId));
    final myId = ref.watch(userProvider).user?.id;

    return GradientScaffold(
      appBar: AppBar(title: Text('${widget.nickname}님의 방명록')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(guestbookPagingProvider(widget.userId).notifier).refresh(),
        child: pagingState.items.isEmpty && pagingState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : pagingState.items.isEmpty
                ? const Center(child: Text('작성된 방명록이 없습니다.', style: TextStyle(color: Colors.white70)))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: pagingState.items.length + (pagingState.hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == pagingState.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final entry = pagingState.items[index];
                      final canDelete = entry.writerId == myId || widget.userId == myId;

                      return BentoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: entry.writer?.profileImageUrl != null
                                      ? NetworkImage(entry.writer!.profileImageUrl!)
                                      : null,
                                  child: entry.writer?.profileImageUrl == null
                                      ? const Icon(Icons.person, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.writer?.nickname ?? '익명',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(entry.createdAt),
                                  style: TextStyle(fontSize: 12, color: tokens.textMuted),
                                ),
                                if (canDelete)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.withValues(alpha: 0.6)),
                                    onPressed: () => _confirmDelete(context, ref, entry.id),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(left: 8),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              entry.content,
                              style: TextStyle(fontSize: 15, color: tokens.textPrimary, height: 1.5),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${date.year}.${date.month}.${date.day}';
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
                await ref.read(socialRepositoryProvider).deleteGuestbook(widget.userId, guestbookId);
                // 페이징 상태에서 아이템 제거 및 목록 프로바이더 무효화
                ref.read(guestbookPagingProvider(widget.userId).notifier).removeItem(guestbookId);
                ref.invalidate(guestbookProvider(widget.userId));
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
