import 'dart:io';
import 'package:crave_delivery1/app/app_colors.dart';
import 'package:crave_delivery1/features/auth/data/auth_repository.dart';
import 'package:crave_delivery1/features/auth/domain/models/resturant_profile.dart';
import 'package:crave_delivery1/features/auth/presentation/screens/login_screen.dart';
import 'package:crave_delivery1/features/auth/presentation/widgets/resturant_brand_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_state.dart';
import '../../domain/models/user_role.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/resturant_category_picker.dart';
import '../widgets/role_selector_toggle.dart';

/// Completes profile creation for users signing up via Google or Apple OAuth for the first time.
class OAuthRoleSelectionScreen extends ConsumerStatefulWidget {
  const OAuthRoleSelectionScreen({super.key});

  @override
  ConsumerState<OAuthRoleSelectionScreen> createState() =>
      _OAuthRoleSelectionScreenState();
}

class _OAuthRoleSelectionScreenState
    extends ConsumerState<OAuthRoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();

  UserRole _selectedRole = UserRole.customer;
  RestaurantCategory _selectedCategory = RestaurantCategory.fastFood;
  File? _logoFile;
  File? _coverFile;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Restaurant fields
  final _restaurantNameController = TextEditingController();
  final _restaurantDescController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _restaurantContactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentAuthUser;
    if (user != null) {
      final fullName = user.userMetadata?['full_name'] as String? ?? '';
      final parts = fullName.split(' ');
      if (parts.isNotEmpty) _firstNameController.text = parts.first;
      if (parts.length > 1) {
        _lastNameController.text = parts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _restaurantNameController.dispose();
    _restaurantDescController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _restaurantContactController.dispose();
    super.dispose();
  }

  Future<void> _submitProfileCompletion() async {
    HapticFeedback.lightImpact();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authRepositoryProvider).currentAuthUser;
    if (user == null) {
      context.go('/auth');
      return;
    }

    setState(() => _isLoading = true);
    final profileDataSource = ref.read(supabaseProfileDataSourceProvider);

    try {
      if (_selectedRole == UserRole.customer) {
        await profileDataSource.createCustomerProfile(
          userId: user.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: user.email ?? '',
          phoneNumber: _phoneController.text,
        );
      } else {
        String? logoUrl;
        String? coverUrl;

        if (_logoFile != null) {
          logoUrl = await profileDataSource.uploadRestaurantAsset(
            userId: user.id,
            file: _logoFile!,
            assetType: 'logos',
          );
        }

        if (_coverFile != null) {
          coverUrl = await profileDataSource.uploadRestaurantAsset(
            userId: user.id,
            file: _coverFile!,
            assetType: 'covers',
          );
        }

        await profileDataSource.registerRestaurantOwner(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
          restaurantName: _restaurantNameController.text,
          restaurantDescription: _restaurantDescController.text.isEmpty
              ? null
              : _restaurantDescController.text,
          category: _selectedCategory.displayName,
          city: _cityController.text,
          address: _addressController.text,
          restaurantContact: _restaurantContactController.text,
          logoUrl: logoUrl,
          coverUrl: coverUrl,
        );
      }

      // Re-evaluate session to update authoritative role state
      await ref.read(authControllerProvider.notifier).restoreSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete profile: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF4D4F),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      switch (next) {
        case CustomerAuthenticated():
          context.go('/customer/home');
          break;
        case RestaurantOwnerAuthenticated():
          context.go('/restaurant/dashboard');
          break;
        default:
          break;
      }
    });

    final isRestaurant = _selectedRole == UserRole.restaurantOwner;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Almost There!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select how you intend to use CRAVE to complete your account setup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Role Switcher
                  RoleSelectorToggle(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) =>
                        setState(() => _selectedRole = role),
                  ),
                  const SizedBox(height: 28),

                  // Name Inputs
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'First name',
                          validator: (String? value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) return 'First name is required';
                            if (name.length < 2) {
                              return 'First name is too short';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'Last name',
                          validator: (String? value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) return 'Last name is required';
                            if (name.length < 2) {
                              return 'Last name is too short';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _phoneController,
                    label: isRestaurant
                        ? 'Owner Phone Number'
                        : 'Delivery Contact Phone',
                    hint: '+92 300 1234567',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (String? value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return 'Phone number is required';
                      if (phone.length < 8) return 'Enter a valid phone number';
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  // Restaurant section
                  if (isRestaurant) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 16),
                    const Text(
                      'Restaurant Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _restaurantNameController,
                      label: 'Restaurant Name',
                      hint: 'e.g. Gourmet Burger Co.',
                      prefixIcon: Icons.storefront_outlined,
                      validator: (String? v) =>
                          AuthValidators.validateRequired(v, 'Restaurant name'),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    RestaurantCategoryPicker(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (c) =>
                          setState(() => _selectedCategory = c),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AuthTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'e.g. Lahore',
                            validator: (String? v) =>
                                AuthValidators.validateRequired(v, 'City'),
                            enabled: !_isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: AuthTextField(
                            controller: _restaurantContactController,
                            label: 'Kitchen Phone',
                            hint: 'Order hotline',
                            keyboardType: TextInputType.phone,
                            validator: AuthValidators.validatePhoneNumber,
                            enabled: !_isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _addressController,
                      label: 'Full Street Address',
                      hint: 'Street, Sector, Area',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (String? v) =>
                          AuthValidators.validateRequired(v, 'Address'),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _restaurantDescController,
                      label: 'Short Description (Optional)',
                      hint: 'Specialty dishes and food philosophy',
                      maxLines: 2,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    RestaurantBrandingPicker(
                      logoFile: _logoFile,
                      coverFile: _coverFile,
                      onLogoChanged: (f) => setState(() => _logoFile = f),
                      onCoverChanged: (f) => setState(() => _coverFile = f),
                    ),
                  ],

                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _isLoading ? null : _submitProfileCompletion,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? AppColors.primary.withOpacity(0.6)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Complete Setup & Enter CRAVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
