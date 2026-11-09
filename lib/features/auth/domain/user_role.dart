enum UserRole {
  customer,
  restaurantOwner,
  unknown;

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
