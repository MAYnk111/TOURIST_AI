import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../shared/widgets/attraction_image.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  String _destination = 'Goa, India';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));
  int _travelers = 2;
  double _budget = 15000;
  final TextEditingController _budgetController = TextEditingController(text: '15,000');

  final List<String> _availableInterests = [
    'Beaches',
    'Adventure',
    'Food',
    'Nature',
    'History',
    'Shopping',
  ];

  final Set<String> _selectedInterests = {'Beaches', 'Food', 'Nature'};

  String _travelIntensity = 'moderate';
  bool _familyFriendly = false;
  bool _accessibilityRequired = false;
  bool _mealBreaks = true;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    _destination = appState.planningDestination;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _onFetchRecommendations(AppStateProvider appState) async {
    final days = _endDate.difference(_startDate).inDays.clamp(1, 30);
    await appState.fetchPersonalizedRecommendations(
      destination: _destination,
      durationDays: days,
      interests: _selectedInterests.toList(),
      budgetPerPerson: _budget,
      travelersCount: _travelers,
      travelIntensity: _travelIntensity,
      familyFriendly: _familyFriendly,
      accessibilityRequired: _accessibilityRequired,
    );
  }

  void _onGenerateTrip(AppStateProvider appState) async {
    final startStr = DateFormat('MMM d, y').format(_startDate);
    final endStr = DateFormat('MMM d, y').format(_endDate);

    await appState.generateTrip(
      destination: _destination,
      startDate: startStr,
      endDate: endStr,
      travelers: _travelers,
      budgetPerPerson: _budget,
      interests: _selectedInterests.toList(),
      travelIntensity: _travelIntensity,
      familyFriendly: _familyFriendly,
      accessibilityRequired: _accessibilityRequired,
      mealBreaks: _mealBreaks,
    );

    if (mounted && appState.tripGenerationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.tripGenerationError!),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _onGenerateTrip(appState),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    if (_destination != appState.planningDestination) {
      _destination = appState.planningDestination;
    }
    final dateFormat = DateFormat('MMM d, y');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Top Banner with Scenic Image & Script Text
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1000&q=80',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.blueGrey.shade900),
                  errorWidget: (_, __, ___) => Container(color: Colors.blueGrey.shade800),
                ),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plan Your Trip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tell us your preferences and let AI create the perfect plan for you.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Script quote
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Good Trips\nBetter Stories',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Form Card
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination Input
                      _buildFormField(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFE0F2FE),
                        label: 'Destination',
                        value: _destination,
                        onTap: () {
                          _showDestinationPicker(context);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Travel Dates
                      _buildFormField(
                        icon: Icons.calendar_month_rounded,
                        iconColor: const Color(0xFF16A34A),
                        iconBg: const Color(0xFFDCFCE7),
                        label: 'Travel Dates',
                        value: '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                        onTap: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                          );
                          if (range != null) {
                            setState(() {
                              _startDate = range.start;
                              _endDate = range.end;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Number of Travelers
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.people_alt_rounded, color: Color(0xFF7C3AED), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Number of Travelers',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  Text(
                                    '$_travelers ${_travelers == 1 ? "Person" : "People"}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            // Stepper (- 1 +)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    onPressed: _travelers > 1
                                        ? () => setState(() => _travelers--)
                                        : null,
                                  ),
                                  Text(
                                    '$_travelers',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    onPressed: () => setState(() => _travelers++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Budget (per person)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Budget (per person)',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  TextField(
                                    controller: _budgetController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixText: '₹ ',
                                      prefixStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    onChanged: (val) {
                                      final cleaned = val.replaceAll(',', '').replaceAll('₹', '').trim();
                                      final parsed = double.tryParse(cleaned);
                                      if (parsed != null && parsed > 0) {
                                        setState(() => _budget = parsed);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total group budget: ₹${NumberFormat('#,##,###').format(_budget * _travelers)} for $_travelers ${_travelers == 1 ? "traveler" : "travelers"}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Interests Section
                      const Text(
                        'Your Interests',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Select what you love',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedInterests.add(interest);
                                } else {
                                  if (_selectedInterests.length > 1) {
                                    _selectedInterests.remove(interest);
                                  }
                                }
                              });
                            },
                            backgroundColor: AppColors.surfaceVariant,
                            selectedColor: interest == 'Food'
                                ? const Color(0xFFFFEDD5)
                                : interest == 'Nature'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFE0F2FE),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (interest == 'Food'
                                      ? const Color(0xFFC2410C)
                                      : interest == 'Nature'
                                          ? const Color(0xFF15803D)
                                          : AppColors.primary)
                                  : AppColors.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? (interest == 'Food'
                                        ? const Color(0xFFEA580C)
                                        : interest == 'Nature'
                                            ? const Color(0xFF16A34A)
                                            : AppColors.primary)
                                    : AppColors.border,
                              ),
                            ),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Travel Intensity Section
                      const Text(
                        'Travel Pace',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'How packed do you want your schedule?',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildIntensityChip('Relaxed (2/day)', 'relaxed'),
                          const SizedBox(width: 8),
                          _buildIntensityChip('Moderate (3/day)', 'moderate'),
                          const SizedBox(width: 8),
                          _buildIntensityChip('Intense (4/day)', 'intense'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Smart Toggles: Family, Accessibility, Meal Breaks
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Family Friendly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Prioritize safe, kid-friendly spots', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              value: _familyFriendly,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _familyFriendly = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Accessibility Required', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Wheelchair & level access focus', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              value: _accessibilityRequired,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _accessibilityRequired = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Include Meal Breaks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Schedule 1.0h lunch & dinner breaks', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              value: _mealBreaks,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _mealBreaks = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Discover AI Recommendations Preview Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: appState.isLoadingRecommendations
                              ? null
                              : () => _onFetchRecommendations(appState),
                          icon: appState.isLoadingRecommendations
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                          label: Text(
                            appState.isLoadingRecommendations
                                ? 'Fetching Recommendations...'
                                : 'Preview Matched Attractions',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          ),
                        ),
                      ),

                      // Display Candidate Recommendations if fetched
                      if (appState.personalizedRecommendations != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Matched Attractions',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${appState.selectedRecommendationIds.length} Selected',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Review ML match explanations, include favorite places, or exclude unwanted spots:',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        ...appState.personalizedRecommendations!.items.map((item) {
                          final isSelected = appState.selectedRecommendationIds.contains(item.attraction.id);
                          final isExcluded = appState.excludedRecommendationIds.contains(item.attraction.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isExcluded
                                  ? Colors.red.shade50.withOpacity(0.5)
                                  : (isSelected ? Colors.blue.shade50.withOpacity(0.5) : AppColors.surfaceVariant.withOpacity(0.4)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isExcluded
                                    ? Colors.red.shade200
                                    : (isSelected ? AppColors.primary.withOpacity(0.5) : AppColors.border),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AttractionImage(
                                      imageUrl: item.attraction.imageUrl,
                                      category: item.attraction.category,
                                      name: item.attraction.name,
                                      width: 50,
                                      height: 50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.attraction.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            item.attraction.category,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${(item.score * 100).toInt()}% Match',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                item.attraction.formattedEntryFee,
                                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Selection Checkbox
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (_) => appState.toggleCandidateSelection(item.attraction.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.explanation,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(
                                        isExcluded ? 'Excluded' : 'Exclude',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isExcluded ? Colors.white : Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: isExcluded ? Colors.red.shade600 : Colors.red.shade50,
                                      onPressed: () => appState.toggleCandidateExclusion(item.attraction.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 24),

                      // Generate My Trip Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: appState.isGeneratingTrip
                              ? null
                              : () => _onGenerateTrip(appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: appState.isGeneratingTrip
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Optimizing your itinerary...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Generate My Trip ✨',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityChip(String label, String value) {
    final isSelected = _travelIntensity == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 8),
        onSelected: (selected) {
          if (selected) {
            setState(() => _travelIntensity = value);
          }
        },
      ),
    );
  }

  void _showDestinationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final appState = context.watch<AppStateProvider>();
            final quickPickCoords = <String, (double, double)>{
              'goa': (15.2993, 74.1240),
              'pune': (18.5204, 73.8567),
              'mumbai': (19.0760, 72.8777),
              'manali': (32.2396, 77.1887),
              'udaipur': (24.5854, 73.7125),
              'munnar': (10.0889, 77.0595),
              'jaipur': (26.9124, 75.7873),
              'varanasi': (25.3176, 82.9739),
              'kochi': (9.9312, 76.2673),
            };

            final quickPicks = [
              'Goa, India',
              'Pune, Maharashtra',
              'Mumbai, Maharashtra',
              'Manali, Himachal Pradesh',
              'Udaipur, Rajasthan',
              'Munnar, Kerala',
              'Jaipur, Rajasthan',
              'Varanasi, Uttar Pradesh',
              'Kochi, Kerala',
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Destination', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: 'Search destinations in India...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          appState.searchDestinations(val.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Quick Picks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickPicks.map((qp) {
                        final isSelected = _destination.toLowerCase().contains(qp.split(',')[0].toLowerCase());
                        return ActionChip(
                          label: Text(qp.split(',')[0]),
                          backgroundColor: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onPressed: () {
                            setState(() => _destination = qp);
                            final key = qp.split(',')[0].toLowerCase().trim();
                            final coords = quickPickCoords[key];
                            appState.setPlanningDestination(qp, lat: coords?.$1, lon: coords?.$2);
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    if (appState.isSearchingDestinations)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (appState.searchedDestinations.isNotEmpty) ...[
                      const Text('Search Results', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: appState.searchedDestinations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final d = appState.searchedDestinations[index];
                            final fullName = '${d.name}, ${d.state}';
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(d.state),
                              trailing: _destination.toLowerCase().contains(d.name.toLowerCase())
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                  : null,
                              onTap: () {
                                setState(() => _destination = fullName);
                                appState.setPlanningDestination(fullName, lat: d.latitude, lon: d.longitude);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
