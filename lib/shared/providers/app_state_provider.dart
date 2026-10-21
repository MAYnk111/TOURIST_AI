import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/destination.dart';
import '../models/attraction.dart';
import '../models/trip_plan.dart';
import '../models/budget_breakdown.dart';
import '../models/itinerary_day.dart';
import '../models/timeline_stop.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/recommendation_result.dart';
import '../../core/data/sample_data.dart';
import '../../core/networking/api_client.dart';
import '../../core/services/auth_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  // Navigation
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // Authentication & Session
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isAuthLoading = true;
  bool get isAuthLoading => _isAuthLoading;

  UserProfile _userProfile = UserProfile.defaultUser();
  UserProfile get userProfile => _userProfile;

  // Destinations & Attractions
  List<Destination> _destinations = SampleData.popularDestinations;
  List<Destination> get destinations => _destinations;

  List<Destination> _searchedDestinations = [];
  List<Destination> get searchedDestinations => _searchedDestinations;

  bool _isSearchingDestinations = false;
  bool get isSearchingDestinations => _isSearchingDestinations;

  final List<Attraction> _allAttractions = SampleData.goaAttractions;
  List<Attraction> get allAttractions => _allAttractions;

  List<Attraction> _destinationAttractions = [];
  List<Attraction> get destinationAttractions => _destinationAttractions;

  String _currentLoadedDestination = '';
  String get currentLoadedDestination => _currentLoadedDestination;

  bool _isLoadingAttractions = false;
  bool get isLoadingAttractions => _isLoadingAttractions;

  String? _attractionsError;
  String? get attractionsError => _attractionsError;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Active Trip Planning State
  String _planningDestination = 'Goa, India';
  String get planningDestination => _planningDestination;

  double? _planningLat;
  double? get planningLat => _planningLat;

  double? _planningLon;
  double? get planningLon => _planningLon;

  TripPlan _currentTrip = SampleData.getDefaultGoaTrip();
  TripPlan get currentTrip => _currentTrip;

  int _selectedDayIndex = 0;
  int get selectedDayIndex => _selectedDayIndex;

  ItineraryDay get selectedDay {
    if (_selectedDayIndex < _currentTrip.days.length) {
      return _currentTrip.days[_selectedDayIndex];
    }
    return _currentTrip.days.first;
  }

  // Saved Items
  final Set<String> _savedAttractionIds = {'baga_beach', 'calangute_beach'};
  Set<String> get savedAttractionIds => _savedAttractionIds;

  // Provider Status
  Map<String, dynamic> _providerStatus = {};
  Map<String, dynamic> get providerStatus => _providerStatus;

  bool isAttractionSaved(String id) => _savedAttractionIds.contains(id);

  // AI Assistant Chat Messages
  final List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;

  bool _isGeneratingTrip = false;
  bool get isGeneratingTrip => _isGeneratingTrip;

  String? _tripGenerationError;
  String? get tripGenerationError => _tripGenerationError;

  bool _isAssistantTyping = false;
  bool get isAssistantTyping => _isAssistantTyping;

  // Personalized Recommendations & Stage 5 Workflow State
  RecommendationResponseModel? _personalizedRecommendations;
  RecommendationResponseModel? get personalizedRecommendations => _personalizedRecommendations;

  bool _isLoadingRecommendations = false;
  bool get isLoadingRecommendations => _isLoadingRecommendations;

  final Set<String> _selectedRecommendationIds = {};
  Set<String> get selectedRecommendationIds => _selectedRecommendationIds;

  final Set<String> _excludedRecommendationIds = {};
  Set<String> get excludedRecommendationIds => _excludedRecommendationIds;

  bool _isSearchingRemote = false;
  bool get isSearchingRemote => _isSearchingRemote;

  List<Attraction> _remoteSearchResults = [];
  List<Attraction> get remoteSearchResults => _remoteSearchResults;

  AppStateProvider() {
    _initAuthSession();
    _initializeAssistantHistory();
    _fetchDestinations();
    _fetchProviderStatus();
  }

  Future<void> _initAuthSession() async {
    try {
      final savedUser = await _authService.getSavedSession();
      if (savedUser != null) {
        _userProfile = savedUser;
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResult> login(String email, String password) async {
    final result = await _authService.login(email, password);
    if (result.isSuccess && result.user != null) {
      _userProfile = result.user!;
      _isAuthenticated = true;
      notifyListeners();
    }
    return result;
  }

  Future<AuthResult> register(String name, String email, String password) async {
    final result = await _authService.register(name: name, email: email, password: password);
    if (result.isSuccess && result.user != null) {
      _userProfile = result.user!;
      _isAuthenticated = true;
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _userProfile = UserProfile.defaultUser();
    notifyListeners();
  }

  void continueAsGuest() {
    _isAuthenticated = true;
    _userProfile = UserProfile.defaultUser();
    notifyListeners();
  }

  Future<void> _fetchProviderStatus() async {
    try {
      _providerStatus = await _apiClient.getProviderStatus();
      notifyListeners();
    } catch (_) {}
  }

  void setNavIndex(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  void setSelectedDayIndex(int index) {
    _selectedDayIndex = index;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  int _attractionsRequestId = 0;

  void setPlanningDestination(String destination, {double? lat, double? lon}) {
    final clean = destination.trim();
    if (clean.isEmpty) return;

    final hasChanged = _planningDestination.toLowerCase() != clean.toLowerCase() ||
        _planningLat != lat ||
        _planningLon != lon;

    _planningDestination = clean;
    _planningLat = lat;
    _planningLon = lon;

    if (hasChanged) {
      // Invalidate old recommendations, selections, and attractions for the prior destination
      _personalizedRecommendations = null;
      _selectedRecommendationIds.clear();
      _excludedRecommendationIds.clear();
      _tripGenerationError = null;
      _destinationAttractions = [];
      _currentLoadedDestination = clean;
      notifyListeners();

      // Immediately trigger loading for the newly selected destination
      loadAttractionsForDestination(clean, lat: lat, lon: lon, force: true);
    }
  }

  Future<({bool success, String message})> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          success: false,
          message: 'Location services are disabled. Please turn on GPS in your device settings.'
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (
            success: false,
            message: 'Location permission was denied. You can still search destinations manually.'
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return (
          success: false,
          message: 'Location permissions are permanently denied. Please enable them in app settings.'
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );

      _planningLat = position.latitude;
      _planningLon = position.longitude;

      String detectedPlace = 'Current Location';
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
        );
        final resp = await http.get(uri, headers: {
          'User-Agent': 'AITourist/1.0 (contact@aitourist.local)',
        }).timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final addr = data['address'] as Map<String, dynamic>?;
          if (addr != null) {
            final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['suburb'] ?? addr['county'];
            final state = addr['state'];
            if (city != null && state != null) {
              detectedPlace = '$city, $state';
            } else if (city != null) {
              detectedPlace = '$city, India';
            }
          }
        }
      } catch (_) {}

      setPlanningDestination(detectedPlace, lat: position.latitude, lon: position.longitude);
      await loadAttractionsForDestination(detectedPlace, lat: position.latitude, lon: position.longitude, force: true);

      return (
        success: true,
        message: 'Current location detected: $detectedPlace'
      );
    } catch (e) {
      return (
        success: false,
        message: 'Could not acquire GPS position: ${e.toString().replaceAll('Exception:', '').trim()}'
      );
    }
  }

  Future<List<Destination>> searchDestinations(String query) async {
    _isSearchingDestinations = true;
    notifyListeners();
    try {
      final results = await _apiClient.searchDestinations(query);
      _searchedDestinations = results;
      return results;
    } finally {
      _isSearchingDestinations = false;
      notifyListeners();
    }
  }

  Future<void> loadAttractionsForDestination(
    String destinationName, {
    double? lat,
    double? lon,
    bool force = false,
  }) async {
    final normName = destinationName.trim();
    if (normName.isEmpty) return;

    if (!force &&
        _currentLoadedDestination.toLowerCase() == normName.toLowerCase() &&
        _destinationAttractions.isNotEmpty) {
      return;
    }

    final requestId = ++_attractionsRequestId;
    _currentLoadedDestination = normName;
    _isLoadingAttractions = true;
    _destinationAttractions = [];
    _attractionsError = null;
    notifyListeners();

    try {
      final destId = normName.toLowerCase().split(',')[0].trim().replaceAll(RegExp(r'\s+'), '_');
      final effectiveLat = lat ?? (_planningDestination.toLowerCase() == normName.toLowerCase() ? _planningLat : null);
      final effectiveLon = lon ?? (_planningDestination.toLowerCase() == normName.toLowerCase() ? _planningLon : null);
      final results = await _apiClient.getAttractions(
        destinationId: destId,
        latitude: effectiveLat,
        longitude: effectiveLon,
      );

      if (requestId != _attractionsRequestId) return;

      _destinationAttractions = results;
      _attractionsError = results.isEmpty ? 'No attractions found for $normName.' : null;
    } catch (e) {
      if (requestId != _attractionsRequestId) return;
      _destinationAttractions = [];
      _attractionsError = 'Failed to load attractions for $normName. Please check your connection and retry.';
    } finally {
      if (requestId == _attractionsRequestId) {
        _isLoadingAttractions = false;
        notifyListeners();
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _remoteSearchResults = [];
    }
    notifyListeners();
  }

  Future<void> searchAttractionsRemote(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _remoteSearchResults = [];
      notifyListeners();
      return;
    }
    _isSearchingRemote = true;
    notifyListeners();

    try {
      final results = await _apiClient.searchAttractions(query);
      _remoteSearchResults = results;
    } catch (_) {
      _remoteSearchResults = [];
    } finally {
      _isSearchingRemote = false;
      notifyListeners();
    }
  }

  void toggleSaveAttraction(String attractionId) {
    if (_savedAttractionIds.contains(attractionId)) {
      _savedAttractionIds.remove(attractionId);
    } else {
      _savedAttractionIds.add(attractionId);
    }
    _userProfile = _userProfile.copyWith(savedPlacesCount: _savedAttractionIds.length);
    notifyListeners();
  }

  List<Attraction> get filteredAttractions {
    if (_remoteSearchResults.isNotEmpty) {
      return _remoteSearchResults;
    }

    // STRICT LOCATION ISOLATION:
    // If a destination has been selected/loaded, NEVER fall back to another city's (e.g. Goa's) attractions!
    final baseList = _destinationAttractions.isNotEmpty
        ? _destinationAttractions
        : (_currentLoadedDestination.isEmpty ? _allAttractions : <Attraction>[]);

    return baseList.where((attraction) {
      final matchesCategory = _selectedCategory == 'All' ||
          attraction.category.toLowerCase() == _selectedCategory.toLowerCase();

      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          attraction.name.toLowerCase().contains(q) ||
          attraction.category.toLowerCase().contains(q) ||
          attraction.destinationName.toLowerCase().contains(q) ||
          attraction.tags.any((t) => t.toLowerCase().contains(q));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Attraction> get savedAttractions {
    return _allAttractions.where((a) => _savedAttractionIds.contains(a.id)).toList();
  }

  Future<void> _fetchDestinations() async {
    try {
      final res = await _apiClient.getDestinations();
      if (res.isNotEmpty) {
        _destinations = res;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchPersonalizedRecommendations({
    required String destination,
    required int durationDays,
    required List<String> interests,
    required double budgetPerPerson,
    required int travelersCount,
    String travelIntensity = 'moderate',
    bool familyFriendly = false,
    bool accessibilityRequired = false,
  }) async {
    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      final res = await _apiClient.getPersonalizedRecommendations(
        destination: destination,
        durationDays: durationDays,
        interests: interests,
        budgetPerPerson: budgetPerPerson,
        travelersCount: travelersCount,
        travelIntensity: travelIntensity,
        familyFriendly: familyFriendly,
        accessibilityRequired: accessibilityRequired,
        exclusions: _excludedRecommendationIds.toList(),
        latitude: _planningLat,
        longitude: _planningLon,
      );
      _personalizedRecommendations = res;
      _selectedRecommendationIds.clear();
      if (res != null) {
        // Pre-select the top recommended attractions by default
        for (final item in res.items) {
          _selectedRecommendationIds.add(item.attraction.id);
        }
      }
    } catch (_) {
      _personalizedRecommendations = null;
    } finally {
      _isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  void toggleCandidateSelection(String id) {
    if (_selectedRecommendationIds.contains(id)) {
      _selectedRecommendationIds.remove(id);
    } else {
      _selectedRecommendationIds.add(id);
      _excludedRecommendationIds.remove(id);
    }
    notifyListeners();
  }

  void toggleCandidateExclusion(String id) {
    if (_excludedRecommendationIds.contains(id)) {
      _excludedRecommendationIds.remove(id);
    } else {
      _excludedRecommendationIds.add(id);
      _selectedRecommendationIds.remove(id);
    }
    notifyListeners();
  }

  Future<void> generateTrip({
    required String destination,
    required String startDate,
    required String endDate,
    required int travelers,
    required double budgetPerPerson,
    required List<String> interests,
    String travelIntensity = 'moderate',
    bool familyFriendly = false,
    bool accessibilityRequired = false,
    bool mealBreaks = true,
  }) async {
    _isGeneratingTrip = true;
    _tripGenerationError = null;
    notifyListeners();

    try {
      final trip = await _apiClient.generateItinerary(
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        travelers: travelers,
        budgetPerPerson: budgetPerPerson,
        interests: interests,
        travelIntensity: travelIntensity,
        exclusions: _excludedRecommendationIds.toList(),
        selectedAttractionIds: _selectedRecommendationIds.isNotEmpty
            ? _selectedRecommendationIds.toList()
            : null,
        familyFriendly: familyFriendly,
        accessibilityRequired: accessibilityRequired,
        mealBreaks: mealBreaks,
        latitude: _planningLat,
        longitude: _planningLon,
      );
      _currentTrip = trip;
      _tripGenerationError = null;
      _selectedDayIndex = 0;
      _currentNavIndex = 2; // Jump to Itinerary screen
      _apiClient.saveTripRemote(trip);
    } catch (e) {
      _tripGenerationError = 'Could not generate itinerary for $destination: ${e.toString().replaceAll('Exception:', '').trim()}';
    } finally {
      _isGeneratingTrip = false;
      notifyListeners();
    }
  }

  void removeStopFromItinerary(int dayIndex, String stopId) {
    if (dayIndex >= _currentTrip.days.length) return;
    final day = _currentTrip.days[dayIndex];
    final updatedStops = day.stops.where((s) => s.id != stopId).toList();
    final updatedDay = day.copyWith(stops: updatedStops);

    final updatedDays = List<ItineraryDay>.from(_currentTrip.days);
    updatedDays[dayIndex] = updatedDay;

    // Recalculate estimated cost slightly
    final updatedBudget = _currentTrip.budget;
    _currentTrip = _currentTrip.copyWith(days: updatedDays, budget: updatedBudget);
    notifyListeners();
  }

  Future<void> updateTripBudget(double newBudgetPerPerson) async {
    final travelers = _currentTrip.travelersCount > 0 ? _currentTrip.travelersCount : 1;
    final newTotalBudget = newBudgetPerPerson * travelers;
    final days = _currentTrip.days.isNotEmpty ? _currentTrip.days.length : 3;

    try {
      final updatedBudget = await _apiClient.estimateCost(
        destination: _currentTrip.destination,
        days: days,
        travelers: travelers,
        userBudget: newTotalBudget,
        travelStyle: newBudgetPerPerson <= 3000 ? 'budget' : (newBudgetPerPerson > 8000 ? 'luxury' : 'balanced'),
      );
      _currentTrip = _currentTrip.copyWith(
        budgetPerPerson: newBudgetPerPerson,
        totalBudget: newTotalBudget,
        budget: updatedBudget,
      );
    } catch (_) {
      final isWithin = _currentTrip.budget.totalEstimated <= newTotalBudget;
      final diff = (newTotalBudget - _currentTrip.budget.totalEstimated).abs();
      final updatedBudget = BudgetBreakdown(
        accommodation: _currentTrip.budget.accommodation,
        foodDrinks: _currentTrip.budget.foodDrinks,
        transport: _currentTrip.budget.transport,
        activities: _currentTrip.budget.activities,
        miscellaneous: _currentTrip.budget.miscellaneous,
        totalEstimated: _currentTrip.budget.totalEstimated,
        userBudget: newTotalBudget,
        isWithinBudget: isWithin,
        costPerPerson: _currentTrip.budget.totalEstimated / travelers,
        groupBudget: newTotalBudget,
        budgetPerPerson: newBudgetPerPerson,
        budgetDifference: diff,
        days: days,
        nights: _currentTrip.budget.nights,
        travelers: travelers,
        modelBasis: _currentTrip.budget.modelBasis,
        isExperimental: _currentTrip.budget.isExperimental,
        knownFeesTotal: _currentTrip.budget.knownFeesTotal,
        unknownFeesCount: _currentTrip.budget.unknownFeesCount,
        calculationAssumptions: _currentTrip.budget.calculationAssumptions,
      );
      _currentTrip = _currentTrip.copyWith(
        budgetPerPerson: newBudgetPerPerson,
        totalBudget: newTotalBudget,
        budget: updatedBudget,
      );
    }
    notifyListeners();
  }

  void addAttractionToItinerary(Attraction attraction) {
    if (_currentTrip.days.isEmpty) return;
    final day = _currentTrip.days[_selectedDayIndex];
    final newStop = TimelineStop(
      id: 'stop_${DateTime.now().millisecondsSinceEpoch}',
      time: '05:00 PM',
      attraction: attraction,
      notes: 'Added from attractions list.',
      durationHours: attraction.estimatedDurationHours,
    );
    final updatedStops = List<TimelineStop>.from(day.stops)..add(newStop);
    final updatedDay = day.copyWith(stops: updatedStops);
    final updatedDays = List<ItineraryDay>.from(_currentTrip.days);
    updatedDays[_selectedDayIndex] = updatedDay;
    _currentTrip = _currentTrip.copyWith(days: updatedDays);
    notifyListeners();
  }

  void _initializeAssistantHistory() {
    _chatMessages.add(
      ChatMessage(
        id: 'msg_welcome',
        text: 'Hello! I am your AI Travel Assistant. Ask me anything about itineraries, Sinhagad trekking gear, packing checklists, Jaipur or Pune plans, or budget tips!',
        isUser: false,
      ),
    );
  }

  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
    );
    _chatMessages.add(userMsg);
    _isAssistantTyping = true;
    notifyListeners();

    try {
      final history = _chatMessages.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      final res = await _apiClient.sendChatMessage(
        message: text,
        history: history,
        destination: _planningDestination,
        travelers: _currentTrip.travelersCount,
        budgetPerPerson: _currentTrip.budgetPerPerson,
        interests: _currentTrip.interests,
        dates: '${_currentTrip.startDate} - ${_currentTrip.endDate}',
      );

      List<Attraction>? recs;
      if (res['attractions'] != null) {
        recs = (res['attractions'] as List)
            .map((item) => Attraction.fromJson(item))
            .toList();
      }

      final botMsg = ChatMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        text: res['reply'] ?? 'Here are the details you requested.',
        isUser: false,
        attractionRecommendations: recs,
        budgetSummaryText: res['cost_summary_text'],
        showViewItineraryAction: res['show_view_itinerary'] == true,
      );
      _chatMessages.add(botMsg);
    } catch (_) {
      _chatMessages.add(ChatMessage(
        id: 'bot_err_${DateTime.now().millisecondsSinceEpoch}',
        text: 'I could not connect to the travel assistant. Please verify your network connection and retry.',
        isUser: false,
      ));
    } finally {
      _isAssistantTyping = false;
      notifyListeners();
    }
  }

  void updateProfileName(String newName, String newEmail) {
    _userProfile = _userProfile.copyWith(name: newName, email: newEmail);
    notifyListeners();
  }
}
