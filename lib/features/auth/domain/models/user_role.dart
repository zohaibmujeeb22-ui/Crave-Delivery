/// The authoritative user roles in CRAVE.
enum UserRole {
  customer,
  restaurantOwner,
  unknown;

  /// The exact string value expected by PostgreSQL database constraints.
  String get dbValue {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.restaurantOwner:
        return 'restaurant_owner';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  /// Converts a database string back into our Dart enum.
  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'restaurant_owner':
      case 'restaurant':
        return UserRole.restaurantOwner;
      default:
        return UserRole.unknown;
    }
  }
}
