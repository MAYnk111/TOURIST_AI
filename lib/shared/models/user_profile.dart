class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final List<String> interests;
  final int savedPlacesCount;
  final int tripsCount;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.interests = const ['Beaches', 'Adventure', 'Food'],
    this.savedPlacesCount = 12,
    this.tripsCount = 4,
  });

  factory UserProfile.defaultUser() {
    return const UserProfile(
      id: 'usr_mayank',
      name: 'Mayank Pawar',
      email: 'mayankpawar@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      interests: ['Beaches', 'Food', 'Adventure'],
      savedPlacesCount: 14,
      tripsCount: 3,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      savedPlacesCount: json['saved_places_count'] ?? json['savedPlacesCount'] ?? 0,
      tripsCount: json['trips_count'] ?? json['tripsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'interests': interests,
      'saved_places_count': savedPlacesCount,
      'trips_count': tripsCount,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    List<String>? interests,
    int? savedPlacesCount,
    int? tripsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      savedPlacesCount: savedPlacesCount ?? this.savedPlacesCount,
      tripsCount: tripsCount ?? this.tripsCount,
    );
  }
}
