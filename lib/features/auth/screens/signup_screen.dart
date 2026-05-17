import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_gradient_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _signup() {
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  void _goToLogin() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
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

          AuthTextField(
            label: 'Full Name',
            hintText: 'Enter your name',
            icon: Icons.person_outline,
            controller: _nameController,
            keyboardType: TextInputType.name,
          ),

          const SizedBox(height: 18),

          AuthTextField(
            label: 'Email',
            hintText: 'Enter your email',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 18),

          AuthTextField(
            label: 'Password',
            hintText: 'Create a password',
            icon: Icons.lock_outline,
            controller: _passwordController,
            obscureText: !_showPassword,
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
            label: 'Confirm Password',
            hintText: 'Confirm your password',
            icon: Icons.lock_outline,
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
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

          AuthGradientButton(text: 'Sign Up', onPressed: _signup),

          const SizedBox(height: 22),

          Center(
            child: TextButton(
              onPressed: _goToLogin,
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
    );
  }
}
