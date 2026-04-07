import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class PendingOperation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String type; // 'setMoney' | 'addMoney' | 'removeMoney' | 'distribute' | 'multiply' | 'donate' | 'updateChild' | 'archiveChild' | 'donateBucket' | 'transfer' | 'withdraw'

  @HiveField(2)
  Map<String, dynamic> payload;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  int retryCount;

  PendingOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
  });
}

class PendingOperationAdapter extends TypeAdapter<PendingOperation> {
  @override
  final int typeId = 0;

  @override
  PendingOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingOperation(
      id: fields[0] as String,
      type: fields[1] as String,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      createdAt: fields[3] as DateTime,
      retryCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
