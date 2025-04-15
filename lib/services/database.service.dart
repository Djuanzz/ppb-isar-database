import 'package:expense_tracker/models/record.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static late final Isar db;

  static Future<void> setupDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    db = await Isar.open([RecordSchema], directory: appDir.path);
  }
}
