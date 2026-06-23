import 'package:abyss_relic/systems/config/data_loader.dart';
import 'package:abyss_relic/systems/config/game_database_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed data loads into GameDatabase without config issues', () async {
    final result = await const GameDatabaseService(
      dataLoader: DataLoader(),
    ).loadDataDirectory();

    expect(result.issues, isEmpty);
    expect(result.database.findRecord('classes', 'exile'), isNotNull);
    expect(result.database.findRecord('classes', 'necrospeaker'), isNotNull);
    expect(result.database.findRecord('classes', 'ember_mage'), isNotNull);
    expect(result.database.findRecord('classes', 'frost_ranger'), isNotNull);
    expect(result.database.findRecord('classes', 'sanctifier'), isNotNull);
    expect(result.database.findRecord('skills', 'toxic_slash'), isNotNull);
    expect(
      result.database.findRecord('drop_pools', 'drop_chapter_1'),
      isNotNull,
    );
  });
}
