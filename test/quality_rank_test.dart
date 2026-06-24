import 'package:abyss_relic/systems/equipment/quality_rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quality rank follows the canonical order', () {
    expect(qualityRank('normal'), lessThan(qualityRank('magic')));
    expect(qualityRank('magic'), lessThan(qualityRank('rare')));
    expect(qualityRank('rare'), lessThan(qualityRank('epic')));
    expect(qualityRank('epic'), lessThan(qualityRank('legendary')));
    expect(qualityRank('legendary'), lessThan(qualityRank('ancient')));
    expect(qualityRank('ancient'), lessThan(qualityRank('mythic')));
    expect(qualityRank('mythic'), lessThan(qualityRank('abyss')));
  });

  test('legacy forbidden quality is ranked as ancient compatibility', () {
    expect(qualityRank('forbidden'), qualityRank('ancient'));
  });
}
