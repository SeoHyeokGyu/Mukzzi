// lib/src/features/meal_record/data/repositories/meal_repository.dart

import '../../../../core/network/api_client.dart';
import '../models/meal_model.dart';

class MealRepository {
  final ApiClient _apiClient;

  MealRepository(this._apiClient);

  /// 식사 기록 생성 — POST /meals
  Future<MealRecord> create(CreateMealRequest request) async {
    final response = await _apiClient.post('/meals', data: request.toJson());
    final data = response['data'] as Map<String, dynamic>;
    return MealRecord.fromJson(data['meal'] as Map<String, dynamic>);
  }

  /// 식사 기록 단건 조회 — GET /meals/:id
  Future<MealRecord> findById(String id) async {
    final response = await _apiClient.get('/meals/$id');
    final data = response['data'] as Map<String, dynamic>;
    return MealRecord.fromJson(data['meal'] as Map<String, dynamic>);
  }

  /// 식사 기록 목록 조회 — GET /meals (cursor 기반)
  Future<MealListResult> findAll(MealListFilter filter) async {
    final response = await _apiClient.get(
      '/meals',
      queryParameters: filter.toQueryParameters(),
    );
    // data가 List로 직접 옴
    final items = (response['data'] as List<dynamic>)
        .map((e) => MealRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    // 페이지네이션은 별도 키로 옴
    final pagination = response['pagination'] as Map<String, dynamic>?;
    final hasNext = pagination?['has_next'] as bool? ?? false;

    return MealListResult(
      meals: items,
      hasNext: hasNext,
      nextCursor: items.isNotEmpty ? items.last.id : null,
    );
  }

  /// 식사 기록 수정 — PATCH /meals/:id
  Future<MealRecord> update(int id, Map<String, dynamic> fields) async {
    final response = await _apiClient.patch('/meals/$id', data: fields);
    final data = response['data'] as Map<String, dynamic>;
    return MealRecord.fromJson(data['meal'] as Map<String, dynamic>);
  }

  /// 식사 기록 삭제 — DELETE /meals/:id
  Future<void> delete(String id) async {
    await _apiClient.delete('/meals/$id');
  }

  /// 오늘의 영양 합계 — GET /nutrition/today
  /// Go route: rg.Group("/nutrition") → GET "/today"
  Future<Map<String, dynamic>> getTodayNutrition() async {
    final response = await _apiClient.get('/nutrition/today');
    return response['data'] as Map<String, dynamic>;
  }

  /// 주간 영양 합계 — GET /nutrition/weekly?start_date=
  /// Go route: rg.Group("/nutrition") → GET "/weekly"
  Future<List<Map<String, dynamic>>> getWeeklyNutrition(String startDate) async {
    final response = await _apiClient.get(
      '/nutrition/weekly',
      queryParameters: {'start_date': startDate},
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['intakes'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// 친구 태그 수락 — POST /meals/:id/tags/:tagId/accept
  Future<void> acceptFriendTag(int mealId, int taggedUserId) async {
    await _apiClient.post(
      '/meals/$mealId/tags/$taggedUserId/accept',
      data: {},
    );
  }
}