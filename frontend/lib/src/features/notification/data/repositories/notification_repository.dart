import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mukzzi/src/core/network/api_client.dart';
import 'package:mukzzi/src/core/constants/app_constants.dart';
import 'package:mukzzi/src/features/notification/data/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sse/sse_client.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  NotificationRepository(this._apiClient, this._prefs);

  String get _now => DateFormat('HH:mm:ss.SSS').format(DateTime.now());

  /// 실시간 알림 스트림 수신 (SSE)
  /// 조건부 임포트된 SseClient를 통해 Web(HttpRequest) 또는 Mobile(Dio Stream)로 자동 분기됩니다.
  Stream<NotificationModel> subscribeToNotifications() {
    final token = _prefs.getString(AppConstants.accessTokenKey);
    const baseUrl = AppConstants.apiBaseUrl;
    
    // Web 환경일 경우 쿼리 파라미터 방식을 위해 URL 가공 (헤더 지원이 불안정할 경우 대비)
    final url = kIsWeb 
        ? '$baseUrl/notifications/stream?token=$token'
        : '$baseUrl/notifications/stream';

    debugPrint('[$_now][NotificationRepository] SSE 구독 요청 시작 (Platform: ${kIsWeb ? "Web" : "Mobile"})');
    
    return getSseClientInstance().subscribe(url, token, _apiClient.dio);
  }

  /// 알림 목록 조회
  Future<List<NotificationModel>> getNotifications({int limit = 20, String? cursor}) async {
    final response = await _apiClient.get(
      '/notifications',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    
    final data = response['data'] as List<dynamic>? ?? [];
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/notifications/$id/read', data: {});
  }

  Future<void> markAllAsRead() async {
    await _apiClient.post('/notifications/read-all', data: {});
  }
}
