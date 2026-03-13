import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../features/trips/models/trip_model.dart';
import '../constants/app_constants.dart';

/// Key used inside the Hive settings box to persist the active trip id.
const _kActiveTripKey = 'active_trip_id';

/// Lightweight global state for the currently-selected trip.
///
/// Usage:
///   final provider = TripProvider.instance;
///   provider.activeTrip.addListener(() { ... });
///   provider.setActiveTrip(trip);
class TripProvider {
  TripProvider._();
  static final TripProvider instance = TripProvider._();

  // ValueNotifier so any widget can listen without a full state manager.
  final ValueNotifier<TripModel?> activeTrip = ValueNotifier(null);

  Box<TripModel> get _tripsBox => Hive.box<TripModel>(HiveBoxes.trips);

  Box get _settingsBox => Hive.box(HiveBoxes.settings);

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Call once after Hive boxes are open (inside main).
  Future<void> init() async {
    final savedId = _settingsBox.get(_kActiveTripKey) as String?;
    if (savedId != null) {
      final trip = _tripsBox.values
          .cast<TripModel?>()
          .firstWhere((t) => t?.id == savedId, orElse: () => null);
      activeTrip.value = trip;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  List<TripModel> getAllTrips() {
    return _tripsBox.values.toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
  }

  TripModel? getActiveTrip() => activeTrip.value;

  Future<void> setActiveTrip(TripModel trip) async {
    activeTrip.value = trip;
    await _settingsBox.put(_kActiveTripKey, trip.id);
  }

  Future<void> clearActiveTrip() async {
    activeTrip.value = null;
    await _settingsBox.delete(_kActiveTripKey);
  }

  Future<void> saveTrip(TripModel trip) async {
    await _tripsBox.put(trip.id, trip);
  }

  Future<void> deleteTrip(TripModel trip) async {
    // If we delete the active trip, clear selection.
    if (activeTrip.value?.id == trip.id) {
      await clearActiveTrip();
    }
    await trip.delete();
  }
}
