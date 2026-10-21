import 'package:flutter_test/flutter_test.dart';
import 'package:ai_tourist/core/services/auth_service.dart';
import 'package:ai_tourist/shared/models/destination.dart';
import 'package:ai_tourist/shared/providers/app_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Tests', () {
    test('Login with default seeded credentials succeeds and persists session', () async {
      final authService = AuthService();
      final res = await authService.login('mayankpawar@gmail.com', 'password123');

      expect(res.isSuccess, isTrue);
      expect(res.user?.email, 'mayankpawar@gmail.com');
      expect(res.token, isNotNull);

      // Verify session restored
      final savedUser = await authService.getSavedSession();
      expect(savedUser?.email, 'mayankpawar@gmail.com');
    });

    test('Login with incorrect password fails with error', () async {
      final authService = AuthService();
      final res = await authService.login('mayankpawar@gmail.com', 'wrongpassword');

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Incorrect password'));
    });

    test('Register new user succeeds, persists and signs in', () async {
      final authService = AuthService();
      final res = await authService.register(
        name: 'Aditi Sharma',
        email: 'aditi@example.com',
        password: 'securePass123',
      );

      expect(res.isSuccess, isTrue);
      expect(res.user?.name, 'Aditi Sharma');
      expect(res.user?.email, 'aditi@example.com');

      final savedUser = await authService.getSavedSession();
      expect(savedUser?.email, 'aditi@example.com');
    });

    test('Logout clears saved session', () async {
      final authService = AuthService();
      await authService.login('mayankpawar@gmail.com', 'password123');
      expect(await authService.getSavedSession(), isNotNull);

      await authService.logout();
      expect(await authService.getSavedSession(), isNull);
    });
  });

  group('AppStateProvider Destination Isolation Tests', () {
    test('Changing planning destination invalidates stale recommendations', () {
      final appState = AppStateProvider();
      expect(appState.planningDestination, 'Goa, India');

      appState.setPlanningDestination('Nashik, Maharashtra', lat: 20.0112, lon: 73.7902);
      expect(appState.planningDestination, 'Nashik, Maharashtra');
      expect(appState.planningLat, 20.0112);
      expect(appState.planningLon, 73.7902);
      expect(appState.personalizedRecommendations, isNull);
      expect(appState.selectedRecommendationIds, isEmpty);
      expect(appState.excludedRecommendationIds, isEmpty);
    });

    test('loadAttractionsForDestination normalizes ID and populates state', () async {
      final appState = AppStateProvider();
      await appState.loadAttractionsForDestination('Goa, India');

      expect(appState.isLoadingAttractions, isFalse);
      expect(appState.attractionsError, isNull);
      expect(appState.destinationAttractions, isNotEmpty);
      expect(appState.filteredAttractions, isNotEmpty);
    });

    test('Destination model correctly serializes and deserializes coordinates', () {
      final json = {
        'id': 'nashik',
        'name': 'Nashik',
        'country': 'India',
        'state': 'Maharashtra',
        'description': 'Ancient city in Maharashtra',
        'image_url': 'https://example.com/nashik.jpg',
        'rating': 4.5,
        'review_count': 1200,
        'tags': ['Discovery', 'Heritage'],
        'is_trending': false,
        'latitude': 20.0112,
        'longitude': 73.7902,
      };
      final d = Destination.fromJson(json);
      expect(d.name, 'Nashik');
      expect(d.latitude, 20.0112);
      expect(d.longitude, 73.7902);

      final out = d.toJson();
      expect(out['latitude'], 20.0112);
      expect(out['longitude'], 73.7902);
    });
  });
}
