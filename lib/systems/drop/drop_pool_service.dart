import 'dart:math';

import '../../models/loot_drop.dart';
import '../config/game_database.dart';

class DropPoolService {
  const DropPoolService(this._database);

  final GameDatabase _database;

  List<LootDrop> roll({
    required String poolId,
    required int seed,
  }) {
    final pool = _database.findRecord('drop_pools', poolId);
    if (pool == null) {
      throw StateError('Drop pool not found: $poolId');
    }

    final entries = [
      for (final entry in pool['entries'] as List? ?? const [])
        DropPoolEntry.fromJson(Map<String, Object?>.from(entry as Map)),
    ].where((entry) => entry.weight > 0).toList();
    if (entries.isEmpty) {
      return const [];
    }

    final random = Random(seed);
    final entry = _pickWeighted(entries, random);
    final quantity = entry.rollQuantity(random);

    return [
      _dropFor(entry: entry, quantity: quantity),
    ];
  }

  DropPoolEntry _pickWeighted(List<DropPoolEntry> entries, Random random) {
    final totalWeight = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.weight,
    );
    final target = random.nextDouble() * totalWeight;
    var cursor = 0.0;

    for (final entry in entries) {
      cursor += entry.weight;
      if (target < cursor) {
        return entry;
      }
    }

    return entries.last;
  }

  LootDrop _dropFor({
    required DropPoolEntry entry,
    required int quantity,
  }) {
    switch (entry.type) {
      case 'equipment':
        return LootDrop.equipment(instanceId: entry.refId);
      case 'material':
        return LootDrop.material(materialId: entry.refId, quantity: quantity);
      default:
        return LootDrop.other(
          type: entry.type,
          refId: entry.refId,
          quantity: quantity,
        );
    }
  }
}

class DropPoolEntry {
  const DropPoolEntry({
    required this.type,
    required this.refId,
    required this.weight,
    required this.minQty,
    required this.maxQty,
  });

  factory DropPoolEntry.fromJson(Map<String, Object?> json) {
    return DropPoolEntry(
      type: json['type'] as String,
      refId: json['refId'] as String,
      weight: json['weight'] as int,
      minQty: json['minQty'] as int? ?? 1,
      maxQty: json['maxQty'] as int? ?? 1,
    );
  }

  final String type;
  final String refId;
  final int weight;
  final int minQty;
  final int maxQty;

  int rollQuantity(Random random) {
    if (maxQty <= minQty) {
      return minQty;
    }

    return minQty + random.nextInt(maxQty - minQty + 1);
  }
}
