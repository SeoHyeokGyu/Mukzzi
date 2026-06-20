import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mukzzi_character.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../data/models/character_model.dart';
import '../../domain/models/reward_model.dart';
import '../../domain/models/title_model.dart';
import '../providers/character_provider.dart';
import '../providers/reward_provider.dart';
import '../providers/title_provider.dart';

class EquipmentManagementPage extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? initialSlot;

  const EquipmentManagementPage({
    super.key,
    this.initialTab,
    this.initialSlot,
  });

  @override
  ConsumerState<EquipmentManagementPage> createState() =>
      _EquipmentManagementPageState();
}

class _EquipmentManagementPageState
    extends ConsumerState<EquipmentManagementPage> {
  bool _isTitleMode = false;
  final ScrollController _slotScrollController = ScrollController();
  CharacterModel? _tempCharacter;
  EquipmentSlot? _selectedSlot;
  bool _showAcquiredOnly = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isTitleMode = widget.initialTab == 'title';

    if (widget.initialSlot != null) {
      _selectedSlot = EquipmentSlot.fromJson(widget.initialSlot);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedSlot();
    });
  }

  @override
  void dispose() {
    _slotScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedSlot() {
    if (_selectedSlot == null || !_slotScrollController.hasClients) return;
    final index = EquipmentSlot.values.indexOf(_selectedSlot!);
    if (index == -1) return;
    final targetIndex = index + 1;
    final offset = targetIndex * 90.0 - 40.0;
    _slotScrollController.animateTo(
      offset.clamp(0.0, _slotScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _toggleEquipment({
    required RewardModel reward,
    required bool isEquipped,
  }) async {
    if (_isSubmitting) return;

    final slot = reward.renderConfig?.slot;
    if (slot == null || _tempCharacter == null) return;

    final originalCharacter = _tempCharacter!;
    
    // 로컬 상태 낙관적 즉시 업데이트
    final updatedEquipment = Map<EquipmentSlot, RewardModel>.from(originalCharacter.equipment);
    if (isEquipped) {
      updatedEquipment.remove(slot);
    } else {
      updatedEquipment[slot] = reward;
    }

    setState(() {
      _isSubmitting = true;
      _tempCharacter = originalCharacter.copyWith(equipment: updatedEquipment);
    });

    try {
      final repository = ref.read(characterRepositoryProvider);
      await repository.equipItem(
        slot: slot.value,
        rewardId: isEquipped ? null : reward.id,
      );
      if (!mounted) return;
      _invalidateCharacters();

      if (isEquipped) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('장착 해제되었습니다.'),
            action: SnackBarAction(
              label: '되돌리기',
              onPressed: () => _undoUnequip(slot: slot, rewardId: reward.id),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      // 실패 시 즉시 롤백
      setState(() {
        _tempCharacter = originalCharacter;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEquipped ? '해제에 실패했습니다.' : '장착에 실패했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _undoUnequip({
    required EquipmentSlot slot,
    required String rewardId,
  }) async {
    if (!mounted || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(characterRepositoryProvider);
      await repository.equipItem(slot: slot.value, rewardId: rewardId);
      if (!mounted) return;
      _invalidateCharacters();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('되돌리기에 실패했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _invalidateCharacters() {
    if (!mounted) return;
    ref.invalidate(characterProvider);
    ref.invalidate(testCharacterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final currentUser = ref.watch(userProvider).user;
    final isAdmin = kDebugMode || currentUser?.username == 'admin';

    if (isAdmin) {
      ref.listen<AsyncValue<CharacterModel?>>(
        testCharacterProvider,
        (previous, next) {
          next.whenOrNull(
            data: (character) {
              if (character != null && mounted) {
                setState(() {
                  _tempCharacter = character;
                });
              }
            },
          );
        },
      );
    } else {
      ref.listen<AsyncValue<CharacterModel>>(
        characterProvider,
        (previous, next) {
          next.whenOrNull(
            data: (character) {
              if (mounted) {
                setState(() {
                  _tempCharacter = character;
                });
              }
            },
          );
        },
      );
    }

    final AsyncValue<CharacterModel?> characterAsync = isAdmin
        ? ref.watch(testCharacterProvider)
        : ref
            .watch(characterProvider)
            .whenData<CharacterModel?>((character) => character);
    final rewardsAsync = ref.watch(rewardListProvider);
    // pre-watch so data is cached before switching to title mode
    ref.watch(titleListProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('장착 관리'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final character = _tempCharacter;
          return Column(
            children: [
              if (character != null)
                _CharacterPreview(
                  character: character,
                  availableHeight: constraints.maxHeight,
                )
              else
                const SizedBox.shrink(),
              _SlotSelector(
                selectedSlot: _selectedSlot,
                equipment: character?.equipment ?? {},
                tokens: tokens,
                scrollController: _slotScrollController,
                onSelected: (slot) => setState(() {
                  _isTitleMode = false;
                  _selectedSlot = slot;
                }),
                isTitleMode: _isTitleMode,
                onTitleSelected: () => setState(() {
                  _isTitleMode = true;
                  _selectedSlot = null;
                }),
              ),
              if (!_isTitleMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChoiceChip(
                        label: const Text('획득한 아이템만'),
                        selected: _showAcquiredOnly,
                        onSelected: (val) =>
                            setState(() => _showAcquiredOnly = val),
                      ),
                      Text(
                        '최신순',
                        style: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isTitleMode
                    ? _buildTitleContent(tokens)
                    : (character != null
                        ? _buildItemGrid(character, rewardsAsync, tokens)
                        : characterAsync.when(
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => CollectionErrorState(
                              onRetry: _invalidateCharacters,
                            ),
                            data: (char) {
                              if (char == null) {
                                return const CollectionEmptyState(
                                  icon: Icons.person_off_outlined,
                                  title: '캐릭터를 불러오지 못했어요',
                                  subtitle: '캐릭터가 생성된 뒤 장착을 관리할 수 있어요',
                                );
                              }
                              _tempCharacter = char;
                              return _buildItemGrid(char, rewardsAsync, tokens);
                            },
                          )),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleContent(AppColorTokens tokens) {
    final titlesAsync = ref.watch(titleListProvider);
    return titlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => CollectionErrorState(
        onRetry: () => ref.invalidate(titleListProvider),
      ),
      data: (titles) {
        if (titles.isEmpty) {
          return const CollectionEmptyState(
            icon: Icons.workspace_premium,
            title: '아직 칭호가 없어요',
            subtitle: '다양한 도전을 달성하면 칭호를 얻을 수 있어요',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: titles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _TitleCard(
            title: titles[i],
            onEquip: () => _handleEquipTitle(context, titles[i]),
          ),
        );
      },
    );
  }

  Future<void> _handleEquipTitle(BuildContext context, TitleModel title) async {
    final repo = ref.read(titleRepositoryProvider);
    try {
      if (title.isEquipped) {
        await repo.equipTitle(null);
      } else {
        await repo.equipTitle(title.id);
      }
      ref.invalidate(titleListProvider);
    } catch (e) {
      debugPrint('[EquipmentManagementPage] equipTitle error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 중 오류가 발생했어요')),
        );
      }
    }
  }

  Widget _buildItemGrid(
    CharacterModel character,
    AsyncValue<List<RewardModel>> rewardsAsync,
    AppColorTokens tokens,
  ) {
    return rewardsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => CollectionErrorState(
        onRetry: () => ref.invalidate(rewardListProvider),
      ),
      data: (rewards) {
        final candidates = rewards.where((reward) {
          final slot = reward.renderConfig?.slot;
          if (slot == null) return false;

          if (_showAcquiredOnly && !reward.acquired) return false;

          return _selectedSlot == null || slot == _selectedSlot;
        }).toList();

        if (candidates.isEmpty) {
          return const CollectionEmptyState(
            icon: Icons.inventory_2_outlined,
            title: '장착할 수 있는 아이템이 없어요',
            subtitle: '획득한 장착 아이템이 여기에 표시돼요',
          );
        }

        return Center(
          child: SizedBox(
            width: 480,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final reward = candidates[index];
                final slot = reward.renderConfig!.slot;
                final isEquipped =
                    character.equipment[slot]?.id == reward.id;
                return _EquipmentRewardCard(
                  reward: reward,
                  slot: slot,
                  isEquipped: isEquipped,
                  isSubmitting: _isSubmitting,
                  tokens: tokens,
                  onTap: () => _toggleEquipment(
                    reward: reward,
                    isEquipped: isEquipped,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({
    required this.character,
    required this.availableHeight,
  });

  final CharacterModel character;
  final double availableHeight;

  // 이 미만이면 프리뷰(최소 80px)가 칩/슬롯 셀렉터/그리드에 필요한 공간을 잠식하는 지점
  static const double _minVisibleHeight = 380;

  // 가용 높이 대비 프리뷰 비율. clamp(80~130)와 함께 444~722px 구간에서만 비례 동작.
  static const double _heightRatio = 0.18;
  static const double _minCharSize = 80;
  static const double _maxCharSize = 130;

  @override
  Widget build(BuildContext context) {
    if (availableHeight < _minVisibleHeight) {
      return const SizedBox.shrink();
    }

    final charSize = (availableHeight * _heightRatio)
        .clamp(_minCharSize, _maxCharSize)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MukzziCharacter(
        state: character.state,
        size: charSize,
        showAccessory: character.equippedAccessory != null,
        equippedAccessory: character.equippedAccessory?.assetUrl,
        equipment: character.equipment,
        backgroundEdgeFade: true,
        enableAnimation: false,
      ),
    );
  }
}

class _SlotSelector extends StatelessWidget {
  const _SlotSelector({
    required this.selectedSlot,
    required this.equipment,
    required this.tokens,
    required this.onSelected,
    required this.scrollController,
    required this.isTitleMode,
    required this.onTitleSelected,
  });

  final EquipmentSlot? selectedSlot;
  final Map<EquipmentSlot, RewardModel> equipment;
  final AppColorTokens tokens;
  final ValueChanged<EquipmentSlot?> onSelected;
  final ScrollController scrollController;
  final bool isTitleMode;
  final VoidCallback onTitleSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: <double>[0.0, 0.08, 0.92, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _SlotChip(
              label: '칭호',
              icon: Icons.workspace_premium,
              selected: isTitleMode,
              equipped: false,
              tokens: tokens,
              onTap: onTitleSelected,
            ),
            _SlotChip(
              label: '전체',
              icon: Icons.apps,
              selected: !isTitleMode && selectedSlot == null,
              equipped: equipment.isNotEmpty,
              tokens: tokens,
              onTap: () => onSelected(null),
            ),
            ...EquipmentSlot.values.map(
              (slot) => _SlotChip(
                label: slot.label,
                icon: slot.icon,
                selected: !isTitleMode && selectedSlot == slot,
                equipped: equipment.containsKey(slot),
                tokens: tokens,
                onTap: () => onSelected(slot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.equipped,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool equipped;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected || equipped ? tokens.primary : tokens.textMuted;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(icon, size: 18, color: foreground),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? tokens.textPrimary : tokens.textSub,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: tokens.primaryBg,
        backgroundColor: tokens.card,
        side: BorderSide(
          color: equipped
              ? tokens.primary.withValues(alpha: selected ? 0.8 : 0.45)
              : tokens.textMuted.withValues(alpha: 0.18),
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EquipmentRewardCard extends StatelessWidget {
  const _EquipmentRewardCard({
    required this.reward,
    required this.slot,
    required this.isEquipped,
    required this.isSubmitting,
    required this.tokens,
    required this.onTap,
  });

  final RewardModel reward;
  final EquipmentSlot slot;
  final bool isEquipped;
  final bool isSubmitting;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAcquired = reward.acquired;
    final cardBgColor = tokens.card.withValues(alpha: 0.6);
    
    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.rItem),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(tokens.rItem),
            border: Border.all(
              color: isEquipped 
                  ? tokens.primary.withValues(alpha: 0.5) 
                  : tokens.textMuted.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.rItem),
            child: InkWell(
              onTap: () {
                if (!isAcquired) {
                  final router = GoRouter.of(context);
                  final isTestRoute = router.configuration.routes.any(
                    (r) => r is GoRoute && r.path == '/collection',
                  );
                  if (isTestRoute) {
                    context.push('/collection');
                  } else {
                    context.push('/character/collection');
                  }
                } else if (!isSubmitting) {
                  onTap();
                }
              },
              borderRadius: BorderRadius.circular(tokens.rItem),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tokens.primaryBg.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(slot.icon, size: 16, color: tokens.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SlotLabel(label: slot.label, tokens: tokens),
                              if (isEquipped) ...[
                                const SizedBox(height: 2),
                                _EquippedLabel(tokens: tokens),
                              ],
                            ],
                          ),
                        ),
                        if (!isAcquired) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.lock_outline, size: 18, color: tokens.textMuted),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      reward.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textMuted,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: isAcquired
                          ? _ActionLabel(
                              label: isEquipped ? '해제' : '장착',
                              isEquipped: isEquipped,
                              tokens: tokens,
                            )
                          : Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tokens.textMuted.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '획득하러 가기 →',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.primary,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!isAcquired) {
      cardContent = Opacity(
        opacity: 0.6,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class _SlotLabel extends StatelessWidget {
  const _SlotLabel({required this.label, required this.tokens});

  final String label;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: tokens.primary,
      ),
    );
  }
}

class _EquippedLabel extends StatelessWidget {
  const _EquippedLabel({required this.tokens});

  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '장착중',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tokens.primary,
        ),
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({
    required this.label,
    required this.isEquipped,
    required this.tokens,
  });

  final String label;
  final bool isEquipped;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isEquipped ? tokens.listItemBg : tokens.primaryBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isEquipped ? tokens.textSub : tokens.primary,
        ),
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  final TitleModel title;
  final VoidCallback onEquip;

  const _TitleCard({required this.title, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    final acquired = title.acquired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: title.isEquipped
            ? Border.all(color: AppColors.orange.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // 칭호 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: acquired
                  ? AppColors.softPeach
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 26,
              color: acquired ? AppColors.orange : AppColors.iconDisabled,
            ),
          ),
          const SizedBox(width: 14),
          // 칭호 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: acquired ? AppColors.textPrimary : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    if (title.isEquipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.softPeach,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '장착 중',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (acquired && title.achievedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('yyyy.MM.dd').format(title.achievedAt!.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 장착 버튼
          if (acquired)
            TextButton(
              onPressed: onEquip,
              style: TextButton.styleFrom(
                foregroundColor: title.isEquipped ? AppColors.textSecondary : AppColors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(title.isEquipped ? '해제' : '장착'),
            ),
        ],
      ),
    );
  }
}
