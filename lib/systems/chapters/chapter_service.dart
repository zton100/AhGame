import '../../models/chapter_config.dart';
import '../../models/save_data.dart';
import '../config/game_database.dart';

class ChapterService {
  ChapterService(GameDatabase database)
      : _chaptersById = {
          for (final entry in database.recordsForTable('chapters').entries)
            entry.key: ChapterConfig.fromJson(entry.value),
        };

  final Map<String, ChapterConfig> _chaptersById;

  ChapterConfig requireChapter(String chapterId) {
    final chapter = _chaptersById[chapterId];
    if (chapter == null) {
      throw StateError('Chapter not found: $chapterId');
    }

    return chapter;
  }

  StageConfig currentStage(PlayerProgress progress) {
    final chapter = requireChapter(progress.currentChapterId);
    return _requireStage(chapter, progress.currentStageId);
  }

  StageConfig currentProgressionStage(PlayerProgress progress) {
    return currentStage(progress);
  }

  StageConfig stageById({
    required String chapterId,
    required String stageId,
  }) {
    return _requireStage(requireChapter(chapterId), stageId);
  }

  StageConfig? highestClearedStage(PlayerProgress progress) {
    final stageId = progress.highestClearedStageId;
    if (stageId == null) {
      return null;
    }

    return stageById(
      chapterId: progress.currentChapterId,
      stageId: stageId,
    );
  }

  StageConfig? highestFarmableStage(PlayerProgress progress) {
    final chapter = requireChapter(progress.currentChapterId);
    final highestClearedId = progress.highestClearedStageId;
    if (highestClearedId == null) {
      final current = currentProgressionStage(progress);
      if (canEnterStage(progress: progress, stage: current) &&
          current.monsterIds.isNotEmpty) {
        return current;
      }

      return null;
    }

    final highestClearedIndex = chapter.stages.indexWhere(
      (stage) => stage.stageId == highestClearedId,
    );
    if (highestClearedIndex < 0) {
      throw StateError('Stage not found: $highestClearedId');
    }

    for (var i = highestClearedIndex; i >= 0; i -= 1) {
      final stage = chapter.stages[i];
      if (canEnterStage(progress: progress, stage: stage) &&
          stage.monsterIds.isNotEmpty) {
        return stage;
      }
    }

    return null;
  }

  bool shouldFarmPreviousStage(PlayerProgress progress) {
    final current = currentProgressionStage(progress);
    return current.requiredLevel > progress.level;
  }

  StageConfig? maybeNextProgressionStage(PlayerProgress progress) {
    return nextStage(
      chapterId: progress.currentChapterId,
      stageId: progress.currentStageId,
    );
  }

  StageConfig? nextStage({
    required String chapterId,
    required String stageId,
  }) {
    final chapter = requireChapter(chapterId);
    final index =
        chapter.stages.indexWhere((stage) => stage.stageId == stageId);
    if (index < 0) {
      throw StateError('Stage not found: $stageId');
    }
    if (index + 1 >= chapter.stages.length) {
      return null;
    }

    return chapter.stages[index + 1];
  }

  bool canEnterStage({
    required PlayerProgress progress,
    required StageConfig stage,
  }) {
    return progress.level >= stage.requiredLevel;
  }

  SaveData markStageCleared(SaveData saveData) {
    final progress = saveData.playerProgress;
    final stage = currentStage(progress);
    final next = nextStage(
      chapterId: progress.currentChapterId,
      stageId: stage.stageId,
    );

    return saveData.copyWith(
      playerProgress: progress.copyWith(
        currentStageId: next?.stageId ?? stage.stageId,
        highestClearedStageId: stage.stageId,
      ),
    );
  }

  StageConfig _requireStage(ChapterConfig chapter, String stageId) {
    for (final stage in chapter.stages) {
      if (stage.stageId == stageId) {
        return stage;
      }
    }

    throw StateError('Stage not found: $stageId');
  }
}
