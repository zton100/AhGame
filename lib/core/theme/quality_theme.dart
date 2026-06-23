import 'package:flutter/material.dart';

enum EquipmentQuality {
  normal('normal', '普通', Color(0xFFB7BEC9)),
  magic('magic', '魔法', Color(0xFF5CA7F2)),
  rare('rare', '稀有', Color(0xFFD6B84A)),
  epic('epic', '史诗', Color(0xFFB36EF0)),
  legendary('legendary', '传奇', Color(0xFFE18A3B)),
  mythic('mythic', '神话', Color(0xFFE34F63)),
  abyss('abyss', '深渊', Color(0xFF35D0C2)),
  forbidden('forbidden', '禁忌', Color(0xFF9B1C31));

  const EquipmentQuality(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;
}
