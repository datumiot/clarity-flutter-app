import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/models/collector_model.dart';
import '../../data/models/meter_model.dart';
import 'auth_provider.dart';

class DeviceState {
  final List<Collector> collectors;
  final Collector? selectedCollector;
  final List<Meter> meters;
  final Meter? selectedMeter;
  final List<MeterReading> readings;
  final bool isLoading;
  final String? error;

  const DeviceState({
    this.collectors = const [],
    this.selectedCollector,
    this.meters = const [],
    this.selectedMeter,
    this.readings = const [],
    this.isLoading = false,
    this.error,
  });

  DeviceState copyWith({
    List<Collector>? collectors,
    Collector? selectedCollector,
    List<Meter>? meters,
    Meter? selectedMeter,
    List<MeterReading>? readings,
    bool? isLoading,
    String? error,
  }) =>
      DeviceState(
        collectors: collectors ?? this.collectors,
        selectedCollector: selectedCollector ?? this.selectedCollector,
        meters: meters ?? this.meters,
        selectedMeter: selectedMeter ?? this.selectedMeter,
        readings: readings ?? this.readings,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  final ApiClient _api;

  DeviceNotifier(this._api) : super(const DeviceState());

  Future<void> fetchCollectors() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getCollectors();
      final list = (response.data as List)
          .map((e) => Collector.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(collectors: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchCollector(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getCollector(id);
      final collector =
          Collector.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(selectedCollector: collector, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMeters(int collectorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getMeters(collectorId);
      final list = (response.data as List)
          .map((e) => Meter.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(meters: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMeter(int meterId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getMeter(meterId);
      final meter = Meter.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(selectedMeter: meter, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchReadings(int meterId,
      {String? startDate, String? endDate, int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getMeterReadings(meterId,
          startDate: startDate, endDate: endDate, limit: limit);
      final list = (response.data as List)
          .map((e) => MeterReading.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(readings: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateCollector(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateCollector(id, data);
      await fetchCollectors();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCollector(int id) async {
    try {
      await _api.deleteCollector(id);
      await fetchCollectors();
      return true;
    } catch (_) {
      return false;
    }
  }

  void selectCollector(Collector? collector) =>
      state = state.copyWith(selectedCollector: collector);

  void selectMeter(Meter? meter) =>
      state = state.copyWith(selectedMeter: meter);

  void clearError() => state = state.copyWith(error: null);
}

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  final api = ref.watch(apiClientProvider);
  return DeviceNotifier(api);
});
