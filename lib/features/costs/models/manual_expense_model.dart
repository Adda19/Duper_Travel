import 'package:hive/hive.dart';

part 'manual_expense_model.g.dart';

@HiveType(typeId: 2)
class ManualExpenseModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String tripId;

  @HiveField(2)
  late String descripcion;

  @HiveField(3)
  late String categoria;

  @HiveField(4)
  late double montoEstimado;

  @HiveField(5)
  late double montoReal;

  @HiveField(6)
  late DateTime fecha;

  ManualExpenseModel({
    required this.id,
    required this.tripId,
    required this.descripcion,
    required this.categoria,
    required this.montoEstimado,
    this.montoReal = 0,
    required this.fecha,
  });

  @override
  String toString() =>
      'ManualExpenseModel(id: $id, descripcion: $descripcion, monto: $montoEstimado)';
}
