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

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'descripcion': descripcion,
        'categoria': categoria,
        'montoEstimado': montoEstimado,
        'montoReal': montoReal,
        'fecha': fecha.toIso8601String(),
      };

  factory ManualExpenseModel.fromJson(Map<String, dynamic> json) =>
      ManualExpenseModel(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        descripcion: json['descripcion'] as String,
        categoria: json['categoria'] as String,
        montoEstimado: (json['montoEstimado'] as num).toDouble(),
        montoReal: (json['montoReal'] as num?)?.toDouble() ?? 0,
        fecha: DateTime.parse(json['fecha'] as String),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  @override
  String toString() =>
      'ManualExpenseModel(id: $id, descripcion: $descripcion, monto: $montoEstimado)';
}
