import 'package:abyss_relic/models/data_file_meta.dart';
import 'package:abyss_relic/models/loaded_data_file.dart';
import 'package:abyss_relic/models/loot_drop.dart';
import 'package:abyss_relic/systems/config/game_database.dart';
import 'package:abyss_relic/systems/drop/drop_pool_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DropPoolService rolls deterministic drops by seed', () {
    final service = DropPoolService(_database());

    final first = service.roll(poolId: 'chapter_1', seed: 42);
    final second = service.roll(poolId: 'chapter_1', seed: 42);

    expect(first.map((drop) => drop.refId), second.map((drop) => drop.refId));
    expect(first.map((drop) => drop.quantity),
        second.map((drop) => drop.quantity));
  });

  test('DropPoolService respects weight and quantity range', () {
    final service = DropPoolService(_database());

    final drops = [
      for (var seed = 1; seed <= 20; seed += 1)
        service.roll(poolId: 'chapter_1', seed: seed).single,
    ];

    expect(drops.map((drop) => drop.refId), everyElement('iron'));
    expect(drops.map((drop) => drop.type), everyElement(LootDropType.material));
    expect(drops.map((drop) => drop.quantity),
        everyElement(allOf(greaterThanOrEqualTo(2), lessThanOrEqualTo(4))));
  });

  test('DropPoolService maps unsupported types as other drops', () {
    final service = DropPoolService(_database());

    final drop = service.roll(poolId: 'soul_pool', seed: 1).single;

    expect(drop.type, LootDropType.other);
    expect(drop.refId, 'core_plague_heart');
  });

  test('DropPoolService preserves equipment quantity rolls', () {
    final service = DropPoolService(_database());

    final drop = service.roll(poolId: 'equipment_pool', seed: 1).single;

    expect(drop.type, LootDropType.equipment);
    expect(drop.refId, 'rusted_blade');
    expect(drop.quantity, 2);
  });

  test('DropPoolService rejects missing pools', () {
    final service = DropPoolService(_database());

    expect(
      () => service.roll(poolId: 'missing', seed: 1),
      throwsA(isA<StateError>()),
    );
  });
}

GameDatabase _database() {
  return GameDatabase.fromFiles([
    LoadedDataFile(
      meta: const DataFileMeta(
        assetPath: 'assets/data/drop_pools.json',
        schemaVersion: 1,
        recordCount: 3,
        topLevelKeys: ['schemaVersion', 'drop_pools'],
      ),
      json: {
        'schemaVersion': 1,
        'drop_pools': [
          {
            'id': 'chapter_1',
            'name': 'Chapter 1',
            'entries': [
              {
                'type': 'equipment',
                'refId': 'rusted_blade',
                'weight': 0,
                'minQty': 1,
                'maxQty': 1,
              },
              {
                'type': 'material',
                'refId': 'iron',
                'weight': 100,
                'minQty': 2,
                'maxQty': 4,
              },
            ],
          },
          {
            'id': 'soul_pool',
            'name': 'Soul Pool',
            'entries': [
              {
                'type': 'soul_core',
                'refId': 'core_plague_heart',
                'weight': 100,
                'minQty': 1,
                'maxQty': 1,
              },
            ],
          },
          {
            'id': 'equipment_pool',
            'name': 'Equipment Pool',
            'entries': [
              {
                'type': 'equipment',
                'refId': 'rusted_blade',
                'weight': 100,
                'minQty': 2,
                'maxQty': 2,
              },
            ],
          },
        ],
      },
    ),
  ]);
}
