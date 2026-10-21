import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../shared/providers/app_state_provider.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../features/home/screens/home_screen.dart';
import '../features/trip_planner/screens/trip_planner_screen.dart';
import '../features/itinerary/screens/itinerary_screen.dart';
import '../features/assistant/screens/assistant_screen.dart';
import '../features/profile/screens/profile_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const ProfileDrawer(),
      body: IndexedStack(
        index: appState.currentNavIndex,
        children: [
          HomeScreen(
            onOpenDrawer: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const TripPlannerScreen(),
          const ItineraryScreen(),
          const AssistantScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: appState.currentNavIndex,
        onTap: (index) {
          appState.setNavIndex(index);
        },
      ),
    );
  }
}
