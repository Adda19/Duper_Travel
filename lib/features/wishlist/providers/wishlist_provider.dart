import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../places/models/place_model.dart';
import '../../places/providers/place_provider.dart';
import '../models/wishlist_place_model.dart';

class WishlistProvider {
  WishlistProvider._();
  static final WishlistProvider instance = WishlistProvider._();

  Box<WishlistPlaceModel> get _box =>
      Hive.box<WishlistPlaceModel>(HiveBoxes.wishlist);

  // ── Read ───────────────────────────────────────────────────────────────────

  List<WishlistPlaceModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.fechaGuardado.compareTo(a.fechaGuardado));
  }

  List<WishlistPlaceModel> getPendientes() =>
      getAll().where((p) => p.isPending).toList();

  List<WishlistPlaceModel> getVisitados() =>
      getAll().where((p) => p.isVisited).toList();

  List<WishlistPlaceModel> getByTipo(String tipo) =>
      getAll().where((p) => p.tipo == tipo).toList();

  List<WishlistPlaceModel> getByCiudad(String ciudad) => getAll()
      .where((p) => p.ciudad.toLowerCase().contains(ciudad.toLowerCase()))
      .toList();

  WishlistPlaceModel? getById(String id) =>
      _box.values.cast<WishlistPlaceModel?>().firstWhere(
            (p) => p?.id == id,
            orElse: () => null,
          );

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> addPlace(WishlistPlaceModel place) async {
    await _box.put(place.id, place);
  }

  Future<void> updatePlace(WishlistPlaceModel place) async {
    await place.save();
  }

  Future<void> deletePlace(WishlistPlaceModel place) async {
    await place.delete();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> markAsVisited(WishlistPlaceModel place) async {
    place.estado = WishlistStatus.visited;
    place.fechaVisitado = DateTime.now();
    await place.save();
  }

  Future<void> markAsPending(WishlistPlaceModel place) async {
    place.estado = WishlistStatus.pending;
    place.fechaVisitado = null;
    await place.save();
  }

  /// Copies this wishlist place as a [PlaceModel] into the given trip.
  Future<PlaceModel> moveToTrip(
    WishlistPlaceModel wPlace,
    String tripId,
    int dia,
  ) async {
    final place = PlaceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      nombre: wPlace.nombre,
      tipo: wPlace.tipo,
      latitud: wPlace.latitud,
      longitud: wPlace.longitud,
      dia: dia,
      estado: PlaceStatus.pending,
      costoEstimado: wPlace.costoEstimado,
      tiempoEstimadoMin: wPlace.tiempoEstimadoMin,
      horario: wPlace.horario,
      tags: List<String>.from(wPlace.tags),
      comentarios: wPlace.comentarios,
      links: List<String>.from(wPlace.links),
      fotos: List<String>.from(wPlace.fotos),
    );
    await PlaceProvider.instance.addPlace(place);
    return place;
  }
}
