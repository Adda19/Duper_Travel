import 'package:flutter_test/flutter_test.dart';
import 'package:dupper/features/itinerary/utils/trip_progress.dart';
import 'package:dupper/features/places/models/place_model.dart';

PlaceModel p(int dia, String estado) => PlaceModel(
      id: '${dia}_$estado${DateTime.now().microsecondsSinceEpoch}',
      tripId: 't',
      nombre: 'n',
      tipo: 'x',
      latitud: 0,
      longitud: 0,
      dia: dia,
      estado: estado,
    );

void main() {
  group('progresoVisitados', () {
    test('empty is 0', () => expect(progresoVisitados([]), 0));
    test('1 of 4', () {
      expect(
          progresoVisitados(
              [p(1, 'visited'), p(1, 'pending'), p(1, 'pending'), p(2, 'pending')]),
          0.25);
    });
    test('all visited', () {
      expect(progresoVisitados([p(1, 'visited'), p(2, 'visited')]), 1.0);
    });
    test('pending only', () {
      expect(progresoVisitados([p(1, 'pending')]), 0.0);
    });
    test('skipped not visited', () {
      expect(progresoVisitados([p(1, 'skipped'), p(1, 'visited')]), 0.5);
    });
  });

  group('progresoPorDia', () {
    test('two days', () {
      final r = progresoPorDia([
        p(1, 'visited'),
        p(1, 'visited'),
        p(2, 'pending'),
        p(2, 'pending'),
        p(2, 'skipped'),
      ]);
      expect(r, {1: 1.0, 2: 0.0});
    });
    test('empty', () => expect(progresoPorDia([]), isEmpty));
    test('partial', () {
      expect(progresoPorDia([p(1, 'visited'), p(1, 'pending')])[1], 0.5);
    });
  });
}
