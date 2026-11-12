import 'package:flutter_test/flutter_test.dart';
import 'package:dupper/features/itinerary/utils/day_load.dart';
import 'package:dupper/features/places/models/place_model.dart';

PlaceModel p(int min, {double lat = 0, double lon = 0}) => PlaceModel(
      id: 'x',
      tripId: 't',
      nombre: 'n',
      tipo: 'otro',
      latitud: lat,
      longitud: lon,
      tiempoEstimadoMin: min,
    );

void main() {
  test('día vacío', () {
    expect(minutosDelDia([]), 0);
    expect(diaSobrecargado([]), false);
  });

  test('un solo lugar sin traslado', () {
    expect(minutosDelDia([p(75)]), 75);
  });

  test('dos lugares en el mismo punto', () {
    expect(minutosDelDia([p(90), p(90)]), 180);
  });

  test('11 h sobrecargado, 3 h no', () {
    expect(diaSobrecargado([p(660)]), true);
    expect(diaSobrecargado([p(180)]), false);
  });

  test('límite exacto y personalizado', () {
    expect(diaSobrecargado([p(600)]), false);
    expect(diaSobrecargado([p(601)]), true);
    expect(diaSobrecargado([p(100)], limiteMin: 99), true);
    expect(diaSobrecargado([p(100)], limiteMin: 100), false);
  });

  test('traslado de 15 km son unos 30 min', () {
    final m = minutosDelDia([p(0), p(0, lat: 0.135)]);
    expect((m - 30).abs() <= 2, true);
  });

  test('traslado incluido en el total', () {
    final lugares = [p(290), p(290, lat: 0.135)];
    final m = minutosDelDia(lugares);
    expect((m - 610).abs() <= 2, true);
    expect(diaSobrecargado(lugares), true);
  });
}
