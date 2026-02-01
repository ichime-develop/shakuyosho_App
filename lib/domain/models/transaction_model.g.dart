// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 3;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      eventId: fields[1] as String?,
      type: fields[2] as TxType,
      title: fields[3] as String,
      date: fields[4] as DateTime,
      currency: fields[5] as String,
      totalAmount: fields[6] as int,
      participantIds: (fields[7] as List).cast<String>(),
      paidBy: fields[8] as String?,
      shares: (fields[9] as Map?)?.cast<String, int>(),
      fromUserId: fields[10] as String?,
      toUserId: fields[11] as String?,
      repaymentAmount: fields[12] as int?,
      createdBy: fields[13] as String,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime?,
      deletedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.totalAmount)
      ..writeByte(7)
      ..write(obj.participantIds)
      ..writeByte(8)
      ..write(obj.paidBy)
      ..writeByte(9)
      ..write(obj.shares)
      ..writeByte(10)
      ..write(obj.fromUserId)
      ..writeByte(11)
      ..write(obj.toUserId)
      ..writeByte(12)
      ..write(obj.repaymentAmount)
      ..writeByte(13)
      ..write(obj.createdBy)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TxTypeAdapter extends TypeAdapter<TxType> {
  @override
  final int typeId = 2;

  @override
  TxType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TxType.expense;
      case 1:
        return TxType.repayment;
      default:
        return TxType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, TxType obj) {
    switch (obj) {
      case TxType.expense:
        writer.writeByte(0);
        break;
      case TxType.repayment:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
