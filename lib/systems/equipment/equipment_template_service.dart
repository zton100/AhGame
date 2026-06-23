import '../../models/equipment_template.dart';
import '../config/game_database.dart';

class EquipmentTemplateService {
  const EquipmentTemplateService(this._database);

  final GameDatabase _database;

  List<EquipmentTemplate> listTemplates() {
    final templates = _database
        .recordsForTable('equipment_templates')
        .values
        .map(EquipmentTemplate.fromJson)
        .toList();
    templates.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(templates);
  }

  EquipmentTemplate? findTemplate(String templateId) {
    final record = _database.findRecord('equipment_templates', templateId);
    return record == null ? null : EquipmentTemplate.fromJson(record);
  }

  EquipmentTemplate requireTemplate(String templateId) {
    final template = findTemplate(templateId);
    if (template == null) {
      throw StateError('Equipment template not found: $templateId');
    }

    return template;
  }
}
