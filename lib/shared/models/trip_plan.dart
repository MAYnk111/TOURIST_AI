import 'itinerary_day.dart';
import 'budget_breakdown.dart';

class TripPlan {
  final String id;
  final String title;
  final String destination;
  final String startDate;
  final String endDate;
  final int travelersCount;
  final double budgetPerPerson;
  final double totalBudget;
  final List<String> interests;
  final List<ItineraryDay> days;
  final BudgetBreakdown budget;
  final bool isSaved;
  final List<String> constraintWarnings;
  final Map<String, dynamic> dataProvenance;
  final List<String> assumptions;
  final double totalRouteDistanceKm;
  final double totalRouteDurationMinutes;

  const TripPlan({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travelersCount,
    required this.budgetPerPerson,
    required this.totalBudget,
    required this.interests,
    required this.days,
    required this.budget,
    this.isSaved = false,
    this.constraintWarnings = const [],
    this.dataProvenance = const {},
    this.assumptions = const [],
    this.totalRouteDistanceKm = 0.0,
    this.totalRouteDurationMinutes = 0.0,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Your Goa Trip',
      destination: json['destination'] ?? 'Goa, India',
      startDate: json['start_date'] ?? json['startDate'] ?? 'Jan 10, 2025',
      endDate: json['end_date'] ?? json['endDate'] ?? 'Jan 12, 2025',
      travelersCount: (json['travelers_count'] ?? json['travelersCount'] as num?)?.toInt() ?? 2,
      budgetPerPerson: (json['budget_per_person'] ?? json['budgetPerPerson'] as num?)?.toDouble() ?? 15000.0,
      totalBudget: (json['total_budget'] ?? json['totalBudget'] as num?)?.toDouble() ?? 30000.0,
      interests: List<String>.from(json['interests'] ?? ['Beaches', 'Food']),
      days: (json['days'] as List? ?? [])
          .map((d) => ItineraryDay.fromJson(d))
          .toList(),
      budget: BudgetBreakdown.fromJson(json['budget'] ?? {}),
      isSaved: json['is_saved'] ?? json['isSaved'] ?? false,
      constraintWarnings: List<String>.from(json['constraint_warnings'] ?? []),
      dataProvenance: Map<String, dynamic>.from(json['data_provenance'] ?? {}),
      assumptions: List<String>.from(json['assumptions'] ?? []),
      totalRouteDistanceKm: (json['total_route_distance_km'] as num?)?.toDouble() ?? 0.0,
      totalRouteDurationMinutes: (json['total_route_duration_minutes'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'start_date': startDate,
      'end_date': endDate,
      'travelers_count': travelersCount,
      'budget_per_person': budgetPerPerson,
      'total_budget': totalBudget,
      'interests': interests,
      'days': days.map((d) => d.toJson()).toList(),
      'budget': budget.toJson(),
      'is_saved': isSaved,
      'constraint_warnings': constraintWarnings,
      'data_provenance': dataProvenance,
      'assumptions': assumptions,
      'total_route_distance_km': totalRouteDistanceKm,
      'total_route_duration_minutes': totalRouteDurationMinutes,
    };
  }

  TripPlan copyWith({
    String? id,
    String? title,
    String? destination,
    String? startDate,
    String? endDate,
    int? travelersCount,
    double? budgetPerPerson,
    double? totalBudget,
    List<String>? interests,
    List<ItineraryDay>? days,
    BudgetBreakdown? budget,
    bool? isSaved,
    List<String>? constraintWarnings,
    Map<String, dynamic>? dataProvenance,
    List<String>? assumptions,
    double? totalRouteDistanceKm,
    double? totalRouteDurationMinutes,
  }) {
    return TripPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelersCount: travelersCount ?? this.travelersCount,
      budgetPerPerson: budgetPerPerson ?? this.budgetPerPerson,
      totalBudget: totalBudget ?? this.totalBudget,
      interests: interests ?? this.interests,
      days: days ?? this.days,
      budget: budget ?? this.budget,
      isSaved: isSaved ?? this.isSaved,
      constraintWarnings: constraintWarnings ?? this.constraintWarnings,
      dataProvenance: dataProvenance ?? this.dataProvenance,
      assumptions: assumptions ?? this.assumptions,
      totalRouteDistanceKm: totalRouteDistanceKm ?? this.totalRouteDistanceKm,
      totalRouteDurationMinutes: totalRouteDurationMinutes ?? this.totalRouteDurationMinutes,
    );
  }
}
