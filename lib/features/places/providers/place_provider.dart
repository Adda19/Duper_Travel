import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../models/place_model.dart';

class PlaceProvider {
  PlaceProvider._();
  static final PlaceProvider instance = PlaceProvider._();

  Box<PlaceModel> get _box => Hive.box<PlaceModel>(HiveBoxes.places);

  // ── Read ───────────────────────────────────────────────────────────────────

  List<PlaceModel> getPlacesByTrip(String tripId) {
    return _box.values
        .where((p) => p.tripId == tripId)
        .toList()
      ..sort((a, b) {
        final dayDiff = a.dia.compareTo(b.dia);
        return dayDiff != 0 ? dayDiff : a.nombre.compareTo(b.nombre);
      });
  }

  List<PlaceModel> getPlacesByDay(String tripId, int day) {
    return _box.values
        .where((p) => p.tripId == tripId && p.dia == day)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  PlaceModel? getById(String id) {
    return _box.values.cast<PlaceModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> addPlace(PlaceModel place) async {
    await _box.put(place.id, place);
  }

  Future<void> updatePlace(PlaceModel place) async {
    await place.save();
  }

  Future<void> deletePlace(PlaceModel place) async {
    await place.delete();
  }

  Future<void> deletePlacesByTrip(String tripId) async {
    final toDelete = getPlacesByTrip(tripId);
    for (final p in toDelete) {
      await p.delete();
    }
  }
}
