import 'package:flutter_test/flutter_test.dart';
import 'package:trip_cost/core/storage/database/app_database.dart';

AppDatabase createIsolatedTestDatabase() {
  final database = AppDatabase.inMemory();
  addTearDown(database.close);
  return database;
}
