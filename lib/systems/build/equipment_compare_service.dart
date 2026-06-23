import '../../models/equipment_instance.dart';
import 'build_score_service.dart';
import 'build_service.dart';

class EquipmentCompareService {
  const EquipmentCompareService({
    required BuildScoreService scoreService,
  }) : _scoreService = scoreService;

  final BuildScoreService _scoreService;

  EquipmentComparison compare({
    required EquipmentInstance candidate,
    required EquipmentInstance? equipped,
    required BuildAssessment assessment,
  }) {
    final candidateScore = _scoreService.scoreEquipment(
      equipment: candidate,
      assessment: assessment,
    );
    final equippedScore = equipped == null
        ? null
        : _scoreService.scoreEquipment(
            equipment: equipped,
            assessment: assessment,
          );
    final matchScoreDelta =
        candidateScore.matchScore - (equippedScore?.matchScore ?? 0);
    final attackDelta =
        candidateScore.attackScore - (equippedScore?.attackScore ?? 0);

    return EquipmentComparison(
      candidateScore: candidateScore,
      equippedScore: equippedScore,
      matchScoreDelta: matchScoreDelta,
      attackDelta: attackDelta,
      recommendation: _recommendationFor(
        matchScoreDelta: matchScoreDelta,
        equippedScore: equippedScore,
      ),
    );
  }

  EquipmentRecommendation _recommendationFor({
    required double matchScoreDelta,
    required EquipmentBuildScore? equippedScore,
  }) {
    if (equippedScore == null) {
      return EquipmentRecommendation.upgrade;
    }

    if (matchScoreDelta >= 4) {
      return EquipmentRecommendation.upgrade;
    }

    if (matchScoreDelta <= -4) {
      return EquipmentRecommendation.downgrade;
    }

    return EquipmentRecommendation.sidegrade;
  }
}

class EquipmentComparison {
  const EquipmentComparison({
    required this.candidateScore,
    required this.equippedScore,
    required this.matchScoreDelta,
    required this.attackDelta,
    required this.recommendation,
  });

  final EquipmentBuildScore candidateScore;
  final EquipmentBuildScore? equippedScore;
  final double matchScoreDelta;
  final double attackDelta;
  final EquipmentRecommendation recommendation;
}

enum EquipmentRecommendation {
  upgrade,
  sidegrade,
  downgrade,
}
