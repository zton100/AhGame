import 'class_config.dart';
import 'stat_block.dart';

class CharacterState {
  const CharacterState({
    required this.classConfig,
    required this.level,
    required this.experience,
  });

  final ClassConfig classConfig;
  final int level;
  final int experience;

  StatBlock get baseStats => classConfig.baseStats;
  List<String> get classTags => classConfig.tags;
}
