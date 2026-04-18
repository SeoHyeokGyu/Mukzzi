import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import 'sse_client.dart';

SseClient getSseClient() => SseClientMobile();

class SseClientMobile implements SseClient {
  String get _now => DateFormat('HH:mm:ss.SSS').format(DateTime.now());

  @override
  Stream<NotificationModel> subscribe(String url, String? token, Dio dio) async* {
    debugPrint('[$_now][SseClientMobile] Mobile 전용 dio 스트림 연결 시도: $url');

    try {
      final response = await dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          receiveTimeout: Duration.zero,
        ),
      );

      if (response.data == null) return;

      String? currentEvent;
      
      final lineStream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('event:')) {
          currentEvent = trimmed.substring(6).trim();
        } else if (trimmed.startsWith('data:')) {
          final data = trimmed.substring(5).trim();
          if (currentEvent == 'notification') {
            try {
              yield NotificationModel.fromJson(jsonDecode(data));
              debugPrint('[$_now][SseClientMobile] 알림 수신 성공');
            } catch (e) {
              debugPrint('[$_now][SseClientMobile] JSON 파싱 에러: $e');
            }
          }
          currentEvent = null;
        }
      }
    } catch (e) {
      debugPrint('[$_now][SseClientMobile] 스트림 에러: $e');
      rethrow;
    }
  }
}
