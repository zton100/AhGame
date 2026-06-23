class GameDatabaseSummary {
  const GameDatabaseSummary({
    required this.fileCount,
    required this.recordCount,
    required this.errorCount,
  });

  factory GameDatabaseSummary.fromJson(Map<String, Object?> json) {
    return GameDatabaseSummary(
      fileCount: json['fileCount'] as int,
      recordCount: json['recordCount'] as int,
      errorCount: json['errorCount'] as int,
    );
  }

  final int fileCount;
  final int recordCount;
  final int errorCount;

  Map<String, Object?> toJson() {
    return {
      'fileCount': fileCount,
      'recordCount': recordCount,
      'errorCount': errorCount,
    };
  }
}
