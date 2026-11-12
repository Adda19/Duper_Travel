import 'dart:math';

import '../../places/models/place_model.dart';

/// Haversine distance in km between two coordinates.
double distanciaKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final h = pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
  return 2 * r * asin(min(1.0, sqrt(h.toDouble())));
}

/// Sum of consecutive legs; 0 for fewer than 2 places.
double distanciaTotalKm(List<PlaceModel> places) {
  var total = 0.0;
  for (var i = 0; i < places.length - 1; i++) {
    total += distanciaKm(places[i].latitud, places[i].longitud,
        places[i + 1].latitud, places[i + 1].longitud);
  }
  return total;
}

/// Nearest-neighbor ordering starting at the first place. Returns a new list.
List<PlaceModel> optimizarRuta(List<PlaceModel> places) {
  if (places.length < 2) return List<PlaceModel>.from(places);
  final remaining = List<PlaceModel>.from(places);
  final result = <PlaceModel>[remaining.removeAt(0)];
  while (remaining.isNotEmpty) {
    final last = result.last;
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final d = distanciaKm(last.latitud, last.longitud,
          remaining[i].latitud, remaining[i].longitud);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    result.add(remaining.removeAt(bestIdx));
  }
  return result;
}
