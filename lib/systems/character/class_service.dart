import '../../models/class_config.dart';
import '../config/game_database.dart';

class ClassService {
  const ClassService(this._database);

  final GameDatabase _database;

  List<ClassConfig> listClasses() {
    final records = _database.recordsForTable('classes').values;
    final classes = records.map(ClassConfig.fromJson).toList();
    classes.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(classes);
  }

  ClassConfig? findClass(String classId) {
    final record = _database.findRecord('classes', classId);
    return record == null ? null : ClassConfig.fromJson(record);
  }

  ClassConfig requireClass(String classId) {
    final classConfig = findClass(classId);
    if (classConfig == null) {
      throw StateError('Class config not found: $classId');
    }

    return classConfig;
  }
}
