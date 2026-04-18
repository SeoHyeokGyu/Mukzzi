import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/menu_model.dart';
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

  void _onChanged(String value) {
    setState(() => _showDropdown = value.isNotEmpty);
    if (value.isEmpty) {
      ref.read(menuSearchProvider.notifier).clear();
    } else {
      ref.read(menuSearchProvider.notifier).search(value);
    }
  }

  // Listener의 onPointerDown에서 호출 — onTapOutside/포커스보다 먼저 실행됨
  void _onSelected(MenuModel menu) {
    widget.controller.text = menu.name;
    widget.controller.selection =
        TextSelection.collapsed(offset: menu.name.length);
    ref.read(menuSearchProvider.notifier).clear();
    widget.onMenuSelected(menu);
    setState(() => _showDropdown = false);
  }

  void _onSelectNew(String name) {
    widget.controller.text = name;
    widget.controller.selection =
        TextSelection.collapsed(offset: name.length);
    ref.read(menuSearchProvider.notifier).clear();
    widget.onMenuSelected(null);
    setState(() => _showDropdown = false);
  }

  void _clear() {
    widget.controller.clear();
    widget.onMenuSelected(null);
    ref.read(menuSearchProvider.notifier).clear();
    setState(() => _showDropdown = false);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(menuSearchProvider);
    // API 결과 오면 드롭다운 유지 (텍스트 있을 때)
    if (searchState.results.isNotEmpty && widget.controller.text.isNotEmpty) {
      _showDropdown = true;
    }

    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHigh;

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
            suffixIcon: widget.controller.text.isNotEmpty
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
          onTapOutside: (_) {
            // 드롭다운 영역 터치는 Listener가 먼저 처리하므로
            // 여기 도달했을 때는 진짜 바깥 터치
            setState(() => _showDropdown = false);
          },
        ),

        // ── 드롭다운 ──
        if (_showDropdown && widget.controller.text.isNotEmpty)
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
            child: searchState.isLoading
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 검색 결과
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
                // 결과 없을 때만 직접 등록
                if (searchState.results.isEmpty)
                  _DropdownItem(
                    onPointerDown: () =>
                        _onSelectNew(widget.controller.text),
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(
                        '"${widget.controller.text}" 직접 등록',
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

/// Listener로 onPointerDown을 잡아서
/// 웹에서 onTapOutside/포커스 해제보다 먼저 선택 처리
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