import 'package:flutter_test/flutter_test.dart';
import 'package:dupper/features/itinerary/utils/route_optimizer.dart';
import 'package:dupper/features/places/models/place_model.dart';

PlaceModel p(String id, double lat, double lon) => PlaceModel(
      id: id,
      tripId: 't',
      nombre: id,
      tipo: 'other',
      latitud: lat,
      longitud: lon,
    );

List<String> ids(List<PlaceModel> l) => l.map((e) => e.id).toList();

void main() {
  final a = p('A', 0, 0);
  final b = p('B', 0, 1);
  final c = p('C', 0, 2);
  final d = p('D', 0, 3);

  test('distanciaKm Bogota-Medellin', () {
    final km = distanciaKm(4.711, -74.0721, 6.2442, -75.5812);
    expect(km, inInclusiveRange(235, 245));
  });

  test('distanciaKm same point is 0', () {
    expect(distanciaKm(4.7, -74.0, 4.7, -74.0), 0);
  });

  test('distanciaKm symmetric', () {
    expect(distanciaKm(1, 2, 3, 4), closeTo(distanciaKm(3, 4, 1, 2), 1e-9));
  });

  test('empty list', () {
    expect(optimizarRuta([]), isEmpty);
    expect(distanciaTotalKm([]), 0);
  });

  test('one place', () {
    final r = optimizarRuta([a]);
    expect(ids(r), ['A']);
    expect(distanciaTotalKm([a]), 0);
  });

  test('line A,C,B,D becomes A,B,C,D and is shorter', () {
    final input = [a, c, b, d];
    final r = optimizarRuta(input);
    expect(ids(r), ['A', 'B', 'C', 'D']);
    expect(distanciaTotalKm(r), lessThan(distanciaTotalKm(input)));
  });

  test('first place is kept as start', () {
    expect(optimizarRuta([a, c, b, d]).first.id, 'A');
    expect(optimizarRuta([d, a, c, b]).first.id, 'D');
  });

  test('input is not modified and result is a new list', () {
    final input = [a, c, b, d];
    final r = optimizarRuta(input);
    expect(ids(input), ['A', 'C', 'B', 'D']);
    expect(identical(r, input), isFalse);
  });

  test('same places, no loss or duplication', () {
    final r = optimizarRuta([a, c, b, d]);
    expect(r.length, 4);
    expect(ids(r)..sort(), ['A', 'B', 'C', 'D']);
  });

  test('distanciaTotalKm is sum of legs', () {
    final expected = distanciaKm(0, 0, 0, 1) + distanciaKm(0, 1, 0, 2);
    expect(distanciaTotalKm([a, b, c]), closeTo(expected, 1e-9));
  });
}
