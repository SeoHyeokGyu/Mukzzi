import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/collection_states.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/character_collection_model.dart';
import '../providers/character_collection_provider.dart';
import '../providers/character_provider.dart';

class CharacterCollectionPage extends ConsumerWidget {
  const CharacterCollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(characterCollectionListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('먹찌 도감')),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => CollectionErrorState(
          onRetry: () => ref.invalidate(characterCollectionListProvider),
        ),
        data: (collections) {
          if (collections.isEmpty) {
            return const CollectionEmptyState(
              icon: Icons.pets,
              title: '아직 도감이 비어 있어요',
              subtitle: '식사를 기록하면 먹찌가 성장해요',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: collections.length,
            itemBuilder: (_, i) => _CollectionCard(collection: collections[i]),
          );
        },
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final CharacterCollectionModel collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.softPeach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.pets, size: 44, color: AppColors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            collection.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          _PartsRow(collection: collection),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy.MM.dd').format(collection.achievedAt.toLocal()),
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _applyAppearance(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '적용',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyAppearance(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(characterRepositoryProvider);
      await repo.applyAppearance(
        bodyType: collection.bodyType,
        muscle: collection.muscle,
        skinTone: collection.skinTone,
        expression: collection.expression,
      );
      ref.invalidate(characterProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('외형이 적용되었습니다.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('외형 적용에 실패했습니다.')),
        );
      }
    }
  }
}

class _PartsRow extends StatelessWidget {
  final CharacterCollectionModel collection;

  const _PartsRow({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PartDot(value: collection.bodyType, tooltip: '체형'),
        const SizedBox(width: 4),
        _PartDot(value: collection.muscle, tooltip: '근육'),
        const SizedBox(width: 4),
        _PartDot(value: collection.skinTone, tooltip: '피부'),
        const SizedBox(width: 4),
        _PartDot(value: collection.expression, tooltip: '표정'),
      ],
    );
  }
}

class _PartDot extends StatelessWidget {
  final int value;
  final String tooltip;

  const _PartDot({required this.value, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$tooltip: $value',
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

