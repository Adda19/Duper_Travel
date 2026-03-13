// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_place_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WishlistPlaceModelAdapter extends TypeAdapter<WishlistPlaceModel> {
  @override
  final int typeId = 3;

  @override
  WishlistPlaceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WishlistPlaceModel(
      id: fields[0] as String,
      nombre: fields[1] as String,
      tipo: fields[2] as String,
      latitud: fields[3] as double,
      longitud: fields[4] as double,
      ciudad: fields[5] as String,
      pais: fields[6] as String,
      costoEstimado: fields[7] as double,
      tiempoEstimadoMin: fields[8] as int,
      horario: fields[9] as String,
      tags: (fields[10] as List?)?.cast<String>(),
      comentarios: fields[11] as String,
      links: (fields[12] as List?)?.cast<String>(),
      fotos: (fields[13] as List?)?.cast<String>(),
      estado: fields[14] as String,
      fechaGuardado: fields[15] as DateTime,
      fechaVisitado: fields[16] as DateTime?,
      fuente: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WishlistPlaceModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.latitud)
      ..writeByte(4)
      ..write(obj.longitud)
      ..writeByte(5)
      ..write(obj.ciudad)
      ..writeByte(6)
      ..write(obj.pais)
      ..writeByte(7)
      ..write(obj.costoEstimado)
      ..writeByte(8)
      ..write(obj.tiempoEstimadoMin)
      ..writeByte(9)
      ..write(obj.horario)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.comentarios)
      ..writeByte(12)
      ..write(obj.links)
      ..writeByte(13)
      ..write(obj.fotos)
      ..writeByte(14)
      ..write(obj.estado)
      ..writeByte(15)
      ..write(obj.fechaGuardado)
      ..writeByte(16)
      ..write(obj.fechaVisitado)
      ..writeByte(17)
      ..write(obj.fuente);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistPlaceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
