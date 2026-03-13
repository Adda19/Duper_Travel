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

  TripModel({
    required this.id,
    required this.nombre,
    required this.destinos,
    required this.fechaInicio,
    required this.fechaFin,
    required this.numeroPersonas,
    required this.moneda,
    required this.presupuestoTotal,
  });

  /// Single-string display e.g. "Paris · Roma · Barcelona".
  String get destino => destinos.join(' · ');

  int get duracionDias => fechaFin.difference(fechaInicio).inDays + 1;

  double get presupuestoPorPersona =>
      numeroPersonas > 0 ? presupuestoTotal / numeroPersonas : presupuestoTotal;

  @override
  String toString() =>
      'TripModel(id: $id, nombre: $nombre, destinos: $destinos)';
}
