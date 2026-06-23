import 'settings_save.dart';

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
      playerProgress: const PlayerProgress(
        currentClassId: 'exile',
        level: 1,
        experience: 0,
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

  static const int currentVersion = 3;

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
  });

  factory PlayerProgress.fromJson(Map<String, Object?> json) {
    return PlayerProgress(
      currentClassId: json['currentClassId'] as String,
      level: json['level'] as int,
      experience: json['experience'] as int,
    );
  }

  final String currentClassId;
  final int level;
  final int experience;

  PlayerProgress copyWith({
    String? currentClassId,
    int? level,
    int? experience,
  }) {
    return PlayerProgress(
      currentClassId: currentClassId ?? this.currentClassId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'currentClassId': currentClassId,
      'level': level,
      'experience': experience,
    };
  }
}

class InventorySave {
  const InventorySave({required this.equipmentInstanceIds});

  factory InventorySave.fromJson(Map<String, Object?> json) {
    return InventorySave(
      equipmentInstanceIds: List<String>.from(
        json['equipmentInstanceIds'] as List? ?? const [],
      ),
    );
  }

  final List<String> equipmentInstanceIds;

  InventorySave copyWith({List<String>? equipmentInstanceIds}) {
    return InventorySave(
      equipmentInstanceIds: equipmentInstanceIds ?? this.equipmentInstanceIds,
    );
  }

  Map<String, Object?> toJson() {
    return {'equipmentInstanceIds': equipmentInstanceIds};
  }
}
