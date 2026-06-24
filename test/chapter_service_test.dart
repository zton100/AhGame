import 'package:abyss_relic/models/chapter_config.dart';
import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/save_data.dart';
import 'package:abyss_relic/systems/chapters/chapter_service.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/save/save_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy saves default to chapter_1 and stage 1-1', () {
    final save = SaveData.fromJson({
      'saveVersion': SaveData.currentVersion,
      'createdAt': '2026-06-24T00:00:00.000Z',
      'lastSavedAt': '2026-06-24T00:10:00.000Z',
      'lastExitAt': null,
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 1,
        'experience': 0,
      },
      'inventory': {
        'equipmentInstanceIds': <String>[],
      },
      'settings': {
        'soundEnabled': true,
        'hapticsEnabled': true,
      },
    });

    expect(save.playerProgress.currentChapterId, 'chapter_1');
    expect(save.playerProgress.currentStageId, '1-1');
    expect(save.playerProgress.highestClearedStageId, isNull);
  });

  test('migration adds default chapter progress to old saves', () {
    final result = const SaveMigrationService().migrate({
      'saveVersion': 3,
      'createdAt': '2026-06-24T00:00:00.000Z',
      'lastSavedAt': '2026-06-24T00:10:00.000Z',
      'lastExitAt': null,
      'playerProgress': {
        'currentClassId': 'exile',
        'level': 1,
        'experience': 0,
      },
      'inventory': {
        'equipmentInstanceIds': <String>[],
      },
      'settings': {
        'soundEnabled': true,
        'hapticsEnabled': true,
      },
    });

    expect(result.saveData.saveVersion, SaveData.currentVersion);
    expect(result.saveData.playerProgress.currentChapterId, 'chapter_1');
    expect(result.saveData.playerProgress.currentStageId, '1-1');
  });

  test('current stage resolves skeleton grunt from chapter progress', () {
    final service = ChapterService(_database());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final stage = service.currentStage(save.playerProgress);

    expect(stage.stageId, '1-1');
    expect(stage.monsterIds, ['skeleton_grunt']);
  });

  test('marking a stage cleared advances to 1-2', () {
    final service = ChapterService(_database());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24));

    final advanced = service.markStageCleared(save);

    expect(advanced.playerProgress.highestClearedStageId, '1-1');
    expect(advanced.playerProgress.currentStageId, '1-2');
  });

  test('marking the final stage cleared keeps progress stable', () {
    final service = ChapterService(_database());
    final save = SaveData.newGame(now: DateTime.utc(2026, 6, 24)).copyWith(
      playerProgress:
          SaveData.newGame().playerProgress.copyWith(currentStageId: '1-5'),
    );

    final advanced = service.markStageCleared(save);

    expect(advanced.playerProgress.highestClearedStageId, '1-5');
    expect(advanced.playerProgress.currentStageId, '1-5');
  });

  test('ChapterConfig parses chapter and stage records', () {
    final chapter = ChapterConfig.fromJson(_chapterRecord());

    expect(chapter.chapterId, 'chapter_1');
    expect(chapter.stages, hasLength(5));
    expect(chapter.stages.last.isBossStage, isTrue);
  });
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    _file('assets/data/chapters.json', {
      'schemaVersion': 1,
      'chapters': [_chapterRecord()],
    }),
  ]);
}

Map<String, Object?> _chapterRecord() {
  return {
    'id': 'chapter_1',
    'chapterId': 'chapter_1',
    'name': 'Chapter 1',
    'stages': [
      {
        'stageId': '1-1',
        'stageName': 'Grave Road',
        'monsterIds': ['skeleton_grunt'],
        'requiredLevel': 1,
        'isBossStage': false,
      },
      {
        'stageId': '1-2',
        'stageName': 'Rat Cellar',
        'monsterIds': ['plague_rat'],
        'requiredLevel': 1,
        'isBossStage': false,
      },
      {
        'stageId': '1-3',
        'stageName': 'Blood Chapel',
        'monsterIds': ['blood_cultist'],
        'requiredLevel': 2,
        'isBossStage': false,
      },
      {
        'stageId': '1-4',
        'stageName': 'Imp Rift',
        'monsterIds': ['abyss_imp'],
        'requiredLevel': 3,
        'isBossStage': false,
      },
      {
        'stageId': '1-5',
        'stageName': 'Bone Gate',
        'monsterIds': ['skeleton_grunt'],
        'requiredLevel': 4,
        'isBossStage': true,
      },
    ],
  };
}

LoadedDataFile _file(String assetPath, Map<String, Object?> json) {
  return LoadedDataFile(
    meta: DataFileMeta(
      assetPath: assetPath,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      recordCount: 1,
      topLevelKeys: json.keys.toList(),
    ),
    json: json,
  );
}
