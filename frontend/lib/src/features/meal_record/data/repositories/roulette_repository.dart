import '../../../../core/network/api_client.dart';
import '../models/menu_model.dart';

class RouletteResult {
  final List<MenuModel> candidates;
  final MenuModel menu;
  final String reason;

  const RouletteResult({
    required this.candidates,
    required this.menu,
    required this.reason,
  });

  factory RouletteResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final candidateList = data['candidates'] as List<dynamic>? ?? [];
    return RouletteResult(
      candidates: candidateList
          .map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      menu: MenuModel.fromJson(data['menu'] as Map<String, dynamic>),
      reason: data['reason'] as String? ?? '',
    );
  }
}

class FilterResult {
  final List<MenuModel> menus;
  final String source; // "personal" | "global"

  const FilterResult({required this.menus, required this.source});

  factory FilterResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final list = data['menus'] as List<dynamic>;
    return FilterResult(
      menus: list.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList(),
      source: data['source'] as String? ?? 'global',
    );
  }
}

class RouletteRepository {
  final ApiClient _apiClient;

  RouletteRepository(this._apiClient);

  /// POST /menus/roulette
  Future<RouletteResult> spin() async {
    final response = await _apiClient.post('/menus/roulette', data: {});
    return RouletteResult.fromJson(response as Map<String, dynamic>);
  }

  /// GET /menus/filter?weather=...&mood=...
  Future<FilterResult> filter({
    List<String> weathers = const [],
    List<String> moods = const [],
  }) async {
    final response = await _apiClient.get(
      '/menus/filter',
      queryParameters: {
        if (weathers.isNotEmpty) 'weather': weathers.join(','),
        if (moods.isNotEmpty) 'mood': moods.join(','),
      },
    );
    return FilterResult.fromJson(response as Map<String, dynamic>);
  }
}