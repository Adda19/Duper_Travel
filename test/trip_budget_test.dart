import 'package:flutter_test/flutter_test.dart';
import 'package:dupper/features/trips/models/trip_model.dart';

TripModel _trip({
  required DateTime inicio,
  required DateTime fin,
  int personas = 1,
  double total = 0,
}) =>
    TripModel(
      id: 't',
      nombre: 'n',
      destinos: ['x'],
      fechaInicio: inicio,
      fechaFin: fin,
      numeroPersonas: personas,
      moneda: 'COP',
      presupuestoTotal: total,
    );

void main() {
  test('1 al 10 son 10 días', () {
    final t = _trip(inicio: DateTime(2025, 3, 1), fin: DateTime(2025, 3, 10));
    expect(t.duracionDias, 10);
  });

  test('mismo día es 1', () {
    final t = _trip(inicio: DateTime(2025, 3, 1), fin: DateTime(2025, 3, 1));
    expect(t.duracionDias, 1);
  });

  test('mismo día con horas distintas es 1', () {
    final t = _trip(
        inicio: DateTime(2025, 3, 1, 8), fin: DateTime(2025, 3, 1, 20));
    expect(t.duracionDias, 1);
  });

  test('presupuestoPorDia', () {
    final t = _trip(
        inicio: DateTime(2025, 3, 1),
        fin: DateTime(2025, 3, 10),
        total: 1000000);
    expect(t.presupuestoPorDia, 100000);
  });

  test('presupuestoPorPersona', () {
    final t = _trip(
        inicio: DateTime(2025, 3, 1),
        fin: DateTime(2025, 3, 2),
        personas: 3,
        total: 900000);
    expect(t.presupuestoPorPersona, 300000);
  });

  test('0 o negativas personas da 0', () {
    final a = _trip(
        inicio: DateTime(2025, 3, 1),
        fin: DateTime(2025, 3, 2),
        personas: 0,
        total: 900000);
    final b = _trip(
        inicio: DateTime(2025, 3, 1),
        fin: DateTime(2025, 3, 2),
        personas: -2,
        total: 900000);
    expect(a.presupuestoPorPersona, 0);
    expect(b.presupuestoPorPersona, 0);
  });

  test('fechas invertidas dan 0 sin excepción', () {
    final t = _trip(
        inicio: DateTime(2025, 3, 10),
        fin: DateTime(2025, 3, 1),
        total: 1000000);
    expect(t.presupuestoPorDia, 0);
  });
}
