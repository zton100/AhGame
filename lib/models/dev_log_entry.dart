class DevLogEntry {
  const DevLogEntry({
    required this.systemId,
    required this.summary,
    required this.changedFiles,
    required this.testResults,
    required this.createdAt,
  });

  factory DevLogEntry.fromJson(Map<String, Object?> json) {
    return DevLogEntry(
      systemId: json['systemId'] as String,
      summary: json['summary'] as String,
      changedFiles: List<String>.from(json['changedFiles'] as List),
      testResults: List<String>.from(json['testResults'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String systemId;
  final String summary;
  final List<String> changedFiles;
  final List<String> testResults;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'systemId': systemId,
      'summary': summary,
      'changedFiles': changedFiles,
      'testResults': testResults,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
