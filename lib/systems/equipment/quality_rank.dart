const qualityOrder = [
  'normal',
  'magic',
  'rare',
  'epic',
  'legendary',
  'ancient',
  'mythic',
  'abyss',
];

int qualityRank(String qualityId) {
  final normalized = qualityId == 'forbidden' ? 'ancient' : qualityId;
  final index = qualityOrder.indexOf(normalized);
  return index < 0 ? 0 : index;
}

bool isLegendaryOrAbove(String qualityId) {
  return qualityRank(qualityId) >= qualityRank('legendary');
}
