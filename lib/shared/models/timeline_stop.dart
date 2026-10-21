import 'attraction.dart';

class TimelineStop {
  final String id;
  final String time; // e.g. "08:00 AM"
  final Attraction attraction;
  final String notes;
  final double durationHours;

  const TimelineStop({
    required this.id,
    required this.time,
    required this.attraction,
    this.notes = '',
    required this.durationHours,
  });

  factory TimelineStop.fromJson(Map<String, dynamic> json) {
    return TimelineStop(
      id: json['id'] ?? '',
      time: json['time'] ?? '09:00 AM',
      attraction: Attraction.fromJson(json['attraction'] ?? {}),
      notes: json['notes'] ?? '',
      durationHours: (json['duration_hours'] ?? json['durationHours'] as num?)?.toDouble() ?? 1.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'attraction': attraction.toJson(),
      'notes': notes,
      'duration_hours': durationHours,
    };
  }
}
