class DataFileMeta {
  const DataFileMeta({
    required this.assetPath,
    required this.schemaVersion,
    required this.recordCount,
    required this.topLevelKeys,
  });

  factory DataFileMeta.fromJson(Map<String, Object?> json) {
    return DataFileMeta(
      assetPath: json['assetPath'] as String,
      schemaVersion: json['schemaVersion'] as int,
      recordCount: json['recordCount'] as int,
      topLevelKeys: List<String>.from(json['topLevelKeys'] as List),
    );
  }

  final String assetPath;
  final int schemaVersion;
  final int recordCount;
  final List<String> topLevelKeys;

  Map<String, Object?> toJson() {
    return {
      'assetPath': assetPath,
      'schemaVersion': schemaVersion,
      'recordCount': recordCount,
      'topLevelKeys': topLevelKeys,
    };
  }
}
