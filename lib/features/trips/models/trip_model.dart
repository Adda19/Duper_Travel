import 'package:hive/hive.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 0)
class TripModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nombre;

  /// Field 2 - stored as List<String> (was String in v1; adapter reads both).
  @HiveField(2)
  late List<String> destinos;

  @HiveField(3)
  late DateTime fechaInicio;

  @HiveField(4)
  late DateTime fechaFin;

  @HiveField(5)
  late int numeroPersonas;

  @HiveField(6)
  late String moneda;

  @HiveField(7)
  late double presupuestoTotal;

  @HiveField(8)
  String tipoTransporte;

  @HiveField(9)
  DateTime? horaSalida;

  TripModel({
    required this.id,
    required this.nombre,
    required this.destinos,
    required this.fechaInicio,
    required this.fechaFin,
    required this.numeroPersonas,
    required this.moneda,
    required this.presupuestoTotal,
    this.tipoTransporte = 'vuelo',
    this.horaSalida,
  });

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'destinos': destinos,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'numeroPersonas': numeroPersonas,
        'moneda': moneda,
        'presupuestoTotal': presupuestoTotal,
        'tipoTransporte': tipoTransporte,
        'horaSalida': horaSalida?.toIso8601String(),
      };

  factory TripModel.fromJson(Map<String, dynamic> json) => TripModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        destinos: (json['destinos'] as List).cast<String>(),
        fechaInicio: DateTime.parse(json['fechaInicio'] as String),
        fechaFin: DateTime.parse(json['fechaFin'] as String),
        numeroPersonas: json['numeroPersonas'] as int,
        moneda: json['moneda'] as String,
        presupuestoTotal: (json['presupuestoTotal'] as num).toDouble(),
        tipoTransporte: json['tipoTransporte'] as String? ?? 'vuelo',
        horaSalida: json['horaSalida'] != null
            ? DateTime.parse(json['horaSalida'] as String)
            : null,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Single-string display e.g. "Paris · Roma · Barcelona".
  String get destino => destinos.join(' · ');

  int get duracionDias => fechaFin.difference(fechaInicio).inDays + 1;

  double get presupuestoPorPersona =>
      numeroPersonas > 0 ? presupuestoTotal / numeroPersonas : presupuestoTotal;

  @override
  String toString() =>
      'TripModel(id: $id, nombre: $nombre, destinos: $destinos)';
}
