import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/badge_model.dart';

class BadgeDetailBottomSheet extends StatelessWidget {
  final BadgeModel badge;
  final ScrollController? scrollController;

  const BadgeDetailBottomSheet({
    super.key,
    required this.badge,
    this.scrollController,
  });

  static void show(BuildContext context, BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // barrierColor를 명시적으로 설정하여 밝기 테마 대응
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Stack(
        children: [
          // 배경 어디든 누르면 닫히도록 하는 투명 레이어
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            builder: (context, scrollController) => BadgeDetailBottomSheet(
              badge: badge,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 32 + bottomPadding),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 아이콘 영역
              _buildIcon(tokens),
              const SizedBox(height: 20),

              // 뱃지 이름
              Text(
                badge.name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 설명
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: tokens.textSub,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // 달성 조건 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: tokens.listItemBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tokens.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 20,
                        color: tokens.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '달성 조건',
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.condition,
                            style: TextStyle(
                              fontSize: 15,
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 진행도 표시 (Progressive Badge)
              if (!badge.isUnlocked && badge.target > 0)
                _buildProgressCard(tokens),

              const SizedBox(height: 12),

              // 획득일 / 미획득
              _buildUnlockStatus(tokens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(AppColorTokens tokens) {
    if (badge.isUnlocked) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(badge.iconData, size: 48, color: Colors.white),
      );
    }

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: tokens.listItemBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(badge.iconData, size: 48, color: tokens.textMuted.withValues(alpha: 0.5)),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.card,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.listItemBg, width: 2),
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 16,
              color: tokens.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(AppColorTokens tokens) {
    final double progressValue = (badge.progress / badge.target).clamp(0.0, 1.0);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '현재 진행도',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.primary),
              ),
              Text(
                '${badge.progress} / ${badge.target}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: tokens.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: tokens.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockStatus(AppColorTokens tokens) {
    if (badge.isUnlocked && badge.unlockedAt != null) {
      final date = DateTime.tryParse(badge.unlockedAt!);
      final formatted = date != null
          ? DateFormat('yyyy.MM.dd').format(date.toLocal())
          : badge.unlockedAt!;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: tokens.primary),
            const SizedBox(width: 8),
            Text(
              '$formatted 획득 완료',
              style: TextStyle(fontSize: 13, color: tokens.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.listItemBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '아직 달성하지 못했어요',
        style: TextStyle(fontSize: 13, color: tokens.textMuted, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }
}
