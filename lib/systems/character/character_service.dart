import '../../models/character_state.dart';
import '../../models/save_data.dart';
import 'class_service.dart';

class CharacterService {
  const CharacterService({required ClassService classService})
      : _classService = classService;

  final ClassService _classService;

  CharacterState createCharacter({
    required String classId,
    int level = 1,
    int experience = 0,
  }) {
    return CharacterState(
      classConfig: _classService.requireClass(classId),
      level: level,
      experience: experience,
    );
  }

  CharacterState restoreFromSave(SaveData saveData) {
    final progress = saveData.playerProgress;
    return createCharacter(
      classId: progress.currentClassId,
      level: progress.level,
      experience: progress.experience,
    );
  }

  SaveData switchClass(SaveData saveData, String classId) {
    _classService.requireClass(classId);
    return saveData.copyWith(
      playerProgress: saveData.playerProgress.copyWith(
        currentClassId: classId,
      ),
    );
  }
}
