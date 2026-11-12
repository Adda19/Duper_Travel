import '../../places/models/place_model.dart';

/// Fraction (0..1) of visited places. Empty list returns 0.
double progresoVisitados(List<PlaceModel> lugares) {
  if (lugares.isEmpty) return 0;
  return lugares.where((p) => p.visitado).length / lugares.length;
}

/// Fraction of visited places for each `dia` present in the list.
Map<int, double> progresoPorDia(List<PlaceModel> lugares) {
  final porDia = <int, List<PlaceModel>>{};
  for (final p in lugares) {
    porDia.putIfAbsent(p.dia, () => []).add(p);
  }
  return {for (final e in porDia.entries) e.key: progresoVisitados(e.value)};
}
