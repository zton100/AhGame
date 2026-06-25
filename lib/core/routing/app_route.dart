enum AppRoute {
  battle('battle', '战斗'),
  equipment('equipment', '装备'),
  build('build', 'BD'),
  abyss('abyss', '深渊'),
  character('character', '角色'),
  debug('debug', '调试');

  const AppRoute(this.id, this.label);

  final String id;
  final String label;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }
}
