class EffectRegistry {
  const EffectRegistry({this.effectIds = _defaultEffectIds});

  final Set<String> effectIds;

  bool contains(String effectId) => effectIds.contains(effectId);

  static const Set<String> _defaultEffectIds = {
    'deal_damage',
    'stat_bonus',
    'poison_explode_on_death',
    'poison_can_crit',
    'apply_status',
    'heal_self',
    'gain_shield',
  };
}
