// lib/src/features/meal_record/presentation/widgets/menu_search_field.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/menu_model.dart';
import '../providers/favorite_provider.dart';
import '../providers/menu_search_provider.dart';

class MenuSearchField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final void Function(MenuModel? menu) onMenuSelected;

  const MenuSearchField({
    super.key,
    required this.controller,
    required this.onMenuSelected,
  });

  @override
  ConsumerState<MenuSearchField> createState() => _MenuSearchFieldState();
}

class _MenuSearchFieldState extends ConsumerState<MenuSearchField> {
  bool _showDropdown = false;
  bool _isRegistering = false;

  void _onChanged(String value) {
    setState(() => _showDropdown = value.isNotEmpty);
    if (value.isEmpty) {
      ref.read(menuSearchProvider.notifier).clear();
    } else {
      ref.read(menuSearchProvider.notifier).search(value);
    }
  }

  void _onSelected(MenuModel menu) {
    widget.controller.text = menu.name;
    widget.controller.selection =
        TextSelection.collapsed(offset: menu.name.length);
    ref.read(menuSearchProvider.notifier).clear();
    widget.onMenuSelected(menu);
    setState(() => _showDropdown = false);
  }

  Future<void> _onSelectNew(String name) async {
    if (_isRegistering) return;
    setState(() => _isRegistering = true);
    try {
      final menu = await ref
          .read(menuRepositoryProvider)
          .create(name: name, category: 'OTHER');
      if (!mounted) return;
      widget.controller.text = menu.name;
      widget.controller.selection =
          TextSelection.collapsed(offset: menu.name.length);
      ref.read(menuSearchProvider.notifier).clear();
      widget.onMenuSelected(menu);
      setState(() {
        _showDropdown = false;
        _isRegistering = false;
      });
    } catch (_) {
      if (!mounted) return;
      widget.controller.text = name;
      widget.controller.selection =
          TextSelection.collapsed(offset: name.length);
      ref.read(menuSearchProvider.notifier).clear();
      widget.onMenuSelected(null);
      setState(() {
        _showDropdown = false;
        _isRegistering = false;
      });
    }
  }

  void _clear() {
    widget.controller.clear();
    widget.onMenuSelected(null);
    ref.read(menuSearchProvider.notifier).clear();
    setState(() => _showDropdown = false);
  }

  void _showFavoriteBottomSheet(List<MenuModel> favorites) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FavoriteBottomSheet(
        favorites: favorites,
        onSelected: (menu) {
          Navigator.pop(ctx);
          _onSelected(menu);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(menuSearchProvider);
    final favoriteState = ref.watch(favoriteListProvider);
    final isEmpty = widget.controller.text.isEmpty;

    if (searchState.results.isNotEmpty && !isEmpty) {
      _showDropdown = true;
    }

    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final favorites = favoriteState.favorites.map((f) => f.menu).toList();
    final previewFavorites = favorites.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── TextField ──
        TextField(
          controller: widget.controller,
          textInputAction: TextInputAction.done,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '예: 김치찌개',
            prefixIcon: const Icon(Icons.restaurant_menu),
            suffixIcon: !isEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clear,
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: _onChanged,
          onTapOutside: (_) => setState(() => _showDropdown = false),
        ),

        // ── 즐겨찾기 칩 + 전체보기 (검색어 없을 때만) ──
        if (isEmpty && favorites.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: previewFavorites.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final menu = previewFavorites[index];
                      return ActionChip(
                        avatar: const Icon(Icons.star, size: 14),
                        label: Text(menu.name),
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _onSelected(menu),
                      );
                    },
                  ),
                ),
              ),
              if (favorites.length > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showFavoriteBottomSheet(favorites),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '전체보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],

        // ── 드롭다운 (검색어 있을 때) ──
        if (_showDropdown && !isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: (searchState.isLoading || _isRegistering)
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (searchState.results.isNotEmpty)
                  ...searchState.results.map(
                        (menu) => _DropdownItem(
                      onPointerDown: () => _onSelected(menu),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant),
                        title: Text(menu.name),
                        subtitle: Text(
                          '${menu.category} · '
                              '${menu.defaultCalories.toStringAsFixed(0)}kcal',
                        ),
                      ),
                    ),
                  ),
                if (searchState.results.isEmpty)
                  _DropdownItem(
                    onPointerDown: () =>
                        _onSelectNew(widget.controller.text),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(
                        '"${widget.controller.text}" 직접 등록',
                      ),
                      subtitle: const Text(
                        '새 메뉴로 등록됩니다',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── 즐겨찾기 전체보기 바텀시트 ──

class _FavoriteBottomSheet extends StatelessWidget {
  final List<MenuModel> favorites;
  final void Function(MenuModel) onSelected;

  const _FavoriteBottomSheet({
    required this.favorites,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 핸들
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '즐겨찾기 (${favorites.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  final menu = favorites[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      menu.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${menu.category} · ${menu.defaultCalories.toStringAsFixed(0)}kcal',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelected(menu),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final VoidCallback onPointerDown;
  final Widget child;

  const _DropdownItem({
    required this.onPointerDown,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPointerDown(),
      child: child,
    );
  }
}