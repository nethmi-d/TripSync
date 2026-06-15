import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  late Future<AppUser?> _profileFuture;
  bool _isAccountActionRunning = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUserProfile();
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = _authService.getCurrentUserProfile();
    });
  }

  Future<void> _editProfile(AppUser user) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );

    if (updated == true) {
      _reloadProfile();
      _showMessage('Profile updated successfully.');
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access TripSync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    await _runAccountAction(() async {
      await _authService.logout();
      _goToLogin();
    });
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your TripSync profile. Enter your password to confirm.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final password = passwordController.text;
              if (password.isNotEmpty) {
                Navigator.pop(context, password);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    passwordController.dispose();

    if (password == null) {
      return;
    }

    await _runAccountAction(() async {
      await _authService.deleteAccount(password: password);
      _goToLogin();
    });
  }

  Future<void> _runAccountAction(Future<void> Function() action) async {
    setState(() {
      _isAccountActionRunning = true;
    });

    try {
      await action();
    } on AuthServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to complete this action. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isAccountActionRunning = false;
        });
      }
    }
  }

  void _goToLogin() {
    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7FB),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: FutureBuilder<AppUser?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ProfileErrorState(onRetry: _reloadProfile);
          }

          final user = snapshot.data;
          if (user == null) {
            return _ProfileErrorState(
              message: 'Your user profile could not be found.',
              onRetry: _reloadProfile,
            );
          }

          return _buildProfile(user);
        },
      ),
    );
  }

  Widget _buildProfile(AppUser user) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      children: [
        _ProfileHeader(
          user: user,
          onEdit: _isAccountActionRunning ? null : () => _editProfile(user),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Personal information'),
        const SizedBox(height: 10),
        _ProfilePanel(
          children: [
            _ProfileDetail(
              icon: Icons.person_outline_rounded,
              label: 'Full name',
              value: user.fullName,
            ),
            _ProfileDetail(
              icon: Icons.badge_outlined,
              label: 'Display name',
              value: user.displayName,
            ),
            _ProfileDetail(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            _ProfileDetail(
              icon: Icons.phone_outlined,
              label: 'Telephone number',
              value: user.phoneNumber ?? 'Not added',
              isMuted: user.phoneNumber == null,
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Account'),
        const SizedBox(height: 10),
        _ProfilePanel(
          children: [
            _AccountAction(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              subtitle: 'Sign out from this device',
              onTap: _isAccountActionRunning ? null : _logout,
            ),
            _AccountAction(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              subtitle: 'Permanently remove your account',
              color: const Color(0xFFDC2626),
              onTap: _isAccountActionRunning ? null : _deleteAccount,
              showDivider: false,
            ),
          ],
        ),
        if (_isAccountActionRunning) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onEdit;

  const _ProfileHeader({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoUrl;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFDCEEFF),
          backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
          child: photoUrl == null
              ? Text(
                  _initials(user.displayName),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 14),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Profile'),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final initials = words.map((word) => word[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  final List<Widget> children;

  const _ProfilePanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMuted;
  final bool showDivider;

  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.isMuted = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        color: isMuted
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 52, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

class _AccountAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool showDivider;

  const _AccountAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = const Color(0xFF374151),
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          enabled: onTap != null,
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.chevron_right_rounded, color: color),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 56, color: Color(0xFFE5E7EB)),
      ],
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorState({
    this.message = 'Unable to load your profile.',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
