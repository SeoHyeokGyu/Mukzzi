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
    
    // 이미 URL 에 token 이 포함되어 전달됨 (NotificationRepository 에서 처리)
    debugPrint('[$_now][SseClientWeb] EventSource 방식으로 연결 시도');

    try {
      final eventSource = html.EventSource(url);

      eventSource.onOpen.listen((event) {
        debugPrint('[$_now][SseClientWeb] 스트림 연결 열림');
      });

      // 서버에서 c.SSEvent("notification", ...) 로 보낸 데이터 수신
      eventSource.addEventListener('notification', (event) {
        final html.MessageEvent msgEvent = event as html.MessageEvent;
        final String data = msgEvent.data.toString();
        debugPrint('[$_now][SseClientWeb] 알림 수신: $data');
        
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          controller.add(NotificationModel.fromJson(json));
        } catch (e) {
          debugPrint('[$_now][SseClientWeb] 파싱 에러: $e');
        }
      });

      eventSource.onError.listen((event) {
        debugPrint('[$_now][SseClientWeb] 연결 에러 또는 대기 중...');
      });

      controller.onCancel = () {
        debugPrint('[$_now][SseClientWeb] 구독 취소 및 소켓 닫기');
        eventSource.close();
      };
    } catch (e) {
      debugPrint('[$_now][SseClientWeb] 예외 발생: $e');
      controller.addError(e);
    }

    return controller.stream;
  }
}
