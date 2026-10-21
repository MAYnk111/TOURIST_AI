import 'attraction.dart';

class RecommendationItemModel {
  final Attraction attraction;
  final double score;
  final String sourceId;
  final String explanation;
  final Map<String, dynamic> matchFactors;
  final List<String> uncertainties;

  const RecommendationItemModel({
    required this.attraction,
    required this.score,
    required this.sourceId,
    required this.explanation,
    this.matchFactors = const {},
    this.uncertainties = const [],
  });

  factory RecommendationItemModel.fromJson(Map<String, dynamic> json) {
    return RecommendationItemModel(
      attraction: Attraction.fromJson(json['attraction'] ?? {}),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      sourceId: json['source_id'] ?? '',
      explanation: json['explanation'] ?? '',
      matchFactors: Map<String, dynamic>.from(json['match_factors'] ?? {}),
      uncertainties: List<String>.from(json['uncertainties'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attraction': attraction.toJson(),
      'score': score,
      'source_id': sourceId,
      'explanation': explanation,
      'match_factors': matchFactors,
      'uncertainties': uncertainties,
    };
  }
}

class RecommendationResponseModel {
  final String destination;
  final List<RecommendationItemModel> items;
  final Map<String, dynamic> scoringWeights;
  final int totalCandidatesAnalyzed;

  const RecommendationResponseModel({
    required this.destination,
    required this.items,
    this.scoringWeights = const {},
    this.totalCandidatesAnalyzed = 0,
  });

  factory RecommendationResponseModel.fromJson(Map<String, dynamic> json) {
    return RecommendationResponseModel(
      destination: json['destination'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => RecommendationItemModel.fromJson(i))
          .toList(),
      scoringWeights: Map<String, dynamic>.from(json['scoring_weights'] ?? {}),
      totalCandidatesAnalyzed: (json['total_candidates_analyzed'] as num?)?.toInt() ?? 0,
    );
  }
}
