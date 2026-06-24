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

  test('highest farmable stage resolves highest cleared enterable stage', () {
    final service = ChapterService(_database());
    final progress = SaveData.newGame().playerProgress.copyWith(
          level: 1,
          currentStageId: '1-3',
          highestClearedStageId: '1-2',
        );

    final stage = service.highestFarmableStage(progress);

    expect(stage?.stageId, '1-2');
  });

  test('highest farmable stage falls back to current stage with no clears', () {
    final service = ChapterService(_database());
    final progress = SaveData.newGame().playerProgress;

    final stage = service.highestFarmableStage(progress);

    expect(stage?.stageId, '1-1');
  });

  test('should farm previous stage when progression level is too high', () {
    final service = ChapterService(_database());
    final progress = SaveData.newGame().playerProgress.copyWith(
          level: 1,
          currentStageId: '1-3',
          highestClearedStageId: '1-2',
        );

    expect(service.shouldFarmPreviousStage(progress), isTrue);
    expect(service.currentProgressionStage(progress).stageId, '1-3');
    expect(service.maybeNextProgressionStage(progress)?.stageId, '1-4');
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
          SaveData.newGame().playerProgress.copyWith(currentStageId: '1-10'),
    );

    final advanced = service.markStageCleared(save);

    expect(advanced.playerProgress.highestClearedStageId, '1-10');
    expect(advanced.playerProgress.currentStageId, '1-10');
  });

  test('ChapterConfig parses chapter and stage records', () {
    final chapter = ChapterConfig.fromJson(_chapterRecord());

    expect(chapter.chapterId, 'chapter_1');
    expect(chapter.stages, hasLength(10));
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
        'monsterIds': ['grave_guardian'],
        'requiredLevel': 4,
        'isBossStage': true,
      },
      {
        'stageId': '1-6',
        'stageName': 'Plague Tunnels',
        'monsterIds': ['plague_carrier'],
        'requiredLevel': 4,
        'isBossStage': false,
      },
      {
        'stageId': '1-7',
        'stageName': 'Blood Moon Aisle',
        'monsterIds': ['blood_acolyte'],
        'requiredLevel': 5,
        'isBossStage': false,
      },
      {
        'stageId': '1-8',
        'stageName': 'Ashen Reliquary',
        'monsterIds': ['ash_wraith'],
        'requiredLevel': 5,
        'isBossStage': false,
      },
      {
        'stageId': '1-9',
        'stageName': 'Frost Bone Watch',
        'monsterIds': ['frost_bone_archer'],
        'requiredLevel': 6,
        'isBossStage': false,
      },
      {
        'stageId': '1-10',
        'stageName': 'Relic Gate',
        'monsterIds': ['relic_gatekeeper'],
        'requiredLevel': 6,
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
