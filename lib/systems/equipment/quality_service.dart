import '../../models/quality_config.dart';
import '../config/game_database.dart';
import 'quality_rank.dart';

class QualityService {
  const QualityService(this._database);

  final GameDatabase _database;

  List<QualityConfig> listQualities() {
    final configured = _database
        .recordsForTable('qualities')
        .values
        .map(QualityConfig.fromJson)
        .toList();
    configured.sort((a, b) => qualityRank(a.id).compareTo(qualityRank(b.id)));
    return List.unmodifiable(configured);
  }

  QualityConfig? findQuality(String qualityId) {
    final record = _database.findRecord('qualities', qualityId);
    return record == null ? null : QualityConfig.fromJson(record);
  }

  QualityConfig requireQuality(String qualityId) {
    final quality = findQuality(qualityId);
    if (quality == null) {
      throw StateError('Quality config not found: $qualityId');
    }

    return quality;
  }
}
