import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/search_field.dart';
import '../widgets/featured_destination_card.dart';
import '../widgets/interest_shortcuts.dart';
import '../widgets/popular_destinations_carousel.dart';
import '../../attractions/screens/attractions_list_screen.dart';
import '../../attractions/screens/attraction_details_screen.dart';
import '../../attractions/widgets/attraction_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;

  const HomeScreen({
    super.key,
    required this.onOpenDrawer,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _typedQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, AppStateProvider appState) {
    setState(() => _typedQuery = query);
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) return;

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      appState.searchDestinations(query.trim());
    });
  }

  Future<void> _executeSearch(String query, AppStateProvider appState) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return;

    double? lat;
    double? lon;
    String selectedName = cleanQ;

    // 1. Check if matches searched destinations
    final matchedSearch = appState.searchedDestinations.where(
      (d) => d.name.toLowerCase() == cleanQ.toLowerCase() ||
             (d.state.isNotEmpty && d.state.toLowerCase().contains(cleanQ.toLowerCase())),
    );
    if (matchedSearch.isNotEmpty) {
      final match = matchedSearch.first;
      lat = match.latitude;
      lon = match.longitude;
      selectedName = match.name;
    } else {
      // 2. Check catalog popular destinations
      final matchedPopular = appState.destinations.where(
        (d) => d.name.toLowerCase() == cleanQ.toLowerCase(),
      );
      if (matchedPopular.isNotEmpty) {
        final match = matchedPopular.first;
        lat = match.latitude;
        lon = match.longitude;
        selectedName = match.name;
      } else {
        // 3. Geocode via backend/Nominatim
        await appState.searchDestinations(cleanQ);
        if (appState.searchedDestinations.isNotEmpty) {
          final top = appState.searchedDestinations.first;
          lat = top.latitude;
          lon = top.longitude;
          selectedName = top.name;
        }
      }
    }

    appState.setPlanningDestination(selectedName, lat: lat, lon: lon);
    setState(() {
      _typedQuery = '';
      _searchController.clear();
    });
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final trendingDestination = appState.destinations.firstWhere(
      (d) => d.isTrending,
      orElse: () => appState.destinations.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile & Greeting Header
              GreetingHeader(
                profile: appState.userProfile,
                onAvatarTap: widget.onOpenDrawer,
                onLocationTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Detecting GPS location...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  final result = await appState.getCurrentLocation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.success ? AppColors.success : AppColors.textSecondary,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                onNotificationTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Search Bar
              SearchField(
                controller: _searchController,
                onChanged: (val) => _onSearchChanged(val, appState),
                onSearchTap: () => _executeSearch(_searchController.text, appState),
                onSubmitted: (query) => _executeSearch(query, appState),
                onClearTap: () {
                  _searchController.clear();
                  setState(() => _typedQuery = '');
                },
                onVoiceTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice search listening...')),
                  );
                },
              ),

              // Dynamic Search Suggestions Dropdown
              if (_typedQuery.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: appState.isSearchingDestinations
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : (appState.searchedDestinations.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Press Enter to explore attractions in "$_typedQuery"',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: appState.searchedDestinations.length.clamp(0, 5),
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final d = appState.searchedDestinations[idx];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    subtitle: Text(d.state.isNotEmpty ? d.state : d.country, style: const TextStyle(fontSize: 12)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
                                    onTap: () {
                                      appState.setPlanningDestination(d.name, lat: d.latitude, lon: d.longitude);
                                      setState(() {
                                        _typedQuery = '';
                                        _searchController.clear();
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                  );
                                },
                              )),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Active Selected Destination Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exploring ${appState.planningDestination}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (appState.planningLat != null && appState.planningLon != null)
                              Text(
                                '${appState.planningLat!.toStringAsFixed(2)}°N, ${appState.planningLon!.toStringAsFixed(2)}°E',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttractionsListScreen(
                                destinationName: appState.planningDestination,
                                latitude: appState.planningLat,
                                longitude: appState.planningLon,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Attractions in Destination
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attractions in ${appState.planningDestination}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (appState.destinationAttractions.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttractionsListScreen(
                                destinationName: appState.planningDestination,
                                latitude: appState.planningLat,
                                longitude: appState.planningLon,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'See All (${appState.destinationAttractions.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (appState.isLoadingAttractions)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading attractions and verified photos...',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (appState.destinationAttractions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'No attractions found for ${appState.planningDestination}. Try another destination or search above.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: appState.destinationAttractions.take(4).map((attraction) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AttractionCard(
                          attraction: attraction,
                          isSaved: appState.isAttractionSaved(attraction.id),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttractionDetailsScreen(
                                  attraction: attraction,
                                ),
                              ),
                            );
                          },
                          onSaveToggle: () => appState.toggleSaveAttraction(attraction.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 18),

              // Trending Featured Destination Card
              FeaturedDestinationCard(
                destination: trendingDestination,
                onExplore: () {
                  appState.setPlanningDestination(
                    trendingDestination.name,
                    lat: trendingDestination.latitude,
                    lon: trendingDestination.longitude,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttractionsListScreen(
                        destinationName: trendingDestination.name,
                        latitude: trendingDestination.latitude,
                        longitude: trendingDestination.longitude,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Interest Shortcuts
              InterestShortcuts(
                selectedCategory: appState.selectedCategory,
                onSelectCategory: (category) {
                  appState.setSelectedCategory(category);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttractionsListScreen(
                        destinationName: appState.planningDestination,
                        latitude: appState.planningLat,
                        longitude: appState.planningLon,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Popular Destinations Carousel
              PopularDestinationsCarousel(
                destinations: appState.destinations,
                onDestinationTap: (destination) {
                  appState.setPlanningDestination(
                    destination.name,
                    lat: destination.latitude,
                    lon: destination.longitude,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttractionsListScreen(
                        destinationName: destination.name,
                        latitude: destination.latitude,
                        longitude: destination.longitude,
                      ),
                    ),
                  );
                },
                onSeeAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttractionsListScreen(
                        destinationName: appState.planningDestination,
                        latitude: appState.planningLat,
                        longitude: appState.planningLon,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
