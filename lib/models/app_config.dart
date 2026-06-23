class AppConfig {
  const AppConfig({
    required this.id,
    required this.displayName,
    required this.version,
    required this.dataPath,
  });

  factory AppConfig.fromJson(Map<String, Object?> json) {
    return AppConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      version: json['version'] as String,
      dataPath: json['dataPath'] as String,
    );
  }

  final String id;
  final String displayName;
  final String version;
  final String dataPath;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'version': version,
      'dataPath': dataPath,
    };
  }
}
