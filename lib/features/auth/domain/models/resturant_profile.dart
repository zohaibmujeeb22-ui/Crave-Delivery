import 'package:flutter/foundation.dart';

/// Curated categories matching our PostgreSQL constraint.
enum RestaurantCategory {
  fastFood('Fast Food'),
  pakistani('Pakistani'),
  chinese('Chinese'),
  italian('Italian'),
  pizza('Pizza'),
  burgers('Burgers'),
  desserts('Desserts'),
  bakery('Bakery'),
  other('Other');

  final String displayName;
  const RestaurantCategory(this.displayName);

  static RestaurantCategory fromString(String? value) {
    for (final category in RestaurantCategory.values) {
      if (category.displayName.toLowerCase() == value?.toLowerCase()) {
        return category;
      }
    }
    return RestaurantCategory.other;
  }
}

/// Domain entity representing a restaurant establishment.
@immutable
class RestaurantProfile {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final RestaurantCategory category;
  final String city;
  final String address;
  final String contactNumber;
  final String? logoUrl;
  final String? coverUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.category,
    required this.city,
    required this.address,
    required this.contactNumber,
    this.logoUrl,
    this.coverUrl,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a RestaurantProfile from the PostgreSQL 'restaurants' row.
  factory RestaurantProfile.fromJson(Map<String, dynamic> json) {
    return RestaurantProfile(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: RestaurantCategory.fromString(json['category'] as String?),
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts the restaurant back to a PostgreSQL-compatible Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'category': category.displayName,
      'city': city,
      'address': address,
      'contact_number': contactNumber,
      'logo_url': logoUrl,
      'cover_url': coverUrl,
      'is_verified': isVerified,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Creates a copy with updated attributes.
  RestaurantProfile copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    RestaurantCategory? category,
    String? city,
    String? address,
    String? contactNumber,
    String? logoUrl,
    String? coverUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      city: city ?? this.city,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ ownerId.hashCode ^ name.hashCode;

  @override
  String toString() =>
      'RestaurantProfile(id: $id, name: $name, category: ${category.displayName}, city: $city)';
}
