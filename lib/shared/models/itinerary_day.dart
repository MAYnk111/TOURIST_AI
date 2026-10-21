import 'timeline_stop.dart';

class ItineraryDay {
  final int dayNumber;
  final String date;
  final List<TimelineStop> stops;

  const ItineraryDay({
    required this.dayNumber,
    required this.date,
    required this.stops,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      dayNumber: (json['day_number'] ?? json['dayNumber'] as num?)?.toInt() ?? 1,
      date: json['date'] ?? '',
      stops: (json['stops'] as List? ?? [])
          .map((s) => TimelineStop.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'date': date,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }

  ItineraryDay copyWith({
    int? dayNumber,
    String? date,
    List<TimelineStop>? stops,
  }) {
    return ItineraryDay(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      stops: stops ?? this.stops,
    );
  }
}
