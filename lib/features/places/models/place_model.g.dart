// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaceModelAdapter extends TypeAdapter<PlaceModel> {
  @override
  final int typeId = 1;

  @override
  PlaceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaceModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      nombre: fields[2] as String,
      tipo: fields[3] as String,
      latitud: fields[4] as double,
      longitud: fields[5] as double,
      dia: fields[6] as int,
      estado: fields[7] as String,
      costoEstimado: fields[8] as double,
      costoReal: fields[9] as double,
      tiempoEstimadoMin: fields[10] as int,
      horario: fields[11] as String,
      tags: (fields[12] as List?)?.cast<String>(),
      calificacion: fields[13] as double,
      comentarios: fields[14] as String,
      links: (fields[15] as List?)?.cast<String>(),
      fotos: (fields[16] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaceModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.nombre)
      ..writeByte(3)
      ..write(obj.tipo)
      ..writeByte(4)
      ..write(obj.latitud)
      ..writeByte(5)
      ..write(obj.longitud)
      ..writeByte(6)
      ..write(obj.dia)
      ..writeByte(7)
      ..write(obj.estado)
      ..writeByte(8)
      ..write(obj.costoEstimado)
      ..writeByte(9)
      ..write(obj.costoReal)
      ..writeByte(10)
      ..write(obj.tiempoEstimadoMin)
      ..writeByte(11)
      ..write(obj.horario)
      ..writeByte(12)
      ..write(obj.tags)
      ..writeByte(13)
      ..write(obj.calificacion)
      ..writeByte(14)
      ..write(obj.comentarios)
      ..writeByte(15)
      ..write(obj.links)
      ..writeByte(16)
      ..write(obj.fotos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
