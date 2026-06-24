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
