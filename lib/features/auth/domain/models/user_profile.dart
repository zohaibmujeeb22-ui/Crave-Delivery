import 'package:flutter/foundation.dart';
import 'package:crave_delivery1/features/auth/domain/user_role.dart';

/// The account status matching PostgreSQL check constraint.
enum AccountStatus {
  active('active'),
  suspended('suspended'),
  pendingApproval('pending_approval');

  final String dbValue;
  const AccountStatus(this.dbValue);

  static AccountStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AccountStatus.active;
      case 'suspended':
        return AccountStatus.suspended;
      case 'pending_approval':
        return AccountStatus.pendingApproval;
      default:
        return AccountStatus.active;
    }
  }
}

/// Core domain entity representing an authenticated user's profile.
@immutable
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final AccountStatus accountStatus;
  final bool isProfileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.accountStatus = AccountStatus.active,
    this.isProfileCompleted = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed display name (e.g., "John Doe")
  String get fullName => '$firstName $lastName'.trim();

  /// Quick helper checks
  bool get isCustomer => role == UserRole.customer;
  bool get isRestaurantOwner => role == UserRole.restaurantOwner;
  bool get isActive => accountStatus == AccountStatus.active;

  /// Database-safe role value for PostgreSQL storage.
  /// This mirrors the value defined in [UserRole], but keeps serialization logic
  /// local to this model so it's explicit when writing to the database.
  String get roleDbValue {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.restaurantOwner:
        return 'restaurant_owner';
      default:
        return 'customer';
    }
  }

  /// Translates a PostgreSQL 'profiles' row into a Dart UserProfile object.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      accountStatus: AccountStatus.fromString(
        json['account_status'] as String?,
      ),
      isProfileCompleted: json['is_profile_completed'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts this object back into a database-compatible JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'role': roleDbValue,
      'account_status': accountStatus.dbValue,
      'is_profile_completed': isProfileCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Copies this object with updated values.
  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    AccountStatus? accountStatus,
    bool? isProfileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role &&
          accountStatus == other.accountStatus;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ role.hashCode ^ accountStatus.hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $fullName, role: $roleDbValue, status: ${accountStatus.dbValue})';
}
