import '../screens/trash_pickups/trash_pickup_model.dart';

class SegregationAccuracyResult {
  final double score;
  final String statusMessage;
  final String shortLabel;
  final int totalPickups;
  final int properlyDocumentedPickups;

  const SegregationAccuracyResult({
    required this.score,
    required this.statusMessage,
    required this.shortLabel,
    required this.totalPickups,
    required this.properlyDocumentedPickups,
  });
}

class SegregationAccuracyService {
  static SegregationAccuracyResult fromPickups(List<TrashPickup> pickups) {
    final totalPickups = pickups.length;
    if (totalPickups == 0) {
      return const SegregationAccuracyResult(
        score: 0,
        statusMessage: 'Segregation accuracy is low. Ensure proper waste type selection, weight recording, and photo proof.',
        shortLabel: 'Low segregation accuracy',
        totalPickups: 0,
        properlyDocumentedPickups: 0,
      );
    }

    final properlyDocumentedPickups = pickups.where(_isProperlyDocumented).length;
    final score = (properlyDocumentedPickups / totalPickups) * 100;

    return SegregationAccuracyResult(
      score: score,
      statusMessage: _statusMessageForScore(score),
      shortLabel: _shortLabelForScore(score),
      totalPickups: totalPickups,
      properlyDocumentedPickups: properlyDocumentedPickups,
    );
  }

  static bool _isProperlyDocumented(TrashPickup pickup) {
    final hasValidWasteType = pickup.wasteType.trim().isNotEmpty;
    final hasActualWeight = (pickup.actualWeightKg ?? 0) > 0;
    final hasPhotoProof = pickup.proofImageUrl?.trim().isNotEmpty ?? false;

    return hasValidWasteType && hasActualWeight && hasPhotoProof;
  }

  static String _statusMessageForScore(double score) {
    if (score >= 80) {
      return 'Good segregation practice detected.';
    }
    if (score >= 50) {
      return 'Segregation is improving, but more consistency is needed.';
    }
    return 'Segregation accuracy is low. Ensure proper waste type selection, weight recording, and photo proof.';
  }

  static String _shortLabelForScore(double score) {
    if (score >= 80) return 'Good segregation';
    if (score >= 50) return 'Segregation improving';
    return 'Low segregation accuracy';
  }
}
