import 'package:hive_flutter/hive_flutter.dart';
import 'pending_operation.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PendingOperationAdapter());
  }
  await Hive.openBox<PendingOperation>('pending_operations');
}
