import 'package:abyss_relic/systems/config/config_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ConfigLoader reads registered asset data', () async {
    const loader = ConfigLoader();

    final raw = await loader.loadRaw('assets/data/app_config.json');

    expect(raw, contains('"id": "abyss_relic"'));
    expect(raw, contains('"schemaVersion": 1'));
  });
}
