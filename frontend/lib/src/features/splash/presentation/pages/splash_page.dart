import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/providers/common_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final Completer<void> _imageReadyCompleter = Completer<void>();
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. 이미지 렌더링 준비와 인증 정보 조회를 병렬로 시작
    final authInit = _waitForAuth();
    
    // 2. 이미지가 화면에 실제로 그려질 때까지 대기
    await _imageReadyCompleter.future;

    // 3. 이미지가 뜬 시점부터 최소 노출 시간(1.5초로 최적화) 보장
    // 그 사이 인증 정보 조회가 완료되도록 유도
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      authInit,
    ]);

    if (mounted && !_isTransitioning) {
      _isTransitioning = true;
      ref.read(isAppInitializedProvider.notifier).state = true;
    }
  }

  Future<void> _waitForAuth() async {
    // authProvider의 isLoading이 false가 될 때까지 대기
    while (mounted && ref.read(authProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E3),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          // 이미지가 캐시에 있거나 로드되자마자 즉시 렌더링되도록 유도
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              if (!_imageReadyCompleter.isCompleted) {
                _imageReadyCompleter.complete();
              }
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            if (!_imageReadyCompleter.isCompleted) {
              _imageReadyCompleter.complete();
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
