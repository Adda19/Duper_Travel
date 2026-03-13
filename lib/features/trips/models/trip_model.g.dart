// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 0;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Field 2 backward-compat: old data stored a String, new data is List<String>
    final raw2 = fields[2];
    final List<String> destinos = raw2 is List
        ? List<String>.from(raw2)
        : (raw2 as String).isNotEmpty
            ? [raw2 as String]  // ignore: unnecessary_cast
            : [];

    return TripModel(
      id: fields[0] as String,
      nombre: fields[1] as String,
      destinos: destinos,
      fechaInicio: fields[3] as DateTime,
      fechaFin: fields[4] as DateTime,
      numeroPersonas: fields[5] as int,
      moneda: fields[6] as String,
      presupuestoTotal: fields[7] as double,
      tipoTransporte: (fields[8] as String?) ?? 'vuelo',
      horaSalida: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.destinos)
      ..writeByte(3)
      ..write(obj.fechaInicio)
      ..writeByte(4)
      ..write(obj.fechaFin)
      ..writeByte(5)
      ..write(obj.numeroPersonas)
      ..writeByte(6)
      ..write(obj.moneda)
      ..writeByte(7)
      ..write(obj.presupuestoTotal)
      ..writeByte(8)
      ..write(obj.tipoTransporte)
      ..writeByte(9)
      ..write(obj.horaSalida);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
