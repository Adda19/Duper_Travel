import '../../places/models/place_model.dart';
import 'route_optimizer.dart';

/// Visit time plus travel time (30 km/h) between consecutive places.
int minutosDelDia(List<PlaceModel> lugares) {
  var total = 0;
  for (var i = 0; i < lugares.length; i++) {
    total += lugares[i].tiempoEstimadoMin;
    if (i > 0) {
      final km = distanciaKm(lugares[i - 1].latitud, lugares[i - 1].longitud,
          lugares[i].latitud, lugares[i].longitud);
      total += (km / 30 * 60).round();
    }
  }
  return total;
}

bool diaSobrecargado(List<PlaceModel> lugares, {int limiteMin = 600}) =>
    minutosDelDia(lugares) > limiteMin;
