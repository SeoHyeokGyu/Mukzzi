import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mukzzi_character.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../providers/social_providers.dart';

const String riceBowlSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <!-- 밥 -->
  <path d="M20,40 Q50,10 80,40 Z" fill="#FFFFFF" stroke="#CFD8DC" stroke-width="2"/>
  <!-- 그릇 -->
  <path d="M15,40 Q50,90 85,40 Z" fill="#ECEFF1" stroke="#90A4AE" stroke-width="4"/>
  <!-- 그릇 굽 -->
  <rect x="40" y="75" width="20" height="8" rx="2" fill="#B0BEC5"/>
</svg>
''';

const String heartSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <path d="M12,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 88,30 Q 88,60 50,90 Q 12,60 12,30 Z" fill="#FF5252"/>
</svg>
''';

const String starSvg = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <polygon points="50,5 64,36 98,36 70,57 81,91 50,70 19,91 30,57 2,36 36,36" fill="#FFD700"/>
</svg>
''';

class FriendRoomPage extends ConsumerStatefulWidget {
  final String userId;
  final String nickname;

  const FriendRoomPage({
    super.key,
    required this.userId,
    required this.nickname,
  });

  @override
  ConsumerState<FriendRoomPage> createState() => _FriendRoomPageState();
}

class _FriendRoomPageState extends ConsumerState<FriendRoomPage> {
  bool _isVisited = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  CharacterState _characterState = CharacterState.normal;

  bool _showFeedEffect = false;
  bool _showNudgeEffect = false;

  int _friendshipScore = 0;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final myId = ref.read(userProvider).user?.id;
    if (myId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. SharedPreferences 기반 오늘 기방문 여부 확인
      final prefs = await SharedPreferences.getInstance();
      final lastVisit = prefs.getString('last_visit_${myId}_${widget.userId}');
      if (lastVisit != null) {
        final visitDate = DateTime.tryParse(lastVisit);
        if (visitDate != null) {
          final loc = visitDate.toLocal();
          final now = DateTime.now().toLocal();
          if (loc.year == now.year && loc.month == now.month && loc.day == now.day) {
            _isVisited = true;
          }
        }
      }

      // 2. 우정 점수 최신 조회를 위해 친구 정보 fetch (other profile에 friendship score 가 노출되므로)
      await ref.read(socialRepositoryProvider).getOtherProfile(widget.userId);
      // GORM FriendshipScore 필드가 DB에는 있으나 UserModel DTO 등에는 아직 반영이 안 되어 있을 수 있으므로
      // 일단 API visit 호출 시 성공 응답값으로 정확하게 업데이트 하되,
      // 프로필 상세에 우정 점수 컬럼이 연동될 수 있도록 default 0에서 API 성공 시 갱신하도록 처리합니다.
    } catch (e) {
      // 에러 무시
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _interact(String type) async {
    if (_isSubmitting || _isVisited) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final res = await ref.read(socialRepositoryProvider).visitFriend(widget.userId, type);

      // 성공 시 보상 갱신
      final currentScore = res['current_friendship_score'] as int? ?? 0;
      final pointsEarned = res['visitor_point_earned'] as int? ?? 10;

      // SharedPreferences 저장
      final myId = ref.read(userProvider).user?.id;
      if (myId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_visit_${myId}_${widget.userId}', DateTime.now().toIso8601String());
      }

      // 애니메이션 연출 트리거
      setState(() {
        _isVisited = true;
        _friendshipScore = currentScore;
        _characterState = CharacterState.happy;
        if (type == 'FEED') {
          _showFeedEffect = true;
        } else {
          _showNudgeEffect = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('방울 $pointsEarned개를 획득하고 친구에게도 선물했습니다! (우정 점수 +1)'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 650ms 후 리액션 종료 및 캐릭터 상태 복구
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        setState(() {
          _characterState = CharacterState.normal;
        });
      }

      // 이펙트 서서히 클리어
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _showFeedEffect = false;
          _showNudgeEffect = false;
        });
      }
    } catch (e) {
      String errorMsg = '상호작용에 실패했습니다.';
      if (e.toString().contains('already_visited') || e.toString().contains('이미 방문')) {
        errorMsg = '오늘 이 친구의 캐릭터 룸은 이미 방문했습니다.';
        // 어긋난 로컬 상태 갱신
        final myId = ref.read(userProvider).user?.id;
        if (myId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_visit_${myId}_${widget.userId}', DateTime.now().toIso8601String());
        }
        setState(() {
          _isVisited = true;
        });
      } else if (e.toString().contains('limit_exceeded') || e.toString().contains('5회')) {
        errorMsg = '오늘의 상호작용 한도(5회)를 초과했습니다.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GradientScaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GradientScaffold(
      appBar: AppBar(
        title: Text('${widget.nickname}의 캐릭터 룸'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 배경 데코 레이어 (방 같은 느낌을 줌)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          
          // 방 바닥 연출
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.elliptical(500, 80)),
              ),
            ),
          ),

          // 메인 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // 캐릭터 영역 (Stack을 활용하여 바운싱 그림자 포함)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 그림자
                    Positioned(
                      bottom: 5,
                      child: Container(
                        width: 140,
                        height: 20,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // 캐릭터 본체
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MukzziCharacter(
                        state: _characterState,
                        size: 220,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 캐릭터 대사 풍선
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primaryContainer),
                  ),
                  child: Text(
                    _characterState == CharacterState.happy
                        ? '고마워찌! (우정 스코어 업!)'
                        : '놀러와줘서 고마워찌!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 우정 점수 정보 표시
                if (_friendshipScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '우정 지수: $_friendshipScore점',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),

                const Spacer(flex: 3),

                // 하단 상호작용 컨트롤
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                  child: BentoCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isVisited)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  '오늘의 상호작용 완료!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              // 먹이주기 버튼
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isSubmitting ? null : () => _interact('FEED'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.lunch_dining),
                                  label: const Text('먹이주기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 응원하기 버튼
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isSubmitting ? null : () => _interact('NUDGE'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: const Icon(Icons.favorite),
                                  label: const Text('응원하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // [애니메이션 오버레이 1] 먹이주기 (음식 낙하 이펙트)
          if (_showFeedEffect)
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width / 2 - 40,
              child: SvgPicture.string(
                riceBowlSvg,
                width: 80,
                height: 80,
              )
                  .animate()
                  .slideY(begin: -3, end: 2.2, duration: 650.ms, curve: Curves.bounceOut)
                  .fadeOut(delay: 500.ms, duration: 150.ms),
            ),

          // [애니메이션 오버레이 2] 응원하기 (하트 및 별빛 파티클 확산 이펙트)
          if (_showNudgeEffect)
            ...List.generate(6, (index) {
              final double angle = index * (math.pi / 3);
              final double dx = 140 * math.cos(angle);
              final double dy = 140 * math.sin(angle);
              final isHeart = index % 2 == 0;
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 - 25,
                top: MediaQuery.of(context).size.height / 2 - 130,
                child: SvgPicture.string(
                  isHeart ? heartSvg : starSvg,
                  width: 50,
                  height: 50,
                )
                    .animate()
                    .move(begin: Offset.zero, end: Offset(dx, dy), duration: 800.ms, curve: Curves.easeOutCubic)
                    .scale(begin: const Offset(0.2, 0.2), end: const Offset(1.2, 1.2), duration: 800.ms)
                    .fadeOut(delay: 550.ms, duration: 250.ms),
              );
            }),
        ],
      ),
    );
  }
}
