import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/models/character_collection_model.dart';
import '../providers/character_collection_provider.dart';

class CharacterCollectionPage extends ConsumerWidget {
  const CharacterCollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(characterCollectionListProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('먹찌 도감')),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(characterCollectionListProvider),
        ),
        data: (collections) {
          if (collections.isEmpty) return const _EmptyState();
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
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

class _CollectionCard extends StatelessWidget {
  final CharacterCollectionModel collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 캐릭터 외형 시각화
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.softPeach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.pets,
              size: 44,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 10),
          // 파츠 조합 라벨
          Text(
            collection.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          // 파츠 상세
          _PartsRow(collection: collection),
          const SizedBox(height: 4),
          // 달성 날짜
          Text(
            DateFormat('yyyy.MM.dd').format(collection.achievedAt.toLocal()),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 64, color: AppColors.iconDisabled),
          SizedBox(height: 16),
          Text('아직 도감이 비어 있어요', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text('식사를 기록하면 먹찌가 성장해요', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('불러오지 못했어요', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
