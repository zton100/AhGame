import '../../core/save/player_save_provider.dart';
import '../../models/battle_settlement_report.dart';
import '../../models/battle_state.dart';
import '../../models/monster_config.dart';
import '../../models/save_data.dart';
import '../../systems/battle/battle_settlement_service.dart';
import '../../systems/battle/battle_simulator.dart';
import '../../systems/character/character_service.dart';
import '../../systems/character/class_service.dart';
import '../../systems/config/game_database.dart';
import '../../systems/monsters/monster_factory.dart';
import '../../systems/monsters/monster_service.dart';
import '../../systems/skills/skill_service.dart';
import '../../systems/stats/character_final_stats_service.dart';

class BattleController {
  BattleController({
    BattleSimulator simulator = const BattleSimulator(),
    BattleSettlementService settlementService = const BattleSettlementService(),
    MonsterFactory monsterFactory = const MonsterFactory(),
    String fixedMonsterId = 'skeleton_grunt',
  })  : _simulator = simulator,
        _settlementService = settlementService,
        _monsterFactory = monsterFactory,
        _fixedMonsterId = fixedMonsterId;

  final BattleSimulator _simulator;
  final BattleSettlementService _settlementService;
  final MonsterFactory _monsterFactory;
  final String _fixedMonsterId;

  BattleState? battle;
  MonsterConfig? monsterConfig;
  BattleSettlementReport? settlementReport;
  String? errorMessage;

  bool get canSettle => battle?.result == BattleResult.victory;
  bool get hasSettled => settlementReport?.accepted == true;

  void createBattle({
    required SaveData saveData,
    required GameDatabase database,
  }) {
    final character = CharacterService(
      classService: ClassService(database),
    ).restoreFromSave(saveData);
    final inventory = inventoryStateFromSave(saveData.inventory);
    final computedStats = const CharacterFinalStatsService().compute(
      character: character,
      loadout: inventory.equipmentLoadout,
      inventory: inventory,
      database: database,
    );
    final skillService = SkillService(database);
    final monsterService = MonsterService(database);
    final config = monsterService.requireMonster(_fixedMonsterId);
    final monster = _monsterFactory.create(config: config);

    monsterConfig = config;
    settlementReport = null;
    errorMessage = null;
    battle = _simulator.createBattle(
      character: character,
      computedStats: computedStats.computedStats,
      skillLoadout: saveData.playerProgress.skillLoadout,
      monster: monster,
      skillService: skillService,
    );
  }

  void tick({double seconds = 1}) {
    final current = battle;
    if (current == null) {
      errorMessage = 'Start a battle before ticking.';
      return;
    }
    errorMessage = null;
    battle = _simulator.tick(current, seconds);
  }

  void autoAdvance({int maxTicks = 100, double secondsPerTick = 1}) {
    final current = battle;
    if (current == null) {
      errorMessage = 'Start a battle before auto advancing.';
      return;
    }

    var next = current;
    for (var i = 0; i < maxTicks && !next.isFinished; i += 1) {
      next = _simulator.tick(next, secondsPerTick);
    }
    errorMessage = null;
    battle = next;
  }

  Future<BattleSettlementReport?> settleVictory({
    required SaveData saveData,
    required GameDatabase database,
    required PlayerSaveController saveController,
    int seed = 1,
  }) async {
    if (settlementReport != null) {
      return settlementReport;
    }

    final current = battle;
    final config = monsterConfig;
    if (current == null || config == null) {
      errorMessage = 'Start a battle before settlement.';
      return null;
    }
    if (current.result != BattleResult.victory) {
      errorMessage = 'Only victory battles can be settled.';
      return null;
    }

    final report = _settlementService.settle(
      battle: current,
      monster: config,
      saveData: saveData,
      database: database,
      seed: seed,
    );
    settlementReport = report;
    errorMessage = report.accepted ? null : report.reason.name;

    if (report.accepted) {
      await saveController.save(report.saveData);
    }

    return report;
  }
}
