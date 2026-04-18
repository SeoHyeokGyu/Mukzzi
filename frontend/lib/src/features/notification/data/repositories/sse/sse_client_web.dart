import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../models/notification_model.dart';
import 'sse_client.dart';

SseClient getSseClient() => SseClientWeb();

class SseClientWeb implements SseClient {
  String get _now => DateFormat('HH:mm:ss.SSS').format(DateTime.now());

  @override
  Stream<NotificationModel> subscribe(String url, String? token, Dio dio) {
    final controller = StreamController<NotificationModel>();
    
    debugPrint('[$_now][SseClientWeb] EventSource 연결 시작');

    try {
      final eventSource = html.EventSource(url);

      eventSource.onOpen.listen((event) {
        debugPrint('[$_now][SseClientWeb] 연결 성공 (열림)');
      });

      eventSource.addEventListener('notification', (event) {
        final html.MessageEvent msgEvent = event as html.MessageEvent;
        final String data = msgEvent.data.toString();
        
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (!controller.isClosed) {
            controller.add(NotificationModel.fromJson(json));
          }
        } catch (e) {
          debugPrint('[$_now][SseClientWeb] 파싱 에러: $e');
        }
      });

      // EventSource 는 내부적으로 자동 재연결을 수행하므로 에러 로그만 남깁니다.
      eventSource.onError.listen((event) {
        debugPrint('[$_now][SseClientWeb] 대기 중 또는 연결 중단 (브라우저가 재연결 시도 중...)');
      });

      controller.onCancel = () {
        debugPrint('[$_now][SseClientWeb] 리소스 해제');
        eventSource.close();
      };
    } catch (e) {
      debugPrint('[$_now][SseClientWeb] 예외 발생: $e');
      if (!controller.isClosed) controller.addError(e);
    }

    return controller.stream;
  }
}
