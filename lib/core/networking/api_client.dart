import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../shared/models/destination.dart';
import '../../shared/models/attraction.dart';
import '../../shared/models/trip_plan.dart';
import '../../shared/models/budget_breakdown.dart';
import '../../shared/models/recommendation_result.dart';
import '../data/sample_data.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getProviderStatus() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/providers/status'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'active_provider': 'Local Verified Dataset (Backend Offline)',
      'is_live_data': false,
      'attribution': 'Curated Indian Tourism Records',
    };
  }

  Future<List<Destination>> getDestinations() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/destinations'))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Destination.fromJson(json)).toList();
      }
    } catch (_) {}
    return SampleData.popularDestinations;
  }

  Future<List<Destination>> searchDestinations(String query) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return SampleData.popularDestinations;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/destinations/search')
          .replace(queryParameters: {'q': cleanQ});
      final response = await _client.get(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Destination.fromJson(json)).toList();
      }
    } catch (_) {}

    final q = cleanQ.toLowerCase();
    return SampleData.popularDestinations
        .where((d) => d.name.toLowerCase().contains(q) || d.state.toLowerCase().contains(q))
        .toList();
  }

  Future<List<Attraction>> getAttractions({
    String destinationId = 'goa',
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    final cleanId = destinationId.toLowerCase().split(',')[0].trim().replaceAll(RegExp(r'\s+'), '_');
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      if (latitude != null && longitude != null && latitude != 0.0 && longitude != 0.0) {
        queryParams['lat'] = latitude.toString();
        queryParams['lon'] = longitude.toString();
      }

      var uri = Uri.parse('${ApiConfig.baseUrl}/destinations/$cleanId/attractions');
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Attraction.fromJson(json)).toList();
      }
    } catch (_) {}

    // Fallback verified data ONLY for Goa if requested, never for other destinations
    if (cleanId == 'goa') {
      if (category != null && category != 'All') {
        return SampleData.goaAttractions
            .where((a) => a.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
      return SampleData.goaAttractions;
    }
    return [];
  }

  Future<List<Attraction>> searchAttractions(String query) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return [];

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/attractions/search')
          .replace(queryParameters: {'q': cleanQ});
      final response = await _client.get(uri).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Attraction.fromJson(json)).toList();
      }
    } catch (_) {}

    final q = cleanQ.toLowerCase();
    if (q.contains('goa') || q.contains('beach')) {
      return SampleData.goaAttractions
          .where((a) => a.name.toLowerCase().contains(q) || a.category.toLowerCase().contains(q))
          .toList();
    }
    return [];
  }

  Future<BudgetBreakdown> estimateCost({
    required String destination,
    required int days,
    required int travelers,
    required double userBudget,
    String travelStyle = 'balanced',
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/trips/estimate-cost'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'destination': destination,
              'days': days,
              'travelers': travelers,
              'travel_style': travelStyle,
              'user_budget': userBudget,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return BudgetBreakdown.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}

    // Rule-based fallback calculation
    final total = 14200.0;
    return BudgetBreakdown(
      accommodation: 5000,
      foodDrinks: 3200,
      transport: 2500,
      activities: 2800,
      miscellaneous: 700,
      totalEstimated: total,
      userBudget: userBudget > 0 ? userBudget : 15000,
      isWithinBudget: total <= (userBudget > 0 ? userBudget : 15000),
    );
  }

  Future<RecommendationResponseModel?> getPersonalizedRecommendations({
    required String destination,
    required int durationDays,
    required List<String> interests,
    required double budgetPerPerson,
    required int travelersCount,
    String travelIntensity = 'moderate',
    bool familyFriendly = false,
    bool accessibilityRequired = false,
    List<String> exclusions = const [],
    int topK = 6,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/recommendations/personalized'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'destination': destination,
              'duration_days': durationDays,
              'interests': interests,
              'budget_per_person': budgetPerPerson,
              'travelers_count': travelersCount,
              'travel_intensity': travelIntensity,
              'family_friendly': familyFriendly,
              'accessibility_required': accessibilityRequired,
              'exclusions': exclusions,
              'top_k': topK,
              if (latitude != null) 'latitude': latitude,
              if (longitude != null) 'longitude': longitude,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return RecommendationResponseModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<TripPlan> generateItinerary({
    required String destination,
    required String startDate,
    required String endDate,
    required int travelers,
    required double budgetPerPerson,
    required List<String> interests,
    String travelIntensity = 'moderate',
    List<String> exclusions = const [],
    List<String>? selectedAttractionIds,
    bool familyFriendly = false,
    bool accessibilityRequired = false,
    bool mealBreaks = true,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/trips/generate-itinerary'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'destination': destination,
              'start_date': startDate,
              'end_date': endDate,
              'travelers': travelers,
              'budget_per_person': budgetPerPerson,
              'interests': interests,
              'travel_intensity': travelIntensity,
              'exclusions': exclusions,
              'selected_attraction_ids': selectedAttractionIds,
              'family_friendly': familyFriendly,
              'accessibility_required': accessibilityRequired,
              'meal_breaks': mealBreaks,
              if (latitude != null) 'latitude': latitude,
              if (longitude != null) 'longitude': longitude,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return TripPlan.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      // Allow fallback ONLY if Goa was explicitly planned and offline
      if (destination.toLowerCase().contains('goa')) {
        return SampleData.getDefaultGoaTrip();
      }
      rethrow;
    }

    if (destination.toLowerCase().contains('goa')) {
      return SampleData.getDefaultGoaTrip();
    }
    throw Exception('Failed to generate itinerary for $destination');
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required List<Map<String, dynamic>> history,
    String? destination,
    int? travelers,
    double? budgetPerPerson,
    List<String>? interests,
    String? dates,
  }) async {
    try {
      final payload = <String, dynamic>{
        'message': message,
        'history': history,
        if (destination != null) 'destination': destination,
        if (travelers != null) 'travelers': travelers,
        if (budgetPerPerson != null) 'budget_per_person': budgetPerPerson,
        if (interests != null) 'interests': interests,
        if (dates != null) 'dates': dates,
      };

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/assistant/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    return {
      'reply': 'I could not connect to the travel assistant service. Please check your internet connection or verify the backend server at ${ApiConfig.serverUrl}.',
      'attractions': null,
      'cost_summary_text': null,
      'show_view_itinerary': false,
      'grounded_sources': ['Network Connection Notice'],
    };
  }

  Future<String?> saveTripRemote(TripPlan trip, {String userId = 'usr_mayank'}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/trips?user_id=$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(trip.toJson()),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['trip_id'];
      }
    } catch (_) {}
    return null;
  }

  Future<TripPlan?> getTrip(String tripId, {String userId = 'usr_mayank'}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/trips/$tripId?user_id=$userId'),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return TripPlan.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> updateTrip(TripPlan trip, {String userId = 'usr_mayank'}) async {
    try {
      final response = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}/trips/${trip.id}?user_id=$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(trip.toJson()),
          )
          .timeout(ApiConfig.timeout);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> deleteTrip(String tripId, {String userId = 'usr_mayank'}) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/trips/$tripId?user_id=$userId'),
          )
          .timeout(ApiConfig.timeout);
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
