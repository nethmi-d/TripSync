import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/validators.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/profile_photo_service.dart';
import '../../auth/widgets/auth_gradient_button.dart';
import '../../auth/widgets/auth_textfield.dart';
import '../../auth/widgets/profile_photo_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _fullNameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneNumberController;
  bool _isLoading = false;
  XFile? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );
    _phoneNumberController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoBytes = await _selectedPhoto?.readAsBytes();
      await _authService.updateCurrentUserProfile(
        fullName: _fullNameController.text,
        displayName: _displayNameController.text,
        phoneNumber: _phoneNumberController.text,
        photoBytes: photoBytes,
        photoFilename: _selectedPhoto?.name,
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } on AuthServiceException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to update your profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        _showMessage('Choose a profile photo smaller than 2 MB.');
        return;
      }

      setState(() {
        _selectedPhoto = photo;
      });
    } catch (_) {
      _showMessage('Unable to select that photo. Please try another one.');
    }
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
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7FB),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePhotoPicker(
                  selectedPhoto: _selectedPhoto,
                  existingPhotoUrl: widget.user.photoUrl,
                  onPick: _isLoading ? null : _chooseProfilePhoto,
                  actionLabel:
                      widget.user.photoUrl == null && _selectedPhoto == null
                      ? 'Add profile photo'
                      : 'Change profile photo',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      AuthTextField(
                        label: 'Full Name *',
                        hintText: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                        controller: _fullNameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.requiredName(
                          value,
                          fieldName: 'Full name',
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        label: 'Display Name *',
                        hintText: 'Name shown to trip members',
                        icon: Icons.badge_outlined,
                        controller: _displayNameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (value) => Validators.requiredName(
                          value,
                          fieldName: 'Display name',
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        label: 'Telephone Number',
                        hintText: 'Enter your telephone number',
                        icon: Icons.phone_outlined,
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: Validators.optionalPhoneNumber,
                      ),
                      const SizedBox(height: 18),
                      const _ReadOnlyEmailField(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AuthGradientButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyEmailField extends StatelessWidget {
  const _ReadOnlyEmailField();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280), size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Email is your login address and cannot be changed from this screen.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
