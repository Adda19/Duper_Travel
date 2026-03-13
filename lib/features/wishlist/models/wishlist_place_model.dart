import 'package:hive/hive.dart';

part 'wishlist_place_model.g.dart';

// Links are stored as "label:::url" inside List<String> links.
const wishlistLinkSep = ':::';

@HiveType(typeId: 3)
class WishlistPlaceModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nombre;

  @HiveField(2)
  late String tipo;

  @HiveField(3)
  late double latitud;

  @HiveField(4)
  late double longitud;

  @HiveField(5)
  late String ciudad;

  @HiveField(6)
  late String pais;

  @HiveField(7)
  late double costoEstimado;

  @HiveField(8)
  late int tiempoEstimadoMin;

  @HiveField(9)
  late String horario;

  @HiveField(10)
  late List<String> tags;

  @HiveField(11)
  late String comentarios;

  @HiveField(12)
  late List<String> links;

  @HiveField(13)
  late List<String> fotos;

  @HiveField(14)
  late String estado;

  @HiveField(15)
  late DateTime fechaGuardado;

  @HiveField(16)
  DateTime? fechaVisitado;

  @HiveField(17)
  late String fuente;

  WishlistPlaceModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.latitud = 0,
    this.longitud = 0,
    this.ciudad = '',
    this.pais = '',
    this.costoEstimado = 0,
    this.tiempoEstimadoMin = 0,
    this.horario = '',
    List<String>? tags,
    this.comentarios = '',
    List<String>? links,
    List<String>? fotos,
    this.estado = 'pending',
    required this.fechaGuardado,
    this.fechaVisitado,
    this.fuente = 'Otro',
  })  : tags = tags ?? [],
        links = links ?? [],
        fotos = fotos ?? [];

  bool get isPending => estado == 'pending';
  bool get isVisited => estado == 'visited';

  bool get hasLocation => latitud != 0 || longitud != 0;

  @override
  String toString() =>
      'WishlistPlaceModel(id: $id, nombre: $nombre, ciudad: $ciudad)';
}
