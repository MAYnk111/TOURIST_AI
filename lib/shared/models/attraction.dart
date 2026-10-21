import '../../core/config/api_config.dart';

class Attraction {
  final String id;
  final String name;
  final String destinationId;
  final String destinationName;
  final String category;
  final String description;
  final String imageUrl;
  final List<String> photos;
  final double? rating;
  final int? reviewCount;
  final List<String> tags;
  final double estimatedDurationHours;
  final double? entryFeeMin;
  final double? entryFeeMax;
  final double latitude;
  final double longitude;
  final String? openingHours;
  final String? formattedAddress;
  final String? priceLevel;
  final List<String> photoAttributions;
  final String provider;
  final bool isLiveData;
  final bool isSaved;

  const Attraction({
    required this.id,
    required this.name,
    required this.destinationId,
    required this.destinationName,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.photos = const [],
    this.rating,
    this.reviewCount,
    this.tags = const [],
    this.estimatedDurationHours = 2.0,
    this.entryFeeMin,
    this.entryFeeMax,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.openingHours,
    this.formattedAddress,
    this.priceLevel,
    this.photoAttributions = const [],
    this.provider = 'curated',
    this.isLiveData = false,
    this.isSaved = false,
  });

  Attraction copyWith({
    String? id,
    String? name,
    String? destinationId,
    String? destinationName,
    String? category,
    String? description,
    String? imageUrl,
    List<String>? photos,
    double? rating,
    int? reviewCount,
    List<String>? tags,
    double? estimatedDurationHours,
    double? entryFeeMin,
    double? entryFeeMax,
    double? latitude,
    double? longitude,
    String? openingHours,
    String? formattedAddress,
    String? priceLevel,
    List<String>? photoAttributions,
    String? provider,
    bool? isLiveData,
    bool? isSaved,
  }) {
    return Attraction(
      id: id ?? this.id,
      name: name ?? this.name,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tags: tags ?? this.tags,
      estimatedDurationHours: estimatedDurationHours ?? this.estimatedDurationHours,
      entryFeeMin: entryFeeMin ?? this.entryFeeMin,
      entryFeeMax: entryFeeMax ?? this.entryFeeMax,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingHours: openingHours ?? this.openingHours,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      priceLevel: priceLevel ?? this.priceLevel,
      photoAttributions: photoAttributions ?? this.photoAttributions,
      provider: provider ?? this.provider,
      isLiveData: isLiveData ?? this.isLiveData,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static String _resolveUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('/')) {
      return '${ApiConfig.serverUrl}$raw';
    }
    return raw;
  }

  factory Attraction.fromJson(Map<String, dynamic> json) {
    final rawMainImg = json['image_url'] ?? json['imageUrl'] ?? '';
    final rawPhotos = List<String>.from(json['photos'] ?? []);

    return Attraction(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      destinationId: json['destination_id'] ?? json['destinationId'] ?? 'goa',
      destinationName: json['destination_name'] ?? json['destinationName'] ?? 'Goa',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      imageUrl: _resolveUrl(rawMainImg),
      photos: rawPhotos.map((p) => _resolveUrl(p)).toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] ?? json['reviewCount'] as num?)?.toInt(),
      tags: List<String>.from(json['tags'] ?? []),
      estimatedDurationHours: (json['estimated_duration_hours'] ?? json['estimatedDurationHours'] as num?)?.toDouble() ?? 2.0,
      entryFeeMin: (json['entry_fee_min'] ?? json['entryFeeMin'] as num?)?.toDouble(),
      entryFeeMax: (json['entry_fee_max'] ?? json['entryFeeMax'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      openingHours: json['opening_hours'] ?? json['openingHours'],
      formattedAddress: json['formatted_address'] ?? json['formattedAddress'],
      priceLevel: json['price_level'] ?? json['priceLevel'],
      photoAttributions: List<String>.from(json['photo_attributions'] ?? json['photoAttributions'] ?? []),
      provider: json['provider'] ?? 'curated',
      isLiveData: json['is_live_data'] ?? json['isLiveData'] ?? false,
      isSaved: json['is_saved'] ?? json['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destination_id': destinationId,
      'destination_name': destinationName,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'photos': photos,
      'rating': rating,
      'review_count': reviewCount,
      'tags': tags,
      'estimated_duration_hours': estimatedDurationHours,
      'entry_fee_min': entryFeeMin,
      'entry_fee_max': entryFeeMax,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours,
      'formatted_address': formattedAddress,
      'price_level': priceLevel,
      'photo_attributions': photoAttributions,
      'provider': provider,
      'is_live_data': isLiveData,
      'is_saved': isSaved,
    };
  }

  String get formattedDuration {
    if (estimatedDurationHours == estimatedDurationHours.roundToDouble()) {
      return '${estimatedDurationHours.toInt()} hrs';
    }
    return '$estimatedDurationHours hrs';
  }

  String get formattedReviewCount {
    if (reviewCount == null) return '';
    if (reviewCount! >= 1000) {
      return '${(reviewCount! / 1000).toStringAsFixed(1)}k';
    }
    return '$reviewCount';
  }

  String get formattedEntryFee {
    if (entryFeeMin == null || entryFeeMax == null) {
      return 'Price not reported';
    }
    if (entryFeeMin == 0 && entryFeeMax == 0) {
      return 'Free Entry';
    }
    return '₹${entryFeeMin!.toInt()} - ₹${entryFeeMax!.toInt()}';
  }

  String get formattedOpeningHours {
    return openingHours ?? 'Opening hours not reported';
  }
}
