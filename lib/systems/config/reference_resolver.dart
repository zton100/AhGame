import '../../models/config_validation_error.dart';
import 'effect_registry.dart';
import 'game_database.dart';

class ReferenceResolver {
  const ReferenceResolver({
    EffectRegistry effectRegistry = const EffectRegistry(),
  }) : _effectRegistry = effectRegistry;

  final EffectRegistry _effectRegistry;

  List<ConfigValidationError> check(GameDatabase database) {
    return [
      ..._checkSkillClasses(database),
      ..._checkEquipmentClasses(database),
      ..._checkSoulCoreClasses(database),
      ..._checkDropPoolEntries(database),
      ..._checkEffectIds(database),
    ];
  }

  List<ConfigValidationError> _checkSkillClasses(GameDatabase database) {
    return [
      for (final skill in database.recordsForTable('skills').values)
        if (skill['classId'] is String &&
            database.findRecord('classes', skill['classId'] as String) == null)
          _invalidReference(
            assetPath: 'assets/data/skills.json',
            tableName: 'skills',
            recordId: skill['id'] as String?,
            field: 'classId',
            message: 'Skill references missing classId "${skill['classId']}".',
          ),
    ];
  }

  List<ConfigValidationError> _checkEquipmentClasses(GameDatabase database) {
    return [
      for (final item in database.recordsForTable('equipment_templates').values)
        ..._checkAllowedClasses(
          database: database,
          assetPath: 'assets/data/equipment_templates.json',
          tableName: 'equipment_templates',
          record: item,
        ),
    ];
  }

  List<ConfigValidationError> _checkSoulCoreClasses(GameDatabase database) {
    return [
      for (final core in database.recordsForTable('soul_cores').values)
        ..._checkAllowedClasses(
          database: database,
          assetPath: 'assets/data/soul_cores.json',
          tableName: 'soul_cores',
          record: core,
        ),
    ];
  }

  List<ConfigValidationError> _checkAllowedClasses({
    required GameDatabase database,
    required String assetPath,
    required String tableName,
    required Map<String, Object?> record,
  }) {
    final allowedClasses = record['allowedClasses'];
    if (allowedClasses is! List<Object?>) {
      return const [];
    }

    return [
      for (final classId in allowedClasses.whereType<String>())
        if (classId != 'all' && database.findRecord('classes', classId) == null)
          _invalidReference(
            assetPath: assetPath,
            tableName: tableName,
            recordId: record['id'] as String?,
            field: 'allowedClasses',
            message: 'Record references missing class "$classId".',
          ),
    ];
  }

  List<ConfigValidationError> _checkDropPoolEntries(GameDatabase database) {
    final errors = <ConfigValidationError>[];

    for (final pool in database.recordsForTable('drop_pools').values) {
      final entries = pool['entries'];
      if (entries is! List<Object?>) {
        continue;
      }

      for (final entry in entries.whereType<Map<String, Object?>>()) {
        final type = entry['type'];
        final refId = entry['refId'];
        if (type is! String || refId is! String) {
          continue;
        }

        final tableName = _dropTypeToTable(type);
        if (tableName == null) {
          continue;
        }

        if (database.findRecord(tableName, refId) == null) {
          errors.add(
            _invalidReference(
              assetPath: 'assets/data/drop_pools.json',
              tableName: 'drop_pools',
              recordId: pool['id'] as String?,
              field: 'entries.refId',
              message: 'Drop entry references missing $type "$refId".',
            ),
          );
        }
      }
    }

    return errors;
  }

  List<ConfigValidationError> _checkEffectIds(GameDatabase database) {
    return [
      for (final tableName in const [
        'skills',
        'affixes',
        'soul_cores',
        'sets',
      ])
        for (final record in database.recordsForTable(tableName).values)
          ..._effectErrorsForRecord(tableName, record),
    ];
  }

  List<ConfigValidationError> _effectErrorsForRecord(
    String tableName,
    Map<String, Object?> record,
  ) {
    final errors = <ConfigValidationError>[];

    void checkEffect(Object? value, String field) {
      if (value is! Map<String, Object?>) {
        return;
      }

      final effectId = value['effectId'];
      if (effectId is String && !_effectRegistry.contains(effectId)) {
        errors.add(
          _invalidReference(
            assetPath: 'assets/data/$tableName.json',
            tableName: tableName,
            recordId: record['id'] as String?,
            field: field,
            message: 'Unknown effectId "$effectId".',
          ),
        );
      }
    }

    checkEffect(record['effect'], 'effect.effectId');
    checkEffect(record['coreEffect'], 'coreEffect.effectId');
    checkEffect(record['negativeEffect'], 'negativeEffect.effectId');
    checkEffect(record['legendaryEffect'], 'legendaryEffect.effectId');

    final effects = record['effects'];
    if (effects is List<Object?>) {
      for (final effect in effects) {
        checkEffect(effect, 'effects.effectId');
      }
    }

    return errors;
  }

  String? _dropTypeToTable(String type) {
    switch (type) {
      case 'equipment':
        return 'equipment_templates';
      case 'rune':
        return 'runes';
      case 'soul_core':
        return 'soul_cores';
      case 'material':
        return 'materials';
    }
    return null;
  }

  ConfigValidationError _invalidReference({
    required String assetPath,
    required String tableName,
    required String? recordId,
    required String field,
    required String message,
  }) {
    return ConfigValidationError(
      assetPath: assetPath,
      code: ConfigValidationCode.invalidReference,
      tableName: tableName,
      recordId: recordId,
      field: field,
      message: message,
    );
  }
}
