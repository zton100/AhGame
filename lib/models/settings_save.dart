class SettingsSave {
  const SettingsSave({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  factory SettingsSave.fromJson(Map<String, Object?> json) {
    return SettingsSave(
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }

  final bool soundEnabled;
  final bool hapticsEnabled;

  SettingsSave copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsSave(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
    };
  }
}
