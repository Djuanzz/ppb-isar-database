import 'package:expense_tracker/models/enums.dart';
import 'package:isar/isar.dart';

part 'record.g.dart';

@Collection()
class Record {
  Id id = Isar.autoIncrement;

  int amount;

  @enumerated
  Category category;

  Record({required this.amount, required this.category});
}
