import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/common_providers.dart';
import '../../../../core/network/api_client.dart';

// ─────────────────────────────────────────
// 모델
// ─────────────────────────────────────────

class ScheduleStatus {
  final String key;
  final String name;
  final String spec;
  final bool enabled;
  final DateTime? nextRun;

  const ScheduleStatus({
    required this.key,
    required this.name,
    required this.spec,
    required this.enabled,
    this.nextRun,
  });

  factory ScheduleStatus.fromJson(Map<String, dynamic> json) {
    return ScheduleStatus(
      key: json['key'] as String,
      name: json['name'] as String,
      spec: json['spec'] as String,
      enabled: json['enabled'] as bool,
      nextRun: json['next_run'] != null
          ? DateTime.tryParse(json['next_run'] as String)
          : null,
    );
  }

  ScheduleStatus copyWith({bool? enabled}) {
    return ScheduleStatus(
      key: key,
      name: name,
      spec: spec,
      enabled: enabled ?? this.enabled,
      nextRun: nextRun,
    );
  }
}

class SeedStatus {
  final String state;
  final String? source;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int inserted;
  final int skipped;
  final String? error;

  const SeedStatus({
    required this.state,
    this.source,
    this.startedAt,
    this.endedAt,
    required this.inserted,
    required this.skipped,
    this.error,
  });

  factory SeedStatus.fromJson(Map<String, dynamic> json) {
    return SeedStatus(
      state: json['state'] as String? ?? 'IDLE',
      source: json['source'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'] as String)
          : null,
      inserted: json['inserted'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }
}

// ─────────────────────────────────────────
// 상태
// ─────────────────────────────────────────

class AdminState {
  final List<ScheduleStatus> schedules;
  final SeedStatus? seedStatus;
  final bool isLoading;
  final bool isSeeding;
  final String? error;

  const AdminState({
    this.schedules = const [],
    this.seedStatus,
    this.isLoading = false,
    this.isSeeding = false,
    this.error,
  });

  AdminState copyWith({
    List<ScheduleStatus>? schedules,
    SeedStatus? seedStatus,
    bool? isLoading,
    bool? isSeeding,
    String? error,
  }) {
    return AdminState(
      schedules: schedules ?? this.schedules,
      seedStatus: seedStatus ?? this.seedStatus,
      isLoading: isLoading ?? this.isLoading,
      isSeeding: isSeeding ?? this.isSeeding,
      error: error,
    );
  }
}

// ─────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiClient _api;

  AdminNotifier(this._api) : super(const AdminState());

  /// 스케줄 목록 + 시드 상태 동시 로드
  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _api.get('/admin/schedules'),
        _api.get('/admin/menus/seed/status'),
      ]);

      final schedulesJson = results[0]['data'] as List<dynamic>;
      final seedJson = results[1]['data'] as Map<String, dynamic>;

      state = state.copyWith(
        schedules: schedulesJson
            .map((e) => ScheduleStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
        seedStatus: SeedStatus.fromJson(seedJson),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '스케줄 정보를 불러오지 못했습니다: $e',
      );
    }
  }

  /// 특정 스케줄 활성화/비활성화
  Future<void> toggleSchedule(String key, bool enabled) async {
    // 낙관적 업데이트
    final updated = state.schedules.map((s) {
      return s.key == key ? s.copyWith(enabled: enabled) : s;
    }).toList();
    state = state.copyWith(schedules: updated);

    try {
      await _api.patch(
        '/admin/schedules/$key/toggle',
        data: {'enabled': enabled},
      );
    } catch (e) {
      // 실패 시 롤백
      final rolled = state.schedules.map((s) {
        return s.key == key ? s.copyWith(enabled: !enabled) : s;
      }).toList();
      state = state.copyWith(schedules: rolled, error: '상태 변경에 실패했습니다.');
    }
  }

  /// 특정 스케줄 즉시 실행
  Future<void> runScheduleNow(String key) async {
    try {
      await _api.post('/admin/schedules/$key/run', data: {});
    } catch (e) {
      state = state.copyWith(error: '즉시 실행 요청에 실패했습니다.');
    }
  }

  /// 영양소 데이터 즉시 수집
  Future<void> runSeedNow({String source = 'all', int limit = 5000}) async {
    state = state.copyWith(isSeeding: true, error: null);
    try {
      await _api.post('/admin/menus/seed', data: {
        'source': source,
        'limit': limit,
      });
      // 202 응답 → 백그라운드 실행 중. 완료될 때까지 폴링
      await _pollSeedStatus();
    } catch (e) {
      state = state.copyWith(error: '수집 요청에 실패했습니다: $e');
    } finally {
      state = state.copyWith(isSeeding: false);
    }
  }

  /// 3초 간격으로 상태 확인, RUNNING이 아니면 종료
  Future<void> _pollSeedStatus() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      await _refreshSeedStatus();

      final status = state.seedStatus?.state ?? '';
      if (status != 'RUNNING') break;
    }
  }

  Future<void> _refreshSeedStatus() async {
    try {
      final res = await _api.get('/admin/menus/seed/status');
      final seedJson = res['data'] as Map<String, dynamic>;
      state = state.copyWith(seedStatus: SeedStatus.fromJson(seedJson));
    } catch (_) {}
  }
}

// ─────────────────────────────────────────
// Provider
// ─────────────────────────────────────────

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AdminNotifier(api);
});