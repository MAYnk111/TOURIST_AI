class BudgetBreakdown {
  final double accommodation;
  final double foodDrinks;
  final double transport;
  final double activities;
  final double miscellaneous;
  final double totalEstimated;
  final double userBudget;
  final bool isWithinBudget;
  final double costPerPerson;
  final double groupBudget;
  final double budgetPerPerson;
  final double budgetDifference;
  final int days;
  final int nights;
  final int travelers;
  final bool isExperimental;
  final String modelBasis;
  final double knownFeesTotal;
  final int unknownFeesCount;
  final List<String> calculationAssumptions;

  const BudgetBreakdown({
    required this.accommodation,
    required this.foodDrinks,
    required this.transport,
    required this.activities,
    required this.miscellaneous,
    required this.totalEstimated,
    required this.userBudget,
    required this.isWithinBudget,
    this.costPerPerson = 0.0,
    this.groupBudget = 0.0,
    this.budgetPerPerson = 15000.0,
    this.budgetDifference = 0.0,
    this.days = 3,
    this.nights = 2,
    this.travelers = 2,
    this.isExperimental = true,
    this.modelBasis = 'ML Random Forest / Verified Category Pricing',
    this.knownFeesTotal = 0.0,
    this.unknownFeesCount = 0,
    this.calculationAssumptions = const [],
  });

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) {
    final total = (json['total_estimated'] ?? json['totalEstimated'] as num?)?.toDouble() ?? 14200.0;
    final trav = (json['travelers'] as num?)?.toInt() ?? 2;
    final bpp = (json['budget_per_person'] ?? json['budgetPerPerson'] as num?)?.toDouble() ?? 15000.0;
    final gBudget = (json['group_budget'] ?? json['groupBudget'] ?? json['user_budget'] ?? json['userBudget'] as num?)?.toDouble() ?? (bpp * trav);
    final isWithin = json['is_within_budget'] ?? json['isWithinBudget'] ?? (total <= gBudget);
    final diff = (json['budget_difference'] ?? json['budgetDifference'] as num?)?.toDouble() ?? (gBudget - total).abs();
    final cpp = (json['cost_per_person'] ?? json['costPerPerson'] as num?)?.toDouble() ?? (trav > 0 ? total / trav : total);

    return BudgetBreakdown(
      accommodation: (json['accommodation'] as num?)?.toDouble() ?? 5000.0,
      foodDrinks: (json['food_drinks'] ?? json['foodDrinks'] as num?)?.toDouble() ?? 3200.0,
      transport: (json['transport'] as num?)?.toDouble() ?? 2500.0,
      activities: (json['activities'] as num?)?.toDouble() ?? 2800.0,
      miscellaneous: (json['miscellaneous'] as num?)?.toDouble() ?? 700.0,
      totalEstimated: total,
      userBudget: gBudget,
      isWithinBudget: isWithin,
      costPerPerson: cpp,
      groupBudget: gBudget,
      budgetPerPerson: bpp,
      budgetDifference: diff,
      days: (json['days'] as num?)?.toInt() ?? 3,
      nights: (json['nights'] as num?)?.toInt() ?? 2,
      travelers: trav,
      isExperimental: json['is_experimental'] ?? json['isExperimental'] ?? true,
      modelBasis: json['model_basis'] ?? json['modelBasis'] ?? 'ML Random Forest / Verified Category Pricing',
      knownFeesTotal: (json['known_fees_total'] ?? json['knownFeesTotal'] as num?)?.toDouble() ?? 0.0,
      unknownFeesCount: (json['unknown_fees_count'] ?? json['unknownFeesCount'] as num?)?.toInt() ?? 0,
      calculationAssumptions: List<String>.from(json['calculation_assumptions'] ?? json['calculationAssumptions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accommodation': accommodation,
      'food_drinks': foodDrinks,
      'transport': transport,
      'activities': activities,
      'miscellaneous': miscellaneous,
      'total_estimated': totalEstimated,
      'user_budget': userBudget,
      'is_within_budget': isWithinBudget,
      'cost_per_person': costPerPerson,
      'group_budget': groupBudget,
      'budget_per_person': budgetPerPerson,
      'budget_difference': budgetDifference,
      'days': days,
      'nights': nights,
      'travelers': travelers,
      'is_experimental': isExperimental,
      'model_basis': modelBasis,
      'known_fees_total': knownFeesTotal,
      'unknown_fees_count': unknownFeesCount,
      'calculation_assumptions': calculationAssumptions,
    };
  }

  double get accommodationPct => totalEstimated > 0 ? (accommodation / totalEstimated) * 100 : 0;
  double get foodDrinksPct => totalEstimated > 0 ? (foodDrinks / totalEstimated) * 100 : 0;
  double get transportPct => totalEstimated > 0 ? (transport / totalEstimated) * 100 : 0;
  double get activitiesPct => totalEstimated > 0 ? (activities / totalEstimated) * 100 : 0;
  double get miscellaneousPct => totalEstimated > 0 ? (miscellaneous / totalEstimated) * 100 : 0;
}
