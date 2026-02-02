import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/models/update_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class UpdateState {
  final bool isLoading;
  final String? error;
  final String? currentVersion;
  final bool autoUpdateEnabled;
  final String? updateStatus;
  final String? targetVersion;
  final String? updateError;
  final List<FirmwareRelease> availableUpdates;
  final List<UpdateHistory> history;
  final List<RestorePoint> restorePoints;

  const UpdateState({
    this.isLoading = false,
    this.error,
    this.currentVersion,
    this.autoUpdateEnabled = false,
    this.updateStatus,
    this.targetVersion,
    this.updateError,
    this.availableUpdates = const [],
    this.history = const [],
    this.restorePoints = const [],
  });

  UpdateState copyWith({
    bool? isLoading,
    String? error,
    String? currentVersion,
    bool? autoUpdateEnabled,
    String? updateStatus,
    String? targetVersion,
    String? updateError,
    List<FirmwareRelease>? availableUpdates,
    List<UpdateHistory>? history,
    List<RestorePoint>? restorePoints,
  }) {
    return UpdateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentVersion: currentVersion ?? this.currentVersion,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      updateStatus: updateStatus ?? this.updateStatus,
      targetVersion: targetVersion ?? this.targetVersion,
      updateError: updateError ?? this.updateError,
      availableUpdates: availableUpdates ?? this.availableUpdates,
      history: history ?? this.history,
      restorePoints: restorePoints ?? this.restorePoints,
    );
  }

  bool get updateInProgress =>
      updateStatus != null &&
      !['completed', 'failed', 'rolled_back'].contains(updateStatus);
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final ApiClient _api;

  UpdateNotifier(this._api) : super(const UpdateState());

  Future<void> loadUpdates(int collectorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getCollectorUpdates(collectorId);
      final data = response.data as Map<String, dynamic>;

      final available = (data['available_updates'] as List?)
              ?.map((e) => FirmwareRelease.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final hist = (data['recent_history'] as List?)
              ?.map((e) => UpdateHistory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final rpResponse = await _api.getRestorePoints(collectorId);
      final rps = (rpResponse.data as List?)
              ?.map((e) => RestorePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      state = state.copyWith(
        isLoading: false,
        currentVersion: data['current_version'] as String?,
        autoUpdateEnabled: data['auto_update_enabled'] as bool? ?? false,
        updateStatus: data['update_status'] as String?,
        targetVersion: data['target_version'] as String?,
        updateError: data['update_error'] as String?,
        availableUpdates: available,
        history: hist,
        restorePoints: rps,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> triggerUpdate(int collectorId, String version) async {
    try {
      await _api.triggerUpdate(collectorId, version);
      await loadUpdates(collectorId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleAutoUpdate(int collectorId, bool enabled) async {
    try {
      await _api.toggleAutoUpdate(collectorId, enabled);
      state = state.copyWith(autoUpdateEnabled: enabled);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> triggerRollback(int collectorId, int restorePointId) async {
    try {
      await _api.triggerRollback(collectorId, restorePointId);
      await loadUpdates(collectorId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRestorePoint(int collectorId, int restorePointId) async {
    try {
      await _api.deleteRestorePoint(collectorId, restorePointId);
      await loadUpdates(collectorId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final api = ref.watch(apiClientProvider);
  return UpdateNotifier(api);
});
