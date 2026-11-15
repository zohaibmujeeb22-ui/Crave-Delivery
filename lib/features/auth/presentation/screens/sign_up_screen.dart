import 'package:crave_delivery1/app/app_colors.dart';
import 'package:crave_delivery1/features/auth/controllers/auth_controllers.dart';
import 'package:crave_delivery1/features/auth/controllers/auth_state.dart';
import 'package:crave_delivery1/features/auth/controllers/registration_controller.dart';
import 'package:crave_delivery1/features/auth/presentation/screens/login_screen.dart';
import 'package:crave_delivery1/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:crave_delivery1/features/auth/presentation/widgets/role_selector_toggle.dart';
import 'package:crave_delivery1/features/auth/presentation/widgets/social_auth_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dynamic registration screen supporting both Customer and Restaurant onboarding.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _restaurantNameController = TextEditingController();
  final _restaurantDescController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _restaurantContactController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _restaurantNameController.dispose();
    _restaurantDescController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _restaurantContactController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    HapticFeedback.lightImpact();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Color(0xFFFF4D4F),
        ),
      );
      return;
    }

    final regState = ref.read(registrationControllerProvider);
    final regNotifier = ref.read(registrationControllerProvider.notifier);

    if (regState.isCustomer) {
      regNotifier.registerCustomer(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      regNotifier.registerRestaurantOwner(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        restaurantName: _restaurantNameController.text.trim(),
        restaurantDescription: _restaurantDescController.text.trim().isEmpty
            ? null
            : _restaurantDescController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        restaurantContact: _restaurantContactController.text.trim(),
      );
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
        case ProfileCompletionRequired():
          context.go('/profile/setup');
          break;
        default:
          break;
      }
    });

    ref.listen<RegistrationState>(registrationControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFFF4D4F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    final regState = ref.watch(registrationControllerProvider);
    final regNotifier = ref.read(registrationControllerProvider.notifier);
    final isLoading = regState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Join CRAVE',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          regState.isCustomer
                              ? 'Discover curated foods & order with direct COD.'
                              : 'Showcase your kitchen & grow your food orders.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  RoleSelectorToggle(
                    selectedRole: regState.selectedRole,
                    onRoleChanged: (role) => regNotifier.selectRole(role),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'e.g. John',
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              AuthValidators.validateName(value, 'First name'),
                          enabled: !isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'e.g. Doe',
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              AuthValidators.validateName(value, 'Last name'),
                          enabled: !isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'name@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.validateEmail,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+1 234 567 890',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.validatePhone,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.validatePassword,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),

                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Repeat your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 20),

                  if (!regState.isCustomer) ...[
                    AuthTextField(
                      controller: _restaurantNameController,
                      label: 'Restaurant Name',
                      hint: 'e.g. Black Iron Grill',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          AuthValidators.validateName(value, 'Restaurant name'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _restaurantDescController,
                      label: 'Restaurant Description',
                      hint: 'Tell customers what makes your food special',
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'e.g. Lahore',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          AuthValidators.validateName(value, 'City'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Street address',
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          AuthValidators.validateName(value, 'Address'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _restaurantContactController,
                      label: 'Restaurant Contact',
                      hint: 'Business contact number',
                      textInputAction: TextInputAction.done,
                      validator: AuthValidators.validatePhone,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 20),
                  ],

                  GestureDetector(
                    onTap: isLoading ? null : _submitRegistration,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isLoading
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
                      child: isLoading
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
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SocialAuthButtons(
                    isLoading: isLoading,
                    onGooglePressed: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
                    onApplePressed: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithApple(),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/auth'),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
