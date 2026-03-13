// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManualExpenseModelAdapter extends TypeAdapter<ManualExpenseModel> {
  @override
  final int typeId = 2;

  @override
  ManualExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManualExpenseModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      descripcion: fields[2] as String,
      categoria: fields[3] as String,
      montoEstimado: fields[4] as double,
      montoReal: fields[5] as double,
      fecha: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ManualExpenseModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.categoria)
      ..writeByte(4)
      ..write(obj.montoEstimado)
      ..writeByte(5)
      ..write(obj.montoReal)
      ..writeByte(6)
      ..write(obj.fecha);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
