String statLabel(String statId) {
  switch (statId) {
    case 'hp':
      return '生命';
    case 'attack':
      return '攻击';
    case 'armor':
      return '护甲';
    case 'crit_chance':
      return '暴击率';
    case 'crit_damage':
      return '暴击伤害';
    case 'attack_speed':
      return '攻击速度';
    case 'poison_damage':
      return '毒素伤害';
    case 'fire_damage':
      return '火焰伤害';
    case 'frost_damage':
      return '冰霜伤害';
    case 'shadow_damage':
      return '暗影伤害';
    case 'holy_damage':
      return '圣光伤害';
    case 'summon_damage':
      return '召唤伤害';
    case 'block_chance':
      return '格挡率';
    case 'shield':
      return '护盾';
  }
  return statId;
}

String tagLabel(String tagId) {
  switch (tagId) {
    case 'poison':
      return '毒素';
    case 'bleed':
      return '流血';
    case 'shadow':
      return '暗影';
    case 'low_hp':
      return '低生命';
    case 'summon':
      return '召唤';
    case 'curse':
      return '诅咒';
    case 'shield':
      return '护盾';
    case 'undead':
      return '亡骨';
    case 'fire':
      return '火焰';
    case 'burn':
      return '燃烧';
    case 'spell':
      return '法术';
    case 'burst':
      return '爆发';
    case 'frost':
      return '冰霜';
    case 'crit':
      return '暴击';
    case 'ranged':
      return '远程';
    case 'control':
      return '控制';
    case 'holy':
      return '圣光';
    case 'block':
      return '格挡';
    case 'heal':
      return '治疗';
    case 'judgement':
      return '审判';
    case 'melee':
      return '近战';
    case 'physical':
      return '物理';
    case 'beast':
      return '野兽';
    case 'fast':
      return '迅捷';
    case 'human':
      return '人类';
    case 'demon':
      return '恶魔';
    case 'abyss':
      return '深渊';
    case 'training':
      return '训练';
    case 'dummy':
      return '假人';
    case 'elite':
      return '精英';
    case 'plague':
      return '瘟疫';
    case 'blood':
      return '血月';
    case 'cultist':
      return '信徒';
    case 'ash':
      return '灰烬';
    case 'spirit':
      return '灵体';
    case 'boss':
      return '首领';
    case 'corrupted':
      return '腐化';
  }
  return tagId;
}

String slotLabel(String slotId) {
  switch (slotId) {
    case 'weapon':
      return '武器';
    case 'offhand':
      return '副手';
    case 'helmet':
      return '头盔';
    case 'chest':
      return '胸甲';
    case 'gloves':
      return '手套';
    case 'boots':
      return '靴子';
    case 'ring':
      return '戒指';
    case 'amulet':
      return '护符';
  }
  return slotId;
}
