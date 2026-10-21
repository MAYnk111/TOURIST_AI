import 'attraction.dart';
import 'budget_breakdown.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Attraction>? attractionRecommendations;
  final BudgetBreakdown? budgetSummary;
  final String? budgetSummaryText;
  final bool showViewItineraryAction;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.attractionRecommendations,
    this.budgetSummary,
    this.budgetSummaryText,
    this.showViewItineraryAction = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
