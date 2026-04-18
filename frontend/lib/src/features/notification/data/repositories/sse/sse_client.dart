import 'dart:async';
import 'package:dio/dio.dart';
import '../../models/notification_model.dart';

// 조건부 임포트: dart:html 라이브러리가 있으면 웹용을, 없으면 모바일용을 불러옵니다.
import 'sse_client_mobile.dart' if (dart.library.html) 'sse_client_web.dart';

abstract class SseClient {
  Stream<NotificationModel> subscribe(String url, String? token, Dio dio);
}

SseClient getSseClientInstance() => getSseClient();
