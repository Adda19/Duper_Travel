import 'package:hive/hive.dart';

part 'place_model.g.dart';

@HiveType(typeId: 1)
class PlaceModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String tripId;

  @HiveField(2)
  late String nombre;

  @HiveField(3)
  late String tipo;

  @HiveField(4)
  late double latitud;

  @HiveField(5)
  late double longitud;

  @HiveField(6)
  late int dia;

  @HiveField(7)
  late String estado;

  @HiveField(8)
  late double costoEstimado;

  @HiveField(9)
  late double costoReal;

  @HiveField(10)
  late int tiempoEstimadoMin;

  @HiveField(11)
  late String horario;

  @HiveField(12)
  late List<String> tags;

  @HiveField(13)
  late double calificacion;

  @HiveField(14)
  late String comentarios;

  @HiveField(15)
  late List<String> links;

  @HiveField(16)
  late List<String> fotos;

  PlaceModel({
    required this.id,
    required this.tripId,
    required this.nombre,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    this.dia = 1,
    this.estado = 'pending',
    this.costoEstimado = 0,
    this.costoReal = 0,
    this.tiempoEstimadoMin = 60,
    this.horario = '',
    List<String>? tags,
    this.calificacion = 0,
    this.comentarios = '',
    List<String>? links,
    List<String>? fotos,
  })  : tags = tags ?? [],
        links = links ?? [],
        fotos = fotos ?? [];

  // ── JSON ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'nombre': nombre,
        'tipo': tipo,
        'latitud': latitud,
        'longitud': longitud,
        'dia': dia,
        'estado': estado,
        'costoEstimado': costoEstimado,
        'costoReal': costoReal,
        'tiempoEstimadoMin': tiempoEstimadoMin,
        'horario': horario,
        'tags': tags,
        'calificacion': calificacion,
        'comentarios': comentarios,
        'links': links,
        'fotos': fotos,
      };

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        nombre: json['nombre'] as String,
        tipo: json['tipo'] as String,
        latitud: (json['latitud'] as num).toDouble(),
        longitud: (json['longitud'] as num).toDouble(),
        dia: json['dia'] as int? ?? 1,
        estado: json['estado'] as String? ?? 'pending',
        costoEstimado: (json['costoEstimado'] as num?)?.toDouble() ?? 0,
        costoReal: (json['costoReal'] as num?)?.toDouble() ?? 0,
        tiempoEstimadoMin: json['tiempoEstimadoMin'] as int? ?? 60,
        horario: json['horario'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0,
        comentarios: json['comentarios'] as String? ?? '',
        links: (json['links'] as List?)?.cast<String>() ?? [],
        fotos: (json['fotos'] as List?)?.cast<String>() ?? [],
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get visitado => estado == 'visited';
  bool get omitido => estado == 'skipped';

  @override
  String toString() =>
      'PlaceModel(id: $id, nombre: $nombre, tipo: $tipo, dia: $dia)';
}
