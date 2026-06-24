import 'equipment_instance.dart';
import 'equipment_loadout.dart';
import 'inventory_state.dart';
import 'settings_save.dart';
import 'skill_loadout.dart';

class SaveData {
  const SaveData({
    required this.saveVersion,
    required this.createdAt,
    required this.lastSavedAt,
    this.lastExitAt,
    required this.playerProgress,
    required this.inventory,
    required this.settings,
  });

  factory SaveData.newGame({DateTime? now}) {
    final timestamp = now ?? DateTime.now().toUtc();
    return SaveData(
      saveVersion: currentVersion,
      createdAt: timestamp,
      lastSavedAt: timestamp,
      lastExitAt: null,
      playerProgress: PlayerProgress(
        currentClassId: 'exile',
        level: 1,
        experience: 0,
        skillLoadout: SkillLoadout.defaultForClass('exile'),
        currentChapterId: PlayerProgress.defaultChapterId,
        currentStageId: PlayerProgress.defaultStageId,
      ),
      inventory: const InventorySave(equipmentInstanceIds: []),
      settings: const SettingsSave(),
    );
  }

  factory SaveData.fromJson(Map<String, Object?> json) {
    return SaveData(
      saveVersion: json['saveVersion'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSavedAt: DateTime.parse(json['lastSavedAt'] as String),
      lastExitAt: json['lastExitAt'] == null
          ? null
          : DateTime.parse(json['lastExitAt'] as String),
      playerProgress: PlayerProgress.fromJson(
        _asStringMap(json['playerProgress'], 'playerProgress'),
      ),
      inventory: InventorySave.fromJson(
        _asStringMap(json['inventory'], 'inventory'),
      ),
      settings:
          SettingsSave.fromJson(_asStringMap(json['settings'], 'settings')),
    );
  }

  static const int currentVersion = 4;

  final int saveVersion;
  final DateTime createdAt;
  final DateTime lastSavedAt;
  final DateTime? lastExitAt;
  final PlayerProgress playerProgress;
  final InventorySave inventory;
  final SettingsSave settings;

  SaveData copyWith({
    int? saveVersion,
    DateTime? createdAt,
    DateTime? lastSavedAt,
    DateTime? lastExitAt,
    PlayerProgress? playerProgress,
    InventorySave? inventory,
    SettingsSave? settings,
  }) {
    return SaveData(
      saveVersion: saveVersion ?? this.saveVersion,
      createdAt: createdAt ?? this.createdAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      lastExitAt: lastExitAt ?? this.lastExitAt,
      playerProgress: playerProgress ?? this.playerProgress,
      inventory: inventory ?? this.inventory,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'saveVersion': saveVersion,
      'createdAt': createdAt.toIso8601String(),
      'lastSavedAt': lastSavedAt.toIso8601String(),
      'lastExitAt': lastExitAt?.toIso8601String(),
      'playerProgress': playerProgress.toJson(),
      'inventory': inventory.toJson(),
      'settings': settings.toJson(),
    };
  }
}

Map<String, Object?> _asStringMap(Object? value, String fieldName) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected $fieldName to be a JSON object.');
}

class PlayerProgress {
  const PlayerProgress({
    required this.currentClassId,
    required this.level,
    required this.experience,
    this.skillLoadout = const SkillLoadout.empty(),
    this.currentChapterId = defaultChapterId,
    this.currentStageId = defaultStageId,
    this.highestClearedStageId,
  });

  factory PlayerProgress.fromJson(Map<String, Object?> json) {
    final currentClassId = json['currentClassId'] as String;
    return PlayerProgress(
      currentClassId: currentClassId,
      level: json['level'] as int,
      experience: json['experience'] as int,
      skillLoadout: json['skillLoadout'] is Map
          ? SkillLoadout.fromJson(
              Map<String, Object?>.from(json['skillLoadout'] as Map),
            )
          : SkillLoadout.defaultForClass(currentClassId),
      currentChapterId: json['currentChapterId'] as String? ?? defaultChapterId,
      currentStageId: json['currentStageId'] as String? ?? defaultStageId,
      highestClearedStageId: json['highestClearedStageId'] as String?,
    );
  }

  static const defaultChapterId = 'chapter_1';
  static const defaultStageId = '1-1';

  final String currentClassId;
  final int level;
  final int experience;
  final SkillLoadout skillLoadout;
  final String currentChapterId;
  final String currentStageId;
  final String? highestClearedStageId;

