import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/mukzzi_character.dart';
import '../../../profile/presentation/providers/user_provider.dart';
import '../../data/models/character_model.dart';
import '../../domain/models/reward_model.dart';
import '../providers/character_provider.dart';
import '../providers/reward_provider.dart';

class EquipmentManagementPage extends ConsumerStatefulWidget {
  const EquipmentManagementPage({super.key});

  @override
  ConsumerState<EquipmentManagementPage> createState() =>
      _EquipmentManagementPageState();
}

class _EquipmentManagementPageState
    extends ConsumerState<EquipmentManagementPage> {
  EquipmentSlot? _selectedSlot;
  bool _showAcquiredOnly = true;
  bool _isSubmitting = false;

  Future<void> _toggleEquipment({
    required RewardModel reward,
    required bool isEquipped,
  }) async {
    if (_isSubmitting) return;

    final slot = reward.renderConfig?.slot;
    if (slot == null) return;

    setState(() => _isSubmitting = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEquipped ? '해제에 실패했습니다.' : '장착에 실패했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _undoUnequip({
    required EquipmentSlot slot,
    required String rewardId,
  }) async {
    if (!mounted || _isSubmitting) return;

    setState(() => _isSubmitting = true);
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _invalidateCharacters() {
    ref.invalidate(characterProvider);
    ref.invalidate(testCharacterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final currentUser = ref.watch(userProvider).user;
    final isAdmin = kDebugMode || currentUser?.username == 'admin';
    final AsyncValue<CharacterModel?> characterAsync = isAdmin
        ? ref.watch(testCharacterProvider)
        : ref
            .watch(characterProvider)
            .whenData<CharacterModel?>((character) => character);
    final rewardsAsync = ref.watch(rewardListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('장착 관리')),
      body: characterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => CollectionErrorState(onRetry: _invalidateCharacters),
        data: (character) {
          if (character == null) {
            return const CollectionEmptyState(
              icon: Icons.person_off_outlined,
              title: '캐릭터를 불러오지 못했어요',
              subtitle: '캐릭터가 생성된 뒤 장착을 관리할 수 있어요',
            );
          }

          return rewardsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => CollectionErrorState(
              onRetry: () => ref.invalidate(rewardListProvider),
            ),
            data: (rewards) {
              final candidates = rewards.where((reward) {
                final slot = reward.renderConfig?.slot;
                if (slot == null) return false;

                // 획득 여부 필터
                if (_showAcquiredOnly && !reward.acquired) return false;

                return _selectedSlot == null || slot == _selectedSlot;
              }).toList();

              return Column(
                children: [
                  _CharacterPreview(character: character, tokens: tokens),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ChoiceChip(
                          label: const Text('획득한 아이템만'),
                          selected: _showAcquiredOnly,
                          onSelected: (val) => setState(() => _showAcquiredOnly = val),
                        ),
                        // 최신순 정렬 버튼 등의 Placeholder 혹은 단순 텍스트
                        Text('최신순', style: TextStyle(color: tokens.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  _SlotSelector(
                    selectedSlot: _selectedSlot,
                    equipment: character.equipment,
                    tokens: tokens,
                    onSelected: (slot) => setState(() => _selectedSlot = slot),
                  ),
                  Expanded(
                    child: candidates.isEmpty
                        ? const CollectionEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: '장착할 수 있는 아이템이 없어요',
                            subtitle: '획득한 장착 아이템이 여기에 표시돼요',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: candidates.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({
    required this.character,
    required this.tokens,
  });

  final CharacterModel character;
  final AppColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: tokens.cardHeroGrad,
        borderRadius: BorderRadius.circular(tokens.rHero),
      ),
      child: Column(
        children: [
          Text(
            character.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tokens.heroText,
            ),
          ),
          const SizedBox(height: 12),
          MukzziCharacter(
            state: character.state,
            size: 180,
            showAccessory: character.equippedAccessory != null,
            equippedAccessory: character.equippedAccessory?.assetUrl,
            equipment: character.equipment,
          ),
        ],
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
  });

  final EquipmentSlot? selectedSlot;
  final Map<EquipmentSlot, RewardModel> equipment;
  final AppColorTokens tokens;
  final ValueChanged<EquipmentSlot?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SlotChip(
            label: '전체',
            icon: Icons.apps,
            selected: selectedSlot == null,
            equipped: equipment.isNotEmpty,
            tokens: tokens,
            onTap: () => onSelected(null),
          ),
          ...EquipmentSlot.values.map(
            (slot) => _SlotChip(
              label: slot.label,
              icon: slot.icon,
              selected: selectedSlot == slot,
              equipped: equipment.containsKey(slot),
              tokens: tokens,
              onTap: () => onSelected(slot),
            ),
          ),
        ],
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
    return Material(
      color: tokens.card,
      borderRadius: BorderRadius.circular(tokens.rItem),
      child: InkWell(
        onTap: isSubmitting ? null : onTap,
        borderRadius: BorderRadius.circular(tokens.rItem),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(slot.icon, color: tokens.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SlotLabel(label: slot.label, tokens: tokens),
                        if (isEquipped) ...[
                          const SizedBox(width: 6),
                          _EquippedLabel(tokens: tokens),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reward.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ActionLabel(
                label: isEquipped ? '해제' : '장착',
                isEquipped: isEquipped,
                tokens: tokens,
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isEquipped ? tokens.listItemBg : tokens.primaryBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isEquipped ? tokens.textSub : tokens.primary,
        ),
      ),
    );
  }
}
