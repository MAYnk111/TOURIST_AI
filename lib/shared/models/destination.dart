class Destination {
  final String id;
  final String name;
  final String country;
  final String state;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final bool isTrending;
  final double? latitude;
  final double? longitude;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.state,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    this.isTrending = false,
    this.latitude,
    this.longitude,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 1000,
      tags: List<String>.from(json['tags'] ?? []),
      isTrending: json['is_trending'] ?? json['isTrending'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'state': state,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'tags': tags,
      'is_trending': isTrending,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
