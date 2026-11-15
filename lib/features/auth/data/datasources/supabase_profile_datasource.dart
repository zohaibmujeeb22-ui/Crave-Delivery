import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract defining database and storage operations for user and restaurant onboarding.
abstract class SupabaseProfileDataSource {
  Future<Map<String, dynamic>?> getProfile(String userId);

  Future<void> createCustomerProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  });

  Future<Map<String, dynamic>> registerRestaurantOwner({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String restaurantName,
    String? restaurantDescription,
    required String category,
    required String city,
    required String address,
    required String restaurantContact,
    String? logoUrl,
    String? coverUrl,
  });

  Future<String> uploadRestaurantAsset({
    required String userId,
    required File file,
    required String assetType, // 'logos' or 'covers'
  });
}

/// Concrete implementation communicating with Supabase PostgreSQL and Storage.
class SupabaseProfileDataSourceImpl implements SupabaseProfileDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseProfileDataSourceImpl({SupabaseClient? supabaseClient})
    : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  @override
  Future<void> createCustomerProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  }) async {
    await _supabaseClient.from('profiles').insert({
      'id': userId,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim().toLowerCase(),
      'phone_number': phoneNumber.trim(),
      'role': 'customer',
      'account_status': 'active',
      'is_profile_completed': true,
    });
  }

  @override
  Future<Map<String, dynamic>> registerRestaurantOwner({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String restaurantName,
    String? restaurantDescription,
    required String category,
    required String city,
    required String address,
    required String restaurantContact,
    String? logoUrl,
    String? coverUrl,
  }) async {
    // Calls the PostgreSQL stored procedure we created in Migration 001
    final response = await _supabaseClient.rpc(
      'register_restaurant_owner',
      params: {
        'p_first_name': firstName.trim(),
        'p_last_name': lastName.trim(),
        'p_phone_number': phoneNumber.trim(),
        'p_restaurant_name': restaurantName.trim(),
        'p_restaurant_description': restaurantDescription?.trim(),
        'p_category': category,
        'p_city': city.trim(),
        'p_address': address.trim(),
        'p_restaurant_contact': restaurantContact.trim(),
        'p_logo_url': logoUrl,
        'p_cover_url': coverUrl,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<String> uploadRestaurantAsset({
    required String userId,
    required File file,
    required String assetType,
  }) async {
    final fileExtension = file.path.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Path complies with our Storage RLS: logos/{uid}/... or covers/{uid}/...
    final storagePath = '$assetType/$userId/$timestamp.$fileExtension';

    await _supabaseClient.storage
        .from('restaurant-assets')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    final publicUrl = _supabaseClient.storage
        .from('restaurant-assets')
        .getPublicUrl(storagePath);

    return publicUrl;
  }
}
