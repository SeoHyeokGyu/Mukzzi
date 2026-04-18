import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  /// 실시간 알림 스트림 수신 (SSE)
  Stream<NotificationModel> subscribeToNotifications() async* {
    final dio = _apiClient.dio;
    
    // SSE는 일반적인 JSON 응답이 아니므로 ResponseType.stream 사용
    final response = await dio.get<ResponseBody>(
      '/notifications/stream',
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    if (response.data == null) return;

    // 스트림 데이터를 라인 단위로 읽어 처리
    await for (final chunk in response.data!.stream) {
      final content = utf8.decode(chunk);
      final lines = content.split('\n');
      
      String? currentEvent;
      for (final line in lines) {
        if (line.isEmpty) continue;
        
        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:') && currentEvent == 'notification') {
          final data = line.substring(5).trim();
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            yield NotificationModel.fromJson(json);
          } catch (e) {
            debugPrint('[NotificationRepository] JSON 파싱 에러: $e');
          }
          currentEvent = null; // 초기화
        }
      }
    }
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

  /// 알림 읽음 처리
  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/notifications/$id/read', data: {});
  }

  /// 전체 알림 읽음 처리
  Future<void> markAllAsRead() async {
    await _apiClient.post('/notifications/read-all', data: {});
  }
}
