import 'dart:math';

import '../../models/affix_config.dart';
import '../config/game_database.dart';

class AffixRollService {
  AffixRollService(GameDatabase database)
      : _affixes = [
          for (final record in database.recordsForTable('affixes').values)
            AffixConfig.fromJson(record),
        ]..sort((a, b) => a.id.compareTo(b.id));

  final List<AffixConfig> _affixes;

  AffixConfig requireAffix(String affixId) {
    for (final affix in _affixes) {
      if (affix.id == affixId) {
        return affix;
      }
    }

    throw StateError('Affix not found: $affixId');
  }

  List<AffixConfig> candidatesFor({
    required int level,
    required Iterable<String> allowedTags,
  }) {
    final tagSet = allowedTags.toSet();
    return [
      for (final affix in _affixes)
        if (_isEligible(affix: affix, level: level, allowedTags: tagSet)) affix,
    ];
  }

  List<RolledAffix> rollAffixes({
    required int level,
    required Iterable<String> allowedTags,
    required int count,
    required int seed,
  }) {
    if (count <= 0) {
      return const [];
    }

    final random = Random(seed);
    final selectedIds = <String>{};
    final blockedGroups = <String>{};
    final rolled = <RolledAffix>[];

    for (var index = 0; index < count; index += 1) {
      final candidates = [
        for (final affix
            in candidatesFor(level: level, allowedTags: allowedTags))
          if (!selectedIds.contains(affix.id) &&
              !_isBlockedByGroup(affix, blockedGroups))
            affix,
      ];

      if (candidates.isEmpty) {
        break;
      }

      final affix = _pickWeighted(candidates, random);
      selectedIds.add(affix.id);
      final exclusiveGroup = affix.exclusiveGroup;
      if (exclusiveGroup != null) {
        blockedGroups.add(exclusiveGroup);
      }

      rolled.add(RolledAffix(
        affixId: affix.id,
        rollValue: affix.rollRange?.roll(random),
        exclusiveGroup: exclusiveGroup,
      ));
    }

    return rolled;
  }

  bool _isEligible({
    required AffixConfig affix,
    required int level,
    required Set<String> allowedTags,
  }) {
    if (level < affix.minLevel || affix.weight <= 0) {
      return false;
    }

    if (allowedTags.isEmpty) {
      return true;
    }

    return affix.tags.any(allowedTags.contains);
  }

  bool _isBlockedByGroup(AffixConfig affix, Set<String> blockedGroups) {
    final exclusiveGroup = affix.exclusiveGroup;
    return exclusiveGroup != null && blockedGroups.contains(exclusiveGroup);
  }

  AffixConfig _pickWeighted(List<AffixConfig> candidates, Random random) {
    final totalWeight = candidates.fold<int>(
      0,
      (sum, affix) => sum + affix.weight,
    );
    final target = random.nextDouble() * totalWeight;
    var cursor = 0.0;

    for (final affix in candidates) {
      cursor += affix.weight;
      if (target < cursor) {
        return affix;
      }
    }

    return candidates.last;
  }
}
