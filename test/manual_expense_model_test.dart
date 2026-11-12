import 'package:flutter_test/flutter_test.dart';

import 'package:dupper/features/costs/models/manual_expense_model.dart';

void main() {
  group('ManualExpenseModel JSON', () {
    test('toJson y fromJson conservan todos los campos', () {
      final original = ManualExpenseModel(
        id: 'e1',
        tripId: 't1',
        descripcion: 'Taxi al aeropuerto',
        categoria: 'transporte',
        montoEstimado: 50000,
        montoReal: 47500.5,
        fecha: DateTime(2026, 11, 11, 19, 10),
      );

      final copia = ManualExpenseModel.fromJson(original.toJson());

      expect(copia.id, 'e1');
      expect(copia.tripId, 't1');
      expect(copia.descripcion, 'Taxi al aeropuerto');
      expect(copia.categoria, 'transporte');
      expect(copia.montoEstimado, 50000);
      expect(copia.montoReal, 47500.5);
      expect(copia.fecha, DateTime(2026, 11, 11, 19, 10));
    });

    test('montoReal es 0 si falta en el JSON y acepta enteros', () {
      final gasto = ManualExpenseModel.fromJson({
        'id': 'e2',
        'tripId': 't1',
        'descripcion': 'Museo',
        'categoria': 'actividades',
        'montoEstimado': 30000,
        'fecha': '2026-11-12T10:00:00.000',
      });

      expect(gasto.montoReal, 0);
      expect(gasto.montoEstimado, 30000.0);
    });
  });
}
