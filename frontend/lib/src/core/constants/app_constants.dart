import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // API
  static const String apiBaseUrl = kDebugMode
      ? 'http://localhost:8080/api'
      : 'http://144.24.90.88:8080/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Colors
  static const Color primaryColor = Colors.orange;
  static const Color accentColor = Colors.deepOrange;
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.grey;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  // Numeric Constants
  static const int minNicknameLength = 2;
  static const int maxNicknameLength = 12;
  static const int maxFriendsCount = 100;
  static const double minServingSize = 0.5;
  static const double maxServingSize = 3.0;

  // App Info
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://mukzzi.app/privacy';
  static const String termsOfServiceUrl = 'https://mukzzi.app/terms';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration loadingDebounce = Duration(milliseconds: 500);
}
