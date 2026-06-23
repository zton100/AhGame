class LootDrop {
  const LootDrop._({
    required this.type,
    required this.refId,
    required this.quantity,
  });

  const LootDrop.equipment({
    required String instanceId,
  }) : this._(
          type: LootDropType.equipment,
          refId: instanceId,
          quantity: 1,
        );

  const LootDrop.material({
    required String materialId,
    required int quantity,
  }) : this._(
          type: LootDropType.material,
          refId: materialId,
          quantity: quantity,
        );

  const LootDrop.other({
    required String type,
    required String refId,
    required int quantity,
  }) : this._(
          type: LootDropType.other,
          refId: refId,
          quantity: quantity,
        );

  final LootDropType type;
  final String refId;
  final int quantity;
}

enum LootDropType {
  equipment,
  material,
  other,
}
