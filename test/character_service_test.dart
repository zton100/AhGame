import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/character/character_service.dart';
import 'package:abyss_relic/systems/character/class_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CharacterService creates a character for every configured class', () {
    final database = _databaseWithClasses();
    final service = CharacterService(classService: ClassService(database));

    for (final classId in [
      'exile',
      'necrospeaker',
      'ember_mage',
      'frost_ranger',
      'sanctifier',
    ]) {
      final character = service.createCharacter(classId: classId);

      expect(character.classConfig.id, classId);
      expect(character.level, 1);
      expect(character.experience, 0);
      expect(character.baseStats.hp, greaterThan(0));
      expect(character.classConfig.tags, isNotEmpty);
    }
  });

  test('CharacterService rejects missing class ids', () {
    final service = CharacterService(
      classService: ClassService(_databaseWithClasses()),
    );

    expect(
      () => service.createCharacter(classId: 'missing_class'),
      throwsA(isA<StateError>()),
    );
  });

  test('CharacterService restores character state from SaveData', () {
    final service = CharacterService(
      classService: ClassService(_databaseWithClasses()),
    );
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23)).copyWith(
      playerProgress: const PlayerProgress(
        currentClassId: 'sanctifier',
        level: 8,
        experience: 1250,
      ),
    );

    final character = service.restoreFromSave(save);

    expect(character.classConfig.id, 'sanctifier');
    expect(character.level, 8);
    expect(character.experience, 1250);
    expect(character.baseStats.hp, 145);
  });

  test('CharacterService switches current class while preserving progress', () {
    final service = CharacterService(
      classService: ClassService(_databaseWithClasses()),
    );
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 23)).copyWith(
      playerProgress: const PlayerProgress(
        currentClassId: 'exile',
        level: 11,
        experience: 3000,
      ),
    );

    final changed = service.switchClass(save, 'ember_mage');

    expect(changed.playerProgress.currentClassId, 'ember_mage');
    expect(changed.playerProgress.level, 11);
    expect(changed.playerProgress.experience, 3000);
  });
}

GameDatabase _databaseWithClasses() {
  return GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/classes.json',
        schemaVersion: 1,
        recordCount: 5,
        topLevelKeys: ['classes', 'schemaVersion'],
      ),
      json: {
        'schemaVersion': 1,
        'classes': [
          _classRecord('exile', 'Exile', ['poison', 'bleed'], 120, 18, 6),
          _classRecord(
            'necrospeaker',
            'Necrospeaker',
            ['summon', 'curse'],
            100,
            14,
            4,
          ),
          _classRecord(
              'ember_mage', 'Ember Mage', ['fire', 'spell'], 92, 22, 3),
          _classRecord(
            'frost_ranger',
            'Frost Ranger',
            ['frost', 'ranged'],
            105,
            20,
            5,
          ),
          _classRecord(
            'sanctifier',
            'Sanctifier',
            ['holy', 'block'],
            145,
            16,
            9,
          ),
        ],
      },
    ),
  ]);
}

Map<String, Object?> _classRecord(
  String id,
  String name,
  List<String> tags,
  num hp,
  num attack,
  num armor,
) {
  return {
    'id': id,
    'name': name,
    'tags': tags,
    'baseStats': {'hp': hp, 'attack': attack, 'armor': armor},
    'growth': {'hp': 10, 'attack': 2, 'armor': 1},
  };
}
