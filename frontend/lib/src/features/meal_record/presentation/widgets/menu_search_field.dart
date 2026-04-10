import 'package:flutter/material.dart';
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
  final FocusNode _focusNode = FocusNode();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showDropdown = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelected(MenuModel menu) {
    widget.controller.value = TextEditingValue(text: menu.name);
    widget.onMenuSelected(menu);
    setState(() => _showDropdown = false);
    ref.read(menuSearchProvider.notifier).clear();
    _focusNode.unfocus();
  }

  void _onSelectNew(String name) {
    widget.controller.value = TextEditingValue(text: name);
    widget.onMenuSelected(null);
    setState(() => _showDropdown = false);
    ref.read(menuSearchProvider.notifier).clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(menuSearchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.done,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '예: 김치찌개',
            prefixIcon: const Icon(Icons.restaurant_menu),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                widget.controller.clear();
                widget.onMenuSelected(null);
                ref.read(menuSearchProvider.notifier).clear();
                setState(() {});
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {});
            ref.read(menuSearchProvider.notifier).search(value);
          },
        ),
        if (_showDropdown && widget.controller.text.isNotEmpty)
          _DropdownList(
            query: widget.controller.text,
            searchState: searchState,
            onSelected: _onSelected,
            onSelectNew: _onSelectNew,
          ),
      ],
    );
  }
}

class _DropdownList extends StatelessWidget {
  final String query;
  final MenuSearchState searchState;
  final void Function(MenuModel) onSelected;
  final void Function(String) onSelectNew;

  const _DropdownList({
    required this.query,
    required this.searchState,
    required this.onSelected,
    required this.onSelectNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: searchState.isLoading
          ? const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      )
          : Column(
        children: [
          if (searchState.results.isNotEmpty)
            ...searchState.results.map(
                  (menu) => GestureDetector(
                onTapDown: (_) => onSelected(menu),
                child: ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(menu.name),
                  subtitle: Text(
                    '${menu.category} · ${menu.defaultCalories.toStringAsFixed(0)}kcal',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          if (searchState.results.isEmpty)
            GestureDetector(
              onTapDown: (_) => onSelectNew(query),
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text('"$query" 직접 등록'),
              ),
            ),
        ],
      ),
    );
  }
}