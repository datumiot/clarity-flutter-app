import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/models/alert_model.dart';
import 'auth_provider.dart';

class AlertState {
  final List<Alert> alerts;
  final bool isLoading;
  final String? error;

  const AlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  AlertState copyWith({
    List<Alert>? alerts,
    bool? isLoading,
    String? error,
  }) =>
      AlertState(
        alerts: alerts ?? this.alerts,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AlertNotifier extends StateNotifier<AlertState> {
  final ApiClient _api;

  AlertNotifier(this._api) : super(const AlertState());

  Future<void> fetchAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getAlerts();
      final list = (response.data as List)
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(alerts: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(int alertId) async {
    try {
      await _api.markAlertRead(alertId);
      final updated = state.alerts.map((a) {
        if (a.id == alertId) {
          return Alert(
            id: a.id,
            type: a.type,
            message: a.message,
            collectorName: a.collectorName,
            collectorId: a.collectorId,
            isRead: true,
            createdAt: a.createdAt,
          );
        }
        return a;
      }).toList();
      state = state.copyWith(alerts: updated);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllAlertsRead();
      await fetchAlerts();
    } catch (_) {}
  }
}

final alertProvider =
    StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AlertNotifier(api);
});
