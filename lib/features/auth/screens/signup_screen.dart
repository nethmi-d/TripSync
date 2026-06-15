import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../services/profile_photo_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_gradient_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_textfield.dart';
import '../widgets/profile_photo_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  XFile? _selectedPhoto;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoBytes = await _selectedPhoto?.readAsBytes();
      await _authService.signUpWithEmail(
        fullName: _fullNameController.text,
        displayName: _displayNameController.text,
        phoneNumber: _phoneNumberController.text,
        email: _emailController.text,
        password: _passwordController.text,
        photoBytes: photoBytes,
        photoFilename: _selectedPhoto?.name,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on AuthServiceException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to create your account. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToLogin() {
    Navigator.pop(context);
  }

  Future<void> _chooseProfilePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 82,
      );
      if (photo == null) {
        return;
      }

      final size = await photo.length();
      if (size > ProfilePhotoService.maximumPhotoBytes) {
        _showError('Choose a profile photo smaller than 2 MB.');
        return;
      }

      setState(() {
        _selectedPhoto = photo;
      });
    } catch (_) {
      _showError('Unable to select that photo. Please try another one.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          children: [
            const AuthHeader(
              subtitle: 'Create your account and start planning',
            ),
            const SizedBox(height: 36),
            _buildSignupCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 26),

            ProfilePhotoPicker(
              selectedPhoto: _selectedPhoto,
              existingPhotoUrl: null,
              onPick: _isLoading ? null : _chooseProfilePhoto,
              actionLabel: _selectedPhoto == null
                  ? 'Add profile photo (optional)'
                  : 'Change profile photo',
            ),

            const SizedBox(height: 18),

            AuthTextField(
              label: 'Full Name *',
              hintText: 'Enter your full name',
              icon: Icons.person_outline,
              controller: _fullNameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.requiredName(value, fieldName: 'Full name'),
            ),

            const SizedBox(height: 18),

            AuthTextField(
              label: 'Display Name *',
              hintText: 'Name shown to trip members',
              icon: Icons.badge_outlined,
              controller: _displayNameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.requiredName(value, fieldName: 'Display name'),
            ),

            const SizedBox(height: 18),

            AuthTextField(
              label: 'Telephone Number',
              hintText: 'Enter your telephone number',
              icon: Icons.phone_outlined,
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.optionalPhoneNumber,
            ),

            const SizedBox(height: 18),

            AuthTextField(
              label: 'Email *',
              hintText: 'Enter your email',
              icon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),

            const SizedBox(height: 18),

            AuthTextField(
              label: 'Password *',
              hintText: 'Create a password',
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),

            const SizedBox(height: 18),

            AuthTextField(
              label: 'Confirm Password *',
              hintText: 'Confirm your password',
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),

            const SizedBox(height: 24),

            AuthGradientButton(
              text: 'Sign Up',
              onPressed: _signup,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 22),

            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _goToLogin,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