  PlayerProgress copyWith({
    String? currentClassId,
    int? level,
    int? experience,
    SkillLoadout? skillLoadout,
    String? currentChapterId,
    String? currentStageId,
    String? highestClearedStageId,
  }) {
    return PlayerProgress(
      currentClassId: currentClassId ?? this.currentClassId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      skillLoadout: skillLoadout ?? this.skillLoadout,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      currentStageId: currentStageId ?? this.currentStageId,
      highestClearedStageId:
          highestClearedStageId ?? this.highestClearedStageId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'currentClassId': currentClassId,
      'level': level,
      'experience': experience,
      'skillLoadout': skillLoadout.toJson(),
      'currentChapterId': currentChapterId,
      'currentStageId': currentStageId,
      'highestClearedStageId': highestClearedStageId,
    };
  }
}

class InventorySave {
  const InventorySave({
    required this.equipmentInstanceIds,
    this.equipmentInstances = const {},
    this.equipmentLoadout = const EquipmentLoadout.empty(),
    this.equipmentCapacity = InventoryState.defaultEquipmentCapacity,
    this.materials = const [],
    this.lockedEquipmentInstanceIds = const [],
  });

  factory InventorySave.fromJson(Map<String, Object?> json) {
    return InventorySave(
      equipmentInstanceIds: List<String>.from(
        json['equipmentInstanceIds'] as List? ?? const [],
      ),
      equipmentInstances: {
        for (final entry
            in (json['equipmentInstances'] as Map? ?? const {}).entries)
          entry.key as String: EquipmentInstance.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          ),
      },
      equipmentLoadout: json['equipmentLoadout'] is Map
          ? EquipmentLoadout.fromJson(
              Map<String, Object?>.from(json['equipmentLoadout'] as Map),
            )
          : const EquipmentLoadout.empty(),
      equipmentCapacity: json['equipmentCapacity'] as int? ??
          InventoryState.defaultEquipmentCapacity,
      materials: [
        for (final material in json['materials'] as List? ?? const [])
          MaterialStack.fromJson(Map<String, Object?>.from(material as Map)),
      ],
      lockedEquipmentInstanceIds: List<String>.from(
        json['lockedEquipmentInstanceIds'] as List? ?? const [],
      ),
    );
  }

  final List<String> equipmentInstanceIds;
  final Map<String, EquipmentInstance> equipmentInstances;
  final EquipmentLoadout equipmentLoadout;
  final int equipmentCapacity;
  final List<MaterialStack> materials;
  final List<String> lockedEquipmentInstanceIds;

  InventorySave copyWith({
    List<String>? equipmentInstanceIds,
    Map<String, EquipmentInstance>? equipmentInstances,
    EquipmentLoadout? equipmentLoadout,
    int? equipmentCapacity,
    List<MaterialStack>? materials,
    List<String>? lockedEquipmentInstanceIds,
  }) {
    return InventorySave(
      equipmentInstanceIds: equipmentInstanceIds ?? this.equipmentInstanceIds,
      equipmentInstances: equipmentInstances ?? this.equipmentInstances,
      equipmentLoadout: equipmentLoadout ?? this.equipmentLoadout,
      equipmentCapacity: equipmentCapacity ?? this.equipmentCapacity,
      materials: materials ?? this.materials,
      lockedEquipmentInstanceIds:
          lockedEquipmentInstanceIds ?? this.lockedEquipmentInstanceIds,
    );
  }

  bool isLocked(String instanceId) {
    return lockedEquipmentInstanceIds.contains(instanceId);
  }

  InventorySave lockEquipment(String instanceId) {
    if (isLocked(instanceId)) {
      return this;
    }

    return copyWith(
      lockedEquipmentInstanceIds: [
        ...lockedEquipmentInstanceIds,
        instanceId,
      ],
    );
  }

  InventorySave unlockEquipment(String instanceId) {
    if (!isLocked(instanceId)) {
      return this;
    }

    return copyWith(
      lockedEquipmentInstanceIds: [
        for (final id in lockedEquipmentInstanceIds)
          if (id != instanceId) id,
      ],
    );
  }

  Map<String, Object?> toJson() {
    return {
      'equipmentInstanceIds': equipmentInstanceIds,
      'equipmentInstances': {
        for (final entry in equipmentInstances.entries)
          entry.key: entry.value.toJson(),
      },
      'equipmentLoadout': equipmentLoadout.toJson(),
      'equipmentCapacity': equipmentCapacity,
      'materials': [
        for (final material in materials) material.toJson(),
      ],
      'lockedEquipmentInstanceIds': lockedEquipmentInstanceIds,
    };
  }
}
